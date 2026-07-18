"""
QThread workers for background operations.

Keeps the UI responsive by running PDF extraction, question generation,
and answer evaluation in separate threads.
"""

from PyQt6.QtCore import QThread, pyqtSignal
from core.pdf_extractor import extract_text
from core.question_generator import generate_questions
from core.answer_evaluator import evaluate
from db.database import get_session
from db.models import Question, ReviewCard


class PDFWorker(QThread):
    """Extract text from a PDF file in the background."""

    progress = pyqtSignal(int)            # 0-100
    finished = pyqtSignal(dict)           # {"text", "page_count", "pages"}
    error = pyqtSignal(str)

    def __init__(self, file_path: str, parent=None):
        super().__init__(parent)
        self.file_path = file_path

    def run(self):
        try:
            self.progress.emit(10)
            result = extract_text(self.file_path)
            self.progress.emit(100)
            self.finished.emit(result)
        except Exception as e:
            self.error.emit(str(e))


class GenerationWorker(QThread):
    """Generate exam questions in the background (mock for now)."""

    stepChanged = pyqtSignal(int, int, str)   # step_index, progress%, message
    finished = pyqtSignal(list)               # list of question dicts
    error = pyqtSignal(str)

    def __init__(self, doc_id: int, count: int = 8,
                 types: list[str] | None = None,
                 difficulties: list[str] | None = None,
                 language: str = "Arabic",
                 parent=None):
        super().__init__(parent)
        self.doc_id = doc_id
        self.count = count
        self.types = types
        self.difficulties = difficulties
        self.language = language

    def run(self):
        try:
            questions_data = generate_questions(
                doc_id=self.doc_id,
                count=self.count,
                types=self.types,
                difficulties=self.difficulties,
                language=self.language,
                progress_callback=lambda s, p, m: self.stepChanged.emit(s, p, m),
            )
            
            # Save to DB
            session = get_session()
            try:
                saved_questions = []
                for q_dict in questions_data:
                    q = Question(
                        document_id=self.doc_id,
                        type=q_dict.get("type", "mcq"),
                        text=q_dict.get("text", ""),
                        choices_json=q_dict.get("choices"),
                        correct_answer=str(q_dict.get("correct_answer", "")),
                        explanation=q_dict.get("explanation"),
                        source_ref=q_dict.get("source_ref"),
                        difficulty=q_dict.get("difficulty", "medium"),
                        topic=q_dict.get("topic"),
                        key_points_json=q_dict.get("key_points")
                    )
                    session.add(q)
                    session.commit() # Commit individually to get ID, or flush
                    
                    # Create a default ReviewCard for SRS scheduling
                    rc = ReviewCard(question_id=q.id)
                    session.add(rc)
                    session.commit()
                    
                    # Add db id to the dict
                    q_dict["id"] = q.id
                    saved_questions.append(q_dict)
                    
                self.finished.emit(saved_questions)
            finally:
                session.close()
        except Exception as e:
            self.error.emit(str(e))


class EvaluationWorker(QThread):
    """Evaluate an open-ended answer in the background (mock for now)."""

    finished = pyqtSignal(str, int, str)  # question_id, score, feedback
    error = pyqtSignal(str)

    def __init__(self, question_id: str, question_text: str,
                 key_points: list[str] | None,
                 student_answer: str, parent=None):
        super().__init__(parent)
        self.question_id = question_id
        self.question_text = question_text
        self.key_points = key_points
        self.student_answer = student_answer

    def run(self):
        try:
            result = evaluate(
                self.question_text,
                self.key_points,
                self.student_answer,
            )
            self.finished.emit(
                self.question_id,
                result["score"],
                result["feedback"],
            )
        except Exception as e:
            self.error.emit(str(e))
