# Mobile UI Policy

## Target

- Primary: iPhone
- Secondary: iPad
- Later: Android or web if needed

## Apple HIG Principles

- Clarity: 情報を明快にする
- Deference: コンテンツを主役にする
- Depth: 階層と文脈を自然に伝える
- Standard UI first
- Accessibility first

## Rules

1. 1画面1主目的。
2. 主操作は画面下部に明確に配置する。
3. 色だけで状態を表現しない。
4. 隠しジェスチャーに依存しない。
5. 破壊的操作は確認を挟む。
6. 通常、読み込み中、空、エラー、権限不足、オフライン、成功状態を定義する。
7. Dynamic Type、VoiceOver、コントラスト、44pt以上のタップ領域を前提にする。
8. NeXT / OPENSTEP風の表現は、構造・余白・階層感に留める。
9. Apple標準操作性と衝突する装飾は採用しない。

## Exploration Screen Priority

探索実行画面では以下を優先する。

```text
開始
一時停止
反応あり
反応弱い
反応なし
保存
```

詳細設定は探索前画面または設定画面に分離する。
