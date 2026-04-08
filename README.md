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
