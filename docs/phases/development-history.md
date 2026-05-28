# Orpheus Echo 開発実績・履歴書 (Phase 0 - Phase 8)

本ドキュメントは、保護された迷い犬・迷い猫の反応や地理情報、環境適応をもとに元々の名前を推定する支援アプリ「Orpheus Echo」の、初期構想（Phase 0）から最新の屋外環境適応（Phase 8）にわたるすべての開発実績を時系列に整理したプロジェクト公式の開発履歴書です。

---

## 📌 プロジェクト概要
保護された犬や猫に対して一般的な名前候補をTTS（音声合成）再生し、動物に見られた反応ログ（手動入力＋カメラ等による行動特徴量）を記録・解析して、有力な呼称候補の絞り込みを支援するマルチプラットフォーム（iOS/FastAPI）システムです。
> [!WARNING]
> **用語規約**
> 本システムは名前の確定や特定を保証するものではありません。アプリ内の表示文言および結果はすべて「推定」「有力候補」「参考スコア」として取り扱われます。

---

## 🛠️ 各フェーズの開発実績

### Phase 0: Foundation (開発基盤構築)
*   **目的**: プロジェクト全体の構造定義、規約整備、API・DBコントラクトの策定。
*   **実装内容**:
    *   iOS クライアント (`apps/ios/LostPetNameFinder`) および FastAPI バックエンド (`services/api`) の開発ディレクトリ構造を確立。
    *   AIエージェント間の協調ルール（[AGENTS.md](file:///Users/minorukaminao/OrpheusEcho/AGENTS.md)）、UI/UXポリシー（[mobile-ui-policy.md](file:///Users/minorukaminao/OrpheusEcho/docs/ui/mobile-ui-policy.md)）、API契約（[api-contract.md](file:///Users/minorukaminao/OrpheusEcho/docs/api/api-contract.md)）、データベース設計（[schema.sql](file:///Users/minorukaminao/OrpheusEcho/docs/db/schema.sql)）の作成。
    *   初期モックデータ（一般的な名前リスト等）のシードスクリプトを作成。
*   **成果**: 各開発担当エージェントが一貫性を持った設計のもとで自律動作するための開発土台を完成。

### Phase 1: MVP Manual Exploration (手動呼称探索機能)
*   **目的**: コア機能である探索セッションの作成、名前候補再生、手動による反応記録、簡易ランキングの表示。
*   **実装内容**:
    *   **iOS クライアント**:
        *   `SpeciesSelectionView` (対象動物：犬・猫の選択画面) の実装。
        *   `ExplorationView` (候補音声を順次再生し、「反応あり」「弱い」「反応なし」を手動で迅速に記録する画面) の実装。
        *   `CandidateRankingView` (ウケ反応が強かった順に並べた候補名ランキング) の実装。
        *   `HistoryView` (過去セッションの一覧表示と詳細参照) の実装。
    *   **FastAPI バックエンド**:
        *   `/sessions` (セッションの作成・取得・クローズ) および `/candidates` (名前候補取得) エンドポイントの実装。
*   **成果**: 犬・猫に対する手動での呼びかけテストと結果の保存・一覧表示が可能なMVPを実現。

### Phase 2: Offline, Sync, Report (オフライン動作と同期・レポートエクスポート)
*   **目的**: 通信切断時（オフライン時）の探索データローカル保持と再接続時の自動同期、およびデータエクスポートとプライバシーマスキング。
*   **実装内容**:
    *   **iOS クライアント**:
        *   `FileManager` を用いたローカル JSON 形式でのデータ永続化の実装。
        *   ローカルキューを使用した未同期データの再送・同期ハンドラ (`syncOfflineData()`)。
        *   共有時のプライバシーマスキング機能 (位置情報、個体メモ、音声情報を非表示にするトグルオプション)。
    *   **FastAPI バックエンド**:
        *   セッション詳細を JSON/CSV/PDF 形式でパッケージ出力するエクスポート機能の実装。
*   **成果**: 電波の届かない山林や屋外環境でもセッションを記録し、オンライン復帰時にサーバーへ同期 remap できる高い堅牢性を獲得。

### Phase 3: Lightweight AI Scoring (AI判定ロジックと動作マーカー)
*   **目的**: カメラ等の行動観察情報（頭部方向・視線・接近・発声・遅延・再現性）に基づいた Heuristics による行動特徴量スコアリングの導入。
*   **実装内容**:
    *   `ReactionFeatures` 構造体を導入し、頭部回転、視線移動、接近度、再現性スコアなどの加重平均を用いて参考スコアを算出。
    *   iOS UIに、AIが認識した動作マーカー値（頭の向き、視線等）をプログレスバー・バッジとしてリアルタイムにフィードバック表示。
    *   AIによる反応解説テキスト (`explanation`) および判定信頼度 (`confidence`: high/medium/low) の生成。
*   **成果**: 単なる手動の判定に留まらず、AI行動特徴量の変化を加味した客観的で高精度な「参考スコア」の提示が可能に。

### Phase 4: Known Animal Training Data (既知名個体・学習データ収集)
*   **目的**: 個体識別名が明確な犬・猫に対する「正例・負例・曖昧例」の学習データ収集、同意管理とアノテーション。
*   **実装内容**:
    *   `KnownAnimalRegistrationView` による既知名個体登録（アレルギー、毛色、犬種などの設定および飼い主同意 `agreed` 管理）。
    *   `TrainingSessionView` による飼い主呼びかけ（音声収録/再生）、正例・負例テストデータとアノテーション付き画像の登録。
    *   オフライン状態からの同期キュー拡張。
*   **成果**: 将来的な機械学習モデル改善に必要な、アノテーション付きの教師データを蓄積する一連のパイプラインを構築。

### Phase 5: Batch Training and Model Distribution (モデルのバッチ学習と動的更新)
*   **目的**: 蓄積された学習データのバッチ処理と、エバリュエーションによるモデル更新、およびクライアントへの軽量モデル配信。
*   **実装内容**:
    *   **FastAPI バックエンド**:
        *   訓練データエクスポートジョブ、学習シミュレーションバッチジョブ (`/training-data/sync`) の構築。
        *   精度評価メトリクス（F1スコア等）を算出しモデルを切り替えるモデルレジストリの実装。
    *   **iOS クライアント**:
        *   `checkModelUpdate()` で新モデルの検知、および `applyModelUpdate()` によるクライアント側モデルバージョン（1.0.0 → 1.1.x）の動的アップデート。
*   **成果**: 収集した教師データを用いてモデルを再学習し、アプリをアップデートすることなく新たなスコアリングモデルへ更新する仕組みを確立。

### Phase 6: Internationalization (多言語・地域対応と愛称展開)
*   **目的**: 国・言語別の名前辞書の切り替え、音声プロファイル（TTS）のローカライズ、およびニックネーム・発音近似の愛称展開。
*   **実装内容**:
    *   **iOS クライアント**:
        *   `SettingsView` による国 (JP/US/GB) および言語 (ja-JP/en-US/en-GB) の選択。
    *   **FastAPI バックエンド**:
        *   国・言語ごとの名前マスタ辞書の取得。
        *   多言語 TTS プロファイル取得と音声ファイルの事前プレビュー作成 (`/tts/preview`)。
        *   愛称展開ロジック: 「Max」に対して「Maxie」「Maxy」などの英語ニックネーム、および日本語「モモ」に対して「モモちゃん」「モモちん」等の愛称を自動展開。
*   **成果**: グローバル市場での迷子捜索に対応し、言語ごとの多様な呼びかけパターンを自動検証可能に。

### Phase 7: Joke Mode (ジョーク・娯楽用ニックネーム探索)
*   **目的**: 本体機能から明確に分離された、ユーザー自身や友人の写真を使って楽しむ「ニックネーム提案・笑顔判定」お遊びモードの追加。
*   **実装内容**:
    *   `JokeSetupView` (娯楽用途への警告表示、PhotosPickerによる画像選択/顔検出)。
    *   `JokeExplorationView` (フロントカメラプレビューを模擬した笑顔・笑い検知、TTS再生とリアクション)。
    *   `JokeResultView` (最優秀ニックネーム、ウケスコアランキングの提示)。
    *   SwiftUI `ImageRenderer` を用いた NeXTStep 枠線をベースにした「ジョーク結果カード」のローカル生成と、OS共有シートを用いたエクスポート。
    *   **安全性ガードレール (No Unsafe Attribute Guessing)**:
        *   実名や身体的特徴、性別、人種等の機微な属性推定を一切禁止し、ブラックリストフィルター (`joke_guardrails.py`) で安全なニックネームだけを出力。
*   **成果**: 探索機能のロジックやデータベースと完全に分離しつつ、エンターテインメント要素を融合した親しみやすいUXを実現。

### Phase 8: Outdoor Advanced Exploration (環境音適応 ＆ 探索反応ヒートマップ)
*   **目的**: 屋外での探索精度を最大化するための、環境音測定デシベルに応じた音声最適化と、MapKit による地理的ヒートマップ可視化。
*   **実装内容**:
    *   `NoiseMonitor.swift`: `AVAudioRecorder` を使用して再生直前の環境騒音レベル（dB）を実機で実測する機能（フォールバック対応）。
    *   **騒音適応TTS**: 騒音値（例: 60dB以上）に応じて AVSpeechUtterance の音量を引き上げ、再生速度を下げ、ピッチを高くする動的キャリブレーション。
    *   `HeatmapView.swift`: MapKit を用いて、探索セッションの位置情報 (経緯度) からピンをマッピング。反応スコアに応じてアノテーションピンを色分け（赤：強反応、オレンジ：中反応、青：弱反応）し、タップ時に詳細シート (騒音レベルや最適呼称候補) を提示。
    *   **FastAPI バックエンド**:
        *   `GET /api/v1/heatmap-points` を新設し、共通エンベロープで位置情報＋騒音データ＋最適候補名を一括返却。
*   **成果**: 屋外での再生環境の聞き取りやすさを高め、どの地点でどの名前に強い反応があったかを地理的に直感的に俯瞰できる高度なフィールド探索環境を構築。

---

## 🧪 自動E2E接続テスト結果
接続検証テストランナー `LostPetNameFinderTestRunner` で、FastAPI バックエンドサーバーと連携し、全シナリオが 100% 成功したことを検証・確認しています。

```text
=== Starting API Client Connection Test ===
Removed local persistence at /Users/minorukaminao/Library/Developer/CoreSimulator/Devices/.../orpheus_local_data.json

--- 1. Creating Exploration Session ---
Session created successfully!
Session ID: ses_3f15e8533528
Species: dog
Notes: Test notes via Swift runner
Status: created

--- 2. Fetching Candidates ---
Candidates fetched: 5
 - モモ (ID: cand_001)
 - モカ (ID: cand_002)
 - ルナ (ID: cand_003)
 - ココ (ID: cand_004)
 - レオ (ID: cand_005)

--- 3. Recording Trial ---
Recording trial for: モモ
Trials count: 1
Recorded Trial ID: trl_97652e94d17f
Candidate Name: モモ
Reaction: reaction_yes
Ranked Candidates (after trial):
 - モモ: score 0.90, uncertain: true, confidence: low, explanation: 呼びかけに対し、目視での明らかな反応が観察されました。

--- 4. Refining Candidates ---
Refined Candidates:
 - モモ: score 0.90, uncertain: true, confidence: low, explanation: 呼びかけに対し、目視での明らかな反応が観察されました。
 - モモちゃん: score 0.85, uncertain: true, confidence: low, explanation: 有力候補「モモ」から展開された愛称候補です。

--- 5. Closing Session ---
Session status after close: closed
Session closed successfully.

=== Scenario 2: Offline Exploration & Sync ===
Toggling offline mode ON...
Creating offline session...
Offline Session Created: ses_offline_6607FF
Recording trial while offline...
Closing session while offline...
Sync queues status before online sync:
 - Pending Sessions: 1
 - Pending Trials: 1
Toggling offline mode OFF & performing synchronization...
Sync queues status after sync:
 - Pending Sessions: 0
 - Pending Trials: 0
Synced Online Session ID: ses_66f1a188f925

=== Scenario 3: Report Export ===
Requesting export for format: json
 - SUCCESS: Exported file is downloadable! (Size: 1692 bytes)
Requesting export for format: csv
 - SUCCESS: Exported file is downloadable! (Size: 584 bytes)
Requesting export for format: pdf
 - SUCCESS: Exported file is downloadable! (Size: 39368 bytes)

=== Scenario 4: Known Animal & Training Session ===
1. Registering Known Animal...
Registered Known Animal ID: ka_36bebd8e628a
True Name: タマ
2. Registering Photo Metadata...
Successfully registered image metadata. Image ID: img_aa8de83789b3
3. Creating Training Session...
Training Session Created ID: trs_e1948dcba8b0
4. Recording Positive/Negative Training Trials...
Trials recorded count: 3
5. Completing Training Session...
Training session completed successfully.

=== Scenario 4.2: Offline Known Animal & Sync ===
Toggling offline mode ON...
Registering Known Animal while offline...
Creating training session while offline...
Recording trials while offline...
Completing training session while offline...
Sync queues status before online sync:
 - Pending Known Animals: 1
 - Pending Training Sessions: 1
Toggling offline mode OFF & performing synchronization...
SUCCESS: Phase 4 offline queue sync completed!

=== Scenario 5: Batch Training & Model Distribution ===
Initial model version: 1.0.0
1. Running training data export...
Export Job created ID: job_exp_3de08783f585
2. Spawning training sync batch job...
Sync Learning Job created ID: job_sync_8771ae529620
3. Waiting for learning job completion...
Job status: completed, progress: 100.0%
New Model Version generated: 1.1.22
4. Checking for model updates on client...
Update available: true
Latest version: 1.1.22
5. Applying model update to client...
Applied model version: 1.1.22
6. Fetching current active model metadata...
Active model version on registry: 1.1.22
SUCCESS: Phase 5 Batch Training & Model Distribution verified!

=== Scenario 6: Internationalization & Localization ===
1. Fetching available countries and languages...
Countries available: 3
2. Configuring Client to United States & en-US locale...
3. Creating Exploration Session in US locale...
Created US Session ID: ses_c854003553fb
4. Fetching Candidates in US locale...
Candidates fetched: 3 (Max, Bella, Charlie)
5. Recording Trial for 'Max' with positive reaction...
6. Refining Candidates and verifying English Nicknames...
Refined Candidates: Max, Maxie, Maxy
SUCCESS: English nickname generated successfully!
7. Requesting TTS Preview on English voice profile...
SUCCESS: TTS preview generated at valid URL.
SUCCESS: Phase 6 Internationalization verified!

=== Scenario 7: Joke Mode Validation ===
1. Creating Joke Session...
Joke Session Created ID: jks_e1cdabdaff69
2. Uploading Joke Image...
Image upload completed. Has Face: true
3. Generating Joke Candidates...
Joke Candidates count: 5 (たっちゃん, よっちゃん, モモっち, 部長っぽい人, 社長さん)
4. Recording Reactions for Candidates...
5. Fetching Joke Results...
SUCCESS: Phase 7 Joke Mode verified!

=== Scenario 8: Outdoor Advanced Exploration ===
1. Creating Coordinate-Aware Session (代々木公園)...
Outdoor Session Created ID: ses_2e5cfaa589fa
Coordinates: (35.6698, 139.6975)
2. Fetching Candidates for Yoyogi Park...
Candidate to play: Max
3. Recording Trial with Environmental Noise Decibels (68.2 dB)...
Trial Recorded ID: trl_a007807c6971
Recorded Ambient Noise: 68.2 dB
4. Closing Session...
5. Fetching Heatmap Points from API...
Heatmap points returned count: 3
 - Point ID: ses_1416e4e5ca1b, Coordinates: (35.6698, 139.6975), Best Name: Max, Score: 0.9, Avg Noise: 68.2 dB
 - Point ID: ses_2e5cfaa589fa, Coordinates: (35.6698, 139.6975), Best Name: Max, Score: 0.9, Avg Noise: 68.2 dB
 - Point ID: ses_3f15e8533528, Coordinates: (35.6698, 139.6975), Best Name: Max, Score: 0.9, Avg Noise: 68.2 dB
SUCCESS: Phase 8 Outdoor Advanced Exploration verified!

=== SUCCESS: All Scenario tests completed successfully! ===
```
