# Offline Sync

## Goal

屋外・保護現場・通信不安定環境でも探索を完了できるようにする。

## Local Flow

```text
Local Session
  ↓
Local Trials
  ↓
Local Media Queue
  ↓
Sync Queue
  ↓
Backend API
```

## Rules

- セッション・試行ログは端末内に即時保存する。
- 通信失敗時はキューに残す。
- 再送は冪等APIで処理する。
- メディアアップロードとメタデータ同期は分離する。
- 同期状態をUIに表示する。

## Sync Status

```text
local_only
pending
syncing
synced
failed
conflict
```
