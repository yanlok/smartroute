# SmartRoute design system

JC's current Home and User Management visual language is the product baseline: compact hierarchy, white surfaces, restrained shadows, SmartRoute red actions, and transport colours only when they communicate route meaning.

## Tokens

All first-party screens use `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`, and `AppTheme`. Feature screens may compose distinct layouts but should not introduce private colour palettes, arbitrary radii, or unrelated typography.

## Shared patterns

- `AppPageHeader` standardizes drill-down title, subtitle, back, and one optional action.
- Primary tabs are Home, Plan, Transit, Alerts, and Profile.
- Cards use clean surfaces, restrained borders/shadows, and compact information density.
- Buttons have clear enabled, disabled, saving, and retry states.
- Forms remain visible above the keyboard and use safe areas.
- Empty states explain the next useful action; errors never expose provider or database internals.
- Maps live inside rounded content panels with accessible semantics and useful markers.

## Transport truth language

- `LIVE` uses green and appears only when a fresh official vehicle position matches the selected static GTFS route.
- `SCHEDULED` uses the secondary colour for GTFS timetable or journey progress.
- `Expected` and `approximately` identify calculated schedule values.
- SmartRoute-authored notices are labelled `SMARTROUTE NOTICE`; verified feed notices use `OFFICIAL`.
- No screen says `Realtime unavailable`. A feed problem quietly changes the experience to `Scheduled times shown`.

## Responsive and accessible behavior

The primary target is a narrow-to-typical Android phone. Main content scrolls, CTAs avoid bottom-navigation overlap, forms account for view insets, map controls use native Google Maps placement, and tap targets use standard Material sizing. Text hierarchy remains usable with Android text scaling.
