# Smart ODSC Queue — Project Reference

> เอกสารสรุป project สำหรับ Claude (และ developer) ใช้เป็น context หลักเวลาทำงานในโปรเจคนี้

---

## 1. ภาพรวม (Overview)

**Smart ODSC Queue** = Flutter **kiosk app** (touch screen) สำหรับศูนย์บริการประตูเดียว (One-Door Service Center, ODSC) ของรัฐบาลลาว ติดตั้งที่หน้าศูนย์บริการ ให้ประชาชนกดออก **บัตรคิว** (queue ticket) แล้วพิมพ์ออกมาจาก thermal printer ทันที

- **ผู้ใช้:** ประชาชนทั่วไป (จิ้มหน้าจอ) + เจ้าหน้าที่ (admin path สำหรับตั้ง printer)
- **ภาษา UI:** ລາວ (default) + English — toggle ได้ที่มุมขวาบนหน้า welcome
- **App name:** `Smart ODSC Queue` v1.0.0(1)
- **Bundle id (pubspec):** `smart_odsc_queue`

---

## 2. Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.41.9 / Dart 3.11.5 |
| State mgmt | **GetX** (`get: ^4.6.6`) — MVC + Rx + DI + routing + i18n |
| HTTP | `http` + `http_interceptor` (Auth / Logging / Error / Cache interceptors) |
| Auth | JWT Bearer (`jwt_decoder`, `flutter_secure_storage`) |
| Local storage | `get_storage` (locale, prefs) + `flutter_secure_storage` (tokens) |
| Printing | `blue_thermal_printer` + `esc_pos_utils_plus` (Bluetooth thermal printer) |
| Other | `qr_flutter`, `barcode_widget`, `screenshot`, `lottie`, `flutter_map`, `firebase_*`, `talker_flutter` |

**Backend:** ติดต่อ `smart-odsc-core` (Node + TS + Express + Prisma + Zod + Redis) — ดู §7

---

## 3. โครงสร้างไฟล์ (Project Structure)

```
lib/
├── main.dart                      # entry — GetMaterialApp, locale boot, theme
└── app/
    ├── data/
    │   ├── api_helper/            # api_service.dart, jwt_helper.dart
    │   ├── interceptors/          # auth / logging / error / cache
    │   ├── models/                # user_model.dart + service/queue/feedback models
    │   └── repositories/          # auth_repository.dart + others
    ├── modules/                   # feature modules (GetX MVC)
    │   ├── kiosk/                 # ฟีเจอร์หลัก — queue ticket flow
    │   │   ├── bindings/
    │   │   ├── controllers/       # kiosk_controller.dart (1 controller, big)
    │   │   └── views/             # kiosk_view.dart + service_detail_page.dart
    │   ├── login/                 # admin login (staff path)
    │   ├── home/                  # admin home
    │   ├── printer/               # admin: bluetooth printer pairing
    │   └── profile/               # admin profile / logout
    ├── routes/
    │   ├── app_pages.dart         # GetPage list
    │   └── app_routes.dart        # route name constants
    ├── shared/
    │   ├── constants/             # app_constants.dart (ColorConstants, AppConstants, StorageKeys)
    │   ├── services/              # printer_service.dart (thermal print logic)
    │   ├── utils/                 # error_handler.dart
    │   └── widgets/               # custom_dialog.dart, language_switcher.dart, printable_ticket.dart
    └── translations/              # GetX Translations (ลาว + EN)
        ├── app_translations.dart  # main class, merges all
        ├── welcome_translations.dart
        ├── kiosk_translations.dart
        ├── ticket_translations.dart
        ├── feedback_translations.dart
        ├── service_translations.dart
        └── admin_translations.dart
```

**โครงสร้าง module ตาม GetX MVC convention:**
- `bindings/` — `Bindings` class สำหรับ DI (`Get.put`/`Get.lazyPut`) ผูกกับ route
- `controllers/` — business logic + Rx state (`.obs`, `RxString`, `RxInt`)
- `views/` — pure UI (`StatelessWidget` ที่อ่าน state ผ่าน `Obx()` / `GetX()`)

---

## 4. Modules

### 4.1 `kiosk/` — ฟีเจอร์หลัก (queue ticket flow)

หน้าจอเดียว (`KioskView`) แต่มี **multi-step wizard** ใน `currentStep` (RxInt) — step 0 คือ welcome, step 1+ คือ flow ออกบัตร

**Flow ออกบัตรคิว (currentStep = 1 → 9):**
1. Welcome (step 0) — ปุ่มใหญ่ 3 ปุ่ม: **ກົດບັດຄິວ** / **ໃຫ້ຂໍ້ຄິດເຫັນ** (feedback) / **ບໍລິການອື່ນໆ** (service directory)
2. Service selection — เลือกบริการ (เรียก backend `/api/v1/core/services`)
3. Gender — ຊາຍ / ຍິງ / ອື່ນໆ
4. **Ethnicity** — ລາວ / ຂະມຸ / ມົ້ງ / ອື່ນໆ ← **field ใหม่** (เพิ่ม 2026-05)
5. Age range — 6 ช่วงอายุ (0-12, 13-20, 21-35, 36-45, 46-60, 60+)
6. Disability — ມີຄວາມພິການ / ບໍ່ມີ (skip ถ้าไม่จำเป็น)
7. Visit purpose — ສອບຖາມ / ໃຊ້ບໍລິການ / ຂໍໃບຢັ້ງຢືນ
8. Confirm
9. Submit → backend POST `/api/v1/core/queues` → success → **autoPrint** ticket → result screen (queue number + QR)

**State (kiosk_controller.dart):**
```dart
final RxInt currentStep = 0.obs;
final RxString selectedService = "".obs;
final RxString gender = "".obs;
final RxString ethnicity = "".obs;        // ← เพิ่มใหม่
final RxString ageRange = "".obs;
final RxBool isDisabled = false.obs;
final RxString visitPurpose = "".obs;
// ... + queue result data
```

**Admin entry point:** กดมุมขวาบนหน้า welcome **5 ครั้งเร็วๆ** → เข้า login screen (เจ้าหน้าที่)

### 4.2 `login/` — Staff login
- เจ้าหน้าที่เท่านั้น — login เพื่อตั้ง printer / เปลี่ยน service center
- POST `/api/v1/auth/login-officer`
- เก็บ JWT ใน `flutter_secure_storage`

### 4.3 `home/` — Staff dashboard (เรียบง่าย)
- หลัง login แล้ว → ไปต่อที่ printer setup
- ปุ่ม logout / profile

### 4.4 `printer/` — Bluetooth thermal printer pairing
- ใช้ `blue_thermal_printer` package
- เจ้าหน้าที่เลือกเครื่องที่ pair ไว้แล้วใน Bluetooth settings ของ OS
- มีปุ่ม **Test Print** ทดสอบบัตรตัวอย่าง
- เลือกเครื่องแล้วเก็บ ID ไว้ใน local storage → ใช้ตอน `autoPrint()` ของ kiosk

### 4.5 `profile/` — Staff profile / logout

---

## 5. Kiosk Flow รายละเอียด (Queue Ticket)

### 5.1 Step navigation
- `nextStep()` / `prevStep()` ใน controller
- มี **skip logic** บางเงื่อนไข (เช่น step disability skip ในบางกรณี)
- Progress dots ที่ด้านบนของหน้า (`List.generate(8, ...)`)

### 5.2 Submit booking (`submitBooking()`)

```dart
POST /api/v1/core/queues
{
  "gender": "MALE",
  "ethnicity": "LAO",                  // ← LAO | KHMU | HMONG | OTHER
  "ageRange": "AGE_21_35",
  "isDisabled": false,
  "visitPurpose": "SERVICE_USAGE",
  "serviceId": "uuid-or-null",
  "serviceCenterId": "uuid"
}
```

Response → `queueNumber`, `barCodeNumber`, `createdAt` → ใช้พิมพ์บัตร

### 5.3 Auto print (`autoPrint()`)
- หลัง submit success → เรียก `PrinterService` → render `PrintableTicket` widget → screenshot → ส่ง raster bytes ไป thermal printer
- **PrintableTicket** (`lib/app/shared/widgets/printable_ticket.dart`) เป็น `StatelessWidget` ที่ออกแบบให้พิมพ์ออกหน้ากระดาษ thermal ขนาด ~58mm กว้าง

### 5.4 Reset
- หลังพิมพ์เสร็จ + แสดง result → countdown auto-reset กลับ welcome screen
- `resetBooking()` clear ทุก Rx state กลับ default

---

## 6. UI / Design

**Theme:**
- Primary: `Color(0xFF3554A1)` (navy blue) `ColorConstants.mainCorlor` [sic — typo "Corlor"]
- Light bg: `Color(0xFFE6F1FE)`
- Accent orange: `Color(0xFFFF6533)`
- Font: **NotoSansLao** (รองรับ Lao Unicode ครบ)

**Design language:**
- ปุ่มและ card ขนาดใหญ่ (touch target ≥ 100px) — เพราะเป็น kiosk
- Gradient + colored shadow บน card สวยๆ (ดู `_buildEthnicityCard` ใน `kiosk_view.dart` เป็น reference)
- Icon ขนาดใหญ่ (60-80px) + label fontSize ≥ 28
- Material 3

---

## 7. API Integration

**Backend repo:** `C:\Users\Advic\OneDrive\Desktop\ODSC\smart-odsc-core` (Node + TS + Prisma)

**Endpoints หลักที่ kiosk เรียก:**

| Method | Path | ใช้เมื่อ |
|---|---|---|
| `POST` | `/api/v1/auth/login-officer` | Staff login |
| `GET`  | `/api/v1/core/services` | โหลด list บริการ (step service selection) |
| `GET`  | `/api/v1/core/services/:id` | service detail page |
| `POST` | `/api/v1/core/queues` | สร้างบัตรคิว |
| `POST` | `/api/v1/feedback` (?) | ส่ง feedback |

**Auth:** JWT Bearer ใน `Authorization: Bearer <token>` — interceptor (`auth_interceptor.dart`) แนบให้อัตโนมัติทุก request ที่ไม่ใช่ login

**Base URL:** ดู `lib/app/data/api_helper/api_service.dart`

---

## 8. Internationalization (i18n)

เพิ่ม **2026-05-15** — รองรับ ລາວ + English

**Setup:** GetX `Translations` (ไม่ใช่ `intl` + arb)

- `lib/app/translations/app_translations.dart` = main class merges 6 sub-translation files
- `main.dart` boot: `loadPersistedLocale()` → set `Get.locale` ก่อน `runApp`
- Default locale: `lo_LA`
- Storage key: `app.locale_tag` (GetStorage)

**Toggle UI:**
- `lib/app/shared/widgets/language_switcher.dart` — pill button 2 ตัว (ລາວ / EN)
- แสดงเฉพาะ **หน้า welcome (step 0)** มุมขวาบน (top:24, right:130 — เลี่ยง admin tap zone)
- Tap → `Get.updateLocale(Locale(...))` + persist

**Translation key naming:**
- Namespaced: `welcome.queue_button`, `step.ethnicity`, `gender.male`, `ethnicity.lao`, etc.
- ใช้ `'key'.tr` (GetX extension) ในทุก widget แทน hardcoded string

**Printed ticket localization:**
- Labels (`Queue No.` / `ເລກຄິວ`) — แปลตาม locale ปัจจุบัน
- Ethnicity values — แปลตาม locale ด้วย (`LAO` → `ລາວ` หรือ `Lao`)
- **Dynamic data จาก backend** (service name, queue number) — **ไม่แปล** ใช้ตามที่ backend ส่งมา

**Translation strings ที่เดาแปล** (รอ user verify):
- "ກະຊວງ ພາຍໃນ" → "Ministry of Interior" (อาจเป็น "Ministry of Home Affairs")
- Rating labels, fee terms — ดู report flutter-engineer ใน chat history

---

## 9. Thermal Printer

**Hardware:** Bluetooth thermal printer (58mm) — pair กับ OS ผ่าน Bluetooth settings ก่อน แล้วเลือกใน app

**Flow:**
1. Staff login → printer screen → เลือกเครื่องที่ pair → set ใช้งาน (เก็บ device ID ใน local)
2. ตอน kiosk submit booking success → `autoPrint()`:
   - Render `PrintableTicket` widget เป็น screenshot
   - Convert เป็น raster ESC/POS commands ผ่าน `esc_pos_utils_plus`
   - ส่งไป printer ผ่าน `blue_thermal_printer`

**Ticket layout (printable_ticket.dart):**
- Header: ชื่อศูนย์บริการ + ตราหน่วยงาน
- **Queue number** ตัวใหญ่ + barcode
- Service name (box)
- Ethnicity label (เพิ่มใหม่ 2026-05) — "ຊົນເຜົ່າ: ລາວ" หรือ "Ethnicity: Lao"
- Date + Time
- Footer: "ກະລຸນາລໍຖ້າເອີ້ນຄິວ" / "Please wait to be called"
- QR code → "(Scan to Track Status)"

---

## 10. Recent Changes (Changelog)

### 2026-05-15
- **i18n setup**: เพิ่ม GetX `Translations` รองรับ ລາວ + English
- Language toggle pill บนหน้า welcome (top-right)
- Printable ticket labels + ethnicity values แปลตาม locale
- Persist locale ใน GetStorage

### Earlier (2026-05)
- **Ethnicity step**: เพิ่ม step `ຊົນເຜົ່າ` หลัง gender (ລາວ/ຂະມຸ/ມົ້ງ/ອື່ນໆ)
  - Frontend: `kiosk_controller.dart` (RxString ethnicity), `kiosk_view.dart` (_buildEthnicityStep + _buildEthnicityCard), `printable_ticket.dart` (label)
  - Backend (smart-odsc-core): `prisma/schema/queue.prisma` (field + enum), `queue.validate.ts` (Zod schema)
- **TODO**: `OTHER` ethnicity = free-text input (user พิมพ์เองว่าชนเผ่าอะไร) — เริ่ม plan แล้วยังไม่ได้ทำ
  - Backend: เพิ่ม `ethnicityOther String?` (nullable)
  - Frontend: เมื่อกด OTHER → dialog TextField → save → next
  - Printable ticket: print custom text แทน label "ອື່ນໆ"

---

## 11. ข้อห้ามสำคัญ (Constraints)

### NO DATABASE TOUCH
**ห้าม Claude (และ subagent) แตะ database ของ ODSC โดยตรงเด็ดขาด:**
- ห้ามรัน `prisma migrate dev/reset/deploy`, `prisma db push/pull`, `prisma db seed`
- ห้ามรัน `prisma generate` (user รันเอง)
- ห้าม raw SQL query ผ่าน psql/mysql
- ห้าม drop/create/alter table, delete/update rows

**เหตุผล:** DB เป็น **production data จริง** — กู้คืนไม่ได้ถ้าหลุดมือลบ

**Workflow ที่ถูก:**
- แก้ schema (`prisma/schema/*.prisma`) → save file → **บอก user ให้รันคำสั่ง prisma เอง**
- ต้อง query เพื่อ debug → ขอ user ให้ run แล้วเอาผลมา

ดูเพิ่มในหน่วยความจำ: `feedback-no-db-touch`

### ODSC Workspace (5 projects)
```
C:\Users\Advic\OneDrive\Desktop\ODSC\
├── smart-odsc-core/      # Backend API (Node + TS + Prisma) ← ใช้ทุก client
├── smart-odsc-queue/     # ตรงนี้ — Kiosk app (Flutter)
├── smart-odsc-admin/     # Admin dashboard (?)
├── smart-odsc-citizen/   # Citizen mobile app (?)
└── smart-odsc-portal/    # Web portal (?)
```

ดูเพิ่มในหน่วยความจำ: `reference-odsc-workspace`

---

## 12. วิธี run / test

```bash
# Run on connected Android device or emulator
cd C:\Users\Advic\OneDrive\Desktop\ODSC\smart-odsc-queue
flutter pub get
flutter run

# Build APK (release)
flutter build apk --release

# Build for kiosk tablet
flutter build apk --release --target-platform android-arm64
```

**Test bilingual flow:**
1. เปิด app → boot เป็น ລາວ
2. Tap **EN** มุมขวาบน → flip ทุกหน้า
3. กดบัตรคิว → เดิน flow ครบ → confirm
4. Pair printer (admin login → printer settings) → test print → verify ticket label ตรงตาม locale
5. Kill app + เปิดใหม่ → จำภาษาที่เลือก

**Admin path:**
- จาก welcome screen → tap มุมขวาบน 5 ครั้งเร็วๆ → login

---

## 13. Known Issues / TODOs

- [ ] **OTHER ethnicity = free-text** (รอทำ — ดู §10)
- [ ] Typo: `ບໍ່ສາມາ` (ขาด ດ) ใน error message — ไม่แก้เพราะอาจมีที่อื่นอ้างถึง confirm กับ user ก่อน
- [ ] Translation strings ที่เดา (Ministry name etc.) — รอ user verify
- [ ] โหมด offline กรณี backend ล่ม — ตอนนี้แค่แสดง error dialog
- [ ] Feedback flow บางจุดยังไม่มี loading state ชัดเจน

---

## 14. References ภายใน (Memory cross-links)

- `feedback-no-db-touch` — กฎห้ามแตะ DB
- `feedback-rtk-usage` — ใช้ rtk filter commands ประหยัด token
- `reference-odsc-workspace` — workspace 5 projects

อยู่ที่: `C:\Users\Advic\.claude\projects\C--Users-Advic-OneDrive-Desktop-ODSC-smart-odsc-queue\memory\`

---

*Last updated: 2026-05-15 — หลังเพิ่ม i18n*
