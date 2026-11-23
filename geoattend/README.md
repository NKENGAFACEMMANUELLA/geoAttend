# GeoAttend (Flutter)

GPS-based employee attendance app with three roles: **Employee**, **HOD** and **Admin**.
Everything runs on in-memory mock repositories, so the whole UI works before the backend exists.

## Run it

This archive contains `lib/`, `pubspec.yaml` and `analysis_options.yaml`. Generate the platform folders once, then run:

```bash
flutter create --org com.example --project-name geoattend .
flutter pub get
flutter run
```

### Platform setup (needed for real GPS and the map)

**Android** — `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>GeoAttend uses your location to verify you are at your workplace.</string>
```

## Demo sign-in

Any valid email and any password works. The login screen decides the role:

| Screen | Role |
|---|---|
| Login (default) | Employee, with links to the other two |
| "HOD" link | Head of Department (Sales) |
| "Admin" link | Administrator |

Reset-password code: any 4 digits.

## GPS in the demo

`AppConfig.useMockLocation = true` (in `lib/core/constants/app_config.dart`) simulates a position about 11 m
from the workplace so clock-in works on an emulator. **Set it to `false` for real GPS.**
To test "outside the geofence", lower the radius in Admin → Geofence below 11 m... or turn the flag off and test on a device.

## Structure

```
lib/
├── main.dart, app.dart
├── core/        constants, theme, router (+ role shell), session, DI, utils, models
├── shared/      reusable widgets (buttons, inputs, state screens, dialogs) + AsyncCubit
└── features/
    ├── splash, auth, home, attendance, leave, correction, notifications
    ├── profile, settings, reports
    ├── hod          team attendance, daily summary, leave approval
    ├── admin        dashboard, employees, departments, HOD assignment, company settings
    └── workplace    workplaces, details, geofence configuration (map)
```

Each feature uses `domain/` (entities + repository interface), `data/` (mock repository) and
`presentation/` (cubit, pages, widgets). State management is `flutter_bloc` (Cubit), navigation is `go_router`
with one bottom-nav shell per role and role-based redirects, DI is `get_it`.

## Reports

HOD and Admin pick a report type and date. The report opens on screen (highlights + table) and can be exported as a **PDF** (share sheet) or copied as **CSV**. Admins can scope a report to one department. Employees do not have a Reports tab; their third tab is **Requests** (leave and correction requests).

After pulling this update run `flutter pub get` and, for iOS, `cd ios && pod install` (new packages: `pdf`, `printing`).

## Connecting to the API (Phase 1: login)

The whole app now uses the real API (`geoattend-api`): login and profile (Phase 1), admin data (Phase 2),
clock-in/out with server-side geofence and offline mode (Phase 3), leave and corrections with HOD then HR approval
(Phase 4), team attendance and reports (Phase 5), notifications (Phase 6).

**Offline clock-in:** with no connection the app checks the last known workplace on the phone, saves the clock-in/out
(shown as "Offline"), and sends it to the server the next time attendance loads. If the server refuses a saved
record (for example it was outside the area), a message is shown on the home screen.

New screens: HOD *Correction requests* (approve/reject), Admin *Leave approvals* (HR stage) and *Reports* shortcut.

```bash
# 1. start the API (see geoattend-api/README.md)   ->  http://localhost:3000
# 2. run the app
flutter run                                                       # Android emulator / iOS simulator
flutter run --dart-define=API_URL=http://192.168.1.20:3000/api/v1   # physical phone on your Wi-Fi (use your computer's IP)
flutter run --dart-define=API_URL=https://your-api.onrender.com/api/v1   # deployed API
flutter run --dart-define=USE_MOCK=true                                # no backend at all (all mock data)
# or mock only one area: USE_MOCK_AUTH, USE_MOCK_ADMIN, USE_MOCK_OPS (attendance/leave/corrections/notifications/reports)
```

Platform settings needed once:

- **Android** `android/app/build.gradle(.kts)`: set `minSdk` to **23** (secure token storage).
  For plain-HTTP testing add `android:usesCleartextTraffic="true"` to `<application>` in `AndroidManifest.xml`
  (not needed with an `https://` URL).
- **iOS** `ios/Runner/Info.plist`: for plain-HTTP testing add
  ```xml
  <key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsLocalNetworking</key><true/></dict>
  ```
  A physical iPhone calling `http://<computer-ip>` needs `NSAllowsArbitraryLoads` instead (development only),
  so an `https://` URL (deployed API or a free Cloudflare tunnel) is easier.

Real GPS: set `AppConfig.useMockLocation = false` (lib/core/constants/app_config.dart) and, as admin, set the workplace
position where you stand (Geofence screen). The Android emulator's location is under Extended controls.

After updating: `flutter pub get`, then on iOS `cd ios && pod install`.

Demo logins: admin@geoattend.app / Admin@123, james.wilson@geoattend.app / Hod@1234,
emmanuella@geoattend.app / Employee@123 (use the matching login screen: Employee, HOD, Admin).

## Going live

1. Add `dio` and write `*RemoteRepository` classes implementing the existing interfaces
   (for example `AuthRepository`, `AttendanceRepository`).
2. Swap the registrations in `lib/core/di/injection.dart`.
3. Throw `NoConnectionException` on network failures and the "No Internet Connection" screen appears automatically.
4. Store the JWT with `flutter_secure_storage` and add it in a Dio interceptor.

## Design decisions where the mockups disagreed

- Password recovery uses the "Forgot Password" version (Image with Submit); the code screen says "Check Your Email".
- "Correction Details" in the mockups showed leave data; it is built as the correction request list with an extra **All** tab.
- The leave details screen is read-only with **Cancel Request** while pending (the mockup had a stray "Submit Request" button).
- Bottom-nav highlight follows the current tab on every screen.
- Admin/HOD logins have no "Create One" link; employees register themselves, admins add everyone else.
- Late is amber everywhere. "New request" notifications use neutral icons, green/red are reserved for decisions.
- Dates are real (today), not the April/September 2025 placeholders.
- Settings sub-screens (notifications, privacy, help...) had no designs and are minimal.
