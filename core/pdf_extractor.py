"""Extract text content from PDF files using PyMuPDF."""

import fitz  # PyMuPDF


def extract_text(file_path: str) -> dict:
    """
    Extract text from a PDF file page by page.

    Returns:
        dict with keys:
            - text: full extracted text
            - page_count: number of pages
            - pages: list of per-page text strings
    """
    doc = fitz.open(file_path)
    pages = []
    for page in doc:
        pages.append(page.get_text())
    doc.close()

    return {
        "text": "\n\n".join(pages),
        "page_count": len(pages),
        "pages": pages,
    }

def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> list[str]:
    """
    Split text into chunks of approximately `chunk_size` words, 
    with an overlap of `overlap` words.
    """
    words = text.split()
    chunks = []
    
    if not words:
        return chunks
        
    start = 0
    while start < len(words):
        end = start + chunk_size
        chunk = " ".join(words[start:end])
        chunks.append(chunk)
        start += chunk_size - overlap
        
    return chunks
