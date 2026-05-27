# Orpheus Echo (推定呼称探索支援アプリ)

本プロジェクトは、迷子になった犬や猫の反応を手がかりに、元々の名前を推定するための探索支援アプリケーション「Orpheus Echo」のソースコードリポジトリです。
保護された犬や猫に対して一般的な名前候補を音声再生し、動物に見られた反応ログ（手動入力＋カメラ等による行動特徴量）を記録・解析して、有力な呼称候補の絞り込みを支援します。

> [!WARNING]
> **用語規約に関するお知らせ**
> 本システムは名前の確定や特定を保証するものではありません。アプリ内の表示文言および結果はすべて「推定」「有力候補」「参考スコア」として取り扱われます。

---

## 📂 プロジェクトのフォルダ構成

```text
OrpheusEcho/
├── apps/
│   └── ios/
│       └── LostPetNameFinder/       # SwiftUI モバイルアプリケーション (iOS / macOS ターゲット)
│           ├── Sources/
│           │   ├── LostPetNameFinder/ # アプリ本体（Views / Models）
│           │   └── TestRunner/        # API接続疎通検証用コマンドラインツール
│           └── Package.swift          # Swift Package Manager (SPM) 構成
├── services/
│   └── api/                         # FastAPI バックエンドアプリケーション (Python)
│       ├── app/
│       │   ├── api/                   # 各種 API エンドポイント
│       │   ├── models/                # SQLAlchemy DBモデル / エンティティ定義
│       │   ├── repositories/          # データベース・永続化リポジトリ (SQLite対応)
│       │   └── services/              # AI/ML 重み付けランキングおよびセッション管理
│       └── pyproject.toml             # Python 依存パッケージ構成
└── docs/                            # 各種設計ドキュメント
    ├── api/                         # API仕様書 (api-contract.md)
    ├── ui/                          # モバイル画面仕様、HIG・UIレビューポリシー
    ├── db/                          # データベーススキーマ設計 (schema.sql)
    └── operation/                   # 操作説明書 (user-guide.md)
```

---

## 🛠️ 主な実装機能とアーキテクチャ

### 1. SwiftUI モバイルクライアント (iOS)
- **リアルタイム通信**: [`APIClient.swift`](apps/ios/LostPetNameFinder/Sources/LostPetNameFinder/Models/APIClient.swift) を介して FastAPI バックエンドへ `URLSession` を用いて非同期で接続し、共通レスポンスエンベロープをデコードします。
- **オフラインフォールバック (Offline Capable)**: 通信切断時やサーバー停止時は自動的にオフラインモードへ移行し、ローカルだけでセッション生成・試行記録・簡易 Heuristics ランキング計算を継続します。
- **UIフィードバック表示**: 呼びかけ時に推定されたAI行動マーカー値（視線移動、頭の回転、耳の動き、接近度）を探索画面にリアルタイムに表示します。

### 2. FastAPI バックエンド (Python)
- **行動特徴量の加重 Heuristics**: 試行データ記録時、名前認識への寄与度が高い「頭の回転（Head Turn）」および「視線移動（Gaze Shift）」に重み（各 `0.35`）を配分し、手動反応結果（40%）と加重特徴量（60%）をブレンドして「参考スコア」を算出します。
- **データベース永続化**: SQLite をフォールバックデータベースとして SQLAlchemy 経由でデータを永続化します。

---

## 🚀 起動・ビルド手順

### 1. バックエンド (FastAPI) の起動
検証用ポートとして **`8001`** ポートを使用して起動します。

```bash
cd services/api
# 仮想環境の作成と有効化
python3 -m venv .venv
source .venv/bin/activate
# 依存ライブラリのインストール
pip install -e .
# サーバーの起動
uvicorn app.main:app --reload --host 127.0.0.1 --port 8001
```

- 起動後、[http://127.0.0.1:8001/api/v1/health](http://127.0.0.1:8001/api/v1/health) でヘルスチェックを確認できます。

### 2. SwiftUI アプリのビルド・検証
Swift Package Manager (SPM) を使用して、iOS アプリコンポーネントのコンパイルおよび疎通テストランナーを実行できます。

```bash
cd apps/ios/LostPetNameFinder

# アプリケーションのクリーンビルド
swift build

# FastAPI(8001ポート)と連携した E2E 接続自動検証テストの実行
swift run LostPetNameFinderTestRunner
```

---

## 📖 関連ドキュメント
- **操作マニュアル**: [docs/operation/user-guide.md](docs/operation/user-guide.md)
- **API仕様書**: [docs/api/api-contract.md](docs/api/api-contract.md)
- **UI/UX設計ポリシー**: [docs/ui/mobile-ui-policy.md](docs/ui/mobile-ui-policy.md)
- **データベース DDL**: [docs/db/schema.sql](docs/db/schema.sql)
