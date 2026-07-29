# SmartRoute Design System and UI Standards

This document is the design-system source of truth for SmartRoute. Developers and AI coding agents must read it before changing Flutter UI. It describes the implemented visual language; it is not permission to redesign the product.

## 1. Principles

SmartRoute is a compact, high-contrast transit interface with red brand actions, strong hierarchy, white cards, restrained shadows, and transport-line colors with domain meaning.

1. Match established screens before inventing a pattern.
2. Search the current feature, `shared/widgets`, and theme files before creating a component.
3. Use tokens instead of literal colors, typography, spacing, radii, or shadows.
4. Keep status, route steps, fares, times, and actions immediately scannable.
5. Support safe areas, content growth, text scaling, and different viewport widths.
6. Never rely on color alone and give controls usable semantics and touch targets.

## 2. Sources of Truth

| File | Responsibility |
| --- | --- |
| `lib/core/theme/app_theme.dart` | Material 3 theme and component defaults |
| `lib/core/theme/app_colors.dart` | Brand, semantic, transit, surface, text, border, and gradient colors |
| `lib/core/theme/app_typography.dart` | Plus Jakarta Sans and DM Mono styles |
| `lib/core/theme/app_spacing.dart` | Base spacing and named dimensions |
| `lib/core/theme/app_radius.dart` | Corner-radius scale |
| `lib/core/theme/app_shadows.dart` | Surface and action shadows |

`AppTheme.light` is the only configured theme. Do not assume dark mode exists or add isolated dark-mode branches. Dark mode requires a complete token and component audit.

## 3. Colors

Use `AppColors` for every application color. Do not add `Color(0x...)`, arbitrary Material swatches, or `Colors.grey.shade...` in feature code. Existing literals are legacy exceptions, not patterns to copy. Add a well-named semantic token when a required color is missing.

### Brand and neutral usage

- `primary`: principal actions, active states, and brand emphasis.
- `primaryDark` and `primaryDeep`: darker gradient accents.
- `primaryLight`: low-emphasis red surfaces.
- `secondary` and `secondaryLight`: secondary emphasis and its tint.
- `background`: page background.
- `surface` or `card`: white content surfaces.
- `textPrimary`, `textSecondary`, and `textTertiary`: decreasing text emphasis.
- `border`, `borderLight`, and `divider`: structural separation.
- `mutedBg` and `mutedForeground`: low-emphasis controls and icon wells.

Use `gradientPrimary`, `gradientHeader`, `gradientBlue`, and `gradientProfile` only for their established purposes. White-opacity tokens are for content on gradients.

### Semantic and transit colors

Use coordinated foreground/background token families for success, live state, alert severity, and transport status. Pair every operational color with a label, icon, or shape.

Transit tokens have fixed meaning and must not be decorative:

| Token | Meaning |
| --- | --- |
| `kjLine` | Kelana Jaya Line |
| `spLine` | Sri Petaling Line |
| `mkLine` | MRT Kajang Line |
| `mpLine` | MRT Putrajaya Line |
| `mlLine` | KL Monorail |
| `brLine` / `busLine` | BRT or bus presentation |

If model data provides hex strings, convert them once at a reusable presentation boundary with a validated fallback. Do not scatter string parsing through widgets.

## 4. Typography

Plus Jakarta Sans is the primary UI font. DM Mono is reserved for numeric information whose alignment aids scanning, such as fare, journey duration, ETA, distance, and statistics.

Use `AppTypography` or `Theme.of(context).textTheme`. Do not call `GoogleFonts` or construct ad hoc `TextStyle` objects in features. Existing direct calls in `main.dart` are legacy details. Use `copyWith` only for contextual differences such as text on a gradient; create a semantic style if an override repeats.

- Headline styles establish page and hero hierarchy.
- Title styles identify sections and cards.
- Body styles carry content and actions.
- Label/caption styles carry chips and metadata.
- Mono styles carry important numerical values.
- Do not shrink text to make content fit.
- Allow wrapping unless there is a genuine one-line constraint.
- Use ellipsis only when truncation cannot hide critical meaning.
- Test increased text scale.
- Avoid emoji as the only meaningful icon when an accessible Flutter icon or asset exists.

## 5. Spacing, Size, Shape, and Elevation

`AppSpacing` follows a 4 px rhythm with established intermediate values. Prefer semantic tokens such as `pageHorizontal`, `pageBottom`, `cardPadding`, and `inputVertical` over base values.

- Standard horizontal page padding is `AppSpacing.pageHorizontal` (16 px).
- Standard scroll bottom padding is `AppSpacing.pageBottom` (32 px), plus required safe-area inset.
- Cards normally use `cardPadding` (16 px) or `cardPaddingMedium` (14 px).
- Inputs inherit centralized theme padding.
- Do not add unexplained one-off gaps when a token expresses the intent.
- Fixed dimensions are appropriate for icons, avatars, badges, and bounded canvases, not whole-screen layout.

Use `AppRadius`: `xs` for tiny details, `sm` for compact segments, `md` for inputs/chips/icon wells, `lg` for cards and major buttons, `xxl` for prominent sheet corners, and `circular` for pills, avatars, and dots.

Use `AppShadows` by purpose: card variants for surfaces, named button shadows for matching actions, `header` for separated headers, and `panel` for raised information panels. `loginCard` and `phoneShell` are specialized. Standard cards remain subtle and normally retain the light border.

Add a new design token only after confirming it is recurring or represents an enduring system rule. Painter coordinates are not global spacing tokens.

## 6. Components

`AppTheme.light` configures Material 3 app bars, cards, inputs, bottom navigation, dividers, and elevated buttons. Prefer themed Material components over rebuilding them with decorated containers.

### Buttons

- Use one dominant primary action per local decision area.
- Primary red is for the principal action; secondary actions use outlined, text, or muted treatments.
- Disabled actions must be visibly disabled and non-interactive.
- During asynchronous submission, show progress and prevent duplicate activation.
- Labels describe outcomes, such as “Find Best Routes,” rather than vague wording.

### Inputs

- Use `TextFormField` and form validation when input can be invalid.
- Labels are required; placeholders do not replace them.
- Configure keyboard type, text input action, autofill, obscuring, and capitalization.
- Show errors beside the relevant field and preserve input after failure.
- Dispose owned controllers and focus nodes.

### Cards, rows, chips, and badges

- Group related information into one surface with consistent padding and radius.
- Make the full row tappable when it represents one action.
- Use separators or spacing consistently.
- Use lazy list builders for dynamic or potentially long lists.
- Chips represent filters or choices; badges represent status or metadata.
- Preserve a usable touch region around compact visual controls.

## 7. Screen Composition and Responsiveness

A standard screen contains a safe status-bar region, a header, a bounded or scrollable content region, an optional persistent action/panel, and the correct bottom safe area. Login and home may integrate the status bar into their gradient header. `AppShell` controls status-bar icon brightness.

- Use `SafeArea` or explicit `MediaQuery` insets consistently with neighboring screens; never apply the same inset twice.
- Main content normally uses `AppColors.background` with white cards.
- Ensure shell navigation and system insets do not obscure bottom content.
- Avoid nested unconstrained vertical scroll views.
- Keep a screen readable with private section widgets; promote only demonstrated cross-feature reuse.
- Use constraints, not a fixed reference-phone size, for overall layout.
- Prefer `Expanded`, `Flexible`, `Wrap`, `LayoutBuilder`, and scrolling where content can grow.
- Prevent row overflow with long labels and larger text.
- Constrain content width on wide web displays where needed for readability.
- Derive custom-painter geometry from the supplied `Size` where possible.
- Test narrow mobile width, typical mobile width, increased text scale, and a wide web viewport for material UI changes.
- Never shrink typography based on `MediaQuery` to hide layout problems.

## 8. Interaction and Motion

Motion communicates state or spatial relationships and must not delay the user. Existing patterns include selection transitions, skyline motion, live pulses, simulated vehicle progress, and map pan/zoom.

- Prefer Flutter animation APIs over manual rebuild loops.
- Keep timing and curves consistent with neighboring interactions.
- Dispose all repeating animation controllers and timers.
- Make `CustomPainter.shouldRepaint` reflect every visual input.
- Animate the smallest meaningful region.
- Respect reduced-motion platform preference for non-essential or continuous motion.
- Never describe simulated movement or static data as production live data.

## 9. Accessibility

- Give icon-only actions tooltips and semantic labels.
- Add `Semantics` to meaningful custom-painted or gesture-only controls.
- Prefer `InkWell`, `IconButton`, or Material buttons over bare `GestureDetector` for standard actions.
- Provide at least a 48 logical pixel primary interaction region where practical.
- Maintain foreground/background contrast.
- Pair status colors with labels, icons, or shapes.
- Preserve logical focus and traversal order.
- Do not block text scaling.
- Exclude decorative painting from semantics when appropriate.
- Announce validation failures and important asynchronous state changes.

## 10. Copy and Localization Readiness

The app currently uses English literals and has no localization framework. Preserve existing terminology and capitalization.

- Do not duplicate the same new user-facing string across files.
- Keep feature-only copy in one obvious feature-owned location until localization exists.
- Keep app-wide labels in an app-wide string source, not in theme or model files.
- Do not introduce localization during an unrelated visual change.
- Use Malaysian transit terms consistently: LRT, MRT, BRT, Monorail, station, line, fare, transfer, and platform.
- Errors must be concise and actionable and never reveal implementation details.

Localization is an app-wide architectural change and must migrate copy coherently rather than create a second partial string system.

## 11. UI States

Every asynchronous, data-driven component must deliberately support relevant states: initial/loading, success, empty, failure, retry/refresh, and disabled/offline when applicable.

Mock-only synchronous screens do not need artificial loading. When a real source is added, preserve layout during loading, distinguish empty results from failure, prevent duplicate requests, and offer recovery when possible.

## 12. Assets, Icons, and Painting

- Prefer established Material icons when accurate.
- Use `flutter_svg` for scalable vector assets and declare assets in `pubspec.yaml`.
- Do not add an icon package for a single icon.
- Provide descriptions for informative assets and exclude decorative assets from semantics.
- Reuse `KLSkyline` and `StatusBar` only where their exact behavior fits.
- Keep map and network painter colors aligned with transit tokens.
- Keep state and interaction outside `CustomPainter`.
- Do not embed domain data in drawing code if it must become dynamic or interactive.

## 13. Flutter UI Coding Rules

- Use `const` constructors and widgets whenever values are compile-time constants.
- Keep `build` free of side effects and expensive repeated work.
- Name widgets by responsibility, not appearance alone.
- Keep feature-only widgets private and pass required inputs explicitly.
- Reuse or extend a component before creating a near-duplicate.
- Never hardcode reusable colors, spacing, radii, shadows, or typography.
- Keep network, persistence, authentication, and business rules out of widgets.
- Follow `flutter_lints`; do not add broad suppressions.
- Format all Dart code using the standard formatter.

## 14. Design Review Checklist

Before completing UI work, verify:

- Existing components were searched and reused.
- All design values use project tokens.
- Hierarchy matches adjacent SmartRoute screens.
- No literal duplicates an existing token.
- Layout works at narrow and wide widths and increased text scale.
- Safe areas and shell navigation do not obscure content.
- Long, empty, loading, error, and disabled content behave correctly when applicable.
- Controls have semantics, usable targets, and visible states.
- Color is not the only status signal.
- Controllers, timers, focus nodes, and animations are disposed.
- `dart format`, `flutter analyze`, and relevant tests pass.
- Visual inspection finds no overflow, clipping, misalignment, or style regression.

If a request conflicts with this system, do not silently create an exception. Identify the conflict, confirm whether it is an intentional design-system change, update the shared token or component at the correct level, and document the decision.
