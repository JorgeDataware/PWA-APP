---
name: gortex-screens-web-1-dirs
description: "Work in the screens/web +1 dirs area — 16 symbols across 4 files (83% cohesion)"
---

# screens/web +1 dirs

16 symbols | 4 files | 83% cohesion

## When to Use

Use this skill when working on files in:
- `lib/screens/web/favorites_screen.dart`
- `lib/screens/web/news_detail_screen.dart`
- `lib/screens/web/news_list_screen.dart`
- `lib/services/favorites_service.dart`

## Key Files

| File | Symbols |
|------|---------|
| `lib/screens/web/favorites_screen.dart` | _load, initState, build, _remove, _FavoritesScreenState |
| `lib/screens/web/news_detail_screen.dart` | _NewsDetailScreenState, _load, build, initState, _toggleFavorite |
| `lib/screens/web/news_list_screen.dart` | _NewsListScreenState, initState, build, _load, _toggleFavorite |
| `lib/services/favorites_service.dart` | FavoritesService |

## Entry Points

- `lib/screens/web/news_list_screen.dart::_NewsListScreenState._toggleFavorite`
- `lib/screens/web/news_detail_screen.dart::_NewsDetailScreenState._toggleFavorite`
- `lib/screens/web/favorites_screen.dart::_FavoritesScreenState.build`

## How to Explore

```
get_communities with id: "community-18"
smart_context with task: "understand screens/web +1 dirs", format: "gcx"
find_usages with id: "lib/screens/web/news_list_screen.dart::_NewsListScreenState._toggleFavorite", format: "gcx"
```

_`format: "gcx"` returns the [GCX1 compact wire format](../../docs/wire-format.md) — round-trippable, ~27% fewer tokens than JSON. Drop it for JSON output; agents using `@gortex/wire` or the Go `github.com/gortexhq/gcx-go` package decode either._
