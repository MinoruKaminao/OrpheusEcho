from __future__ import annotations

import re

# 機微な属性（性別・民族・国籍・宗教など）および身体的特徴、不快・侮辱表現のブラックリスト
OFFENSIVE_AND_SENSITIVE_KEYWORDS = [
    # 性別・ジェンダーの機微・断定・揶揄
    "オカマ", "オナベ", "ニューハーフ", "ゲイ", "レズビアン", "ホモ", "お釜",
    "おっさん", "おばさん", "クソババア", "クソジジイ", "男っぽい", "女っぽい",
    
    # 民族・国籍・出身地・人種
    "日本人", "アメリカ人", "中国人", "韓国人", "黒人", "白人", "黄色人種",
    "ハーフ", "クォーター", "混血", "外人", "外国人", "田舎者", "都会人",
    
    # 身体的特徴・外見の侮辱・揶揄
    "デブ", "ブタ", "チビ", "ハゲ", "ブサイク", "デコ助", "ガリガリ", "ブス",
    "不細工", "デブ助",
    
    # 一般的・その他の卑猥・暴力・侮辱・差別
    "バカ", "アホ", "マヌケ", "死ね", "殺す", "ゴミ", "クズ", "奴隷", "キチガイ",
    "差別", "キモい", "変質者", "犯罪者", "キモイ", "うざい", "ウザい"
]


def validate_nickname(nickname: str) -> bool:
    """Validate that the nickname is safe and does not violate guardrails.

    Returns True if the nickname is safe, False otherwise.
    """
    if not nickname:
        return False

    normalized = nickname.lower().replace(" ", "").replace("　", "")

    # 1. ブラックリストチェック
    for keyword in OFFENSIVE_AND_SENSITIVE_KEYWORDS:
        if keyword.lower() in normalized:
            return False

    # 2. フルネーム（姓名）のような構造を簡易検知して除外
    # 日本語の漢字フルネーム（例: 「田中太郎」のような漢字のみの連続で2〜5文字程度）
    if re.match(r"^[\u4e00-\u9faf]{4,6}$", normalized):
        return False

    return True


def is_likely_real_name(name: str) -> bool:
    """Check if the generated name looks like a real full name, which is forbidden.

    We avoid full names or exact identity references.
    """
    if not name:
        return True

    # 英語の「First Last」形式のチェック (例: "John Doe")
    if re.match(r"^[a-zA-Z]+\s+[a-zA-Z]+$", name):
        return True

    # 漢字のみの連続 (姓名の可能性が高い)
    if re.match(r"^[\u4e00-\u9faf]{4,6}$", name):
        return True

    # 「様」「殿」などの敬称が含まれる場合も実名判定に近いので除外
    if name.endswith("様") or name.endswith("殿"):
        return True

    return False
