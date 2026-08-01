---
name: gortex-screens-web-7-dirs
description: "Work in the screens/web +7 dirs area — 36 symbols across 13 files (78% cohesion)"
---

# screens/web +7 dirs

36 symbols | 13 files | 78% cohesion

## When to Use

Use this skill when working on files in:
- `lib/core/theme.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/register_screen.dart`
- `lib/screens/shell_screen.dart`
- `lib/screens/wearable/wearable_news_detail_screen.dart`
- `lib/screens/wearable/wearable_news_list_screen.dart`
- `lib/screens/web/admin/admin_news_screen.dart`
- `lib/screens/web/favorites_screen.dart`
- `lib/screens/web/news_detail_screen.dart`
- `lib/screens/web/news_list_screen.dart`
- `lib/screens/web/profile_screen.dart`
- `lib/widgets/news_card.dart`
- `windows/runner/win32_window.h`

## Key Files

| File | Symbols |
|------|---------|
| `lib/core/theme.dart` | dark, AppTheme |
| `lib/screens/auth/login_screen.dart` | _LoginScreenState, _submit, build |
| `lib/screens/auth/register_screen.dart` | _RegisterScreenState, build, _submit |
| `lib/screens/shell_screen.dart` | build, _NavItem, build, _DesktopShell |
| `lib/screens/wearable/wearable_news_detail_screen.dart` | _NewsDetail, build |
| `lib/screens/wearable/wearable_news_list_screen.dart` | _ErrorState, build, build, _EmptyState |
| `lib/screens/web/admin/admin_news_screen.dart` | build |
| `lib/screens/web/favorites_screen.dart` | build, _FavoriteCard |
| `lib/screens/web/news_detail_screen.dart` | _ArticleView, build |
| `lib/screens/web/news_list_screen.dart` | _ErrorView, build, _EmptyView, build |
| `lib/screens/web/profile_screen.dart` | _save, build |
| `lib/widgets/news_card.dart` | build, build, WearableNewsCard, NewsCard, _NewsImage, ... |
| `windows/runner/win32_window.h` | Size |

## Entry Points

- `lib/core/theme.dart::AppTheme.dark`
- `lib/screens/web/news_detail_screen.dart::_ArticleView.build`
- `lib/screens/shell_screen.dart::_DesktopShell.build`
- `lib/screens/web/favorites_screen.dart::_FavoriteCard.build`
- `lib/widgets/news_card.dart::WearableNewsCard.build`

## Connected Communities

- **screens · build · shell_screen (7)** (1 cross-edges)

## How to Explore

```
get_communities with id: "community-19"
smart_context with task: "understand screens/web +7 dirs", format: "gcx"
find_usages with id: "lib/core/theme.dart::AppTheme.dark", format: "gcx"
```

_`format: "gcx"` returns the [GCX1 compact wire format](../../docs/wire-format.md) — round-trippable, ~27% fewer tokens than JSON. Drop it for JSON output; agents using `@gortex/wire` or the Go `github.com/gortexhq/gcx-go` package decode either._
