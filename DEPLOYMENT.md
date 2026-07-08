# Deployment Guide — `smart-odsc-queue`

This is the end-to-end "ship to a kiosk" runbook. It covers (1) the
one-time keystore generation, (2) building a production APK,
(3) uploading the APK, (4) the backend env update that flips kiosks
onto the new build, and (5) the kiosk first-time provisioning that an
IT engineer does once per device.

---

## 0. Prerequisites — one-time setup

### 0.1 Generate the release keystore

Run from the `android/` folder. The keystore signs every APK that
ever ships under the same package ID, so **losing it means you can
never publish an upgrade to the same kiosks again** without
uninstalling all of them. Back it up off-repo.

```bash
cd android
keytool -genkey -v \
  -keystore odsc-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias odsc
```

You'll be prompted for:
- Keystore password (remember this)
- Key password (can be same as keystore)
- Distinguished name (org/country/etc — fill in real ODSC values)

The file `android/odsc-release.jks` is gitignored. Store a backup in:
- 1Password / vault entry for the org
- A second physical location (encrypted)

### 0.2 Create `android/key.properties`

```bash
cd android
cp key.properties.example key.properties
# edit key.properties, fill in real passwords
```

Gradle reads this file automatically — `signingConfig` becomes the
real release config the moment this file exists.

### 0.3 (Optional) Verify signing config

```bash
flutter build apk --release
# check that android/app/build/outputs/apk/release/app-release.apk
# is signed by your keystore, not the debug key:
keytool -printcert -jarfile android/app/build/outputs/apk/release/app-release.apk
```

---

## 1. Per-release: build the APK

### 1.1 Bump version in `pubspec.yaml`

```yaml
version: 1.0.1+3   # versionName + versionCode
```

Convention: `versionCode` matches the integer in `APP_VERSION_ANDROID_LATEST_CODE`
on the backend. Bump it on every release.

### 1.2 Build

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The default `baseUrl` baked into the APK is `https://api.odsc.gov.la`
(see `lib/app/data/constants/api_endpoints.dart`). To build against
a different host (staging, dev LAN, etc.), pass `--dart-define`:

```bash
flutter build apk --release --dart-define=BASE_URL=https://staging-api.odsc.gov.la
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 1.3 Rename + upload

```bash
# Convention matches the URL the backend hands clients:
cp build/app/outputs/flutter-apk/app-release.apk \
   smart-odsc-queue-3.apk

# Upload to the public storage host. Example using curl + the
# government storage console (replace with whatever your ops team
# actually uses):
curl -X PUT \
  -H "Authorization: Bearer $STORAGE_TOKEN" \
  --data-binary @smart-odsc-queue-3.apk \
  https://storage-console.odsc.gov.la/odsc-public-storage/apks/smart-odsc-queue-3.apk
```

### 1.4 Update backend env vars

In `smart-odsc-master-data` production env:

```env
APP_VERSION_ANDROID_MIN_CODE=3
APP_VERSION_ANDROID_LATEST_CODE=3
APP_VERSION_ANDROID_LATEST_NAME=1.0.1
APP_VERSION_ANDROID_APK_URL=https://storage-console.odsc.gov.la/odsc-public-storage/apks/smart-odsc-queue-3.apk
```

Restart the master-data service. Every connected kiosk will detect
the new minimum on its next splash check (typically within an hour
of idle).

### 1.5 Verify

```bash
curl https://api.odsc.gov.la/api/v1/master-data/app-version
```

Expected payload (shape):
```json
{
  "code": "ODSC-200",
  "message": "SUCCESS",
  "data": {
    "android": {
      "minVersionCode": 3,
      "latestVersionCode": 3,
      "latestVersionName": "1.0.1",
      "apkUrl": "https://...smart-odsc-queue-3.apk"
    },
    "releaseNotes": { "lo": "...", "en": "..." }
  }
}
```

---

## 2. Rollback

A bad release can be reverted **without touching any kiosk physically**.

```env
APP_VERSION_ANDROID_MIN_CODE=2          # back to the prior code
APP_VERSION_ANDROID_LATEST_CODE=2
APP_VERSION_ANDROID_LATEST_NAME=1.0.0
APP_VERSION_ANDROID_APK_URL=https://.../smart-odsc-queue-2.apk
```

Restart master-data. Kiosks running v3 stay on v3 (Android won't
downgrade a signed APK to an older signed APK), but every kiosk that
was *about* to upgrade now stays on v2. The kiosks already on v3
keep working unless `MIN_CODE` is bumped past them.

If v3 is actively broken on field kiosks, IT has to physically visit
those kiosks, `adb uninstall com.smartodsc.smart_odsc_queue`, and
manually reinstall the v2 APK. (This is the only "we must visit each
device" scenario in the whole system.)

---

## 3. First-time kiosk provisioning (IT, once per device)

Per kiosk, an IT engineer does this **once** at device hand-out:

1. Connect device to kiosk WiFi (must reach `api.odsc.gov.la`).
2. Sideload the APK:
   ```bash
   adb install smart-odsc-queue-<latest>.apk
   ```
   or copy the APK to a USB stick, plug into the kiosk, open the
   APK file in the file manager.
3. Open Android Settings → Apps → Special app access → "Install
   unknown apps" → ODSC Queue → toggle **Allow from this source**.
4. Launch the app. Verify it reaches the login screen (or the
   force-update screen if the device is already behind).

After this, the device is fully OTA-capable. Every subsequent
update happens via the force-update flow without IT touching the
device again.

---

## 4. Pre-release checklist

Quick sanity sweep before publishing:

- [ ] `pubspec.yaml` `version` bumped (both name + `+code`)
- [ ] `key.properties` exists locally and points at the real keystore
- [ ] `keytool -printcert -jarfile app-release.apk` shows the
      production cert, NOT the debug cert
- [ ] APK installed cleanly over a previous release on a real
      kiosk (no signature mismatch)
- [ ] Manual smoke test:
  - Cold boot → splash → login renders
  - Login → kiosk view renders
  - Backend env briefly bumped to `MIN_CODE = LATEST_CODE+1` →
    force-update screen appears → tap Update → progress bar runs
    → install dialog pops → install completes → app relaunches at
    the new build
- [ ] Token logging in `http_interceptors.dart` is at preview-only
      (8-char prefix), not full token (already done — re-check
      before each release)
- [ ] `android/app/src/main/AndroidManifest.xml` does NOT have
      `android:usesCleartextTraffic="true"` (or, if it does, every
      backend URL the app talks to is HTTPS so the setting is moot)

---

## 5. Reference: things that broke during initial bring-up

Recorded here so they don't bite the next person.

### 5.1 `Get.lazyPut` for splash / force-update controllers
Symptom: app frozen on logo splash forever; force-update button
does nothing. Cause: GetView's lazy factory only fires when the
view's `build` reads `controller`. Force-update accessed it;
splash did not. **Fix: use `Get.put` (eager) for any binding whose
controller side-effects the boot path or owns a user action.**

### 5.2 ota_update install fails with signature mismatch
Symptom: download succeeds, install dialog opens, then "App not
installed" toast. Cause: previous build was debug-signed; new build
is release-signed (or vice versa). **Fix: always sign release with
the same keystore; debug builds can only OTA-update other debug
builds.**

### 5.3 Bluetooth printer reconnect stalls the platform-channel queue
Symptom: `PackageInfo.fromPlatform()` takes 30+ seconds at cold
start when the previously-paired printer is out of range. Cause:
`blue_thermal_printer.connect()` blocks the AsyncTask SerialExecutor
that several plugins share. **Fix already in place:** the version
check wraps `PackageInfo.fromPlatform()` in a 3-second `.timeout()`,
and the splash fails open on any exception.

### 5.4 "Install unknown apps" toggle is per-source
Symptom: ota_update install dialog says "your phone currently isn't
allowed to install unknown apps from this source." Cause: Android
8+ requires per-app permission, granted at Settings → Apps →
Special app access. **Fix: covered in §3 above; IT must do this
during first-time provisioning.**
