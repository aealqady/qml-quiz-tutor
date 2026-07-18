"""
Controllers to bridge QML UI with Python backend logic.
"""

from datetime import datetime, timedelta, timezone
from PyQt6.QtCore import QObject, pyqtSlot, pyqtProperty, pyqtSignal, QUrl, QThread
from sqlalchemy import func
from pathlib import Path
from db.database import get_session
from db.models import Document, Question, ExamSession, ExamAnswer, ReviewCard, Setting, SummaryChat
from workers.llm_worker import PDFWorker, GenerationWorker, EvaluationWorker
from core.pdf_extractor import extract_text
from core.llm_client import LLMClient
import requests
import threading
from fpdf import FPDF
import os
import arabic_reshaper
from bidi.algorithm import get_display

class UploadController(QObject):
    documentsChanged = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._docs = []
        self._workers = []
        self._load_from_db()

    def _load_from_db(self):
        session = get_session()
        docs = session.query(Document).order_by(Document.uploaded_at.desc()).all()
        self._docs = [
            {
                "id": str(d.id),
                "name": d.name,
                "pages": d.pages,
                "questions": len(d.questions),
                "status": d.status,
                "uploadedAt": d.uploaded_at.strftime("%Y-%m-%d") if d.uploaded_at else ""
            } for d in docs
        ]
        session.close()
        self.documentsChanged.emit()

    @pyqtProperty(list, notify=documentsChanged)
    def documents(self):
        return self._docs

    @pyqtSlot(list)
    def processFiles(self, urls):
        """Called from QML when files are dropped."""
        for url in urls:
            path = QUrl(url).toLocalFile()
            if not path.lower().endswith('.pdf'):
                continue
                
            session = get_session()
            doc = Document(name=Path(path).name, file_path=path, status="processing")
            session.add(doc)
            session.commit()
            doc_id = doc.id
            session.close()
            
            self._load_from_db()
            
            # Start background PDF worker
            worker = PDFWorker(path)
            worker.finished.connect(lambda res, did=doc_id: self._on_pdf_finished(did, res))
            worker.error.connect(lambda err, did=doc_id: self._on_pdf_error(did, err))
            # Keep a reference so it isn't garbage collected
            self._workers.append(worker)
            worker.start()

    def _on_pdf_finished(self, doc_id, result):
        session = get_session()
        doc = session.query(Document).get(doc_id)
        if doc:
            doc.pages = result["page_count"]
            doc.status = "ready"
            session.commit()
        session.close()
        self._load_from_db()

    def _on_pdf_error(self, doc_id, error_msg):
        session = get_session()
        doc = session.query(Document).get(doc_id)
        if doc:
            doc.status = "error"
            session.commit()
        session.close()
        self._load_from_db()
        print(f"PDF Error for doc {doc_id}: {error_msg}")


class ExamController(QObject):
    generationProgressChanged = pyqtSignal()
    questionsChanged = pyqtSignal()
    examSubmitted = pyqtSignal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._gen_step = ""
        self._gen_progress = 0
        self._questions = []
        self._worker = None

    @pyqtProperty(str, notify=generationProgressChanged)
    def generationStep(self):
        return self._gen_step

    @pyqtProperty(int, notify=generationProgressChanged)
    def generationProgress(self):
        return self._gen_progress

    @pyqtProperty(list, notify=questionsChanged)
    def questions(self):
        return self._questions

    @pyqtSlot(int, int, list, list, str)
    def startGeneration(self, doc_id, count, types, difficulties, language="Arabic"):
        """Called from QML to start exam generation."""
        if self._worker is not None and self._worker.isRunning():
            return  # Already generating
            
        self._gen_step = "Initializing..."
        self._gen_progress = 0
        self.generationProgressChanged.emit()
        
        self._worker = GenerationWorker(doc_id, count, types, difficulties, language)
        self._worker.stepChanged.connect(self._on_gen_step)
        self._worker.finished.connect(self._on_gen_finished)
        self._worker.start()

    def _on_gen_step(self, step_idx, progress, msg):
        self._gen_step = msg
        self._gen_progress = progress
        self.generationProgressChanged.emit()

    def _on_gen_finished(self, questions_data):
        self._gen_progress = 100
        self._gen_step = "Done!"
        self.generationProgressChanged.emit()
        self._questions = questions_data
        self.questionsChanged.emit()

    @pyqtSlot('QVariantMap')
    def submitExam(self, user_answers_dict):
        """Submit user answers, score them, save to DB, and update Progress."""
        session = get_session()
        try:
            exam_session = ExamSession(score=0.0, status="completed")
            session.add(exam_session)
            session.flush()

            total_score = 0
            
            for i, q in enumerate(self._questions):
                idx = str(i)
                ans = user_answers_dict.get(idx, "")
                
                db_q_id = q.get("id")
                if not db_q_id:
                    continue
                    
                is_correct = False
                eval_score = 0
                feedback = ""
                
                if q["type"] in ["mcq", "truefalse"]:
                    is_correct = str(ans).strip().lower() == str(q.get("correct_answer")).strip().lower()
                    eval_score = 100 if is_correct else 0
                    feedback = q.get("explanation", "")
                else:
                    from core.answer_evaluator import evaluate
                    res = evaluate(q.get("text", ""), q.get("key_points", []), str(ans))
                    eval_score = res["score"]
                    is_correct = eval_score >= 50
                    feedback = res["feedback"]

                total_score += eval_score
                
                exam_ans = ExamAnswer(
                    session_id=exam_session.id,
                    question_id=db_q_id,
                    user_answer=str(ans),
                    is_correct=is_correct,
                    eval_score=eval_score,
                    eval_feedback=feedback
                )
                session.add(exam_ans)
                
            if len(self._questions) > 0:
                exam_session.score = total_score / len(self._questions)
                
            session.commit()
            self.examSubmitted.emit()
        except Exception as e:
            session.rollback()
            print(f"Error submitting exam: {e}")
        finally:
            session.close()


class ProgressController(QObject):
    statsChanged = pyqtSignal()
    activityChanged = pyqtSignal()
    srsChanged = pyqtSignal()
    topicsChanged = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._exams_completed = 0
        self._avg_score = 0.0
        self._questions_answered = 0
        self._study_streak = 0
        self._activity_data = []
        self._srs_data = []
        self._radar_data = []
        self._topic_breakdown = []
        self.refresh()

    @pyqtProperty(int, notify=statsChanged)
    def examsCompleted(self): return self._exams_completed

    @pyqtProperty(str, notify=statsChanged)
    def avgScoreStr(self): return f"{int(self._avg_score)}%"

    @pyqtProperty(int, notify=statsChanged)
    def questionsAnswered(self): return self._questions_answered

    @pyqtProperty(str, notify=statsChanged)
    def studyStreakStr(self): return f"{self._study_streak}d"

    @pyqtProperty(list, notify=activityChanged)
    def activityData(self): return self._activity_data

    @pyqtProperty(list, notify=srsChanged)
    def srsData(self): return self._srs_data

    @pyqtProperty(list, notify=topicsChanged)
    def radarData(self): return self._radar_data

    @pyqtProperty(list, notify=topicsChanged)
    def topicBreakdown(self): return self._topic_breakdown

    @pyqtSlot()
    def refresh(self):
        """Fetch all analytics from SQLite and update QML properties."""
        session = get_session()
        try:
            # 1. Basic Stats
            self._exams_completed = session.query(ExamSession).filter_by(status="completed").count()
            
            avg_res = session.query(func.avg(ExamSession.score)).filter_by(status="completed").scalar()
            self._avg_score = avg_res if avg_res is not None else 0.0
            
            self._questions_answered = session.query(ExamAnswer).filter(ExamAnswer.user_answer != None).count()
            
            # Simplified streak (mocking real streak logic for now based on recent sessions)
            # In a real app, this would check consecutive days of ExamSession.created_at
            recent_sessions = session.query(ExamSession.created_at).order_by(ExamSession.created_at.desc()).limit(10).all()
            self._study_streak = len(set(s.created_at.date() for s in recent_sessions)) if recent_sessions else 0
            
            # 2. Daily Activity (Mocking last 7 days since DB might be empty)
            # We will generate a rolling 7-day window. If no data, use some default structure.
            now = datetime.now(timezone.utc)
            self._activity_data = []
            for i in range(6, -1, -1):
                d = now - timedelta(days=i)
                # Count correct/incorrect for this day
                # SQLite dates can be tricky, so we do client-side filtering for this small scale
                # Real scale would use strftime grouping
                start_day = d.replace(hour=0, minute=0, second=0, microsecond=0)
                end_day = start_day + timedelta(days=1)
                
                answers_today = session.query(ExamAnswer).join(ExamSession).filter(
                    ExamSession.created_at >= start_day,
                    ExamSession.created_at < end_day
                ).all()
                
                correct = sum(1 for a in answers_today if a.is_correct)
                incorrect = sum(1 for a in answers_today if not a.is_correct)
                
                self._activity_data.append({
                    "day": d.strftime("%b %d"),
                    "correct": correct,
                    "incorrect": incorrect
                })

            # 3. SRS Schedule
            # Group review cards by topic
            upcoming = session.query(ReviewCard).join(Question).filter(
                ReviewCard.next_review <= now + timedelta(days=7)
            ).all()
            
            topic_counts = {}
            for card in upcoming:
                t = card.question.topic or "General"
                topic_counts[t] = topic_counts.get(t, 0) + 1
                
            self._srs_data = [{"topic": t, "count": c, "date": "Today"} for t, c in topic_counts.items()]
            if not self._srs_data:
                # Fallback if DB is empty to show UI
                self._srs_data = [
                    {"topic": "ML Basics (No Data)", "count": 0, "date": "Today"}
                ]

            # 4. Topics Breakdown
            # Calculate average accuracy per topic
            answers = session.query(ExamAnswer).join(Question).all()
            topic_stats = {}
            for a in answers:
                t = a.question.topic or "General"
                if t not in topic_stats:
                    topic_stats[t] = {"total": 0, "correct": 0}
                topic_stats[t]["total"] += 1
                if a.is_correct:
                    topic_stats[t]["correct"] += 1
                    
            radar_res = []
            breakdown_res = []
            for t, stats in topic_stats.items():
                score = int((stats["correct"] / stats["total"]) * 100) if stats["total"] > 0 else 0
                radar_res.append({"topic": t, "score": score})
                color = "#3fb950" if score >= 75 else ("#d29922" if score >= 60 else "#f85149")
                breakdown_res.append({"topic": t, "score": score, "color": color})
                
            self._radar_data = radar_res or [{"topic": "No Data", "score": 0}]
            self._topic_breakdown = breakdown_res or [{"topic": "No Data", "score": 0, "color": "#8b949e"}]

            self.statsChanged.emit()
            self.activityChanged.emit()
            self.srsChanged.emit()
            self.topicsChanged.emit()

        finally:
            session.close()


class SettingsController(QObject):
    modelsChanged = pyqtSignal()
    statusChanged = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._models = []
        self._selected_model = ""
        self._ollama_url = "http://localhost:11434"
        self._status_message = "Ready"
        self._is_checking = False
        self._load_settings()

    def _load_settings(self):
        session = get_session()
        try:
            url_set = session.query(Setting).filter_by(key="ollama_url").first()
            if url_set and url_set.value:
                self._ollama_url = url_set.value
                
            model_set = session.query(Setting).filter_by(key="selected_model").first()
            if model_set and model_set.value:
                self._selected_model = model_set.value
        finally:
            session.close()
            
        # Automatically fetch available models on startup
        self.checkOllama(self._ollama_url)

    @pyqtProperty(list, notify=modelsChanged)
    def availableModels(self): return self._models

    @pyqtProperty(str, notify=modelsChanged)
    def selectedModel(self): return self._selected_model

    @pyqtProperty(str, notify=modelsChanged)
    def ollamaUrl(self): return self._ollama_url

    @pyqtProperty(str, notify=statusChanged)
    def statusMessage(self): return self._status_message

    @pyqtProperty(bool, notify=statusChanged)
    def isChecking(self): return self._is_checking

    @pyqtSlot(str, str)
    def saveSettings(self, url, model):
        self._ollama_url = url
        self._selected_model = model
        
        session = get_session()
        try:
            # Upsert url
            url_set = session.query(Setting).filter_by(key="ollama_url").first()
            if not url_set:
                url_set = Setting(key="ollama_url")
                session.add(url_set)
            url_set.value = url
            
            # Upsert model
            model_set = session.query(Setting).filter_by(key="selected_model").first()
            if not model_set:
                model_set = Setting(key="selected_model")
                session.add(model_set)
            model_set.value = model
            
            session.commit()
            self._status_message = "Settings saved successfully."
        except Exception as e:
            self._status_message = f"Error saving settings: {e}"
        finally:
            session.close()
            
        self.modelsChanged.emit()
        self.statusChanged.emit()

    @pyqtSlot(str)
    def checkOllama(self, url):
        self._is_checking = True
        self._status_message = "Checking connection..."
        self.statusChanged.emit()
        
        # Run in background to avoid freezing UI
        threading.Thread(target=self._fetch_models_bg, args=(url,), daemon=True).start()

    def _fetch_models_bg(self, url):
        try:
            resp = requests.get(f"{url}/api/tags", timeout=5)
            resp.raise_for_status()
            data = resp.json()
            models = [m.get("name") for m in data.get("models", [])]
            
            # Need to update UI on main thread safely, but in PyQt simple variable assignment + signal emit is often okay
            # Better practice is to use a signal, but we will use QMetaObject.invokeMethod if needed.
            # Here, emitting the signal from the background thread might cause issues, so we just do it carefully.
            self._models = models
            if models:
                self._status_message = f"Connected! Found {len(models)} models."
            else:
                self._status_message = "Connected, but no models found. (Try 'ollama pull llama3')"
                
        except requests.exceptions.RequestException as e:
            self._models = []
            self._status_message = "Failed to connect to Ollama. Is it running?"
            print(f"Ollama connection error: {e}")
            
        self._is_checking = False
        
        # Emitting signals from background thread in PyQt6 is thread-safe for cross-thread connections
        # if the connection type is QueuedConnection (default across threads).
        self.modelsChanged.emit()
        self.statusChanged.emit()

class SummaryWorker(QThread):
    finished = pyqtSignal(str, str) # text, pdf_path
    error = pyqtSignal(str)

    def __init__(self, doc_id, user_prompt, parent=None):
        super().__init__(parent)
        self.doc_id = doc_id
        self.user_prompt = user_prompt

    def run(self):
        try:
            session = get_session()
            doc = session.query(Document).get(self.doc_id)
            if not doc or not doc.file_path:
                raise ValueError("Document not found.")
            file_path = doc.file_path
            doc_name = doc.name
            session.close()

            # 1. Extract text
            extraction_result = extract_text(file_path)
            full_text = extraction_result["text"]
            
            words = full_text.split()
            if len(words) > 3000:
                words = words[:3000]
            short_text = " ".join(words)

            # 2. Call LLM
            llm = LLMClient()
            import re
            is_arabic_prompt = bool(re.search(r'[\u0600-\u06FF]', self.user_prompt))
            
            if is_arabic_prompt:
                system_prompt = (
                    "أنت خبير أكاديمي في التلخيص والتعليم. "
                    "قم بإنشاء ملخص شامل ومنظم للنص المقدم بناءً على تعليمات المستخدم. "
                    "بعد الملخص، يجب عليك إضافة قسم خاص بالأسئلة يحتوي بالضبط على: "
                    "1. 20 سؤال 'عرف' مع إجاباتها النموذجية. "
                    "2. 10 أسئلة 'أكمل الفراغ' مع إجاباتها. "
                    "3. 5 أسئلة 'صح أم خطأ' مع إجاباتها. "
                    "يجب أن يكون ردك باللغة العربية بالكامل. استخدم عناوين ونقاط واضحة لترتيب المحتوى."
                )
            else:
                system_prompt = (
                    "You are an expert academic summarizer and tutor. "
                    "Generate a well-structured summary of the provided text based on the user's instructions. "
                    "After the summary, you MUST append a dedicated Questions section containing exactly: "
                    "1. 20 'Define / Explain' questions with their model answers. "
                    "2. 10 'Fill in the blank' questions with answers. "
                    "3. 5 'True or False' questions with answers. "
                    "You MUST respond in English. Use clear headings and bullet points to format the content."
                )
                
            prompt = f"User Request: {self.user_prompt}\n\nDocument Text:\n{short_text}"
            
            summary_text = llm.generate(prompt, system=system_prompt)
            
            # Clean up text to prevent fpdf2 font errors (remove Chinese/Japanese chars if hallucinated)
            # Keep Arabic, English, basic punctuation, numbers.
            # \u0600-\u06FF Arabic, \u0750-\u077F Arabic Supplement, \u08A0-\u08FF Arabic Extended-A
            # \u0000-\u007F ASCII
            cleaned_text = re.sub(r'[^\u0000-\u007F\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\u0100-\u017F\u0080-\u00FF\n\r\t]', '', summary_text)

            # 3. Generate PDF
            pdf = FPDF()
            pdf.add_page()
            
            # Setup Arabic Font
            font_path = Path(__file__).parent / "assets" / "fonts" / "Amiri-Regular.ttf"
            if font_path.exists():
                pdf.add_font("Amiri", "", str(font_path), uni=True)
                pdf.set_font("Amiri", "", 16)
            else:
                pdf.set_font("helvetica", "B", 16)
                
            # Process title for Arabic if needed
            reshaped_title = arabic_reshaper.reshape(f"Summary: {doc_name}")
            bidi_title = get_display(reshaped_title)
            pdf.cell(0, 10, bidi_title, new_x="LMARGIN", new_y="NEXT", align="C")
            pdf.ln(10)
            
            if font_path.exists():
                pdf.set_font("Amiri", "", 14)
            else:
                pdf.set_font("helvetica", "", 12)
                
            # FPDF2 with unicode font supports multi_cell naturally, but Arabic needs reshaping
            import re
            is_arabic = bool(re.search(r'[\u0600-\u06FF]', cleaned_text))
            
            if is_arabic:
                max_width = pdf.w - pdf.l_margin - pdf.r_margin
                paragraphs = cleaned_text.split('\n')
                for p in paragraphs:
                    if not p.strip():
                        pdf.ln(8)
                        continue
                        
                    reshaped_p = arabic_reshaper.reshape(p)
                    words = reshaped_p.split(' ')
                    line = ""
                    
                    for word in words:
                        test_line = word if line == "" else line + " " + word
                        if pdf.get_string_width(test_line) <= max_width:
                            line = test_line
                        else:
                            bidi_line = get_display(line)
                            pdf.cell(max_width, 8, bidi_line, align='R', new_x="LMARGIN", new_y="NEXT")
                            line = word
                            
                    if line:
                        bidi_line = get_display(line)
                        pdf.cell(max_width, 8, bidi_line, align='R', new_x="LMARGIN", new_y="NEXT")
            else:
                pdf.multi_cell(0, 8, cleaned_text, align="L")
            
            output_dir = Path(__file__).parent.parent / "summaries"
            output_dir.mkdir(exist_ok=True)
            pdf_path = output_dir / f"Summary_{doc.id}_{int(datetime.now().timestamp())}.pdf"
            
            pdf.output(str(pdf_path))
            
            self.finished.emit(cleaned_text, str(pdf_path))
            
        except Exception as e:
            self.error.emit(str(e))

class SummaryController(QObject):
    chatChanged = pyqtSignal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._chat_history = []
        self._is_generating = False
        self._worker = None
        self._load_chat_history()

    def _load_chat_history(self):
        with get_session() as db:
            chats = db.query(SummaryChat).order_by(SummaryChat.created_at).all()
            for chat in chats:
                self._chat_history.append({
                    "id": chat.id,
                    "document_id": chat.document_id,
                    "role": chat.role,
                    "text": chat.text,
                    "pdf_path": chat.pdf_path or ""
                })
        self.chatChanged.emit()

    @pyqtProperty(list, notify=chatChanged)
    def chatHistory(self):
        return self._chat_history

    @pyqtProperty(bool, notify=chatChanged)
    def isGenerating(self):
        return self._is_generating

    @pyqtSlot(int, str)
    def sendMessage(self, doc_id, text):
        if self._is_generating: return
        
        # Save user message to DB
        with get_session() as db:
            user_msg = SummaryChat(document_id=doc_id, role="user", text=text)
            db.add(user_msg)
            db.commit()
            db.refresh(user_msg)
            
            self._chat_history.append({
                "id": user_msg.id,
                "document_id": doc_id,
                "role": "user",
                "text": text,
                "pdf_path": ""
            })
            
        self._is_generating = True
        self.chatChanged.emit()
        
        # Pass document_id to worker so it can use it, we'll store it as self._current_doc_id
        self._current_doc_id = doc_id
        self._worker = SummaryWorker(doc_id, text)
        self._worker.finished.connect(self._on_finished)
        self._worker.error.connect(self._on_error)
        self._worker.start()

    def _on_finished(self, text, pdf_path):
        with get_session() as db:
            bot_msg = SummaryChat(document_id=self._current_doc_id, role="bot", text=text, pdf_path=pdf_path)
            db.add(bot_msg)
            db.commit()
            db.refresh(bot_msg)
            
            self._chat_history.append({
                "id": bot_msg.id,
                "document_id": self._current_doc_id,
                "role": "bot", 
                "text": text,
                "pdf_path": pdf_path
            })
            
        self._is_generating = False
        self.chatChanged.emit()
        
    @pyqtSlot(int)
    def deleteMessage(self, message_id):
        with get_session() as db:
            msg = db.query(SummaryChat).filter(SummaryChat.id == message_id).first()
            if msg:
                db.delete(msg)
                db.commit()
                # Update UI list
                self._chat_history = [chat for chat in self._chat_history if chat["id"] != message_id]
                self.chatChanged.emit()

    def _on_error(self, err):
        with get_session() as db:
            err_msg = SummaryChat(
                document_id=getattr(self, '_current_doc_id', None),
                role="bot", text=f"Error: {err}", pdf_path=""
            )
            db.add(err_msg)
            db.commit()
            db.refresh(err_msg)
            
            self._chat_history.append({
                "id": err_msg.id,
                "document_id": getattr(self, '_current_doc_id', None),
                "role": "bot",
                "text": f"Error: {err}",
                "pdf_path": ""
            })
        self._is_generating = False
        self.chatChanged.emit()

    @pyqtSlot(str)
    def openPdf(self, pdf_path):
        import sys, subprocess, os
        
        # PyInstaller overrides LD_LIBRARY_PATH, which breaks external Linux apps (like xdg-open).
        # We need to restore the original environment before launching them.
        env = os.environ.copy()
        if "LD_LIBRARY_PATH_ORIG" in env:
            env["LD_LIBRARY_PATH"] = env["LD_LIBRARY_PATH_ORIG"]
        elif "LD_LIBRARY_PATH" in env:
            del env["LD_LIBRARY_PATH"]
            
        try:
            if sys.platform == "win32":
                os.startfile(pdf_path)
            elif sys.platform == "darwin":
                subprocess.Popen(["open", pdf_path], env=env)
            else:
                subprocess.Popen(["xdg-open", pdf_path], env=env)
        except Exception as e:
            print(f"Error opening PDF: {e}")
