# Development Workflow

## Branch Strategy

```text
main
  develop
    feature/{agent}-{short-name}
```

## Pull Request Requirements

- Purpose
- Scope
- Changed files
- API/DB/UI contract impact
- Screenshots or screen recordings for UI changes
- Tests
- Security/privacy impact

## CI Checks

- lint
- type check
- unit tests
- migration check
- API contract check
- UI snapshot or preview build where applicable
- documentation link check

## Environment

```text
local
dev
staging
production
```
