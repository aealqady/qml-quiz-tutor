import sys
from pathlib import Path
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine
from db.database import init_db
from controllers import UploadController, ExamController, ProgressController, SettingsController, SummaryController


def main():
    # Initialize the local SQLite database
    init_db()

    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # Initialize Controllers
    upload_ctrl = UploadController()
    exam_ctrl = ExamController()
    progress_ctrl = ProgressController()
    settings_ctrl = SettingsController()
    summary_ctrl = SummaryController()
    
    # Prevent garbage collection of controllers
    app._controllers = [upload_ctrl, exam_ctrl, progress_ctrl, settings_ctrl, summary_ctrl]
    
    # Connect signals
    exam_ctrl.examSubmitted.connect(progress_ctrl.refresh)
    
    # Expose Controllers to QML
    ctx = engine.rootContext()
    ctx.setContextProperty("uploadController", upload_ctrl)
    ctx.setContextProperty("examController", exam_ctrl)
    ctx.setContextProperty("progressController", progress_ctrl)
    ctx.setContextProperty("settingsController", settings_ctrl)
    ctx.setContextProperty("summaryController", summary_ctrl)

    # Add the project root to QML import paths so 'import ui 1.0' works
    base_path = Path(__file__).resolve().parent
    engine.addImportPath(str(base_path))

    qml_file = base_path / "ui" / "Main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()