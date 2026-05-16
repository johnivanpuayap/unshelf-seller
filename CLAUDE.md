# Project Rules -- Unshelf Seller

## Coding Standards

Follow `CODING_STANDARDS.md` in the project root for all code conventions, naming, architecture patterns, testing patterns, and git practices.

## Git Workflow

- **Atomic commits**: Each commit should do exactly one thing. Never bundle unrelated changes.
- **No co-authored-by**: Do not add `Co-Authored-By` lines to commit messages.
- **Branch per phase**: Create a separate branch for each refactoring phase under `feature/`:
  - `feature/phase-1-bug-fixes`
  - `feature/phase-2-security`
  - `feature/phase-3-foundation`
  - `feature/phase-4-architecture`
  - `feature/phase-5-polish`
- Branch off `main` for each phase. Merge into `main` when phase is complete.

## Quality Gates

- **Code review before completion**: Every task must be reviewed by a separate agent before marking it as complete. Do not self-approve.
- **Tests before completion**: Every task must have passing tests verified (`flutter test` or `flutter analyze`) before marking it as complete. If tests fail, fix them before proceeding.
- **Verify compilation**: Run `flutter analyze` after every code change to catch issues early.

## Tech Stack

- Flutter 3.41.6 (stable), Dart 3.11
- Firebase (Auth, Firestore, Storage)
- Provider for state management
- get_it for dependency injection
- MVVM architecture with layer-based folder structure
- Flutter SDK path: `C:\flutter\bin` (add to PATH with `export PATH="/c/flutter/bin:$PATH"`)

## Project Structure

```
lib/
  core/           -- DI, base classes, constants, errors, interfaces, logger
  models/         -- Data models
  services/       -- Firebase service implementations
  viewmodels/     -- ChangeNotifier viewmodels extending BaseViewModel
  views/          -- Screen widgets
  components/     -- Reusable UI widgets
  authentication/ -- Auth views and viewmodel
  utils/          -- Helpers (colors)
```

## Conventions

- Models use `fromDocument()` for Firestore reads, `toMap()` for writes
- Nested models (BundleItem, OrderItem) use `fromMap()` / `toMap()`
- ViewModels extend `BaseViewModel` and use `runBusyFuture()` for async work
- Services implement interfaces from `core/interfaces/`
- Use `AppLogger` instead of `print()` for all logging
- Use constants from `core/constants/` instead of hardcoded strings
- Credentials live in `.env`, never hardcoded in source

## Unshelf Rebrand (sub-project 2)

- **Sub-project:** 2 of 5 in the broader Unshelf rebrand
- **Spec:** `docs/crucible/specs/2026-05-16-seller-rebrand-design.md`
- **Plan:** `docs/crucible/plans/2026-05-16-seller-rebrand-implementation.md`
- **Brand kit (submodule):** `brand-kit/docs/crucible/`
- **Shared auth contract:** `brand-kit/docs/crucible/auth-screens.md`

## After cloning

```bash
git submodule update --init --recursive
flutter pub get
```

The brand kit is private — needs SSH access to `johnivanpuayap/unshelf-brand-kit`.

## Locked decisions (rebrand)

- **Name + tagline:** Unshelf · Eat well. Waste less.
- **Palette:** Leaf & Honey (primary `#3F8E4A`)
- **Typography:** DM Serif Display (display/headline/title) + DM Sans (body/label)
- **UI style:** Soft Editorial. Pill buttons. 14px card corners. No glassmorphism. No pure-white surfaces.
- **State management:** Riverpod 4.x with `@riverpod` codegen (after Phase 2 — Provider during Phase 1)
- **Maps:** flutter_map + OSM (already in place)
- **Role:** all auth flow registers users with `type: 'seller'`
- **Uniqueness rule** (`[[unshelf-buyer-seller-uniqueness]]`): seller and buyer share brand tokens + auth flow ONLY. No shared UI components.

## Two-remote constraint

- `origin` → `git@github.com:Unshelf-SoftEng/Unshelf_Seller.git` (ORG — never push here)
- `personal` → `git@github.com:johnivanpuayap/unshelf-seller.git` (TARGET — push here)
- All `gh` commands MUST include `--repo johnivanpuayap/unshelf-seller`. `gh repo set-default johnivanpuayap/unshelf-seller` is set.
