# Daily Darshan widget — one-time Xcode setup

All the code is written. The only thing that can't be done by editing files (safely)
is creating the widget **target**, because that rewrites the Xcode project. It takes
about two minutes in Xcode.

## What's already done (in code)
- `DarshanWidget/DarshanWidget.swift` — the whole widget (timeline provider + Home
  and Lock Screen views for small / medium / large / rectangular / inline).
- `BhaktiAngan/Services/RemoteCatalog.swift` → `WidgetBridge` — the app writes the
  next 7 days of darshan (image + text) into the shared App Group container and
  reloads the widget. It runs on launch and every time the app comes to the front.
- `BhaktiAnganApp.swift` — calls `WidgetBridge.publish(...)` and handles the widget
  tap deep link (`bhaktiangan://today` → Today tab).
- `Info.plist` — the `bhaktiangan` URL scheme is registered.

Until the App Group is enabled, `WidgetBridge` is a silent no-op, so the app already
builds and runs exactly as before (verified).

## The steps

1. **Create the target.** Xcode → File → New → Target → **Widget Extension**.
   - Product Name: `DarshanWidget`
   - **Uncheck** "Include Configuration App Intent" and "Include Live Activity".
   - Finish. If asked to activate the scheme, either choice is fine.

2. **Swap in the real code.** Xcode generated template files inside a new
   `DarshanWidget` group (e.g. `DarshanWidget.swift`, maybe `DarshanWidgetBundle.swift`,
   an `AppIntent.swift`). **Move those templates to Trash.** Then drag
   `DarshanWidget/DarshanWidget.swift` (this folder) into the group and make sure its
   **Target Membership is DarshanWidget only**. Delete the generated `Assets.xcassets`
   for the widget if you like (unused).

3. **App Group on BOTH targets** (this is what lets the app and widget share data):
   - Project → **BhaktiAngan** target → Signing & Capabilities → **+ Capability** →
     **App Groups** → click **+** → add `group.in.bhaktiangan.app`.
   - Project → **DarshanWidget** target → Signing & Capabilities → **+ Capability** →
     **App Groups** → check the same `group.in.bhaktiangan.app`.

4. **Match the deployment target.** Set the DarshanWidget target's Minimum
   Deployments to **iOS 17.0** (same as the app).

5. **Run.** Build and run the app once (so it writes the timeline). Then long-press the
   Home Screen → **+** → search **Bhakti Angan** → add **Daily Darshan** (try small,
   medium, large). On the Lock Screen, edit widgets → add the rectangular or inline one.

## Notes
- The widget shows the darshan the app last computed, and rolls forward on its own for
  up to a week; opening the app refreshes it (and picks up remote / festival darshans).
- It follows the app's language (English or Hindi) as of the last app open.
- `DarshanWidget.entitlements` here is just a reference for the exact group string;
  the App Groups capability in step 3 generates the real entitlements for you.
- The widget is free and never gated.
