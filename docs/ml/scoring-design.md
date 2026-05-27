# Scoring Design

## MVP Rule-Based Score

```text
reaction_score =
  manual_score
  + replay_bonus
  + user_marked_interest_bonus
```

## Manual Score

```text
反応あり: 1.0
反応弱い: 0.5
反応なし: 0.0
未評価: null
```

## Phase 3 Assisted Score

```text
reaction_score =
  head_turn_score * w1
  + gaze_shift_score * w2
  + ear_motion_score * w3
  + approach_score * w4
  + vocalization_score * w5
  + latency_score * w6
  + repeatability_score * w7
  + manual_score * w8
```

## Output Requirements

Each score must include:

- candidate_id
- score
- confidence
- explanation
- source: manual / rule_based / model_assisted
- model_version when applicable

## UI Wording

Use:

- 参考スコア
- 反応が強かった候補
- 有力候補
- 推定結果

Avoid:

- 正解
- 確定
- 特定
- 本当の名前
