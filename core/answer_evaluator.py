"""
Answer Evaluator — MOCK

Returns simulated scores and feedback for open-ended answers.
When LLM integration is added, this module will call llm_client
to evaluate student answers against model answers and key points.
"""

import random
import time


def evaluate(
    question_text: str,
    key_points: list[str] | None,
    student_answer: str,
) -> dict:
    """
    Evaluate an open-ended student answer (mock implementation).

    Simulates LLM evaluation with a random delay and returns
    a randomized score with template-based feedback.

    Args:
        question_text: The original question.
        key_points: Expected key points to cover.
        student_answer: The student's answer text.

    Returns:
        dict with keys: score (int 0-100), feedback (str)
    """
    # Simulate evaluation delay
    time.sleep(random.uniform(1.5, 2.5))

    key_points = key_points or []
    word_count = len(student_answer.split())

    # Score based roughly on answer length + randomness
    base = min(word_count * 2, 60)
    score = min(100, max(20, base + random.randint(-5, 35)))

    # Simulate which key points were "found"
    found = [kp for kp in key_points if random.random() > 0.35]
    missed = [kp for kp in key_points if kp not in found]

    if score >= 80:
        feedback = (
            f"Strong response covering {len(found)} of {len(key_points)} key points. "
            "Your explanation is conceptually accurate and well-structured."
        )
    elif score >= 60:
        extras = f" Try to include: {', '.join(missed[:2])}." if missed else ""
        feedback = f"Decent answer. You covered the core idea but missed some nuance.{extras}"
    else:
        focus = ", ".join(key_points[:3]) if key_points else "the main concepts"
        feedback = f"Needs more depth. Review the source material and focus on: {focus}."

    return {"score": score, "feedback": feedback}
