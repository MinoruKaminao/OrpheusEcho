# Screen Specifications

## Home

- Purpose: 新規探索と履歴確認
- Primary Action: 新規セッション
- Secondary Actions: 履歴、設定
- States: normal, empty history, offline, sync pending, error

## Species Selection

- Purpose: 犬/猫を選択する
- Primary Action: 犬、猫の大ボタン
- States: normal, selection made

## Animal Info

- Purpose: 任意の特徴情報を記録する
- Inputs: 保護場所、毛色、大きさ、年齢感、メモ
- Validation: 任意入力。保存可能な最大文字数を定義する

## Exploration

- Purpose: 名前候補を再生し反応を記録する
- Components: camera preview, current candidate, playback control, reaction buttons
- Primary Actions: 再生開始、一時停止、反応あり、反応弱い、反応なし
- States: permission denied, camera unavailable, offline, recording, paused, completed

## Candidate Ranking

- Purpose: 反応が強かった候補を確認する
- Components: ranked list, score, replay, notes
- Wording: 有力候補、参考スコア、反応が強かった候補

## Result Detail

- Purpose: セッション結果を保存・共有する
- Actions: 保存、共有、再探索
- Privacy: 共有前に位置情報・個人情報・メディア添付の有無を確認する

## History

- Purpose: 過去セッションを確認する
- Components: date, species, top candidates, sync status

## Settings

- Purpose: 音声、保存、同期、言語、プライバシーを設定する
- Rules: 危険な初期値を避け、録画・位置情報は明示許可制
