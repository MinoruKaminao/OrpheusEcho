# Phase Roadmap

## Phase 0: Foundation

- リポジトリ構成
- Agent分担
- UIルール
- API契約
- DB初期設計
- CI/CD初期化
- モックデータ

## Phase 1: MVP Manual Exploration

- 犬/猫選択
- 名前候補再生
- 手動反応記録
- ランキング
- セッション保存
- 履歴

## Phase 2: Offline, Sync, Report

- ローカル保存
- 同期キュー
- 再送制御
- CSV/JSON/PDF出力
- 共有時マスキング

## Phase 3: Lightweight AI Scoring

- 頭部方向変化
- 視線・顔向き変化
- 接近・停止
- 鳴き声検出
- 反応遅延
- 再現性スコア

## Phase 4: Known Animal Training Data

- 既知名個体登録
- 正例/負例/曖昧例収集
- 飼い主音声収録
- アノテーション
- 同意管理

## Phase 5: Batch Training and Model Distribution

- データ検証
- 特徴量生成
- バッチ学習
- モデル評価
- モデルレジストリ
- 軽量モデル配布

## Phase 6: Internationalization

- 国別辞書
- 多言語TTS
- UI言語切替
- 愛称展開
- 発音近似候補

## Phase 7: Joke Mode

- 本体探索と分離
- 娯楽用途と明示
- 実名推定・属性推定を禁止
- 安全なニックネーム候補のみ提示

## Phase 8: Outdoor Advanced Exploration

- 環境音のリアルタイム騒音測定 (AVAudioRecorder / NoiseMonitor)
- 騒音デシベルに応じた TTS 再生パラメータ (音量・ピッチ・速度) の動的適応・最適化
- MapKit を用いた探索反応位置情報の地理的ヒートマップ可視化画面
- スコアに応じたピンの色分け表示 (赤・オレンジ・青)
- ヒートマップのピン詳細ポップオーバー表示とデータ一括取得 API (GET /api/v1/heatmap-points) の連携
