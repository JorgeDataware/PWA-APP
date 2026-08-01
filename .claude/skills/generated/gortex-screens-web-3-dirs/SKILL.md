---
name: gortex-screens-web-3-dirs
description: "Work in the screens/web +3 dirs area — 19 symbols across 7 files (86% cohesion)"
---

# screens/web +3 dirs

19 symbols | 7 files | 86% cohesion

## When to Use

Use this skill when working on files in:
- `lib/core/app_mode.dart`
- `lib/main.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/register_screen.dart`
- `lib/screens/web/favorites_screen.dart`
- `lib/screens/web/news_detail_screen.dart`
- `lib/screens/web/news_list_screen.dart`

## Key Files

| File | Symbols |
|------|---------|
| `lib/core/app_mode.dart` | initialize, AppMode |
| `lib/main.dart` | _buildRouter, TechNewsApp, _TechNewsAppState, build, createState, ... |
| `lib/screens/auth/login_screen.dart` | createState, LoginScreen |
| `lib/screens/auth/register_screen.dart` | RegisterScreen, createState |
| `lib/screens/web/favorites_screen.dart` | createState, FavoritesScreen |
| `lib/screens/web/news_detail_screen.dart` | NewsDetailScreen, createState |
| `lib/screens/web/news_list_screen.dart` | NewsListScreen, createState |

## Entry Points

- `lib/main.dart::main`
- `lib/main.dart::_TechNewsAppState._buildRouter`

## How to Explore

```
get_communities with id: "community-4"
smart_context with task: "understand screens/web +3 dirs", format: "gcx"
find_usages with id: "lib/main.dart::main", format: "gcx"
```

_`format: "gcx"` returns the [GCX1 compact wire format](../../docs/wire-format.md) — round-trippable, ~27% fewer tokens than JSON. Drop it for JSON output; agents using `@gortex/wire` or the Go `github.com/gortexhq/gcx-go` package decode either._
