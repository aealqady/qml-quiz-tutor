"""Database engine and session management."""

from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from .models import Base

_DB_PATH = Path(__file__).resolve().parent.parent / "its_data.db"
_engine = create_engine(f"sqlite:///{_DB_PATH}", echo=False)
Session = sessionmaker(bind=_engine)


def init_db():
    """Create all tables if they don't exist."""
    Base.metadata.create_all(_engine)


def get_session():
    """Return a new SQLAlchemy session."""
    return Session()
