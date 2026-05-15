# Unshelf Seller App — Rebrand + Architecture Upgrade Design Spec

> Date: 2026-05-16
> Status: Draft for review
> Sub-project: 2 of 5 in the Unshelf rebrand decomposition
> Repo: `personal-projects/unshelf-seller/` · https://github.com/johnivanpuayap/unshelf-seller

## Context

The Unshelf seller mobile app is the operator-side companion to the buyer marketplace — Cebu-first, Flutter, Firebase backend, managing inventory, batches, bundles, orders, payouts, and analytics for store owners. It is **substantially more mature** than the buyer was when sub-project 3 began:

- **Architecture:** service-oriented. `lib/core/interfaces/` defines abstractions (`IAuthService`, `IOrderService`, `IProductService`, `IStoreService`, etc.). `lib/services/` holds concrete implementations. `get_it: ^8.0.3` is the DI container. `lib/utils/theme.dart` is already extracted.
- **State management:** `provider: ^6.1.2` + `ChangeNotifier` viewmodels (22 of them).
- **Auth flow:** complete — `login_view`, `register_view`, `forgot_password_view`, `forgot_password_viewmodel`, `reset_password_view` (with URL parameter routing for branded reset emails).
- **Maps:** already on `flutter_map: ^7.0.2` + `flutter_map_cancellable_tile_provider: ^3.0.2`. No Google Maps.
- **Tests:** 8 viewmodel/service test files from Phase 7 testing work.
- **Components:** 12 in `lib/components/`: `chart`, `chat_bubble`, `chat_screen`, `custom_app_bar`, `custom_button`, `empty_state`, `image_delete`, `order_card`, `product_card`, `section_header`, `stat_card`, `status_badge`.
- **Docs:** `CLAUDE.md` and `CODING_STANDARDS.md` at root.
- **Brand:** still on the old teal palette (`AppColors.primaryColor = 0xFF0AB68D` in `lib/utils/colors.dart`). No brand-kit submodule. No Abundance Basket logos. Auth screens don't yet conform to the shared spec.

The seller rebrand combines **brand application**, **auth conformance**, **Riverpod migration**, **service-interface polish**, **repositories layer**, **components cleanup**, and **screen redesign** — all within the **uniqueness rule** (no shared layouts/components with the buyer; only the auth flow conforms to the shared spec).

## Scope

**In:**

- Brand kit application: submodule, `UnshelfTheme.light()/.dark()`, Abundance Basket logo assets, retire `lib/utils/colors.dart`'s old palette
- Auth conformance to `brand-kit/docs/crucible/auth-screens.md` for all four shared screens (login, register, forgot password, reset password) + seller-specific deltas (`type: 'seller'` role, Store name field on register, after-login route to `DashboardView`)
- Provider → Riverpod 4.x migration for all 22 viewmodels (`@riverpod` codegen)
- Service-interface polish: every concrete service implements its declared interface; every call site uses the interface (not the concrete)
- Repositories layer in `lib/data/repositories/`: AuthRepository, StoresRepository, OrdersRepository, ProductsRepository, UserRepository, StorageRepository — seller-internal, NOT shared with buyer
- Seller-internal components audit + `lib/components/README.md`
- Full screen redesign of ~30 views across 8 feature-area groups
- Seller-led admin dashboard (today's orders, revenue snapshot, low-stock alerts, expiring batches) — distinct from buyer's products-first home

**Out:**

- Sharing UI components / layouts with the buyer (`[[unshelf-buyer-seller-uniqueness]]`)
- New features (analytics dashboards or capabilities beyond what the existing viewmodels expose)
- Payments cleanup (Stripe → PayMongo) — separate sub-project
- Comprehensive test coverage expansion — separate sub-project (preserve existing 8 tests through migration)
- Store-submission polish (real app icon export, splash, store listings)
- Backend / Firestore schema changes
- Maps swap (already on `flutter_map`)

## Concept summary

| Decision | Value |
|---|---|
| Visual identity | Inherited from brand kit (Leaf & Honey palette, DM Serif Display + DM Sans, Soft Editorial style) |
| Quality bar | The redesigned auth screens that ship in Phase 1 |
| Auth contract | `brand-kit/docs/crucible/auth-screens.md` — seller diffs: `type: 'seller'`, Store name field, `DashboardView` post-login route |
| State mgmt target | Riverpod 4.x with `@riverpod` codegen |
| Service interfaces | Existing `lib/core/interfaces/` polished — every concrete behind an interface |
| Data layer | New `lib/data/repositories/` between services and Firestore (seller-internal) |
| Component strategy | Three uses → extract. Seller-internal. NOT shared with buyer |
| Dashboard IA | Seller-led: orders + revenue + inventory + alerts at top |
| Branch strategy | One branch per phase, PR-merged via `gh pr merge --squash`, target `johnivanpuayap/unshelf-seller` |
| Repo | `personal-projects/unshelf-seller/` — `origin` is ORG (`Unshelf-SoftEng/Unshelf_Seller`), `personal` is personal fork; all gh commands target `johnivanpuayap/unshelf-seller` |
| Git identity | `johnivanpuayap@gmail.com` (already configured) |

## Uniqueness rule (re-stated)

Per memory `[[unshelf-buyer-seller-uniqueness]]`: seller and buyer share **brand tokens, logos, copy voice rules, Soft Editorial principles, and the auth flow**. They do NOT share layouts, components, or business surfaces. The seller is an admin app; the buyer is a marketplace. They look like siblings, not twins.

When building seller `lib/components/` widgets:
- Optimize for seller-side use cases (inventory rows, batch cards, order admin cards, payout statements). Don't try to make them buyer-compatible.
- The buyer has its own `ProductCard` (shopper-facing). The seller's `ProductCard` (inventory-facing) is a different component. Same name conceptually, different implementation.

## Phases

Each phase = one feature branch, one PR (against `johnivanpuayap/unshelf-seller`), squash-merged. Each phase ends at a green state (`flutter analyze`, `flutter test`, `flutter build web --release` all pass).

### Phase 1 — Foundation + Auth Conformance

Branch: `redesign/1-foundation`

- Add `unshelf-brand-kit` as submodule at `brand-kit/`
- Copy `brand-kit/tokens/tokens.dart` to `lib/utils/tokens.dart`
- Rewrite `lib/utils/theme.dart` as `UnshelfTheme.light()` / `.dark()` driven by `UnshelfTokens` (mirror the buyer's pattern from `lib/theme/unshelf_theme.dart` — same approach, but seller-internal)
- Retire `lib/utils/colors.dart` (or convert to a deprecation shim if many callers exist)
- Copy 10 Abundance Basket logo SVGs from `brand-kit/docs/crucible/logos/` to `assets/images/logos/`. SVGs use inline fills (already fixed in buyer Group A; verify in brand kit).
- Wire DM Serif Display + DM Sans via existing `google_fonts: ^6.2.1`; call `UnshelfTheme.preloadFonts()` before `runApp`
- Refine `InputDecorationTheme` per the auth spec (16/16 padding, primary focus ring, error border)
- Conform the four auth screens to `brand-kit/docs/crucible/auth-screens.md`:
  - `login_view` (role check: `type == 'seller'`, route to `DashboardView`)
  - `register_view` (extra Store name field, `type: 'seller'`)
  - `forgot_password_view` + viewmodel (already feature-rich — adapt layout + copy)
  - `reset_password_view` (already has URL param routing — preserve; only update visuals)
- Update CLAUDE.md to reference shared specs (brand kit + auth-screens) and seller-specific locked decisions
- Open PR `redesign/1-foundation` → `main` at exit

**Exit criteria:** `flutter test` 8 tests pass, app boots with new theme, four auth screens visually match the buyer's auth flow.

### Phase 2 — Riverpod 4.x Migration

Branch: `redesign/2-riverpod`

22 viewmodels migrated in one focused sweep, one commit per viewmodel (per the buyer Phase 2 pattern):

- `dashboard_viewmodel`, `home_viewmodel`, `inventory_viewmodel`, `listing_viewmodel`, `batch_viewmodel`, `batch_history_viewmodel`, `bundle_viewmodel`, `order_viewmodel`, `restock_viewmodel`, `select_products_viewmodel`, `product_viewmodel`, `product_summary_viewmodel`, `product_analytics_viewmodel`, `analytics_viewmodel`, `store_viewmodel`, `store_profile_viewmodel`, `store_location_viewmodel`, `store_schedule_viewmodel`, `user_profile_viewmodel`, `wallet_viewmodel`, `notification_viewmodel`, `settings_viewmodel`

Pattern: each former `ChangeNotifier` becomes a `Notifier<TState>` with a typed state. Consumers swap `Consumer<T>` → `ConsumerWidget` + `ref.watch`. Side effects via `ref.read(provider.notifier).method()`.

After all 22:
- Remove `MultiProvider` from `main.dart`
- Remove `provider: ^6.1.2` from `pubspec.yaml`
- Port the 8 existing tests to Riverpod testing patterns (`ProviderContainer` + `overrideWith`)

**Exit criteria:** zero `ChangeNotifierProvider` references, `provider` not in pubspec, 8 ported tests pass, no new analyzer errors.

### Phase 3 — Service Interfaces + Repository Layer

Branch: `redesign/3-data-layer`

**Service interface polish:**
- Audit `lib/core/interfaces/` — confirm every service in `lib/services/` has a corresponding interface. Note: `permission_service.dart` exists without an interface — add `i_permission_service.dart` if it warrants one.
- Audit every call site — grep for `import 'services/.dart'` and replace direct service references with interface types where possible. Use `get_it` to resolve at the boundary; consumers depend on interfaces.

**New repositories layer:**
- Create `lib/data/repositories/` mirroring buyer's pattern (seller-internal, distinct implementations):
  - `auth_repository.dart` (+ `firebase/firebase_auth_repository.dart`)
  - `stores_repository.dart` (+ Firebase impl)
  - `orders_repository.dart` (+ Firebase impl)
  - `products_repository.dart` (+ Firebase impl)
  - `user_repository.dart` (+ Firebase impl)
  - `storage_repository.dart` (+ Firebase impl)
- Services delegate to repositories for data-access concerns. Business logic stays in services.
- Update interfaces if their method signatures change as a result (e.g., `IOrderService.getOrders()` might now call `OrdersRepository.watch()`).

**Exit criteria:** all services use interfaces consistently; new `lib/data/repositories/` layer in place; 8 tests still pass.

### Phase 4 — Screen Redesign (8 groups)

Each group = one branch + one PR. Quality Bar = the auth screens from Phase 1. Layouts stay seller-unique (admin/inventory feel, not marketplace) per the uniqueness rule.

**Group A — Dashboard + Home + Notifications**
- `dashboard_view`, `home_view`, `notifications_view`
- Seller-led admin dashboard (today's orders count, revenue snapshot, low-stock alerts, expiring batches)

**Group B — Inventory + Listings**
- `inventory_view`, `listings_view`, `add_product_view`, `edit_product_view`, `product_details_view`, `product_analytics_view`

**Group C — Batches + Bundles + Restock**
- `add_batch_view`, `edit_batch_view`, `batch_history_view`, `add_bundle_view`, `edit_bundle_view`, `bundle_details_view`, `restock_details_view`, `restock_selection_view`, `select_products_view`

**Group D — Orders + History**
- `orders_view`, `order_details_view`, `order_history_view`, `order_history_details_view`

**Group E — Store profile + Analytics + Location/Schedule**
- `store_view`, `store_analytics_view`, `edit_store_profile_view`, `edit_store_location_view`, `edit_store_schedule_view`

**Group F — Wallet + Withdrawals**
- `balance_overview_view`, `withdraw_request_view`

**Group G — Chats + Notifications + Reports**
- `chats_view`, `chat_screen` (component), `report_view`

**Group H — Settings + User Profile**
- `settings_view`, `edit_user_profile_view`

Per group: branch off updated `main` → redesign screens applying tokens + spacing + soft editorial → extract emergent 3+-use components → verify (analyze, test, build web) → open PR (against personal) → squash-merge → next group branches off fresh main.

### Phase 5 — Components Audit + README

Branch: `redesign/5-components`

- Audit `lib/components/` (existing 12 + anything extracted in Phase 4)
- Retheme any legacy widget with hardcoded values (`Color(0xFF...)`, `TextStyle(fontFamily:)`, `Colors.white`)
- Delete dead/unused widgets
- Promote any 3+-use pattern still inline
- Write `lib/components/README.md` listing every seller-internal component, with one-line purpose + props + use sites + example. Header must reference the uniqueness rule: these components are seller-specific; the buyer has its own catalog.

## Testing approach

- **Preservation:** the 8 existing test files (under `test/viewmodels/` and any `test/services/`) must remain green throughout. Port to Riverpod testing patterns in Phase 2 as part of each viewmodel's migration commit.
- **Bug fixes during the rebrand:** any bug found mid-flight gets a regression test before the fix.
- **New abstractions with non-obvious contracts:** if a repository (Phase 3) has non-trivial logic (e.g., a query with a defensive transformation), add a test. Most repositories will be thin pass-throughs to Firestore — no tests needed there.
- **Broad widget/integration test coverage** is NOT in scope. Deferred to a dedicated test-coverage sub-project.

## Acceptance criteria

The seller rebrand is done when:

1. ⬜ `brand-kit/` submodule installed and tracked
2. ⬜ `lib/utils/theme.dart` exposes `UnshelfTheme.light()` / `.dark()` driven by `UnshelfTokens`
3. ⬜ `lib/utils/colors.dart` retired (deleted or empty shim)
4. ⬜ `pubspec.yaml` no longer depends on `provider`; `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner` added
5. ⬜ App boots under `ProviderScope` with no runtime errors
6. ⬜ All 22 viewmodels are Riverpod providers; 8 existing tests pass on Riverpod patterns
7. ⬜ All four auth screens (login, register, forgot password, reset password) conform to `brand-kit/docs/crucible/auth-screens.md`, with seller-specific deltas only
8. ⬜ `lib/data/repositories/` layer exists with the 6 listed repositories + Firebase implementations
9. ⬜ Every service in `lib/services/` is accessed by call sites through its `lib/core/interfaces/` interface (not the concrete type)
10. ⬜ Every screen uses `Theme.of(context).colorScheme` / `textTheme` — grep for `Color(0xFF`, `TextStyle(fontFamily:`, `Colors.white` returns zero hits in `lib/views/`, `lib/authentication/`, `lib/components/` (shadow tokens excepted)
11. ⬜ Logo + app icon + splash use Abundance Basket SVGs
12. ⬜ Seller-led admin dashboard ships (orders / revenue / low-stock / expiring batches above the fold)
13. ⬜ `lib/components/README.md` catalogs all seller-internal components
14. ⬜ App runs end-to-end on Android emulator AND iOS simulator AND `flutter build web --release` (manual smoke test of: login → dashboard → inventory → product detail → batch → order → wallet → profile)
15. ⬜ All five phase branches merged into `main` via PR (5 PRs minimum, plus 8 PRs from Phase 4 groups = 13 PRs total)

## Constraints

- **Repo has TWO remotes:** `origin` → `Unshelf-SoftEng/Unshelf_Seller` (ORG, IGNORE), `personal` → `johnivanpuayap/unshelf-seller` (TARGET). ALL `gh` commands MUST include `--repo johnivanpuayap/unshelf-seller`. `gh repo set-default johnivanpuayap/unshelf-seller` is set. Git push targets `personal/main`, not `origin/main`.
- Brand-kit submodule is **private** (`johnivanpuayap/unshelf-brand-kit`). Cloning the seller requires SSH access to the brand kit too.
- Git identity for this repo: personal (`johnivanpuayap@gmail.com`) — already configured.
- No `Co-Authored-By` trailers in commits.
- Atomic commits with Conventional Commits prefixes.
- Push after every commit (per user push-frequently preference).
- One branch per phase / group. PR via `gh pr create --repo johnivanpuayap/unshelf-seller`. Merge via `gh pr merge <num> --repo johnivanpuayap/unshelf-seller --squash --delete-branch`.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Riverpod migration breaks the existing 8 tests | Port tests as part of each viewmodel commit. If a viewmodel's test can't be ported (deep coupling), file a follow-up issue and proceed with the rest. |
| Auth conformance breaks existing `reset_password_view` URL parameter routing | Read the existing implementation carefully before redesigning. Preserve the URL-param mechanism; only update visuals + copy. |
| Adding repositories duplicates logic with existing services | Refactor in pairs: when adding a repo, move data-access logic OUT of the service in the same commit. Services then thin out — that's the point. |
| Component duplication between buyer and seller | The uniqueness rule says they MUST be different. Build seller components for seller use cases. Resist the temptation to lift from buyer. |
| 30+ screens redesigned in 8 PRs is huge scope | Each group is independently shippable; if user wants to pause after a group, the app is still in a green state. Phase 4 can spread over multiple sessions. |
| Org remote `origin` accidentally receives a PR | `gh repo set-default johnivanpuayap/unshelf-seller` is set; all `gh` commands explicitly pass `--repo johnivanpuayap/unshelf-seller`; git push always targets `personal`, never `origin`. Memory rule `[[gh-default-repo-when-multiple-remotes]]` enforces. |

## Next steps

After approval:
1. Invoke `writing-plans` to generate the implementation plan — task-by-task across the 5 phases
2. Execute via subagent-driven development
3. After seller ships: move on to sub-projects 4 + 5 (landing pages) using Astro + Tailwind + brand kit submodule

## References

- Brand kit: `personal-projects/unshelf/docs/crucible/` (submodule at `brand-kit/`)
- Brand identity: `brand-kit/docs/crucible/brand.md`
- Visual identity: `brand-kit/docs/crucible/design.md`
- Visual preview: `brand-kit/docs/crucible/preview.html`
- **Auth design spec (shared):** `brand-kit/docs/crucible/auth-screens.md`
- Buyer rebrand spec: `personal-projects/unshelf-buyer/docs/crucible/specs/2026-05-16-buyer-rebrand-design.md`
- Buyer UI redesign spec: `personal-projects/unshelf-buyer/docs/crucible/specs/2026-05-16-buyer-ui-redesign.md`
- Buyer rebrand plan: `personal-projects/unshelf-buyer/docs/crucible/plans/2026-05-16-buyer-rebrand-implementation.md`
- Buyer redesign plan: `personal-projects/unshelf-buyer/docs/crucible/plans/2026-05-16-buyer-ui-redesign-implementation.md`
- Memory: `[[unshelf-rebrand]]`, `[[unshelf-buyer-seller-uniqueness]]`, `[[unshelf-copy-voice]]`, `[[gh-default-repo-when-multiple-remotes]]`, `[[always-commit-and-push-specs]]`
