# バックエンド実装用アーティファクト一式

このフォルダには以下を格納しています。

- `schema.sql`  
  PostgreSQL 向け SQL DDL
- `alembic_0001_initial_schema.py`  
  Alembic 初期マイグレーション案
- `pydantic_schemas.py`  
  FastAPI / Pydantic 用の雛形
- `docker-compose.full.yml`  
  開発用の docker-compose 完全版

## 想定前提
- FastAPI + PostgreSQL + Redis + Celery
- メディア保存は MinIO 互換オブジェクトストレージ
- Frontend はモバイルWeb前提
- 学習同期・モデルレジストリはプレースホルダサービス

## 補足
- Alembic ファイルは初期雛形です。実際には SQLAlchemy モデル定義と合わせて調整してください。
- `downgrade()` はテーブル削除中心のシンプルな構成です。運用要件に応じて段階的な migration 戦略に変更してください。
- Pydantic 雛形は主要 API を中心に作っています。レスポンス envelope や pagination schema は別ファイル化すると扱いやすいです。

## FastAPI MVP 実装（今回追加）

仕様書 [`docs/迷い犬迷い猫_推定呼称探索支援アプリ_API仕様書付き_FastAPI実装設計版_v1.1.md`](docs/迷い犬迷い猫_推定呼称探索支援アプリ_API仕様書付き_FastAPI実装設計版_v1.1.md) に基づき、MVP API を [`backend/app/main.py`](backend/app/main.py) をエントリポイントとして追加しました。

### 起動手順

1. Python 3.11.x を用意
2. 依存関係をインストール

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
```

3. API を起動

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

4. モバイルUIを開く

- ブラウザで `http://localhost:8000/` にアクセスすると、モバイル向けの操作画面を表示できます。
- UIファイルは [`backend/app/ui/index.html`](backend/app/ui/index.html) にあり、FastAPI の [`backend/app/main.py`](backend/app/main.py) で `/` ルート配信しています。

### MVPで実装済みの主なAPI

- `GET /api/v1/health`
- `POST /api/v1/sessions`
- `GET /api/v1/sessions/{session_id}`
- `PATCH /api/v1/sessions/{session_id}`
- `POST /api/v1/sessions/{session_id}/close`
- `GET /api/v1/candidates`
- `POST /api/v1/candidates`
- `PATCH /api/v1/candidates/{candidate_id}`
- `DELETE /api/v1/candidates/{candidate_id}`
- `POST /api/v1/sessions/{session_id}/trials`
- `POST /api/v1/sessions/{session_id}/trials/{trial_id}/features`
- `POST /api/v1/sessions/{session_id}/rank`
- `POST /api/v1/sessions/{session_id}/refine`
- `GET /api/v1/sessions/{session_id}/results`
- `GET /api/v1/sessions/{session_id}/export?format=pdf|csv|json`

### 補足

- 現段階では永続化はインメモリ実装（[`backend/app/repositories/in_memory.py`](backend/app/repositories/in_memory.py)）です。
- 共通レスポンス形式は [`backend/app/core/responses.py`](backend/app/core/responses.py) で統一しています。
