from __future__ import annotations

import sys
from pathlib import Path

# プロジェクトルートを Python パスに追加
sys.path.append(str(Path(__file__).resolve().parent.parent))

from app.core.database import SessionLocal, Base, engine
from app.models.db_models import DbJokeNameProfile


def seed_joke_profiles() -> None:
    db = SessionLocal()
    try:
        if db.query(DbJokeNameProfile).count() > 0:
            print("Joke name profiles already seeded.")
            return

        seeds = [
            # 日本語 (ja-JP) - 日本 (JP)
            DbJokeNameProfile(id="jkp_jp_001", name="たっちゃん", type="nickname", language_code="ja-JP", country_code="JP", is_active=True),
            DbJokeNameProfile(id="jkp_jp_002", name="よっちゃん", type="nickname", language_code="ja-JP", country_code="JP", is_active=True),
            DbJokeNameProfile(id="jkp_jp_003", name="モモっち", type="nickname", language_code="ja-JP", country_code="JP", is_active=True),
            DbJokeNameProfile(id="jkp_jp_004", name="部長っぽい人", type="joke_safe", language_code="ja-JP", country_code="JP", is_active=True),
            DbJokeNameProfile(id="jkp_jp_005", name="社長さん", type="joke_safe", language_code="ja-JP", country_code="JP", is_active=True),
            DbJokeNameProfile(id="jkp_jp_006", name="プリン好き", type="joke_safe", language_code="ja-JP", country_code="JP", is_active=True),
            DbJokeNameProfile(id="jkp_jp_007", name="お昼寝のプロ", type="joke_safe", language_code="ja-JP", country_code="JP", is_active=True),
            DbJokeNameProfile(id="jkp_jp_008", name="リーダー", type="joke_safe", language_code="ja-JP", country_code="JP", is_active=True),
            DbJokeNameProfile(id="jkp_jp_009", name="癒やし担当", type="joke_safe", language_code="ja-JP", country_code="JP", is_active=True),
            DbJokeNameProfile(id="jkp_jp_010", name="アイディアマン", type="joke_safe", language_code="ja-JP", country_code="JP", is_active=True),

            # 英語 (en-US) - アメリカ (US)
            DbJokeNameProfile(id="jkp_us_001", name="Buddy", type="nickname", language_code="en-US", country_code="US", is_active=True),
            DbJokeNameProfile(id="jkp_us_002", name="Smiley", type="nickname", language_code="en-US", country_code="US", is_active=True),
            DbJokeNameProfile(id="jkp_us_003", name="Sunshine", type="nickname", language_code="en-US", country_code="US", is_active=True),
            DbJokeNameProfile(id="jkp_us_004", name="Chief", type="joke_safe", language_code="en-US", country_code="US", is_active=True),
            DbJokeNameProfile(id="jkp_us_005", name="Boss", type="joke_safe", language_code="en-US", country_code="US", is_active=True),
            DbJokeNameProfile(id="jkp_us_006", name="Coffee Lover", type="joke_safe", language_code="en-US", country_code="US", is_active=True),
            DbJokeNameProfile(id="jkp_us_007", name="Nap Champion", type="joke_safe", language_code="en-US", country_code="US", is_active=True),
            DbJokeNameProfile(id="jkp_us_008", name="Idea Machine", type="joke_safe", language_code="en-US", country_code="US", is_active=True),

            # 英語 (en-GB) - イギリス (GB)
            DbJokeNameProfile(id="jkp_gb_001", name="Mate", type="nickname", language_code="en-GB", country_code="GB", is_active=True),
            DbJokeNameProfile(id="jkp_gb_002", name="Guinness Fan", type="joke_safe", language_code="en-GB", country_code="GB", is_active=True),
            DbJokeNameProfile(id="jkp_gb_003", name="Tea Master", type="joke_safe", language_code="en-GB", country_code="GB", is_active=True),
        ]

        db.add_all(seeds)
        db.commit()
        print(f"Successfully seeded {len(seeds)} joke profiles.")
    except Exception as e:
        db.rollback()
        print(f"Error seeding joke profiles: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_joke_profiles()
