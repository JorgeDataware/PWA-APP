# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**TechNews** is a Flutter PWA (Progressive Web App) — a tech news blog that targets two distinct form factors from a single codebase: standard web (desktop/mobile) and wearable (smartwatch-sized screens ≤320px).

The Flutter SDK is located at `C:\flutter`. The backend API runs at `http://localhost:5273`.

## Commands

```bash
# Run on Chrome (primary target)
flutter run -d chrome

# Build web release
flutter build web

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture

### Responsive Layout System

The entire layout strategy hinges on `BuildContext` extensions in `lib/core/utils.dart`:

```dart
context.isWearable  // width <= 320px → wearable UI
context.isMobile    // width <= 768px → bottom nav bar
context.isDesktop   // width > 768px  → sidebar nav
```

Routes in `main.dart` use `context.isWearable` to swap between two completely separate screen implementations at the same URL path. The `AppShell` in `lib/screens/shell_screen.dart` also switches between three shell layouts (`_WearableShell`, `_MobileShell`, `_DesktopShell`) based on the same breakpoints.

### State Management

Single provider: `AuthProvider` (`lib/providers/auth_provider.dart`) — a `ChangeNotifier` passed to `GoRouter` as `refreshListenable` so navigation guards react to auth state changes. Session is persisted to `SharedPreferences` (token + user fields). No other providers exist; screens fetch their own data directly from services.

### Service Layer

All services are static-method classes that delegate to `ApiClient`:

- `ApiClient` — handles JWT bearer tokens, JSON encode/decode, and maps HTTP errors to Spanish-language `ApiException` messages
- `AuthService` — login / register, returns `LoginResponse` with token + `User`
- `NewsService` — CRUD for `/api/web/news` and read-only `/api/wearable/news`
- `FavoritesService` — `/api/web/favorites`
- `UserService` — `/api/web/users` (admin)

### Routing

`go_router` with a `StatefulShellRoute.indexedStack` (5 branches: News, Favorites, Profile, Admin News, Admin Users). Admin branches are only visible in the nav when `user.isAdmin == true`. The router redirects unauthenticated users to `/login` and authenticated users away from auth routes.

### Wearable vs Web Screens

| Route | Web screen | Wearable screen |
|---|---|---|
| `/news` | `NewsListScreen` | `WearableNewsListScreen` |
| `/news/:id` | `NewsDetailScreen` | `WearableNewsDetailScreen` |

Wearable screens are in `lib/screens/wearable/`; web screens in `lib/screens/web/`.

### Theme

Dark-only theme defined entirely in `lib/core/theme.dart` (`AppTheme`). Use the named color constants (`AppTheme.primary`, `AppTheme.surface`, etc.) rather than hardcoded hex values.

### User Roles

`User.isAdmin` returns `true` when `role == 'Admin'`. Admin users see extra nav tabs and can access `/admin/news` and `/admin/users`.
