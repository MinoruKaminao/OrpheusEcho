from __future__ import annotations


def get_nickname_variants(name: str, language_code: str) -> list[str]:
    """Generate localized nickname variants based on language rules.

    - ja-JP: Appends 'ちゃん', 'くん', 'たん'
    - en-US / en-GB: Appends standard diminutive suffixes like 'ie', 'y', 's'
      and handles trailing vowels substitution (e.g. Bella -> Bellie / Belly).
    """
    if not name:
        return []

    lang = language_code.lower()
    if "ja" in lang:
        # Japanese rules
        return [f"{name}ちゃん", f"{name}くん", f"{name}たん"]
    elif "en" in lang:
        # English rules
        variants = []
        # Check trailing vowel
        vowels = ("a", "e", "i", "o", "u", "y")
        last_char = name[-1].lower()
        if last_char in vowels:
            # Replace trailing vowel with 'ie' and 'y'
            base = name[:-1]
            variants.append(f"{base}ie")
            variants.append(f"{base}y")
            # Or append 's' to the original
            variants.append(f"{name}s")
        else:
            # Consonant base: append 'ie', 'y', 's'
            variants.append(f"{name}ie")
            variants.append(f"{name}y")
            variants.append(f"{name}s")
        return variants
    else:
        # Fallback default
        return [f"{name}y", f"{name}ie"]
