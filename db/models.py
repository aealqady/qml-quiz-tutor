"""SQLAlchemy ORM models for the Intelligent Tutoring System."""

from datetime import datetime, timezone
from sqlalchemy import (
    Column, Integer, String, Float, DateTime,
    ForeignKey, Text, Boolean, JSON,
)
from sqlalchemy.orm import relationship, DeclarativeBase


class Base(DeclarativeBase):
    pass


class Document(Base):
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    pages = Column(Integer, default=0)
    status = Column(String, default="processing")  # processing | ready | error
    progress = Column(Integer, default=0)
    file_path = Column(String)
    uploaded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    topics = relationship("Topic", back_populates="document", cascade="all, delete-orphan")
    questions = relationship("Question", back_populates="document", cascade="all, delete-orphan")


class Topic(Base):
    __tablename__ = "topics"

    id = Column(Integer, primary_key=True)
    document_id = Column(Integer, ForeignKey("documents.id"))
    name = Column(String, nullable=False)

    document = relationship("Document", back_populates="topics")


class Question(Base):
    __tablename__ = "questions"

    id = Column(Integer, primary_key=True)
    document_id = Column(Integer, ForeignKey("documents.id"))
    type = Column(String, nullable=False)       # mcq | truefalse | openended
    text = Column(Text, nullable=False)
    choices_json = Column(JSON, nullable=True)   # list of strings for MCQ
    correct_answer = Column(String)              # index for MCQ, "true"/"false" for TF, model answer for open
    explanation = Column(Text)
    source_ref = Column(String)
    difficulty = Column(String, default="medium") # easy | medium | hard
    topic = Column(String)
    key_points_json = Column(JSON, nullable=True) # list of strings for open-ended

    document = relationship("Document", back_populates="questions")


class ExamSession(Base):
    __tablename__ = "exam_sessions"

    id = Column(Integer, primary_key=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    time_limit = Column(Integer, nullable=True)  # minutes, None = unlimited
    score = Column(Float, nullable=True)
    status = Column(String, default="active")    # active | completed

    answers = relationship("ExamAnswer", back_populates="session", cascade="all, delete-orphan")


class ExamAnswer(Base):
    __tablename__ = "exam_answers"

    id = Column(Integer, primary_key=True)
    session_id = Column(Integer, ForeignKey("exam_sessions.id"))
    question_id = Column(Integer, ForeignKey("questions.id"))
    user_answer = Column(String)
    is_correct = Column(Boolean, nullable=True)
    eval_score = Column(Integer, nullable=True)
    eval_feedback = Column(Text, nullable=True)

    session = relationship("ExamSession", back_populates="answers")
    question = relationship("Question")


class ReviewCard(Base):
    __tablename__ = "review_cards"

    id = Column(Integer, primary_key=True)
    question_id = Column(Integer, ForeignKey("questions.id"), unique=True)
    easiness = Column(Float, default=2.5)
    interval = Column(Integer, default=1)        # days
    repetitions = Column(Integer, default=0)
    next_review = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    question = relationship("Question")


class Setting(Base):
    __tablename__ = "settings"

    id = Column(Integer, primary_key=True)
    key = Column(String, unique=True, nullable=False)
    value = Column(String, nullable=True)


class SummaryChat(Base):
    __tablename__ = "summary_chats"

    id = Column(Integer, primary_key=True)
    document_id = Column(Integer, ForeignKey("documents.id"), nullable=True)
    role = Column(String, nullable=False)  # user | agent
    text = Column(Text, nullable=False)
    pdf_path = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    document = relationship("Document")
