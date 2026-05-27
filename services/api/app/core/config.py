import os


class Settings:
    PROJECT_NAME: str = "Orpheus Echo API"
    VERSION: str = "0.1.0"
    
    # 環境変数から DATABASE_URL を取得、なければ SQLite などのテスト用 DB URL をフォールバックとする
    # PostgreSQLが稼働していない環境での検証用に、sqlite 接続も許容
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "sqlite:///./orpheus_echo_fallback.db"
    )


settings = Settings()
