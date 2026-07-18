# QML Quiz Tutor (Intelligent Tutoring System)

**QML Quiz Tutor** is an advanced, offline-first desktop application built for students and educators. It leverages local Large Language Models (LLMs) via Ollama to automatically extract knowledge from PDF documents and generate interactive quizzes and flashcards.

## 🌟 Key Features

* **AI-Powered Question Generation:** Upload any educational PDF, and the local AI automatically extracts the content and generates Multiple Choice, True/False, and Free-Response questions.
* **Smart Answer Evaluation:** Instead of just checking exact matches, the system uses the LLM to semantically evaluate free-text answers and provide constructive feedback.
* **Spaced Repetition System (SRS):** Built-in flashcard scheduler to help users retain information over the long term using proven spaced repetition algorithms.
* **100% Offline & Private:** All data processing and LLM inference happen locally on your machine using Ollama. No data is sent to the cloud.
* **Modern & Responsive UI:** Built with Qt/QML to deliver a beautiful, fluid, and animated user experience with a sleek dark mode.
* **Bilingual Support:** Fully supports both English and Arabic interfaces and content generation.
* **Analytics Dashboard:** Tracks study streaks, accuracy, and topic-wise performance.

## 🛠️ Technology Stack

* **Frontend:** QML / Qt Quick (via PyQt6)
* **Backend:** Python 3.11+
* **Database:** SQLite with SQLAlchemy ORM
* **AI Integration:** Ollama (Local LLMs like LLaMA 3, Mistral, etc.)
* **Document Processing:** PyMuPDF for fast and accurate text extraction from PDFs.
* **CI/CD:** GitHub Actions for automated Windows executable builds via PyInstaller.

## 🚀 Getting Started

### Prerequisites
1. Install [Python 3.11+](https://www.python.org/).
2. Install [Ollama](https://ollama.com/) and pull your preferred model (e.g., `ollama pull llama3`).

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/aealqady/qml-quiz-tutor.git
   cd qml-quiz-tutor
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the application:
   ```bash
   python main.py
   ```

## 🧠 How It Works
1. **Upload:** Drag and drop a PDF into the app.
2. **Process:** A background worker extracts text and sends structured chunks to the local LLM.
3. **Generate:** The LLM responds with well-formatted JSON containing generated questions, which are then saved to the local SQLite database.
4. **Study:** Take the exam. The app uses the LLM to read your free-text answers, comparing them semantically against the generated key points, and assigns a score and feedback.

## 📝 License
This project is licensed under the MIT License.
