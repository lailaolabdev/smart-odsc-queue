# smart-odsc-queue — CLAUDE.md

## Overview
Flutter kiosk application for queue ticket issuance at Lao government One-Door Service Centers (Smart ODSC — ບໍລິການປະຕູດຽວຂອງລັດຖະບານ ສປປ ລາວ). Citizens walk up to a touch-screen kiosk, answer a few questions, and receive a printed queue ticket with a QR code for status tracking.

**Version:** 1.0.0+1 | **Dart SDK:** ^3.11.1 | **Flutter targets:** Android, iOS, Web

---

## Architecture

**Pattern:** GetX MVC — each module has `views/`, `controllers/`, `bindings/`.

```
lib/
├── main.dart                         # App entry point, kiosk full-screen mode
└── app/
    ├── routes/
    │   ├── app_routes.dart           # Route name constants
    │   └── app_pages.dart            # GetPage route definitions
    ├── data/
    │   ├── api_helper/
    │   │   ├── api_service.dart      # HelpersApi singleton (http_interceptor)
    │   │   └── jwt_helper.dart       # JWT decode & storage utilities
    │   ├── constants/
    │   │   └── api_endpoints.dart    # All API URLs + HTTP status codes
    │   ├── interceptors/
    │   │   └── http_interceptors.dart # Auth, Logging, Error, Cache interceptors
    │   ├── models/
    │   │   └── user_model.dart       # UserModel (id, officerProfile, tokens)
    │   └── repositories/
    │       └── auth_repository.dart
    ├── modules/
    │   ├── kiosk/    # Main kiosk flow (core module)
    │   ├── home/     # Home screen
    │   ├── login/    # Officer login
    │   ├── printer/  # Bluetooth printer settings
    │   └── profile/  # Officer profile
    └── shared/
        ├── constants/app_constants.dart  # ColorConstants, AppConstants, StorageKeys
        ├── services/printer_service.dart # BlueThermalPrinter wrapper (GetxService)
        ├── utils/
        │   ├── error_handler.dart
        │   ├── logger.dart               # AppLogger (talker_flutter)
        │   └── secure_storage_service.dart
        └── widgets/
            ├── custom_dialog.dart        # showLoading / showError / hideLoading
            └── printable_ticket.dart     # Thermal ticket widget (screenshot→print)
```

---

## Kiosk Flow (KioskController steps)

| Step | Screen | Description |
|------|--------|-------------|
| 0 | Printer Setup | Connect Bluetooth printer before starting |
| 1 | Welcome | 3 buttons: ຄຳຕິຊົມ (Feedback), **ກົດບັດຄິວ** (Queue), ລາຍການບໍລິການ (Services) |
| 2 | Gender | MALE / FEMALE / OTHER |
| 3 | Age Range | AGE_0_12 → AGE_60_UP (6 options, 2-column grid) |
| 4 | Disability | ບໍ່ພິການ (big green) / ພິການ (subtle orange) |
| 5 | Visit Purpose | INQUIRY / SERVICE / CERTIFICATION |
| 6 | Service Choice | Select service now, or skip |
| 7 | Service List | Searchable grid; selecting calls `submitBooking()` |
| 8 | Ticket Result | Shows queue number + QR code; auto-prints; 60 s timer then reset |
| 9 | Service Directory | Same service list but view-only (no booking) |
| 10 | Feedback | 5-emoji rating; rating > 1 auto-submits; rating = 1 shows comment field |

**Navigation rules:**
- Back from step 8, 9, or 10 → `resetBooking()` (returns to step 1)
- `resetBooking()` clears all booking state and cancels the timer
- Hidden admin tap: top-right 100×100 area, 5 taps within 2 s → navigates to `/printer`

---

## API

**Base URL:** `https://api.odsc.gov.la`

| Endpoint | Method | Usage |
|----------|--------|-------|
| `/api/v1/core/services` | GET | Fetch service list (`?status=true&search=...`) |
| `/api/v1/core/queues` | POST | Submit booking → returns `queueNumber`, `barCodeNumber` |
| `/api/v1/master-data/feedback` | POST | Submit citizen feedback |
| `/api/v1/auth/login-officer` | POST | Officer login |

**Booking payload fields:** `gender`, `ageRange`, `visitPurpose`, `serviceCenterId`, `organizationId`, `isDisabled`, `status: "WAITING"`, optional `serviceId`.

**Tracking URL pattern:** `http://odsc.gov.la/lo/queue-tracking?queueNumber=X&serviceCenterId=Y`

**HTTP client:** `HelpersApi` singleton using `http_interceptor`. Interceptors: Auth (JWT Bearer), Logging, ErrorHandling, Cache. Timeout: 30 s.

---

## Printer Integration

`PrinterService` (GetxService, registered at startup via `Get.put()`):
- Uses `blue_thermal_printer` + `esc_pos_utils_plus`
- `printLaoTextAsImage(Uint8List)` — resizes image to 512 px width, converts to ESC/POS raster, sends via Bluetooth, feeds and cuts paper
- Prints Lao text as raster image (not ESC/POS text) to avoid font encoding issues
- Selected printer persisted in `GetStorage` under key `'selected_printer'`

**Auto-print trigger:** Called automatically in `KioskController.autoPrint()` after a successful booking (step 8). Uses `ScreenshotController` to capture `PrintableTicket` widget off-screen at 3× pixel ratio.

---

## State & Storage

- **GetX Rx observables** for all reactive state in controllers
- **GetStorage** — non-sensitive data: `'user'` (officer profile + tokens), `'selected_printer'`
- **FlutterSecureStorage** — sensitive credentials
- **UserModel** fields used in booking: `officerProfile.serviceCenterId`, `officerProfile.organizations[0].organizationId`

---

## Kiosk System Setup

`main.dart` sets `SystemUiMode.immersiveSticky` for full-screen kiosk operation (no status/nav bars).

> **Dev bypass:** `main.dart` writes a mock user directly to `GetStorage` and skips login. Remove before production:
> ```dart
> // --- MOCK LOGIN BYPASS --- (lines 25–48 in main.dart)
> ```

---

## Key Packages

| Package | Purpose |
|---------|---------|
| `get ^4.6.6` | State management, routing, DI |
| `get_storage ^2.1.1` | Local key-value storage |
| `flutter_secure_storage ^10.0.0` | Secure credential storage |
| `blue_thermal_printer ^1.2.3` | Bluetooth ESC/POS printer |
| `esc_pos_utils_plus ^2.0.4` | ESC/POS raster image commands |
| `screenshot ^3.0.0` | Capture widget to bytes for printing |
| `barcode_widget ^2.0.4` | QR code display (ticket + result screen) |
| `http_interceptor ^2.0.0` | HTTP middleware (auth, logging, cache) |
| `talker_flutter ^4.6.0` | Logging (`AppLogger.info/error`) |
| `firebase_messaging ^16.1.1` | Push notifications |

---

## Colors & Theme

- **Primary:** `#3554A1` (`ColorConstants.mainCorlor`)
- **Orange accent:** `#FF6533`
- **Font:** NotoSansLao (referenced in theme, ensure it is bundled in `pubspec.yaml` fonts section)
- Material 3 with seed color `#2E5394`

---

## Assets

```
assets/images/
├── main-logo.jpg   # App logo (splash, launcher, ticket header)
├── logo.png
└── line-nam-bg.png # Background pattern (currently opacity: 0)
```

---

## Dev Commands

```bash
flutter pub get
flutter run                         # Default device
flutter run -d chrome               # Web
flutter build apk --release         # Android APK
flutter build ios --release         # iOS
```
