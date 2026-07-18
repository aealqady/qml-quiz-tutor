pragma Singleton
import QtQuick

QtObject {
    id: root
    
    property string lang: "en"
    property bool isAr: lang === "ar"
    
    property var dict: {
        "en": {
            // Sidebar
            "menu_docs": "Documents",
            "menu_exam": "Exam",
            "menu_progress": "Progress",
            "menu_summary": "Summary",
            "menu_settings": "Settings",
            
            // Upload
            "upload_title": "Upload Documents",
            "upload_subtitle": "Drag & drop PDF files to start generating exams.",
            "upload_btn": "Select PDF Files",
            "upload_drop": "Drop PDF here",
            
            // Exam Setup
            "exam_title": "Exam Configuration",
            "exam_subtitle": "Set up your AI-generated exam parameters.",
            "source_docs": "Source Documents",
            "question_types": "Question Types",
            "mcq": "Multiple Choice",
            "tf": "True / False",
            "open": "Open Ended",
            "difficulty": "Difficulty",
            "easy": "Easy",
            "medium": "Medium",
            "hard": "Hard",
            "generate_exam": "Generate Exam",
            "no_docs": "No ready documents available.",
            
            // Exam Player
            "exam_completed": "Exam Completed",
            "question": "Question",
            "of": "of",
            "exit_exam": "Exit Exam",
            "no_questions": "No questions generated yet.",
            "exam_finished_msg": "🎉 Exam Finished!",
            "exam_saved_msg": "Your answers have been saved and will be evaluated.",
            "view_progress": "View Progress",
            "previous": "Previous",
            "next": "Next",
            "submit": "Submit",
            "type_answer": "Type your answer here...",
            "true_btn": "True",
            "false_btn": "False",
            
            // Progress
            "prog_title": "Progress & Analytics",
            "prog_subtitle": "Track your performance and scheduled reviews.",
            "exams_completed": "Exams Completed",
            "avg_score": "Avg Score",
            "qs_answered": "Questions Answered",
            "study_streak": "Study Streak",
            
            // Summary
            "sum_title": "AI Summary Generator",
            "sum_subtitle": "Chat with the AI to generate a structured PDF summary from a document.",
            "source_doc": "Source Document:",
            "generating": "Generating summary and PDF...",
            "send": "Send",
            "open_pdf": "Open PDF",
            "you": "You",
            "agent": "ITS Agent",
            "sum_placeholder": "Create a detailed summary of this document...",
            "delete_msg": "Delete",
            
            // Settings
            "settings_title": "System Settings",
            "settings_subtitle": "Configure your AI models and application preferences.",
            "lang_section": "Language / اللغة",
            "switch_lang": "Switch to العربية",
            "ollama_setup": "Ollama Setup",
            "ollama_url": "Ollama URL",
            "test_conn": "Test Connection",
            "ai_model": "AI Model",
            "save_settings": "Save Settings",
            "sys_status": "System Status",
            "no_models": "No models available. Please test connection first.",
            
            // Sidebar Stats
            "session_stats": "SESSION STATS",
            "stat_reviewed": "Reviewed",
            "stat_streak": "Streak",
            "stat_accuracy": "Accuracy"
        },
        "ar": {
            // Sidebar
            "menu_docs": "المستندات",
            "menu_exam": "الاختبار",
            "menu_progress": "التقدم",
            "menu_summary": "الملخص",
            "menu_settings": "الإعدادات",
            
            // Upload
            "upload_title": "رفع المستندات",
            "upload_subtitle": "اسحب وأفلت ملفات الـ PDF للبدء.",
            "upload_btn": "اختر ملفات PDF",
            "upload_drop": "أفلت الملف هنا",
            
            // Exam Setup
            "exam_title": "إعدادات الاختبار",
            "exam_subtitle": "قم بضبط معايير الاختبار المولد بالذكاء الاصطناعي.",
            "source_docs": "المستندات المصدرية",
            "question_types": "أنواع الأسئلة",
            "mcq": "اختيار من متعدد",
            "tf": "صح / خطأ",
            "open": "أسئلة مقالية",
            "difficulty": "الصعوبة",
            "easy": "سهل",
            "medium": "متوسط",
            "hard": "صعب",
            "generate_exam": "توليد الاختبار",
            "no_docs": "لا توجد مستندات جاهزة.",
            
            // Exam Player
            "exam_completed": "اكتمل الاختبار",
            "question": "سؤال",
            "of": "من",
            "exit_exam": "إنهاء الاختبار",
            "no_questions": "لم يتم توليد أسئلة بعد.",
            "exam_finished_msg": "🎉 انتهى الاختبار!",
            "exam_saved_msg": "تم حفظ إجاباتك وسيتم تقييمها قريباً.",
            "view_progress": "عرض التقدم",
            "previous": "السابق",
            "next": "التالي",
            "submit": "إرسال",
            "type_answer": "اكتب إجابتك هنا...",
            "true_btn": "صح",
            "false_btn": "خطأ",
            
            // Progress
            "prog_title": "التقدم والإحصائيات",
            "prog_subtitle": "تتبع أدائك ومواعيد المراجعة المجدولة.",
            "exams_completed": "الاختبارات المنجزة",
            "avg_score": "متوسط الدرجات",
            "qs_answered": "الأسئلة المجابة",
            "study_streak": "أيام الدراسة المتصلة",
            
            // Summary
            "sum_title": "مولد الملخصات الذكي",
            "sum_subtitle": "تحدث مع الذكاء الاصطناعي لإنشاء ملخص PDF منظم للمستند.",
            "source_doc": "المستند المصدري:",
            "generating": "جاري إنشاء الملخص وملف PDF...",
            "send": "إرسال",
            "open_pdf": "فتح الـ PDF",
            "you": "أنت",
            "agent": "المعلم الذكي",
            "sum_placeholder": "أنشئ لي ملخصاً مفصلاً لهذا المستند...",
            "delete_msg": "حذف",
            
            // Settings
            "settings_title": "إعدادات النظام",
            "settings_subtitle": "قم بضبط نماذج الذكاء الاصطناعي وتفضيلات التطبيق.",
            "lang_section": "اللغة / Language",
            "switch_lang": "Switch to English",
            "ollama_setup": "إعدادات Ollama",
            "ollama_url": "رابط خادم Ollama",
            "test_conn": "فحص الاتصال",
            "ai_model": "نموذج الذكاء الاصطناعي",
            "save_settings": "حفظ الإعدادات",
            "sys_status": "حالة النظام",
            "no_models": "لا توجد نماذج. يرجى فحص الاتصال أولاً.",
            
            // Sidebar Stats
            "session_stats": "إحصائيات الجلسة",
            "stat_reviewed": "المراجعات",
            "stat_streak": "أيام متصلة",
            "stat_accuracy": "الدقة"
        }
    }
    
    property var currentDict: dict[lang]
    
    onLangChanged: {
        currentDict = dict[lang]
    }
}
