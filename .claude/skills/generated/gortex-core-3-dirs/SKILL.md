---
name: gortex-core-3-dirs
description: "Work in the core +3 dirs area — 22 symbols across 4 files (69% cohesion)"
---

# core +3 dirs

22 symbols | 4 files | 69% cohesion

## When to Use

Use this skill when working on files in:
- `lib/core/mock_data.dart`
- `lib/models/favorite.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/services/favorites_service.dart`

## Key Files

| File | Symbols |
|------|---------|
| `lib/core/mock_data.dart` | news, _Account, createNews, users, deleteUser, ... |
| `lib/models/favorite.dart` | Favorite |
| `lib/screens/auth/login_screen.dart` | initState |
| `lib/services/favorites_service.dart` | addFavorite, getFavorites |

## Entry Points

- `lib/core/mock_data.dart::MockData.addFavorite`
- `lib/core/mock_data.dart::MockData.createNews`

## Connected Communities

- **services +4 dirs** (2 cross-edges)

## How to Explore

```
get_communities with id: "community-5"
smart_context with task: "understand core +3 dirs", format: "gcx"
find_usages with id: "lib/core/mock_data.dart::MockData.addFavorite", format: "gcx"
```

_`format: "gcx"` returns the [GCX1 compact wire format](../../docs/wire-format.md) — round-trippable, ~27% fewer tokens than JSON. Drop it for JSON output; agents using `@gortex/wire` or the Go `github.com/gortexhq/gcx-go` package decode either._
