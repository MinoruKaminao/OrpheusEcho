# Name Dictionary

## Candidate Fields

```text
country
language
species
base_name
reading
popularity_rank
nickname_variants
phonetic_variants
tts_locale
enabled
source
confirmed_at
```

## Rules

- 犬用・猫用を分離する。
- 国・言語ごとに辞書を分離する。
- 愛称展開は base_name と別に保持する。
- 発音近似候補はTTS検証対象にする。
- 辞書の出典と確認日を記録する。
