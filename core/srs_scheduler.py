"""
SM-2 Spaced Repetition Scheduler.

Implements the SuperMemo-2 algorithm for optimal review scheduling.
"""

from datetime import datetime, timedelta, timezone


def sm2(
    quality: int,
    easiness: float = 2.5,
    interval: int = 1,
    repetitions: int = 0,
) -> tuple[float, int, int]:
    """
    Calculate next review parameters using SM-2 algorithm.

    Args:
        quality: Response quality rating (0-5).
            0 = complete blackout
            1 = incorrect, remembered on seeing answer
            2 = incorrect, but easy to recall
            3 = correct with serious difficulty
            4 = correct with some hesitation
            5 = perfect response
        easiness: Current easiness factor (>= 1.3).
        interval: Current interval in days.
        repetitions: Number of consecutive correct responses.

    Returns:
        Tuple of (new_easiness, new_interval, new_repetitions).
    """
    if quality >= 3:  # Correct response
        if repetitions == 0:
            interval = 1
        elif repetitions == 1:
            interval = 6
        else:
            interval = round(interval * easiness)
        repetitions += 1
    else:  # Incorrect response — reset
        repetitions = 0
        interval = 1

    # Update easiness factor
    easiness = max(
        1.3,
        easiness + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02),
    )

    return easiness, interval, repetitions


def next_review_date(
    quality: int,
    easiness: float = 2.5,
    interval: int = 1,
    repetitions: int = 0,
) -> tuple[float, int, int, datetime]:
    """
    Calculate SM-2 parameters and the next review date.

    Returns:
        Tuple of (new_easiness, new_interval, new_repetitions, next_review_datetime).
    """
    new_e, new_i, new_r = sm2(quality, easiness, interval, repetitions)
    next_dt = datetime.now(timezone.utc) + timedelta(days=new_i)
    return new_e, new_i, new_r, next_dt
