# SmartRoute final Android QA

Use a physical Android phone with internet access and a restricted Google Maps key. Record PASS/FAIL and evidence; do not mark an item passed from compilation alone.

- [ ] Register a passenger, confirm email if required, log in, restart the app, and confirm session restoration.
- [ ] Confirm Home shows the authenticated name and only real favourites, recents, notices, and dataset counts.
- [ ] Plan manually between real stops; verify results, route detail, line/station links, and Google Map GTFS shape/markers.
- [ ] Enable location preference, grant Android permission, use current location, then deny permission and confirm manual planning still works.
- [ ] Save a route, confirm Home updates, logout/login, reopen the favourite, and replan it.
- [ ] Run a successful search, confirm recent history updates, logout/login, and replan from history without duplicate growth.
- [ ] Open a rail journey; confirm SCHEDULED, next departure/expected timing, map, and station sequence with no LIVE or realtime-unavailable message.
- [ ] During operating hours choose a supported Rapid KL/MRT feeder bus route; confirm LIVE only if a fresh official vehicle marker appears. If not, confirm Scheduled times shown.
- [ ] Browse Transit by mode and line, tap station/route map markers, follow a route, and confirm identities match Planner/Detail/Progress.
- [ ] With an authorized Admin QA account, publish a real-line SmartRoute notice with expiry.
- [ ] With a subscribed/favourite passenger, confirm the notice on Home and Alerts, open it, mark read, and confirm unread count updates.
- [ ] Archive/expire the admin notice and confirm it disappears from active passenger surfaces after refresh.
- [ ] Verify notifications preference suppresses/restores in-app relevance and location preference controls location use.
- [ ] Verify About/Data Sources, profile edit, keyboard layouts, narrow-screen scrolling, text scaling, back actions, five-tab navigation, and logout.
- [ ] Tap every visible icon, button, card, toggle, filter, menu, and CTA; report any disabled-looking or dead action.
