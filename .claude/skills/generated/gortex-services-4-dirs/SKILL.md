---
name: gortex-services-4-dirs
description: "Work in the services +4 dirs area — 32 symbols across 7 files (77% cohesion)"
---

# services +4 dirs

32 symbols | 7 files | 77% cohesion

## When to Use

Use this skill when working on files in:
- `external-call::stdlib:package:http/http.dart`
- `lib/core/mock_data.dart`
- `lib/models/news.dart`
- `lib/screens/web/admin/admin_news_screen.dart`
- `lib/services/api_client.dart`
- `lib/services/favorites_service.dart`
- `lib/services/news_service.dart`

## Key Files

| File | Symbols |
|------|---------|
| `external-call::stdlib:package:http/http.dart` | package:http/http.dart |
| `lib/core/mock_data.dart` | updateNews, newsById |
| `lib/models/news.dart` | News, toCreateJson, contentPreview |
| `lib/screens/web/admin/admin_news_screen.dart` | _submit |
| `lib/services/api_client.dart` | toString, put, getToken, clearToken, _handleNoContent, ... |
| `lib/services/favorites_service.dart` | removeFavorite |
| `lib/services/news_service.dart` | getWebNews, getWebNewsById, deleteNews, NewsService, createNews, ... |

## Entry Points

- `lib/screens/web/admin/admin_news_screen.dart::_NewsFormState._submit`

## Connected Communities

- **core +3 dirs** (2 cross-edges)
- **screens/web +7 dirs** (1 cross-edges)

## How to Explore

```
get_communities with id: "community-21"
smart_context with task: "understand services +4 dirs", format: "gcx"
find_usages with id: "lib/screens/web/admin/admin_news_screen.dart::_NewsFormState._submit", format: "gcx"
```

_`format: "gcx"` returns the [GCX1 compact wire format](../../docs/wire-format.md) — round-trippable, ~27% fewer tokens than JSON. Drop it for JSON output; agents using `@gortex/wire` or the Go `github.com/gortexhq/gcx-go` package decode either._
