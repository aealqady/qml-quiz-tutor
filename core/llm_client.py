"""
LLM Client

This module defines the interface for communicating with a local LLM
via Ollama's REST API.
"""

import requests
import json
from db.database import get_session
from db.models import Setting

class LLMClient:
    """Client for generating text via Ollama API."""

    def __init__(self, model: str = None, base_url: str = None):
        # Fetch from DB if not provided
        if not model or not base_url:
            session = get_session()
            try:
                url_set = session.query(Setting).filter_by(key="ollama_url").first()
                self.base_url = url_set.value if url_set and url_set.value else "http://localhost:11434"
                
                model_set = session.query(Setting).filter_by(key="selected_model").first()
                self.model = model_set.value if model_set and model_set.value else "llama3"
            finally:
                session.close()
        else:
            self.model = model
            self.base_url = base_url

    def generate(self, prompt: str, system: str | None = None, format_json: bool = False) -> str:
        """
        Generate a response from the LLM.

        Args:
            prompt: The user prompt to send.
            system: Optional system prompt for context.
            format_json: If True, tell Ollama to output JSON format.

        Returns:
            The LLM's text response.
        """
        url = f"{self.base_url}/api/generate"
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "num_ctx": 8192  # Increased context window for long documents and 35+ questions
            }
        }
        
        if system:
            payload["system"] = system
            
        if format_json:
            payload["format"] = "json"

        try:
            resp = requests.post(url, json=payload, timeout=600)
            resp.raise_for_status()
            data = resp.json()
            return data.get("response", "")
        except requests.exceptions.RequestException as e:
            raise RuntimeError(f"Ollama generation failed: {e}")
