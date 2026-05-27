from __future__ import annotations


def levenshtein_distance(s1: str, s2: str) -> int:
    """Compute the Levenshtein distance between two strings using Dynamic Programming."""
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)

    if len(s2) == 0:
        return len(s1)

    previous_row = list(range(len(s2) + 1))
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (0 if c1 == c2 else 1)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row

    return previous_row[-1]


def compute_phonetic_similarity(r1: str | None, r2: str | None) -> float:
    """Calculate normalized similarity [0.0, 1.0] based on Levenshtein distance of pronunciation readings."""
    if not r1 or not r2:
        return 0.0

    r1_clean = r1.strip().lower()
    r2_clean = r2.strip().lower()

    if r1_clean == r2_clean:
        return 1.0

    distance = levenshtein_distance(r1_clean, r2_clean)
    max_len = max(len(r1_clean), len(r2_clean))

    if max_len == 0:
        return 0.0

    return float(1.0 - (distance / max_len))
