# API Contract

本書は、推定呼称探索支援アプリ「OrpheusEcho」におけるフロントエンド（モバイルWeb UI）とバックエンド（FastAPI）間の通信インターフェイス仕様を定義する。

## 1. 共通仕様

### 1.1 認証・認可
- **方式**: Bearer Token / JWT 認証
- フロントエンドは認証取得後、`Authorization: Bearer <token>` ヘッダーを各リクエストに付与する。
- ローカル動作およびオフライン実行中は、認証およびオンライン連携APIの呼び出しをバイパスまたはキューへの蓄積で処理する。

### 1.2 共通レスポンス・エンベロープ
すべてのAPIレスポンスは以下のエンベロープ形式で統一される。

#### 正常レスポンス (JSON)
```json
{
  "data": {
    // 各API固有の返却データ
  },
  "meta": {
    "request_id": "req_123456789abc",
    "timestamp": "2026-05-27T12:00:00Z"
  },
  "error": null
}
```

#### ページング対応レスポンス (JSON)
```json
{
  "data": [
    // リストデータ
  ],
  "meta": {
    "request_id": "req_123456789abc",
    "timestamp": "2026-05-27T12:00:00Z",
    "page": 1,
    "page_size": 20,
    "total": 120
  },
  "error": null
}
```

#### エラーレスポンス (JSON)
レスポンスコードは対応するHTTPステータスコードを返却する。
```json
{
  "data": null,
  "meta": {
    "request_id": "req_123456789abc",
    "timestamp": "2026-05-27T12:00:00Z"
  },
  "error": {
    "code": "VALIDATION_ERROR", // もしくは "NOT_FOUND", "UNAUTHORIZED", "INTERNAL_SERVER_ERROR"
    "message": "エラーの内容を示す人間可読なメッセージ"
  }
}
```

### 1.3 共通のAPIルール
1. **アイデムポテンシー（冪等性）**:
   - 同期処理の再送制御を可能にするため、オフライン環境下で生成されたセッションIDや試行IDはクライアント側（UUID）で生成して送信することを許容する。
2. **アップロード分離**:
   - 動画・音声などの重いバイナリは、業務APIから分離し、署名付きURLを用いたストレージダイレクトアップロード（Pre-signed URLフロー）を利用する。
3. **推定表現の厳守**:
   - 推論やスコアリングを返すAPI（Ranking / Results）では、「特定」「確定」「正解」という表現は含めず、一貫して「推定」「有力候補」「参考スコア」として記述・返却する。

---

## 2. API エンドポイント

### 2.1 セッションAPI (Sessions)

#### 新規探索セッションの作成
- **URL**: `POST /api/v1/sessions`
- **概要**: 現場での探索開始時にセッションを新規作成する。
- **Request**:
```json
{
  "species": "dog", // "dog" | "cat"
  "temp_animal_id": "DOG-TMP-001", // 任意
  "location_text": "那覇市", // 任意
  "coat_color": "brown", // 任意
  "age_hint": "adult", // 任意
  "country_code": "JP", // 任意 (デフォルト辞書選択用)
  "language_code": "ja-JP", // 任意 (デフォルトTTS発音用)
  "multi_country_mode": false,
  "notes": "首輪なし" // 任意
}
```
- **Response**:
```json
{
  "data": {
    "session_id": "ses_9a8b7c6d5e4f",
    "status": "created"
  },
  "meta": {
    "request_id": "req_001",
    "timestamp": "2026-05-27T12:00:00Z"
  },
  "error": null
}
```

#### セッション詳細の取得
- **URL**: `GET /api/v1/sessions/{session_id}`
- **Response**: セッションの現在のメタデータおよびステータス。

#### セッション属性の更新
- **URL**: `PATCH /api/v1/sessions/{session_id}`
- **Request**: 更新する差分データ（`notes`, `location_text` 等）
- **Response**: 更新後のセッションオブジェクト。

#### セッションの終了（クローズ）
- **URL**: `POST /api/v1/sessions/{session_id}/close`
- **概要**: 探索を完了させ、ステータスを `closed` に遷移させる。
- **Response**:
```json
{
  "data": {
    "session_id": "ses_9a8b7c6d5e4f",
    "status": "closed"
  },
  "meta": {
    "request_id": "req_002",
    "timestamp": "2026-05-27T12:30:00Z"
  },
  "error": null
}
```

---

### 2.2 呼称候補API (Name Candidates)

#### 呼称候補リストの取得
- **URL**: `GET /api/v1/candidates`
- **Query**:
  - `species`: "dog" | "cat" (必須)
  - `country_code`: "JP" 等
  - `language_code`: "ja-JP" 等
  - `q`: あいまい検索文字列
  - `page`: 整数 (デフォルト1)
  - `page_size`: 整数 (デフォルト20)
- **Response**: ページング対応の候補名一覧。

#### 呼称候補の新規登録
- **URL**: `POST /api/v1/candidates`
- **Request**:
```json
{
  "name": "モモ",
  "species": "dog",
  "country_code": "JP",
  "language_code": "ja-JP"
}
```
- **Response**: 登録された候補オブジェクト。

#### 呼称候補の更新
- **URL**: `PATCH /api/v1/candidates/{candidate_id}`
- **Response**: 更新後のオブジェクト。

#### 呼称候補の無効化（論理削除）
- **URL**: `DELETE /api/v1/candidates/{candidate_id}`
- **Response**: ステータス更新完了結果。

---

### 2.3 試行API (Trials)

#### 呼称試行（呼びかけ）の記録
- **URL**: `POST /api/v1/sessions/{session_id}/trials`
- **概要**: 現場で特定の候補名を音声再生または手動呼びかけし、その直後に対象動物に見られた手動反応（反応あり/弱い/なしなど）を記録する。
- **Request**:
```json
{
  "candidate_id": "cand_001",
  "variant_text": "モモちゃん",
  "voice_type": "female_bright",
  "modulation_type": "nickname", // "normal" | "nickname" | "stretched" 等
  "played_at": "2026-05-27T12:10:00Z",
  "manual_flag": "reaction_yes" // "reaction_yes" | "reaction_weak" | "reaction_no"
}
```
- **Response**:
```json
{
  "data": {
    "trial_id": "trl_1a2b3c4d5e6f",
    "status": "accepted_for_scoring"
  },
  "meta": {
    "request_id": "req_003",
    "timestamp": "2026-05-27T12:10:01Z"
  },
  "error": null
}
```

#### 解析特徴量の保存（AI/ML推論補助データ）
- **URL**: `POST /api/v1/sessions/{session_id}/trials/{trial_id}/features`
- **概要**: カメラ映像解析などで得られた表情・動きの変化スコアを試行ログに紐付けて保存する（Phase 3移行で本格利用）。
- **Request**:
```json
{
  "gaze_shift_score": 0.82,
  "ear_motion_score": 0.65,
  "head_turn_score": 0.77,
  "posture_change_score": 0.33,
  "approach_score": 0.12,
  "vocalization_score": 0.08,
  "repeatability_score": 0.71
}
```
- **Response**: 保存完了ステータス。

---

### 2.4 スコア・ランキングAPI (Ranking)

#### 候補ランキングの再計算
- **URL**: `POST /api/v1/sessions/{session_id}/rank`
- **概要**: 当該セッションにおけるこれまでの試行データ（手動反応や特徴量）を元に、呼称候補の反応の強さ（参考スコア）を算出・ソートして返す。
- **Response**:
```json
{
  "data": {
    "top_candidates": [
      {"candidate_id": "cand_001", "name": "モモ", "score": 0.91, "uncertainty_flag": false},
      {"candidate_id": "cand_008", "name": "モカ", "score": 0.74, "uncertainty_flag": true}
    ]
  },
  "meta": {
    "request_id": "req_004",
    "timestamp": "2026-05-27T12:15:00Z"
  },
  "error": null
}
```

#### 愛称・近似候補の展開（再探索候補生成）
- **URL**: `POST /api/v1/sessions/{session_id}/refine`
- **概要**: 反応が強かった上位の候補名に基づいて、さらにバリエーション（例：「モモ」に対して「ももちゃん」「もちょ」など）を生成する。
- **Response**: 展開された再探索向け候補名リスト。

---

### 2.5 結果・レポートAPI (Results)

#### セッション結果サマリの取得
- **URL**: `GET /api/v1/sessions/{session_id}/results`
- **概要**: セッションデータ、試行回数、上位候補ランキングを含む結果詳細を返す。

#### 結果のエクスポート
- **URL**: `GET /api/v1/sessions/{session_id}/export`
- **Query**: `format=pdf|csv|json`
- **Response**:
  - `pdf`: レポート作成バックグラウンドジョブを作成し、進捗および将来のダウンロード用URL（`download_url`）を返す。
  - `csv` / `json`: ファイルの準備ができ次第、即時ダウンロード用URLまたはデータを返す。

---

### 2.6 既知名登録・学習データ収集API (Training & Known Animals)

#### 既知名個体の登録
- **URL**: `POST /api/v1/known-animals`
- **Request**:
```json
{
  "species": "cat",
  "true_name": "ルナ",
  "aliases": ["ルー", "ルナちゃん"],
  "sex": "female",
  "age_range": "adult",
  "breed": "mixed",
  "coat_color": "black",
  "owner_consent_status": "agreed" // "agreed" | "withdrawn"
}
```
- **Response**: 登録結果オブジェクト。

#### 学習収集セッションの作成
- **URL**: `POST /api/v1/training-sessions`
- **概要**: 飼い主などが協力して正名・誤名に対する反応をデータ収集するためのセッション。
- **Request**:
```json
{
  "known_animal_id": "ka_001",
  "speaker_type": "owner",
  "environment_type": "indoor",
  "purpose": "positive_negative_collection"
}
```
- **Response**: セッションID等。
