---
name: gortex-providers-1-dirs
description: "Work in the providers +1 dirs area — 16 symbols across 2 files (74% cohesion)"
---

# providers +1 dirs

16 symbols | 2 files | 74% cohesion

## When to Use

Use this skill when working on files in:
- `lib/providers/auth_provider.dart`
- `lib/screens/web/news_list_screen.dart`

## Key Files

| File | Symbols |
|------|---------|
| `lib/providers/auth_provider.dart` | user, isLoading, updateUser, _persist, register, ... |
| `lib/screens/web/news_list_screen.dart` | _ListView, build, build, _GridView |

## Entry Points

- `lib/providers/auth_provider.dart::AuthProvider.initialize`
- `lib/screens/web/news_list_screen.dart::_GridView.build`
- `lib/screens/web/news_list_screen.dart::_ListView.build`

## How to Explore

```
get_communities with id: "community-8"
smart_context with task: "understand providers +1 dirs", format: "gcx"
find_usages with id: "lib/providers/auth_provider.dart::AuthProvider.initialize", format: "gcx"
```

_`format: "gcx"` returns the [GCX1 compact wire format](../../docs/wire-format.md) — round-trippable, ~27% fewer tokens than JSON. Drop it for JSON output; agents using `@gortex/wire` or the Go `github.com/gortexhq/gcx-go` package decode either._
