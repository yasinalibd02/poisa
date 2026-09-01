# Kori · কড়ি

**Simple money tracking. / সহজ হিসাব।**

An offline-capable personal finance app for Android and iOS, fully bilingual in
English and Bangla. Google sign-in only, Cloud Firestore for storage, and every
number derived live from the ledger so balances can never drift.

- **Package id:** `com.kori.moneytracker`
- **Flutter:** 3.24+ · **Dart:** 3.5+ · Material 3

---

## Setup

### 1. Create the Firebase project

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. **Authentication → Sign-in method →** enable **Google**, and *only* Google.
3. **Firestore Database →** create a database (production mode is fine; the
   rules in this repo replace the defaults).

### 2. Register the apps and add your signing fingerprints

Android needs your SHA-1 **and** SHA-256, or Google Sign-In returns no ID token.

```sh
# Debug fingerprints
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore \
  -storepass android -keypass android

# Release fingerprints (once you have an upload key)
keytool -list -v -alias <your-alias> -keystore <your-keystore.jks>
```

Add both to **Project settings → Your apps → Android app → Add fingerprint**.
Register the Android app as `com.kori.moneytracker` and the iOS app with the
same bundle id.

### 3. Generate the Firebase config

```sh
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id>
```

This overwrites `lib/firebase_options.dart` and writes
`android/app/google-services.json` plus `ios/Runner/GoogleService-Info.plist`.
Until you run it, the app starts on a "Firebase setup required" screen listing
these steps instead of crashing.

### 4. Wire up Google Sign-In

**Android** needs the *Web* client ID (Credential Manager exchanges it for the
ID token Firebase verifies). Copy it from **Authentication → Sign-in method →
Google → Web SDK configuration**, then either pass it at run time:

```sh
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

…or set `AppConfig.googleServerClientId` in
[`lib/core/constants/app_config.dart`](lib/core/constants/app_config.dart).

**iOS** needs the URL scheme. Open `ios/Runner/GoogleService-Info.plist`, copy
`REVERSED_CLIENT_ID`, and replace `REPLACE_WITH_REVERSED_CLIENT_ID` in
[`ios/Runner/Info.plist`](ios/Runner/Info.plist).

### 5. Deploy the security rules and indexes

```sh
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules,firestore:indexes
```

### 6. Run

```sh
flutter pub get
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

---

## What ships

| Screen | Behaviour |
|---|---|
| Splash | Logo fade + scale, resolves session and onboarding flag, then routes |
| Onboarding | Three slides plus a language step; sets `onboarding_done` |
| Login | Google only, inline loading, friendly errors, terms + privacy links |
| Dashboard | Month selector, balance card, wallet cards, expense donut, budget bars, last 10 transactions |
| Add / Edit | Expense · Income · Transfer, calculator keypad, category & account pickers, date/time, note |
| Transactions | Day groups with subtotals, pinned Income/Expense/Net bar, search, filter sheet, swipe-delete with undo, long-press multi-select, incremental paging |
| Categories | Expense/Income tabs, grid with monthly totals, icon + colour editor, reorder, guarded delete |
| Accounts | Net worth, live per-account balances, archive, guarded delete |
| Budget | Per-category and overall monthly limits, colour-coded progress, copy last month |
| Reports | Week/Month/Year/Custom, donut breakdown, six-month bars, trend line, ranked list |
| Settings | Language, Bangla numerals, theme, currency, week/month start, CSV export, sign out, delete account |
| States | Empty, shimmer loading, error with retry, offline banner |

---

## Architecture

Feature-first clean architecture. The UI never touches Firestore.

```
lib/
  main.dart                 Bootstrap: preferences → Firebase → ProviderScope
  app/                      app.dart · router.dart · routes.dart · app_shell.dart · theme.dart
  core/
    constants/              colours, sizes, icon catalogue, currencies, enums, seed data
    extensions/             context helpers
    services/               Firebase init, Firestore refs/providers, prefs, CSV, links, connectivity
    utils/                  money formatting, Bangla numerals, period maths, calculator, failures
    widgets/                cards, badges, pickers, dialogs, snackbars, empty/error/shimmer states
  l10n/                     app_en.arb · app_bn.arb (+ generated delegates)
  features/<feature>/
    data/                   models (fromMap/toMap/copyWith) + repository
    presentation/           screens · widgets · providers
```

**State:** Riverpod 2 with `Notifier` / `AsyncNotifier` / `StreamProvider` and
`AsyncValue` loading and error handling throughout.

**Routing:** `go_router` with an auth-guarded `redirect`. Splash owns its own
exit so the animation is never cut short; every other route is guarded by
`onboarding_done` and the Firebase session.

### One ledger stream

`TransactionRepository.watchAll()` is the single Firestore listener behind every
derived number — account balances, budget spend, report aggregates. Those all
have to be exact, which means seeing every row anyway, and Firestore's offline
cache serves the listener locally so the app opens with correct balances before
the network answers. Screens filter and page that list in memory. For a personal
ledger (thousands of rows) this is comfortably cheap; a far larger one would
want denormalised running totals instead.

Because of that, the Transactions screen's "20 per page" is a growing render
window rather than repeated queries — which is also the only way paging can
compose with the category, account, amount and free-text filters, none of which
Firestore can express in a single query.

### Balances are derived, never stored

`opening balance ± every transaction that touches the account`. Editing or
deleting a transaction can therefore never leave a stale balance behind.

---

## Data model

```
users/{uid}
  displayName, email, photoUrl, currencyCode, languageCode,
  themeMode, useBanglaNumerals, createdAt, updatedAt

users/{uid}/accounts/{accountId}
  name, type, icon, colorHex, openingBalance, isArchived, sortOrder, createdAt

users/{uid}/categories/{categoryId}
  nameEn, nameBn, type ("income"|"expense"), icon, colorHex,
  isDefault, sortOrder, createdAt

users/{uid}/transactions/{transactionId}
  type ("income"|"expense"|"transfer"), amount (double, always positive),
  categoryId, accountId, toAccountId (transfer only),
  note, date, createdAt, updatedAt

users/{uid}/budgets/{budgetId}
  categoryId (null = overall), limitAmount, period ("monthly"),
  year, month, createdAt
```

Timestamps are written client-side rather than with `FieldValue.serverTimestamp()`:
a server timestamp reads back as `null` from the offline cache until it syncs,
which would break date ordering exactly when the user is offline.

`firestore.indexes.json` declares the `(type, date desc)` transactions index and
the `(year, month)` budgets index. Firestore's automatic single-field indexes
already cover v1's queries; these are pre-declared so type- and month-scoped
queries never fail with a runtime "index required" error.

### First-login seeding

On first sign-in `UserRepository.ensureUserDocument` creates the profile doc and
seeds, in one batch:

- **12 expense categories** — Food/খাবার, Transport/যাতায়াত, Shopping/কেনাকাটা,
  Bills/বিল, Rent/বাসা ভাড়া, Health/স্বাস্থ্য, Education/শিক্ষা,
  Entertainment/বিনোদন, Family/পরিবার, Mobile-Internet/মোবাইল-ইন্টারনেট,
  Gift/উপহার, Other/অন্যান্য
- **7 income categories** — Salary/বেতন, Business/ব্যবসা, Freelance/ফ্রিল্যান্স,
  Bonus/বোনাস, Investment/বিনিয়োগ, Gift/উপহার, Other/অন্যান্য
- **1 account** — Cash / নগদ, opening balance 0

Seeded categories carry `isDefault: true`: they can be renamed and recoloured,
but not deleted.

---

## Language

Every user-facing string comes from `lib/l10n/app_en.arb` and `app_bn.arb`
(233 keys each, verified in parity). There are no hardcoded strings in widgets.

- Switching language in Settings or onboarding updates the UI immediately —
  `MaterialApp.router` rebuilds on the settings provider.
- The font follows the language (Inter for English, Hind Siliguri for Bangla)
  and each falls back to the other, so a Bangla note typed while the UI is in
  English still renders real glyphs instead of tofu.
- Numbers, currency and dates format per locale. Bangla numerals (১২৩৪) are a
  separate Settings toggle, defaulted on when the user picks Bangla.
- Text scaling is clamped to 1.3x: Bangla is a tall script and the dense money
  rows start clipping past that.

Both font families are bundled in `assets/fonts/` rather than fetched at
runtime, so an offline first launch still renders correctly.

### Adding a string

1. Add the key to `lib/l10n/app_en.arb` **and** `lib/l10n/app_bn.arb`.
2. `flutter gen-l10n`
3. Use it as `context.l10n.yourKey`.

---

## Preferences

`SharedPreferences` is authoritative for rendering — it is synchronous, so the
first frame is already themed and in the right language, and it works offline.
Preferences are mirrored into `users/{uid}` so a second device adopts them on
sign-in; local choices always win over the remote copy.

---

## Branding

- `assets/images/kori_logo.svg` — the mark as vector, K as a true cut-out.
- `lib/core/widgets/kori_logo.dart` — the same mark painted at runtime, so the
  splash costs no asset decode and stays crisp at any size.
- `android/app/src/main/res/drawable/ic_launcher_{background,foreground}.xml` —
  adaptive-icon layers (gradient coin + leaf; white K inside the safe zone),
  wired up in `mipmap-anydpi-v26/ic_launcher.xml` and also used as the
  monochrome layer for themed icons.
- Legacy launcher PNGs and the full iOS icon set are generated from the same
  geometry.

---

## Checks

```sh
flutter analyze   # clean, no warnings
flutter test      # calculator, money formatting, Bangla numerals, validators
```

---

## Deliberate choices

- **Riverpod without codegen.** Plain `Notifier`/`Provider` declarations rather
  than `riverpod_annotation`, avoiding `build_runner` and generated-file drift.
  Same API surface, one less build step.
- **Material Symbols over `lucide_icons`.** The 72-icon picker catalogue uses
  built-in `Icons`, keyed by stable strings in Firestore, so the icon set can
  change without a data migration and Flutter's icon tree-shaking keeps working.
- **`share_plus` + `path_provider`** were added for CSV export, and
  `url_launcher` for the policy and store links.
- **Reorder mode instead of a draggable grid.** Flutter has no reorderable grid;
  the Categories screen toggles to a `ReorderableListView` to rearrange.
- **Category names in both languages, account names in one.** The schema gives
  accounts a single `name`; the seeded Cash account is named in whichever
  language was picked during onboarding, and the user can rename it.

## Not in this build (phase 2)

Recurring transactions, bill reminders and notifications, receipt photos,
multi-currency conversion, PIN/biometric lock, shared wallets, PDF export, ads,
in-app purchases.
