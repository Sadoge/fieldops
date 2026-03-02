# FieldOps

FieldOps is a Flutter application for managing field work orders with an
offline-first workflow. It combines local persistence, background sync, role-
aware access control, and export utilities so teams can keep working even when
connectivity is unreliable.

## What It Includes

- Work order list, detail, create, and edit flows
- Notes and photo attachments linked to work orders
- Audit log tracking
- CSV and PDF export, plus native sharing support
- Authentication and permission-based route guards
- Local SQLite storage with Drift
- Sync queue handling with reconnect-triggered sync and Android background sync
- Supabase integration, with a local mock backend fallback

## Tech Stack

- Flutter
- Riverpod + `flutter_riverpod`
- GoRouter
- Drift + SQLite
- Supabase
- Workmanager

## Project Layout

```text
lib/
  core/
    auth/         Authentication, user state, local auth persistence
    config/       App-level configuration such as Supabase credentials
    database/     Drift database, schema, and generated data layer
    export/       CSV, PDF, and share services
    network/      Remote client abstractions and implementations
    permissions/  Role and permission checks
    router/       App navigation and guarded routes
    sync/         Sync queue, conflict handling, retry policy, sync engine
  features/
    audit_log/
    notes/
    photos/
    work_orders/
```

## Getting Started

### Prerequisites

- Flutter SDK compatible with Dart `^3.9.2`
- Xcode / Android Studio toolchains as required by your target platform

### Install Dependencies

```bash
flutter pub get
```

### Configure the Backend

The app currently defaults to Supabase:

- `lib/core/providers.dart` sets `useSupabase = true`
- `lib/core/config/supabase_config.dart` contains placeholder credentials

Before running the app, do one of the following:

1. Replace `SupabaseConfig.url` and `SupabaseConfig.anonKey` with real values.
2. Or switch `useSupabase` to `false` to use the local mock backend instead.

If you leave placeholder credentials in place while `useSupabase` is `true`,
startup will fail when Supabase initializes.

### Generate Code

This project uses code generation for Drift, Riverpod, and JSON models.

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run the App

```bash
flutter run
```

## Common Commands

Run tests:

```bash
flutter test
```

Regenerate generated files while developing:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

Format source files:

```bash
dart format lib test
```

## Sync Behavior

- The app stores data locally in a Drift-backed SQLite database.
- Pending changes are queued and synced when connectivity returns.
- On Android, `Workmanager` registers a periodic background sync task every 15
  minutes.
- When the app detects a reconnect event, it triggers a foreground sync.

## Notes

- The local database file is created as `fieldops.sqlite` in the app documents
  directory.
- Route access to the audit log is guarded by the permission layer.
- Generated files such as `*.g.dart` should be kept in sync with schema and
  model changes.
