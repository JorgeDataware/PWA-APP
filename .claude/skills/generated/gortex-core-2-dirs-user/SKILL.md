---
name: gortex-core-2-dirs-user
description: "Work in the core +2 dirs · User area — 17 symbols across 5 files (62% cohesion)"
---

# core +2 dirs · User

17 symbols | 5 files | 62% cohesion

## When to Use

Use this skill when working on files in:
- `lib/core/constants.dart`
- `lib/core/mock_data.dart`
- `lib/core/utils.dart`
- `lib/models/user.dart`
- `lib/services/user_service.dart`

## Key Files

| File | Symbols |
|------|---------|
| `lib/core/constants.dart` | AppConstants |
| `lib/core/mock_data.dart` | createUser |
| `lib/core/utils.dart` | screenWidth, isDesktop, isWearable, ContextExtensions, isMobile |
| `lib/models/user.dart` | isAdmin, User |
| `lib/services/user_service.dart` | getUserById, updateProfile, createUser, getProfile, updateUser, ... |

## Entry Points

- `lib/core/mock_data.dart::MockData.createUser`

## Connected Communities

- **services +4 dirs** (7 cross-edges)
- **core +3 dirs** (1 cross-edges)

## How to Explore

```
get_communities with id: "community-7"
smart_context with task: "understand core +2 dirs · User", format: "gcx"
find_usages with id: "lib/core/mock_data.dart::MockData.createUser", format: "gcx"
```

_`format: "gcx"` returns the [GCX1 compact wire format](../../docs/wire-format.md) — round-trippable, ~27% fewer tokens than JSON. Drop it for JSON output; agents using `@gortex/wire` or the Go `github.com/gortexhq/gcx-go` package decode either._
