# Commit Message Rules

## Primary format

Use `scope: summary` unless repository docs define a stricter format.

## Scope selection

1. Prefer the dominant changed module.
2. Use stable nouns (`scanner`, `tests`, `build`, `docs`, `ci`, `app`).
3. Avoid vague scopes (`misc`, `temp`, `stuff`).

## Summary wording

1. Start with an action verb.
2. Describe concrete change.
3. Keep one intent per commit.
4. Do not end subject with period.

## Anti-patterns

1. `update code`
2. `fix bug`
3. `misc changes`
4. `wip`

## Better examples

1. `scanner: improve photo QR fallback alert`
2. `tests: add scan history quick-action coverage`
3. `build: align bundle id for debug target`
4. `docs: clarify camera permission behavior`
