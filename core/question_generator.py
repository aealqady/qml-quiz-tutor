"""
Question Generator

Uses LLMClient to generate questions from extracted PDF text.
"""

import json
import random
import time
import math
from db.database import get_session
from db.models import Document
from core.pdf_extractor import extract_text, chunk_text
from core.llm_client import LLMClient



def generate_questions(
    doc_id: int,
    count: int = 8,
    types: list[str] | None = None,
    difficulties: list[str] | None = None,
    language: str = "Arabic",
    progress_callback=None,
) -> list[dict]:
    """
    Generate questions using local LLM based on document text.

    Args:
        doc_id: Source document ID.
        count: Number of questions to generate.
        types: Allowed question types (mcq, truefalse, openended).
        difficulties: Allowed difficulties (easy, medium, hard).
        progress_callback: Optional callable(step: int, progress: int, message: str).

    Returns:
        List of question dicts ready for database insertion.
    """
    types = types or ["mcq", "truefalse", "openended"]
    difficulties = difficulties or ["easy", "medium", "hard"]

    if progress_callback:
        progress_callback(0, 5, "Extracting text from PDF...")

    session = get_session()
    try:
        doc = session.query(Document).get(doc_id)
        if not doc or not doc.file_path:
            raise ValueError(f"Document {doc_id} not found or missing file_path.")
        file_path = doc.file_path
    finally:
        session.close()

    # 1. Extract text
    extraction_result = extract_text(file_path)
    full_text = extraction_result["text"]

    if progress_callback:
        progress_callback(1, 20, "Chunking text for analysis...")

    # 2. Chunk text
    chunks = chunk_text(full_text, chunk_size=400, overlap=50)
    if not chunks:
        raise ValueError("No text extracted from the document.")

    # 3. Select random chunks to distribute questions
    num_chunks_to_use = min(len(chunks), max(1, count // 2))
    selected_chunks = random.sample(chunks, num_chunks_to_use)

    if progress_callback:
        progress_callback(2, 30, "Initializing LLM...")

    llm = LLMClient()
    questions = []

    # Calculate how many questions to ask per chunk. Ask for +1 as a buffer for small models.
    questions_per_chunk = math.ceil(count / num_chunks_to_use) + 1

    for i, chunk in enumerate(selected_chunks):
        if len(questions) >= count:
            break
            
        if progress_callback:
            prog = 30 + int(60 * (i / num_chunks_to_use))
            progress_callback(3 + i, prog, f"Generating questions from section {i+1}...")

        # Construct prompt
        prompt = (
            f"Generate exactly {questions_per_chunk} questions based on this text.\n"
            f"Allowed types: {', '.join(types)}.\n"
            f"Allowed difficulties: {', '.join(difficulties)}.\n"
            f"CRITICAL: The questions and all choices MUST be written in {language}.\n\n"
            f"TEXT:\n{chunk}"
        )

        try:
            from core.prompts import get_generator_system_prompt
            sys_prompt = get_generator_system_prompt(language)
            response = llm.generate(prompt, system=sys_prompt, format_json=True)
            
            # Parse response
            # Sometimes LLMs wrap json in markdown even if instructed otherwise, so clean it
            clean_resp = response.strip()
            if clean_resp.startswith("```json"):
                clean_resp = clean_resp[7:]
            if clean_resp.endswith("```"):
                clean_resp = clean_resp[:-3]
            clean_resp = clean_resp.strip()
            
            batch = json.loads(clean_resp)
            if not isinstance(batch, list):
                if isinstance(batch, dict) and "questions" in batch:
                    batch = batch["questions"]
                else:
                    batch = [batch] # Try wrapping in list
            
            # Validate and add to list
            for q in batch:
                q["document_id"] = doc_id
                if "key_points" not in q:
                    q["key_points"] = None
                questions.append(q)
                
        except Exception as e:
            print(f"Error generating from chunk: {e}")
            continue

    if progress_callback:
        progress_callback(99, 100, "Finalizing question bank...")

    # Ensure we don't return more than requested
    return questions[:count]
