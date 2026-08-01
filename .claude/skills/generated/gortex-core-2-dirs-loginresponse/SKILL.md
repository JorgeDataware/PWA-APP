---
name: gortex-core-2-dirs-loginresponse
description: "Work in the core +2 dirs · LoginResponse area — 6 symbols across 3 files (63% cohesion)"
---

# core +2 dirs · LoginResponse

6 symbols | 3 files | 63% cohesion

## When to Use

Use this skill when working on files in:
- `lib/core/mock_data.dart`
- `lib/models/user.dart`
- `lib/services/auth_service.dart`

## Key Files

| File | Symbols |
|------|---------|
| `lib/core/mock_data.dart` | login, register |
| `lib/models/user.dart` | LoginResponse |
| `lib/services/auth_service.dart` | AuthService, register, login |

## Entry Points

- `lib/core/mock_data.dart::MockData.register`
- `lib/core/mock_data.dart::MockData.login`

## Connected Communities

- **core +3 dirs** (2 cross-edges)
- **services +4 dirs** (2 cross-edges)

## How to Explore

```
get_communities with id: "community-6"
smart_context with task: "understand core +2 dirs · LoginResponse", format: "gcx"
find_usages with id: "lib/core/mock_data.dart::MockData.register", format: "gcx"
```

_`format: "gcx"` returns the [GCX1 compact wire format](../../docs/wire-format.md) — round-trippable, ~27% fewer tokens than JSON. Drop it for JSON output; agents using `@gortex/wire` or the Go `github.com/gortexhq/gcx-go` package decode either._
