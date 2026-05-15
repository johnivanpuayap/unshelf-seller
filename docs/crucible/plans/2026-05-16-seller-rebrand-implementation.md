# Seller Rebrand + Architecture Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the Unshelf brand kit to the seller app, conform auth screens to the shared auth design, migrate state management to Riverpod 4.x, polish service interfaces + add a repositories layer, redesign every screen to design-system quality with a seller-led admin dashboard, and ship a components catalog — all while preserving the seller's distinct visual identity from the buyer (uniqueness rule).

**Architecture:** Five phases, 13 PRs total (Phases 1/2/3/5 = 1 PR each, Phase 4 = 8 group PRs). Each phase ends green (analyze, test, build web). Brand inherited from `brand-kit/` submodule. Auth contract from `brand-kit/docs/crucible/auth-screens.md`. Seller-internal components stay distinct from buyer's catalog (uniqueness rule).

**Tech Stack:** Flutter 3.41 · Dart · Riverpod 4.x (`@riverpod` codegen, migrated from Provider) · `get_it: ^8.0.3` DI · flutter_map · flutter_svg · google_fonts · firebase_* (auth, firestore, storage) · google_sign_in · `lib/core/interfaces/` service interfaces · new `lib/data/repositories/` layer.

**Spec:** `docs/crucible/specs/2026-05-16-seller-rebrand-design.md`
**Auth contract (shared with buyer):** `brand-kit/docs/crucible/auth-screens.md`
**Brand reference:** `brand-kit/docs/crucible/design.md` · `brand-kit/docs/crucible/preview.html`
**Buyer redesign reference (for quality bar, NOT for layouts):** `personal-projects/unshelf-buyer/lib/authentication/views/login_view.dart` and `lib/components/`
**Uniqueness rule:** memory `[[unshelf-buyer-seller-uniqueness]]` — seller and buyer share brand tokens, logos, copy voice, soft editorial principles, and the auth flow. NOTHING else.

**Conventions:**
- Branch per phase / group. Phase 1-3 + 5: `redesign/<phase-num>-<short-name>`. Phase 4 groups: `redesign/4<letter>-<group-name>` (e.g., `redesign/4A-dashboard`).
- Atomic commits with Conventional Commits prefixes.
- **No `Co-Authored-By` trailers**
- Push after every commit (`git push personal <branch>` — note: `personal` is the personal remote; the seller repo's `origin` is the ORG and we never push there)
- One PR per phase/group via `gh pr create --repo johnivanpuayap/unshelf-seller`
- Merge via `gh pr merge <num> --repo johnivanpuayap/unshelf-seller --squash --delete-branch`
- Git identity already: `johnivanpuayap@gmail.com`
- After each PR merge, next phase branches from fresh `main`
- **ALL `gh` commands MUST include `--repo johnivanpuayap/unshelf-seller`** (the repo has an `origin` remote pointing to the ORG — never let gh auto-pick). `gh repo set-default johnivanpuayap/unshelf-seller` is already set.

---

## File Structure

```
personal-projects/unshelf-seller/
├── .gitmodules                                   [Phase 1 — brand-kit submodule]
├── brand-kit/                                    [Phase 1 — submodule]
├── CLAUDE.md                                     [Phase 1 — update]
├── assets/images/logos/                          [Phase 1 — 10 SVGs from brand-kit]
├── lib/
│   ├── utils/
│   │   ├── tokens.dart                           [Phase 1 — NEW: mirror brand-kit tokens]
│   │   ├── theme.dart                            [Phase 1 — rewrite as UnshelfTheme]
│   │   └── colors.dart                           [Phase 1 — retire or shim]
│   ├── authentication/views/
│   │   ├── login_view.dart                       [Phase 1 — rebuild per auth-screens.md]
│   │   ├── register_view.dart                    [Phase 1 — rebuild + Store name field]
│   │   ├── forgot_password_view.dart             [Phase 1 — rebuild visuals]
│   │   ├── forgot_password_viewmodel.dart        [Phase 2 — Riverpod migrate]
│   │   └── reset_password_view.dart              [Phase 1 — rebuild visuals + preserve URL routing]
│   ├── viewmodels/                               [Phase 2 — migrate all 22 to @riverpod]
│   ├── core/
│   │   ├── interfaces/                           [Phase 3 — audit + polish]
│   │   └── service_locator.dart                  [Phase 3 — register new repos]
│   ├── services/                                 [Phase 3 — delegate to repositories]
│   ├── data/repositories/                        [Phase 3 — NEW directory]
│   │   ├── auth_repository.dart                  [Phase 3 — NEW interface]
│   │   ├── stores_repository.dart                [Phase 3 — NEW]
│   │   ├── orders_repository.dart                [Phase 3 — NEW]
│   │   ├── products_repository.dart              [Phase 3 — NEW]
│   │   ├── user_repository.dart                  [Phase 3 — NEW]
│   │   ├── storage_repository.dart               [Phase 3 — NEW]
│   │   └── firebase/                             [Phase 3 — Firebase impls]
│   ├── components/                               [Phase 4 emergent + Phase 5 audit]
│   │   └── README.md                             [Phase 5 — NEW: seller-internal catalog]
│   └── views/                                    [Phase 4 — 8 redesign groups]
└── docs/crucible/
    ├── specs/2026-05-16-seller-rebrand-design.md [exists]
    └── plans/2026-05-16-seller-rebrand-implementation.md  [this file]
```

---

## Quality Bar (referenced by every phase)

Same rules as the buyer redesign:

- **Layout:** content centered (`maxWidth: 420` on auth/utility screens; full-width with 24px horizontal padding on admin/data screens). `SafeArea`, `SingleChildScrollView` where appropriate. AppBar present only when there's a back action or contextual nav.
- **Typography:** `Theme.of(context).textTheme.*` only. NEVER `TextStyle(fontFamily: ...)` in screen code.
- **Spacing:** 4/8/16/20/24/32/48 scale only.
- **Cards:** `colorScheme.surfaceContainerHighest` fill, 14px radius, two-layer shadow:
  ```dart
  boxShadow: [
    BoxShadow(color: Colors.black.withValues(alpha: .02), offset: Offset(0, 1), blurRadius: 0),
    BoxShadow(color: Color(0xFF1F2A20).withValues(alpha: .06), offset: Offset(0, 8), blurRadius: 28),
  ],
  ```
- **Buttons:** primary = full-width 52px pill `ElevatedButton`; secondary = `OutlinedButton` or `TextButton`.
- **Empty/loading/error states:** every list-like view has all three.
- **CTA copy:** plain transactional verbs. NEVER "Rescue", "Save", "Snag", "Grab".
- **No glassmorphism, no `Colors.white`, no `Color(0xFF...)` in screen code, no `TextStyle(fontFamily:)` in screen code.**

---

## Phase 1 — Foundation + Auth Conformance

Branch: `redesign/1-foundation`

Sets up the brand kit consumption, theme, logo assets, and conforms the four auth screens to the shared spec. **Sets the quality bar for all later phases.**

### Task 1.1: Branch + add brand-kit submodule

```bash
cd "C:/Users/John Ivan/personal-projects/unshelf-seller"
git checkout main
git pull --rebase personal main
git checkout -b redesign/1-foundation
git push -u personal redesign/1-foundation
```

```bash
git submodule add git@github.com:johnivanpuayap/unshelf-brand-kit.git brand-kit
git add .gitmodules brand-kit
git commit -m "chore: add unshelf-brand-kit as submodule"
git push personal redesign/1-foundation
```

**Verify:**
```bash
ls brand-kit/tokens/ brand-kit/docs/crucible/logos/ | head -10
```
Expected: shows `tokens.dart`, `tokens.css`, `tailwind.preset.js`, and 10 SVG logo files.

### Task 1.2: Mirror brand-kit tokens into `lib/utils/tokens.dart`

```bash
cp brand-kit/tokens/tokens.dart lib/utils/tokens.dart
```

Edit `lib/utils/tokens.dart` and replace the second comment line. Current:
```dart
// Source: tokens.json. Regenerate via `npm run build`.
```
Replace with:
```dart
// Source: brand-kit/tokens/tokens.dart (submodule). Refresh: `cp brand-kit/tokens/tokens.dart lib/utils/tokens.dart` after the brand-kit's `npm run build`.
```

```bash
git add lib/utils/tokens.dart
git commit -m "feat(theme): mirror brand-kit tokens into lib/utils/tokens.dart"
git push personal redesign/1-foundation
```

### Task 1.3: Rewrite `lib/utils/theme.dart` as `UnshelfTheme`

Replace the entire contents of `lib/utils/theme.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

abstract class UnshelfTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: UnshelfTokens.colorLightPrimary,
      onPrimary: UnshelfTokens.colorLightOnPrimary,
      secondary: UnshelfTokens.colorLightAccent,
      onSecondary: UnshelfTokens.colorLightForeground,
      tertiary: UnshelfTokens.colorLightHighlight,
      error: UnshelfTokens.colorLightDestructive,
      onError: UnshelfTokens.colorLightOnPrimary,
      surface: UnshelfTokens.colorLightBackground,
      onSurface: UnshelfTokens.colorLightForeground,
      surfaceContainerHighest: UnshelfTokens.colorLightSurface,
      outline: UnshelfTokens.colorLightBorder,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UnshelfTokens.colorLightBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: UnshelfTokens.colorDarkPrimary,
      onPrimary: UnshelfTokens.colorDarkOnPrimary,
      secondary: UnshelfTokens.colorDarkAccent,
      onSecondary: UnshelfTokens.colorDarkForeground,
      tertiary: UnshelfTokens.colorDarkHighlight,
      error: UnshelfTokens.colorDarkDestructive,
      onError: UnshelfTokens.colorDarkOnPrimary,
      surface: UnshelfTokens.colorDarkBackground,
      onSurface: UnshelfTokens.colorDarkForeground,
      surfaceContainerHighest: UnshelfTokens.colorDarkSurface,
      outline: UnshelfTokens.colorDarkBorder,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UnshelfTokens.colorDarkBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
    );
  }

  static void preloadFonts() {
    GoogleFonts.dmSerifDisplay();
    GoogleFonts.dmSans();
  }

  static TextTheme _textTheme(Color onSurface) {
    TextStyle serif({double? fontSize, FontWeight fontWeight = FontWeight.w400, double? height}) =>
        TextStyle(fontFamily: 'DM Serif Display', color: onSurface, fontSize: fontSize, fontWeight: fontWeight, height: height);
    TextStyle sans({double? fontSize, FontWeight fontWeight = FontWeight.w400, double? height}) =>
        TextStyle(fontFamily: 'DM Sans', color: onSurface, fontSize: fontSize, fontWeight: fontWeight, height: height);
    return TextTheme(
      displayLarge: serif(fontSize: 57, height: 1.12),
      displayMedium: serif(fontSize: 45, height: 1.16),
      displaySmall: serif(fontSize: 36, height: 1.22),
      headlineLarge: serif(fontSize: 32, height: 1.25),
      headlineMedium: serif(fontSize: 28, height: 1.29),
      headlineSmall: serif(fontSize: 24, height: 1.33),
      titleLarge: serif(fontSize: 22, height: 1.27),
      titleMedium: sans(fontSize: 16, fontWeight: FontWeight.w600, height: 1.50),
      titleSmall: sans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
      bodyLarge: sans(fontSize: 16, height: 1.50),
      bodyMedium: sans(fontSize: 14, height: 1.43),
      bodySmall: sans(fontSize: 12, height: 1.33),
      labelLarge: sans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
      labelMedium: sans(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33),
      labelSmall: sans(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme cs) => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const StadiumBorder(),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme(ColorScheme cs) => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const StadiumBorder(),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const StadiumBorder(),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) => InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.45), fontFamily: 'DM Sans', fontWeight: FontWeight.w400),
        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.75), fontFamily: 'DM Sans', fontWeight: FontWeight.w500),
        floatingLabelStyle: TextStyle(color: cs.primary, fontFamily: 'DM Sans', fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.6), width: 1.2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.6), width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.error.withValues(alpha: 0.7), width: 1.4)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.error, width: 2)),
      );

  static CardThemeData _cardTheme(ColorScheme cs) => CardThemeData(
        color: cs.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}
```

Verify + commit:
```bash
flutter analyze lib/utils/theme.dart 2>&1 | tail -3
flutter test 2>&1 | tail -3
git add lib/utils/theme.dart
git commit -m "feat(theme): add UnshelfTheme.light()/.dark() driven by brand tokens"
git push personal redesign/1-foundation
```

### Task 1.4: Wire UnshelfTheme into MaterialApp

Read current `lib/main.dart` to find `MaterialApp`. Update its `theme:` / `darkTheme:` to use the new UnshelfTheme. Add `UnshelfTheme.preloadFonts()` before `runApp`. Add the import `import 'package:unshelf_seller/utils/theme.dart';` if not already present.

Find the existing `MaterialApp(...)` block and ensure these properties appear:
```dart
theme: UnshelfTheme.light(),
darkTheme: UnshelfTheme.dark(),
themeMode: ThemeMode.system,
```

Find the `void main()` `runApp` call. Right BEFORE `runApp`, add:
```dart
UnshelfTheme.preloadFonts();
```

Verify + commit:
```bash
flutter analyze 2>&1 | tail -5
flutter test 2>&1 | tail -3
git add lib/main.dart
git commit -m "feat(theme): wire UnshelfTheme into MaterialApp"
git push personal redesign/1-foundation
```

### Task 1.5: Copy logo assets + add to pubspec

```bash
mkdir -p assets/images/logos
cp brand-kit/docs/crucible/logos/*.svg assets/images/logos/
ls assets/images/logos/
```
Expected: 10 SVG files.

Open `pubspec.yaml`, find the `flutter:` block, ensure the `assets:` list includes `- assets/images/logos/` (trailing slash to include the directory). If `assets:` doesn't exist, add it:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/logos/
```
Preserve any existing asset entries.

Add `flutter_svg` to pubspec if not present (check first):
```bash
grep "flutter_svg" pubspec.yaml
```
If absent, add under `dependencies:`:
```yaml
  flutter_svg: ^2.0.10
```

```bash
flutter pub get
git add assets/images/logos/ pubspec.yaml pubspec.lock
git commit -m "feat(assets): add Abundance Basket logo + favicon SVGs from brand kit"
git push personal redesign/1-foundation
```

### Task 1.6: Retire `lib/utils/colors.dart`

Check how many files import `AppColors`:
```bash
grep -rn "AppColors\." lib/ test/ | wc -l
```

**If 0:** delete the file:
```bash
git rm lib/utils/colors.dart
git commit -m "chore: remove AppColors — replaced by UnshelfTheme tokens"
```

**If 1-5:** delete + fix the callers in the same commit. For each caller, replace `AppColors.X` with the closest `Theme.of(context).colorScheme.*` token (typically `primary`, `secondary`, `surface`, `onSurface`, `outline`).

**If 6+:** leave `lib/utils/colors.dart` as-is for now. Phase 4's screen redesigns will eliminate callers naturally; final removal happens in Phase 5.

Commit the chosen action with an appropriate message. Push.

### Task 1.7: Rebuild `lib/authentication/views/login_view.dart`

Read the current file FIRST to understand its existing integration with `IAuthService` / `IUserProfileService` (via `service_locator.dart`) and Google Sign-In. **Preserve those integration patterns** (the seller already uses interface-driven service lookup — that's good architecture, don't undo it). Only rewrite the visual layout + copy to conform to `brand-kit/docs/crucible/auth-screens.md`.

Replacement template — the subagent must wire the existing AuthService/UserProfileService calls (don't change auth logic, only the visual structure). The role check is `type == 'seller'`. After-login route is `HomeView` (which is the seller's dashboard route; do not rename).

Use this layout shell as the new structure (preserve existing handler bodies that call AuthService, IUserProfileService, GoogleSignIn — only replace the layout):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// ... preserve other existing imports for AuthService, UserProfileService, GoogleSignIn, etc.

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _submitting = false;

  // PRESERVE existing _login() / _googleSignIn() handler bodies from the old file.
  // Just wrap them with: if (!_formKey.currentState!.validate() || _submitting) return;
  // setState(() => _submitting = true); ... try ... finally setState(() => _submitting = false);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(child: SvgPicture.asset('assets/images/logos/logo-icon.svg', height: 112, semanticsLabel: 'Unshelf')),
                    const SizedBox(height: 24),
                    Text('Welcome back', style: tt.headlineMedium?.copyWith(color: cs.onSurface), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Eat well. Waste less.', style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.65), fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                    const SizedBox(height: 40),
                    _FieldLabel('Email', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'you@example.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Password', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: 'Your password',
                        suffixIcon: IconButton(
                          icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: cs.onSurface.withValues(alpha: 0.55)),
                          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordView())),
                        child: Text('Forgot password?', style: tt.labelLarge?.copyWith(color: cs.primary)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _login,
                        child: _submitting
                            ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.onPrimary))
                            : Text('Sign in', style: tt.labelLarge?.copyWith(color: cs.onPrimary)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Preserve existing "Sign in with Google" button if present.
                    // Style as OutlinedButton with Google icon. Wire to existing _googleSignIn().
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New here?', style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.7))),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RegisterView())),
                          child: Text('Create a seller account', style: tt.labelLarge?.copyWith(color: cs.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600, letterSpacing: 0.3));
}
```

**Seller deltas vs the auth-screens.md spec:**
- Role check: `type == 'seller'` (not `'buyer'`). Reject with snack: `"User has a different role"`.
- After successful login: `Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeView()))`.
- Register link text: `"Create a seller account"` (vs `"Create an account"`).

Verify + commit:
```bash
flutter analyze lib/authentication/views/login_view.dart 2>&1 | tail -3
flutter test 2>&1 | tail -3
git add lib/authentication/views/login_view.dart
git commit -m "feat(auth): rebuild login view per shared auth-screens spec (seller deltas)"
git push personal redesign/1-foundation
```

### Task 1.8: Rebuild `lib/authentication/views/register_view.dart`

Same approach as Task 1.7. Read the existing register view first. Preserve its existing handlers (`_register` calling AuthService + UserProfileService to create user + write user doc). Replace visuals.

**Seller deltas vs the auth-screens.md spec:**
- Extra field: **Store name** (between Email and Phone), `TextFormField` with `_FieldLabel('Store name', ...)`, validator: non-empty.
- User doc write sets `type: 'seller'`, NOT `'buyer'`.
- Pass the store name to whatever existing user-profile service call writes the doc — preserve existing arg shape OR extend it to include `storeName`.
- Subtitle copy: `"Turn your unsold stock into revenue."` (vs buyer's `"Start rescuing near-expiry food near you."`).
- After-register: navigate to `LoginView` (pushReplacement), same as buyer.

Use the structure from Task 1.7's login template, adapted: add `_storeNameController`, add the Store name field block, set `type: 'seller'` in the existing _register handler's user-doc write.

Verify + commit:
```bash
flutter analyze lib/authentication/views/register_view.dart 2>&1 | tail -3
flutter test 2>&1 | tail -3
git add lib/authentication/views/register_view.dart
git commit -m "feat(auth): rebuild register view per shared auth-screens spec (seller deltas + Store name field)"
git push personal redesign/1-foundation
```

### Task 1.9: Rebuild `lib/authentication/views/forgot_password_view.dart`

Read the existing file. Note any integration with `forgot_password_viewmodel.dart`. Preserve the viewmodel integration; just rebuild visuals.

Layout per `auth-screens.md`:
- SafeArea + Center + SingleChildScrollView + maxWidth 420 + Form
- logo-icon at 88px height
- Headline: "Reset your password"
- Subtitle: "Enter your email and we'll send you a reset link."
- Email field (with _FieldLabel, hint "you@example.com", validation)
- Primary 52px pill CTA: "Send reset link"
- Loading spinner during submit
- Bottom row: "Remember your password? · Sign in" (Sign in goes to LoginView with pushReplacement)
- On success → navigate to ResetEmailSentView (NEW — Task 1.10) with the email param
- On user-not-found: ALSO navigate to ResetEmailSentView (don't leak account existence — per the auth spec security note)

Verify + commit:
```bash
flutter analyze lib/authentication/views/forgot_password_view.dart 2>&1 | tail -3
git add lib/authentication/views/forgot_password_view.dart
git commit -m "feat(auth): rebuild forgot password view per shared spec"
git push personal redesign/1-foundation
```

### Task 1.10: Create `lib/authentication/views/reset_email_sent_view.dart`

NEW file. Confirmation screen shown after `forgot_password_view` submits successfully. Identical content + behavior to the buyer's spec — copy text and 60-second resend cooldown.

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_seller/authentication/views/login_view.dart';

class ResetEmailSentView extends StatefulWidget {
  const ResetEmailSentView({super.key, required this.email});
  final String email;
  @override
  State<ResetEmailSentView> createState() => _ResetEmailSentViewState();
}

class _ResetEmailSentViewState extends State<ResetEmailSentView> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      _snack('Reset link sent.');
      _startCooldown();
    } catch (_) {
      _snack('Could not resend. Try again in a moment.');
    }
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _cooldownSeconds -= 1);
      if (_cooldownSeconds <= 0) t.cancel();
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(child: Icon(Icons.mark_email_read_outlined, size: 72, color: cs.primary)),
                  const SizedBox(height: 24),
                  Text('Check your email', style: tt.headlineMedium?.copyWith(color: cs.onSurface), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.65)),
                      children: [
                        const TextSpan(text: 'We sent a password reset link to '),
                        TextSpan(text: widget.email, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.85))),
                        const TextSpan(text: '. Tap the link to set a new password.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginView())),
                      child: Text('Back to sign in', style: tt.labelLarge?.copyWith(color: cs.primary)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Didn't get it? Check spam, or", style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
                      TextButton(
                        onPressed: _cooldownSeconds > 0 ? null : _resend,
                        child: Text(
                          _cooldownSeconds > 0 ? 'resend (${_cooldownSeconds}s)' : 'resend',
                          style: tt.labelLarge?.copyWith(color: _cooldownSeconds > 0 ? cs.onSurface.withValues(alpha: 0.4) : cs.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Verify + commit:
```bash
flutter analyze lib/authentication/views/reset_email_sent_view.dart 2>&1 | tail -3
git add lib/authentication/views/reset_email_sent_view.dart
git commit -m "feat(auth): add reset-email-sent confirmation screen"
git push personal redesign/1-foundation
```

### Task 1.11: Redesign `lib/authentication/views/reset_password_view.dart`

**IMPORTANT:** the existing `reset_password_view.dart` has URL parameter routing for branded password-reset emails. PRESERVE that mechanism. Only update visuals + copy.

Read the file first. Identify how URL params are read (likely from route arguments or from the URL via `dart:html`/`url_strategy`). Preserve that read logic exactly.

Layout: SafeArea + Center + SingleChildScrollView + maxWidth 420 + Form
- logo-icon at 88px
- Headline: "Choose a new password"
- Subtitle: "Use at least 6 characters."
- Two password fields (`_FieldLabel`, password + confirm, both with show/hide toggles, validator: 6+ chars, must match)
- Primary 52px pill CTA: "Set new password"
- On success: snackbar "Password updated" + navigate to LoginView (pushReplacement)

Preserve existing handler that calls `FirebaseAuth.confirmPasswordReset(code: ..., newPassword: ...)` with the URL-param-supplied code.

Verify + commit:
```bash
flutter analyze lib/authentication/views/reset_password_view.dart 2>&1 | tail -3
git add lib/authentication/views/reset_password_view.dart
git commit -m "feat(auth): redesign reset password view (preserves URL parameter routing)"
git push personal redesign/1-foundation
```

### Task 1.12: Update CLAUDE.md

Append to the existing `CLAUDE.md` a new section under "Project Rules -- Unshelf Seller":

```markdown
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
```

Commit:
```bash
git add CLAUDE.md
git commit -m "docs: extend CLAUDE.md with rebrand sub-project pointers + locked decisions"
git push personal redesign/1-foundation
```

### Task 1.13: Verify Phase 1 + open PR + merge

```bash
flutter analyze 2>&1 | tail -8
flutter test 2>&1 | tail -3
flutter build web --release 2>&1 | tail -3
```

Expected: no new analyzer errors (existing pre-existing infos OK), 8 tests pass (the seller's existing test count), build green.

Open PR:
```bash
gh pr create --repo johnivanpuayap/unshelf-seller --base main --head redesign/1-foundation \
  --title "Redesign Phase 1: Foundation + auth conformance" \
  --body "Implements Phase 1 of the seller rebrand spec. Brand-kit submodule, UnshelfTheme, logo assets, auth conformance (all 4 auth screens to brand-kit/docs/crucible/auth-screens.md with seller deltas), reset_email_sent_view (new). Preserves existing IAuthService / IUserProfileService integration. Preserves reset_password_view URL parameter routing."
```

Capture PR URL. Merge:
```bash
PR=$(gh pr list --repo johnivanpuayap/unshelf-seller --head redesign/1-foundation --json number --jq '.[0].number')
gh pr merge --repo johnivanpuayap/unshelf-seller $PR --squash --delete-branch
git checkout main && git pull --rebase personal main
```

---

## Phase 2 — Riverpod 4.x Migration

Branch: `redesign/2-riverpod`

Same pattern as the buyer's Phase 2. Migrate all 22 seller viewmodels from `ChangeNotifier + provider` to `@riverpod` codegen, preserving the existing 8 tests.

### Task 2.1: Branch + add Riverpod deps

```bash
cd "C:/Users/John Ivan/personal-projects/unshelf-seller"
git checkout main && git pull --rebase personal main
git checkout -b redesign/2-riverpod
git push -u personal redesign/2-riverpod
```

In `pubspec.yaml`, under `dependencies:` add:
```yaml
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
```

Under `dev_dependencies:`:
```yaml
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.11
  custom_lint: ^0.7.3
  riverpod_lint: ^2.3.10
```

```bash
flutter pub get
```

If pub get reports a `custom_lint` / `analyzer` conflict (the same issue we hit on buyer Phase 2), bump to Riverpod 3.x/4.x range:
```yaml
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^4.0.0
  riverpod_generator: ^4.0.0
```
and drop `custom_lint` + `riverpod_lint` for now.

In `lib/main.dart`, add the import:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
```
The `hide ChangeNotifierProvider` is required while `provider` is still in pubspec — they both export a class named `ChangeNotifierProvider`. The hide will be removed in Task 2.24.

Wrap the existing `runApp(MultiProvider(...))` call in `ProviderScope`:
```dart
runApp(
  ProviderScope(
    child: MultiProvider(
      providers: [ ... unchanged ... ],
      child: const MyApp(),
    ),
  ),
);
```

Verify:
```bash
flutter analyze 2>&1 | tail -3
flutter test 2>&1 | tail -3
```

Commit:
```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "chore(deps): add flutter_riverpod + codegen; wrap runApp in ProviderScope"
git push personal redesign/2-riverpod
```

### Riverpod Migration Pattern (referenced by all viewmodel tasks)

Apply this pattern to each viewmodel in tasks 2.2 through 2.23. The pattern is identical to the buyer's Phase 2 migration. Each viewmodel is one commit.

**Before (ChangeNotifier):**
```dart
class FooViewModel extends ChangeNotifier {
  FooState _state = FooState.idle();
  FooState get state => _state;

  Future<void> loadFoo() async {
    _state = FooState.loading();
    notifyListeners();
    try {
      final data = await locator<IFooService>().fetch();
      _state = FooState.success(data);
    } catch (e) {
      _state = FooState.error(e.toString());
    }
    notifyListeners();
  }
}
```

**After (`@riverpod` codegen):**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'foo_viewmodel.g.dart';

@riverpod
class FooViewModel extends _$FooViewModel {
  @override
  FooState build() => const FooState.idle();

  Future<void> loadFoo() async {
    state = const FooState.loading();
    try {
      final data = await ref.read(fooServiceProvider).fetch();
      state = FooState.success(data);
    } catch (e) {
      state = FooState.error(e.toString());
    }
  }
}
```

**Service access:** the seller currently uses `get_it`'s `locator<IFooService>()`. For Riverpod, prefer wrapping each service in a small provider:
```dart
@riverpod
IFooService fooService(FooServiceRef ref) => GetIt.instance<IFooService>();
```
This bridges get_it → Riverpod without rewriting service registration. After Phase 3 (repositories), services may move to direct Riverpod providers, but Phase 2 keeps the bridge.

**Consumer migration in views:** `Consumer<FooViewModel>` → `Consumer(builder: (ctx, ref, _) => ...)` OR convert the parent widget to `ConsumerWidget` / `ConsumerStatefulWidget`. Read state via `ref.watch(fooViewModelProvider)`. Trigger actions via `ref.read(fooViewModelProvider.notifier).loadFoo()`.

**Test migration:**
```dart
test('loadFoo populates success', () async {
  final fakeService = FakeFooService();
  final container = ProviderContainer(overrides: [
    fooServiceProvider.overrideWithValue(fakeService),
  ]);
  addTearDown(container.dispose);

  await container.read(fooViewModelProvider.notifier).loadFoo();

  expect(container.read(fooViewModelProvider), isA<FooStateSuccess>());
});
```

**Codegen step:** after each viewmodel migration, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Commit both the hand-edited file AND the generated `*.g.dart`.

**Commit message format:** `refactor(<base-name>): migrate ViewModel from Provider to Riverpod` (e.g., `refactor(wallet): ...`, `refactor(dashboard): ...`).

### Tasks 2.2 through 2.23: Migrate each viewmodel

For each, read the current file, apply the migration pattern, run codegen, port the test if present, run all tests, commit, push.

| Task | Viewmodel | Provider name | Has test? |
|---|---|---|---|
| 2.2 | `dashboard_viewmodel.dart` | `dashboardViewModelProvider` | yes |
| 2.3 | `home_viewmodel.dart` | `homeViewModelProvider` | maybe |
| 2.4 | `inventory_viewmodel.dart` | `inventoryViewModelProvider` | yes |
| 2.5 | `wallet_viewmodel.dart` | `walletViewModelProvider` | yes |
| 2.6 | `order_viewmodel.dart` | `orderViewModelProvider` | yes |
| 2.7 | `batch_viewmodel.dart` | `batchViewModelProvider` | maybe |
| 2.8 | `batch_history_viewmodel.dart` | `batchHistoryViewModelProvider` | maybe |
| 2.9 | `bundle_viewmodel.dart` | `bundleViewModelProvider` | maybe |
| 2.10 | `listing_viewmodel.dart` | `listingViewModelProvider` | maybe |
| 2.11 | `product_viewmodel.dart` | `productViewModelProvider` | maybe |
| 2.12 | `product_summary_viewmodel.dart` | `productSummaryViewModelProvider` | maybe |
| 2.13 | `product_analytics_viewmodel.dart` | `productAnalyticsViewModelProvider` | maybe |
| 2.14 | `analytics_viewmodel.dart` | `analyticsViewModelProvider` | maybe |
| 2.15 | `restock_viewmodel.dart` | `restockViewModelProvider` | maybe |
| 2.16 | `select_products_viewmodel.dart` | `selectProductsViewModelProvider` | maybe |
| 2.17 | `store_viewmodel.dart` | `storeViewModelProvider` | maybe |
| 2.18 | `store_profile_viewmodel.dart` | `storeProfileViewModelProvider` | maybe |
| 2.19 | `store_location_viewmodel.dart` | `storeLocationViewModelProvider` | maybe |
| 2.20 | `store_schedule_viewmodel.dart` | `storeScheduleViewModelProvider` | maybe |
| 2.21 | `user_profile_viewmodel.dart` | `userProfileViewModelProvider` | maybe |
| 2.22 | `notification_viewmodel.dart` | `notificationViewModelProvider` | maybe |
| 2.23 | `settings_viewmodel.dart` | `settingsViewModelProvider` | maybe |

Plus the auth viewmodel:
- 2.23.5 | `forgot_password_viewmodel.dart` (in `lib/authentication/`) | `forgotPasswordViewModelProvider` | maybe

For each: identify which tests in `test/viewmodels/` apply (run `ls test/viewmodels/`). Port test if present.

Common gotchas (same as buyer Phase 2):
- `BaseViewModel` superclass — the seller's viewmodels extend a `BaseViewModel` from `lib/core/`. Riverpod's `Notifier<TState>` replaces this. Drop the BaseViewModel reference per viewmodel as it's migrated.
- `runBusyFuture` helper — the BaseViewModel pattern. Replace with explicit `state = State.loading(); try { ... } catch (e) { state = State.error(...); }`.
- Parameterized constructors (e.g., `StoreViewModel(storeId)`): use Riverpod's `@riverpod` with positional args → generates a family provider.

### Task 2.24: Remove `provider` package

After all 22 viewmodels migrated, verify zero usage:
```bash
grep -rn "ChangeNotifierProvider\|Provider.of\|MultiProvider\|extends ChangeNotifier" lib/ test/
```
Expected: zero hits (the `chat_service.dart` may still extend `ChangeNotifier` from `flutter/foundation` — that's fine, it's NOT from the provider package).

In `lib/main.dart`, replace:
```dart
runApp(
  ProviderScope(
    child: MultiProvider(providers: [...], child: const MyApp()),
  ),
);
```
with:
```dart
runApp(
  const ProviderScope(child: MyApp()),
);
```

Remove the `hide ChangeNotifierProvider` directive on the `flutter_riverpod` import; remove `import 'package:provider/provider.dart';` from `main.dart` and any other lingering files.

Delete `lib/core/base_viewmodel.dart` if it exists and is no longer used (`grep -rn "BaseViewModel" lib/`).

In `pubspec.yaml`, delete the `provider: ^6.1.2` line.

```bash
flutter pub get
flutter analyze 2>&1 | tail -3
flutter test 2>&1 | tail -3
```
Expected: no new errors. Tests pass (8 ported or remaining).

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "chore(deps): remove provider package; ProviderScope is the root state container"
git push personal redesign/2-riverpod
```

### Task 2.25: Phase 2 PR + merge

```bash
flutter build web --release 2>&1 | tail -3
```
Expected: build green.

```bash
gh pr create --repo johnivanpuayap/unshelf-seller --base main --head redesign/2-riverpod \
  --title "Redesign Phase 2: Riverpod 4.x migration (22 viewmodels + provider removed)" \
  --body "Implements Phase 2 of the seller rebrand spec. All 22 viewmodels migrated to @riverpod codegen. provider package removed. 8 existing tests ported to ProviderContainer + overrideWith. BaseViewModel retired."

PR=$(gh pr list --repo johnivanpuayap/unshelf-seller --head redesign/2-riverpod --json number --jq '.[0].number')
gh pr merge --repo johnivanpuayap/unshelf-seller $PR --squash --delete-branch
git checkout main && git pull --rebase personal main
```

---

## Phase 3 — Service Interfaces + Repository Layer

Branch: `redesign/3-data-layer`

### Task 3.1: Branch + audit

```bash
cd "C:/Users/John Ivan/personal-projects/unshelf-seller"
git checkout main && git pull --rebase personal main
git checkout -b redesign/3-data-layer
git push -u personal redesign/3-data-layer
```

Audit `lib/core/interfaces/` vs `lib/services/`:
```bash
ls lib/core/interfaces/
ls lib/services/
```

For each service that does NOT have a corresponding interface (e.g., `permission_service.dart` currently lacks `i_permission_service.dart`), decide if it warrants one. Services that wrap a single platform call (e.g., permission_handler) probably don't need one. Document the decision in a comment in the file.

Grep for call sites that bypass interfaces:
```bash
grep -rn "import.*services/\([a-z_]*\)_service\.dart" lib/viewmodels/ lib/views/ lib/components/
```
Expected: most viewmodels should use `locator<IFooService>()` or `ref.read(fooServiceProvider)`. Files that import the concrete should be fixed to use the interface.

Commit any interface additions as a single tidy-up:
```bash
git add lib/core/interfaces/ lib/services/ lib/<other-paths>
git commit -m "refactor: audit service interfaces; add missing interface stubs"
git push personal redesign/3-data-layer
```

### Task 3.2: Define repository interfaces

Create `lib/data/repositories/` directory. For each repository, define an abstract interface:

**`lib/data/repositories/auth_repository.dart`:**
```dart
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserCredential> signInWithEmail({required String email, required String password});
  Future<UserCredential> createUserWithEmail({required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> confirmPasswordReset({required String code, required String newPassword});
  Future<void> signOut();
  Stream<User?> authStateChanges();
  User? get currentUser;
}
```

**`lib/data/repositories/stores_repository.dart`:**
```dart
import 'package:unshelf_seller/models/store_model.dart';

abstract class StoresRepository {
  Future<StoreModel?> getStore(String storeId);
  Stream<StoreModel?> watchStore(String storeId);
  Future<void> upsertStore(StoreModel store);
  Future<void> updateStoreLocation(String storeId, double lat, double lng);
}
```

**`lib/data/repositories/orders_repository.dart`:**
```dart
import 'package:unshelf_seller/models/order_model.dart';

abstract class OrdersRepository {
  Stream<List<OrderModel>> watchOrders(String storeId);
  Future<OrderModel?> getOrder(String orderId);
  Future<void> updateOrderStatus(String orderId, String status);
}
```

**`lib/data/repositories/products_repository.dart`:**
```dart
import 'package:unshelf_seller/models/product_model.dart';

abstract class ProductsRepository {
  Stream<List<ProductModel>> watchProductsByStore(String storeId);
  Future<ProductModel?> getProduct(String productId);
  Future<String> createProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
}
```

**`lib/data/repositories/user_repository.dart`:**
```dart
import 'package:unshelf_seller/models/user_model.dart';

abstract class UserRepository {
  Future<UserModel?> getUser(String userId);
  Stream<UserModel?> watchUser(String userId);
  Future<void> upsertUser(UserModel user);
  Future<int> fetchFollowersCount(String userId);
}
```

**`lib/data/repositories/storage_repository.dart`:**
```dart
import 'dart:typed_data';

abstract class StorageRepository {
  Future<String> uploadFile(String path, String localFilePath);
  Future<String> uploadBytes(String path, Uint8List bytes);
  Future<void> deleteFile(String path);
}
```

Commit:
```bash
git add lib/data/repositories/*.dart
git commit -m "feat(data): define repository interfaces (auth, stores, orders, products, user, storage)"
git push personal redesign/3-data-layer
```

### Task 3.3: Implement Firebase-backed repositories

Create `lib/data/repositories/firebase/` directory. For each interface, write a Firebase implementation that delegates to `cloud_firestore` / `firebase_auth` / `firebase_storage`.

Each implementation file:
- `lib/data/repositories/firebase/firebase_auth_repository.dart` — `class FirebaseAuthRepository implements AuthRepository`
- `lib/data/repositories/firebase/firebase_stores_repository.dart`
- `lib/data/repositories/firebase/firebase_orders_repository.dart`
- `lib/data/repositories/firebase/firebase_products_repository.dart`
- `lib/data/repositories/firebase/firebase_user_repository.dart`
- `lib/data/repositories/firebase/firebase_storage_repository.dart`

Each is a thin pass-through to the Firebase SDK. Example for `firebase_auth_repository.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_seller/data/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  @override
  Future<UserCredential> signInWithEmail({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<UserCredential> createUserWithEmail({required String email, required String password}) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> confirmPasswordReset({required String code, required String newPassword}) =>
      _auth.confirmPasswordReset(code: code, newPassword: newPassword);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;
}
```

Apply the same pattern for the other 5. Each implementation goes in its own file, one focused class.

For each commit:
```bash
git add lib/data/repositories/firebase/<file>.dart
git commit -m "feat(data): implement <X>Repository with Firebase backend"
git push personal redesign/3-data-layer
```

### Task 3.4: Register repositories in service_locator + Riverpod providers

Edit `lib/core/service_locator.dart` to register each repository:
```dart
locator.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
locator.registerLazySingleton<StoresRepository>(() => FirebaseStoresRepository());
locator.registerLazySingleton<OrdersRepository>(() => FirebaseOrdersRepository());
locator.registerLazySingleton<ProductsRepository>(() => FirebaseProductsRepository());
locator.registerLazySingleton<UserRepository>(() => FirebaseUserRepository());
locator.registerLazySingleton<StorageRepository>(() => FirebaseStorageRepository());
```

Create `lib/data/repositories/providers.dart` exposing Riverpod providers:
```dart
import 'package:get_it/get_it.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_seller/data/repositories/auth_repository.dart';
import 'package:unshelf_seller/data/repositories/stores_repository.dart';
import 'package:unshelf_seller/data/repositories/orders_repository.dart';
import 'package:unshelf_seller/data/repositories/products_repository.dart';
import 'package:unshelf_seller/data/repositories/user_repository.dart';
import 'package:unshelf_seller/data/repositories/storage_repository.dart';

part 'providers.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) => GetIt.instance<AuthRepository>();

@riverpod
StoresRepository storesRepository(StoresRepositoryRef ref) => GetIt.instance<StoresRepository>();

@riverpod
OrdersRepository ordersRepository(OrdersRepositoryRef ref) => GetIt.instance<OrdersRepository>();

@riverpod
ProductsRepository productsRepository(ProductsRepositoryRef ref) => GetIt.instance<ProductsRepository>();

@riverpod
UserRepository userRepository(UserRepositoryRef ref) => GetIt.instance<UserRepository>();

@riverpod
StorageRepository storageRepository(StorageRepositoryRef ref) => GetIt.instance<StorageRepository>();
```

Run codegen:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit:
```bash
git add lib/core/service_locator.dart lib/data/repositories/providers.dart lib/data/repositories/providers.g.dart
git commit -m "feat(data): register repositories with get_it + expose Riverpod providers"
git push personal redesign/3-data-layer
```

### Task 3.5: Refactor existing services to delegate to repositories

For each service in `lib/services/`, identify data-access calls (Firestore queries, Storage uploads, Auth calls) and move them OUT of the service INTO the corresponding repository. The service then becomes a thinner business-logic wrapper.

Example: if `OrderService.getOrdersForStore(storeId)` currently does `FirebaseFirestore.instance.collection('orders').where(...).snapshots().map(...)`, change it to:
```dart
class OrderService implements IOrderService {
  OrderService({OrdersRepository? repo}) : _repo = repo ?? GetIt.instance<OrdersRepository>();
  final OrdersRepository _repo;

  @override
  Stream<List<OrderModel>> getOrdersForStore(String storeId) => _repo.watchOrders(storeId);
}
```

Apply to: `AuthenticationService`, `OrderService`, `ProductService`, `StoreService`, `UserProfileService`, others that have Firestore/Storage calls. Commit per service:
```bash
git commit -m "refactor(services): delegate <service> data access to <X>Repository"
git push personal redesign/3-data-layer
```

### Task 3.6: Run tests + verify + PR + merge

```bash
flutter analyze 2>&1 | tail -5
flutter test 2>&1 | tail -3
flutter build web --release 2>&1 | tail -3
```

Expected: no new errors, all tests pass, build green. If any service test stubs the OLD Firestore behavior directly, port them to stub the repository instead.

```bash
gh pr create --repo johnivanpuayap/unshelf-seller --base main --head redesign/3-data-layer \
  --title "Redesign Phase 3: Service interfaces polish + repositories layer" \
  --body "Implements Phase 3. New lib/data/repositories/ with 6 interfaces + Firebase implementations. Services delegate data-access to repositories. Riverpod providers bridge get_it for Riverpod consumers."

PR=$(gh pr list --repo johnivanpuayap/unshelf-seller --head redesign/3-data-layer --json number --jq '.[0].number')
gh pr merge --repo johnivanpuayap/unshelf-seller $PR --squash --delete-branch
git checkout main && git pull --rebase personal main
```

---

## Phase 4 — Screen Redesigns (8 groups)

Each group = one branch + one PR. Quality Bar = the auth screens from Phase 1.

The seller's screens are admin/inventory-oriented. Layouts should feel like a focused operator app — dense data tables where appropriate, clear hierarchy, action-oriented CTAs.

For each group, the implementer reads the assigned views, applies the Quality Bar, extracts emergent 3+-use components, runs verify, opens a PR.

### Group A — Dashboard + Home + Notifications

Branch: `redesign/4A-dashboard`

**Files:**
- `lib/views/dashboard_view.dart`
- `lib/views/home_view.dart`
- `lib/views/notifications_view.dart`

**Design intent (seller-led admin dashboard):**

```
[Top bar]      Store logo + name + bell icon (notifications) + avatar (profile)
[Hero stats row] Today's revenue / Orders count / Items sold / Low stock — 4 stat cards (use existing lib/components/stat_card.dart, retheme if needed)
[Section: Today's orders]    horizontal scroll of OrderCard with status, customer, total
[Section: Expiring batches] vertical list of batch cards with expiry urgency badges
[Section: Low stock]         3-5 ProductCard rows with current qty + reorder CTA
[Section: Quick actions]    Add product / Add batch / View analytics — 3 outlined buttons
[Bottom nav]                preserve existing bottom nav
```

Notifications: same time-grouped pattern as buyer (Today / This week / Earlier), themed via colorScheme.

Commits (one per view):
```bash
git commit -m "feat(ui): redesign dashboard as seller-led admin home (stats / orders / batches / low stock)"
git commit -m "feat(ui): redesign home view (entry routing to dashboard + bottom nav shell)"
git commit -m "feat(ui): redesign notifications with time-grouped sections"
```

End with PR + merge:
```bash
gh pr create --repo johnivanpuayap/unshelf-seller --base main --head redesign/4A-dashboard \
  --title "Redesign 4A: Dashboard + Home + Notifications" \
  --body "Sub-project 2 Phase 4 Group A. Seller-led admin dashboard, themed home + notifications."
PR=$(gh pr list --repo johnivanpuayap/unshelf-seller --head redesign/4A-dashboard --json number --jq '.[0].number')
gh pr merge --repo johnivanpuayap/unshelf-seller $PR --squash --delete-branch
git checkout main && git pull --rebase personal main
```

### Group B — Inventory + Listings

Branch: `redesign/4B-inventory`

**Files:**
- `lib/views/inventory_view.dart`
- `lib/views/listings_view.dart`
- `lib/views/add_product_view.dart`
- `lib/views/edit_product_view.dart`
- `lib/views/product_details_view.dart`
- `lib/views/product_analytics_view.dart`

**Design intent:** inventory-focused. Tables/lists of products with thumb, name, stock, price, status. Add/Edit forms use `_FieldLabel` pattern from Phase 1. Analytics views use the existing `chart.dart` component (retheme if needed).

Commits per view. PR + merge.

### Group C — Batches + Bundles + Restock

Branch: `redesign/4C-batches`

**Files:**
- `lib/views/add_batch_view.dart`
- `lib/views/edit_batch_view.dart`
- `lib/views/batch_history_view.dart`
- `lib/views/add_bundle_view.dart`
- `lib/views/edit_bundle_view.dart`
- `lib/views/bundle_details_view.dart`
- `lib/views/restock_details_view.dart`
- `lib/views/restock_selection_view.dart`
- `lib/views/select_products_view.dart`

**Design intent:** batch entry forms with expiry pickers (use `datetime_picker.dart`-equivalent — if absent, build a small one), bundle composition with quantity steppers, restock selection multi-select with checkboxes.

Commits per view. PR + merge.

### Group D — Orders + History

Branch: `redesign/4D-orders`

**Files:**
- `lib/views/orders_view.dart`
- `lib/views/order_details_view.dart`
- `lib/views/order_history_view.dart`
- `lib/views/order_history_details_view.dart`

**Design intent:** orders list with status filter chips (Pending / Ready / Picked up / Cancelled), each row is an OrderCard. Detail view shows full order breakdown, customer info, action buttons (Mark ready / Mark picked up / Refund).

Commits per view. PR + merge.

### Group E — Store profile + Analytics + Location/Schedule

Branch: `redesign/4E-store`

**Files:**
- `lib/views/store_view.dart`
- `lib/views/store_analytics_view.dart`
- `lib/views/edit_store_profile_view.dart`
- `lib/views/edit_store_location_view.dart`
- `lib/views/edit_store_schedule_view.dart`

**Design intent:** store profile hero (cover image + name + rating), analytics charts (revenue over time, top products, follower growth), edit forms with field-label pattern. Map screens preserve FlutterMap widget; only redesign chrome.

Commits per view. PR + merge.

### Group F — Wallet + Withdrawals

Branch: `redesign/4F-wallet`

**Files:**
- `lib/views/balance_overview_view.dart`
- `lib/views/withdraw_request_view.dart`

**Design intent:** wallet hero card (large balance number in DM Serif Display), recent transactions list, "Withdraw" CTA. Withdraw request form uses field-label pattern + amount input + bank/GCash details + submit CTA with loading state.

Commits per view. PR + merge.

### Group G — Chats + Reports

Branch: `redesign/4G-chats`

**Files:**
- `lib/views/chats_view.dart`
- `lib/components/chat_screen.dart` (single conversation — currently in components folder)
- `lib/components/chat_bubble.dart` (retheme if needed)
- `lib/views/report_view.dart`

**Design intent:** chat list with conversation tiles (buyer avatar + name + last message + timestamp + unread badge). Chat screen with bubble pattern (incoming/outgoing). Report form with reason chips + textarea + submit.

Commits per view. PR + merge.

### Group H — Settings + User Profile

Branch: `redesign/4H-settings`

**Files:**
- `lib/views/settings_view.dart`
- `lib/views/edit_user_profile_view.dart`

**Design intent:** settings as a list of `SettingsTile` rows (extract if 3+ uses across the redesign). Edit user profile with avatar editor + field labels (Name, Email read-only, Phone) + save CTA.

Commits per view. PR + merge.

---

## Phase 5 — Components Audit + README

Branch: `redesign/5-components`

### Task 5.1: Branch + audit

```bash
cd "C:/Users/John Ivan/personal-projects/unshelf-seller"
git checkout main && git pull --rebase personal main
git checkout -b redesign/5-components
git push -u personal redesign/5-components
```

Run audit:
```bash
ls lib/components/
```

For EACH file in `lib/components/`:
1. Read it.
2. `grep -rn "<ComponentClassName>" lib/` — find use sites.
3. Note: hardcoded colors/fonts? Single-use? Stale?
4. Action:
   - Retheme any hardcoded `Color(0xFF...)` / `Colors.white` / `TextStyle(fontFamily:)` → `Theme.of(context).colorScheme.*` / `textTheme.*`
   - Delete if zero use sites
   - Promote any 3+-use widget that's currently inline somewhere
5. Commit each substantive change atomically.

### Task 5.2: Write `lib/components/README.md`

```markdown
# Seller Components

Reusable widgets for the Unshelf seller Flutter app. These widgets are **seller-specific** — per the uniqueness rule (`[[unshelf-buyer-seller-uniqueness]]`), the buyer app has its own components. Only the auth flow is visually shared between apps (see `brand-kit/docs/crucible/auth-screens.md`).

All components consume the brand theme via `Theme.of(context).colorScheme` and `textTheme`. None hardcode colors or fonts.

## Catalog

### ComponentName

One-line purpose.

**File:** `lib/components/<file>.dart`

**Props:**
- `propName` (Type) — description

**Used by:**
- `lib/views/<view>.dart`
- ...

**Example:**
```dart
ComponentName(prop1: value1, prop2: value2)
```

---

(...repeat for each component...)
```

Document every component. List props, use sites, example. Reference the uniqueness rule prominently.

```bash
git add lib/components/README.md
git commit -m "docs(components): add seller-internal component catalog README"
git push personal redesign/5-components
```

### Task 5.3: PR + merge

```bash
flutter analyze 2>&1 | tail -5
flutter test 2>&1 | tail -3
flutter build web --release 2>&1 | tail -3
```
Expected: all green.

```bash
gh pr create --repo johnivanpuayap/unshelf-seller --base main --head redesign/5-components \
  --title "Redesign Phase 5: Components audit + README" \
  --body "Final pass on lib/components/. Retheme legacy widgets, delete unused, promote 3+-use patterns, write seller-internal catalog. Sub-project 2 (seller rebrand) is complete."
PR=$(gh pr list --repo johnivanpuayap/unshelf-seller --head redesign/5-components --json number --jq '.[0].number')
gh pr merge --repo johnivanpuayap/unshelf-seller $PR --squash --delete-branch
git checkout main && git pull --rebase personal main
git log --oneline -15
```

---

## Self-Review

**Spec coverage:**

| Spec acceptance criterion | Task that fulfills it |
|---|---|
| `brand-kit/` submodule installed | Task 1.1 |
| `lib/utils/theme.dart` exposes UnshelfTheme | Task 1.3 |
| `lib/utils/colors.dart` retired | Task 1.6 (or Phase 5 if too many call sites) |
| `pubspec.yaml` no longer depends on provider; Riverpod added | Task 2.1 (add) + Task 2.24 (remove) |
| App boots under ProviderScope | Task 2.1 |
| All 22 viewmodels are Riverpod providers; 8 tests pass | Tasks 2.2–2.23 + 2.24 |
| All 4 auth screens conform to auth-screens.md w/ seller deltas | Tasks 1.7–1.11 |
| `lib/data/repositories/` layer with 6 repos + Firebase impls | Tasks 3.2 + 3.3 |
| Every service in lib/services/ uses interfaces | Task 3.1 |
| No hardcoded colors/fonts in screen code | Phase 4 (all groups) + Phase 5 audit |
| Logo + app icon + splash use Abundance Basket SVGs | Task 1.5 (logos) + future store-submission sub-project (app icon export) |
| Seller-led admin dashboard | Phase 4 Group A |
| `lib/components/README.md` | Phase 5 Task 5.2 |
| App runs end-to-end on Android + iOS + web | Manual smoke test at each PR's exit |
| All 5 phase branches + 8 redesign groups merged via PR | All tasks |

**Placeholder scan:** Phase 4 groups (B–H) reference the Quality Bar + brand kit instead of spelling out every widget. This is intentional per the spec — design judgment delegated to the implementer with concrete reference (auth screens from Phase 1 + brand-kit/docs/crucible/design.md + preview.html). NOT a TBD.

**Type consistency:** Provider names use `<X>ViewModelProvider` pattern across Phase 2. Repository names use `<X>Repository` interface + `Firebase<X>Repository` impl. `_FieldLabel` is duplicated as file-private widget in each auth screen — to be extracted in Phase 5 audit if it hits 3+ uses (almost certainly will). Component names should be seller-specific (e.g., `ProductCard` for inventory IS distinct from the buyer's `ProductCard` for shopping — same class name, different file in a different repo, per the uniqueness rule).

---

## Execution Handoff

Plan complete and saved to `docs/crucible/plans/2026-05-16-seller-rebrand-implementation.md`. Two execution options:

**1. Subagent-Driven (recommended)** — fresh subagent per task, two-stage review on Phase 1 (sets the quality bar) and Phase 3 (architecture-critical), single-pass verification on Phase 2 viewmodel migrations and Phase 4 redesign groups (Quality Bar enforces consistency). Matches your saved workflow preference.

**2. Inline Execution** — execute phases in this session using `executing-plans`, batch with checkpoints between phases.

**Which approach?**
