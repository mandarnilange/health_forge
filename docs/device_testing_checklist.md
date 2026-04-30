# Device Testing Checklist

## 1. Prerequisites

| Requirement | Version / Notes |
|---|---|
| Xcode | 16.0+ (macOS Sequoia recommended) |
| Android Studio | Hedgehog (2023.1.1) or later |
| Flutter SDK | 3.27.0+ |
| Dart SDK | 3.6.0+ |
| Physical iOS device | Recommended — HealthKit not available in Simulator |
| Physical Android device | Recommended — Health Connect has limited emulator support |
| Oura developer account | Register at [cloud.ouraring.com](https://cloud.ouraring.com) |
| Apple Developer membership | Required for HealthKit entitlements on device |

## 2. iOS / HealthKit Setup

### Entitlements

Add the HealthKit entitlement to your Xcode project:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target > **Signing & Capabilities**.
3. Click **+ Capability** > search **HealthKit** > add it.
4. Ensure `HealthKit` appears in `Runner.entitlements`:

```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

### Info.plist Keys

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Health Forge needs read access to your health data to display metrics.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Health Forge needs write access to store health records.</string>
```

### Adding Test Data in Simulator

> HealthKit is **not available** on the iOS Simulator. Use a physical device or the Health app on a paired Apple Watch Simulator.

On a physical device:

1. Open the **Health** app.
2. Tap **Browse** > select a category (e.g., Heart).
3. Tap a metric (e.g., Heart Rate) > **Add Data**.
4. Enter a value and timestamp > **Add**.

Repeat for: steps, sleep, blood oxygen, weight, and other metrics under test.

## 3. Android / Health Connect Setup

### AndroidManifest.xml Permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.READ_SLEEP" />
<uses-permission android:name="android.permission.health.READ_BLOOD_GLUCOSE" />
<uses-permission android:name="android.permission.health.READ_BLOOD_PRESSURE" />
<uses-permission android:name="android.permission.health.READ_BODY_FAT" />
<uses-permission android:name="android.permission.health.READ_WEIGHT" />
<uses-permission android:name="android.permission.health.READ_OXYGEN_SATURATION" />
<uses-permission android:name="android.permission.health.READ_RESPIRATORY_RATE" />
<uses-permission android:name="android.permission.health.READ_DISTANCE" />
<uses-permission android:name="android.permission.health.READ_TOTAL_CALORIES_BURNED" />
<uses-permission android:name="android.permission.health.READ_ELEVATION_GAINED" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE_VARIABILITY" />
<uses-permission android:name="android.permission.health.READ_RESTING_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_EXERCISE" />
```

Also add the Health Connect intent filter inside `<activity>`:

```xml
<intent-filter>
    <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
</intent-filter>
```

### Health Connect App Installation

- Android 14+: Health Connect is bundled with the OS.
- Android 13: Install **Health Connect by Google** from the Play Store.
- Emulator: Install the Health Connect APK manually via `adb install`.

### Adding Test Data

1. Open the **Health Connect** app on the device.
2. Tap **Data and access** > select a data type.
3. Tap **Add an entry** and fill in values.
4. Alternatively, use the Health Connect Toolbox app for bulk test data.

## 4. Oura Setup

### Developer Portal

1. Go to [cloud.ouraring.com](https://cloud.ouraring.com) and sign in.
2. Navigate to **My Applications** in the left sidebar.

### Creating an OAuth App

1. Click **Create New Application**.
2. Fill in:
   - **App Name**: `Health Forge Dev`
   - **Description**: Development testing for Health Forge
   - **Redirect URI**: `com.healthforge.app://oauth/callback`
   - **Scopes**: Select all read scopes (daily, heartrate, personal, session, sleep, workout)
3. Save and note the **Client ID** and **Client Secret**.

### Redirect URI Configuration

- For iOS: Add the custom URL scheme `com.healthforge.app` to `Info.plist` under `CFBundleURLSchemes`.
- For Android: Add an intent filter for the scheme in `AndroidManifest.xml`.

### Test Credentials

- Use a personal Oura account with an active ring for realistic data.
- For CI, create a **Personal Access Token** under the developer portal for non-interactive testing.

## 5. Auth Flow Testing

### Apple HealthKit

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `auth.authorize(DataProvider.apple)` | iOS permission dialog appears |
| 2 | Grant all requested permissions | `AuthResult.isSuccess == true` |
| 3 | Call `auth.isAuthorized(DataProvider.apple)` | Returns `true` |
| 4 | Deny all permissions in the dialog | `AuthResult.status == AuthStatus.disconnected` |
| 5 | Revoke permissions in Settings > Health > Data Access | Next fetch returns empty or triggers re-auth |

### Google Health Connect

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `auth.authorize(DataProvider.googleHealthConnect)` | Health Connect permission screen appears |
| 2 | Grant all requested permissions | `AuthResult.isSuccess == true` |
| 3 | Call `auth.isAuthorized(DataProvider.googleHealthConnect)` | Returns `true` |
| 4 | Deny permissions | `AuthResult.status == AuthStatus.disconnected` |
| 5 | Revoke in Settings > Health Connect > App permissions | Next fetch returns empty |

### Oura

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `auth.authorize(DataProvider.oura)` | OAuth browser flow opens |
| 2 | Sign in and authorize | Redirect fires, `AuthResult.isSuccess == true` |
| 3 | Call `auth.isAuthorized(DataProvider.oura)` | Returns `true` |
| 4 | Cancel the OAuth flow | `AuthResult.status == AuthStatus.disconnected` |
| 5 | Wait for token to expire (or shorten TTL) | `AuthResult.status == AuthStatus.expired`, refresh triggers |
| 6 | Revoke access at cloud.ouraring.com | Next API call returns 401, triggers re-auth |

## 6. Data Verification Matrix

Test each metric type per provider. Mark `[x]` when verified.

| MetricType | Apple | GHC | Oura |
|---|---|---|---|
| `heartRate` | [ ] | [ ] | [ ] |
| `steps` | [ ] | [ ] | [ ] |
| `sleepSession` | [ ] | [ ] | [ ] |
| `hrv` | [ ] | [ ] | [ ] |
| `restingHeartRate` | [ ] | [ ] | [ ] |
| `bloodOxygen` | [ ] | [ ] | [ ] |
| `respiratoryRate` | [ ] | [ ] | N/A |
| `weight` | [ ] | [ ] | N/A |
| `bodyFat` | [ ] | [ ] | N/A |
| `bloodPressure` | [ ] | [ ] | N/A |
| `bloodGlucose` | [ ] | [ ] | N/A |
| `calories` | [ ] | [ ] | [ ] |
| `distance` | [ ] | [ ] | N/A |
| `elevation` | [ ] | [ ] | N/A |
| `workout` | [ ] | [ ] | N/A |
| `readiness` | N/A | N/A | [ ] |
| `stress` | N/A | N/A | [ ] |
| `recovery` | N/A | N/A | N/A |
| `sleepScore` | N/A | N/A | [ ] |

### Verification Steps Per Cell

1. Sync the metric: `client.sync(provider: ..., metric: ..., range: last7Days)`.
2. Confirm `SyncResult.recordsFetched > 0`.
3. Retrieve from cache: `client.cache.get(metric: ..., range: last7Days)`.
4. Verify record fields are populated (non-null, realistic values).
5. Verify timestamps fall within the requested range.
6. Verify `provider` field matches the expected provider.

## 7. Edge Cases

### Expired Tokens

- [ ] Oura: Force token expiry. Verify automatic refresh. Verify data fetch succeeds after refresh.
- [ ] Oura: Invalidate refresh token. Verify `AuthResult.expired()` is returned and re-auth is prompted.

### Revoked Permissions

- [ ] Apple: Revoke HealthKit permissions in Settings. Verify next fetch returns empty list (not a crash).
- [ ] GHC: Revoke Health Connect permissions. Verify graceful degradation.
- [ ] Oura: Revoke OAuth access. Verify 401 handling.

### No Data Available

- [ ] Sync a metric with no data in the time range. Verify `SyncResult.recordsFetched == 0` and no errors.
- [ ] Verify the app displays an appropriate empty state.

### Rate Limits (Oura API)

- [ ] Trigger rapid successive fetches. Verify 429 response is handled gracefully.
- [ ] Verify retry-after header is respected.
- [ ] Verify the app shows a rate-limit message (not a crash).

### Offline Mode

- [ ] Enable airplane mode. Attempt sync. Verify error result with descriptive message.
- [ ] Verify cached data is still accessible offline.
- [ ] Restore connectivity. Verify sync resumes.

### Partial Data

- [ ] Sync sleep data when only some nights have data. Verify partial results are returned.
- [ ] Sync heart rate when device was worn intermittently. Verify gaps are handled.

### Timezone Handling

- [ ] Create records in one timezone, read in another. Verify `startTime`/`endTime` are UTC-consistent.
- [ ] Verify `timezone` field is populated when the provider supplies it.
- [ ] Verify sleep sessions crossing midnight are represented correctly.

## 8. Regression Checklist

Run before each release:

### Tests

- [ ] `dart run melos run test` — all tests pass (zero failures)
- [ ] `dart run melos run analyze` — zero warnings
- [ ] `dart run melos run format` — no formatting issues

### Auth

- [ ] Apple HealthKit: authorize, verify connected status
- [ ] Google Health Connect: authorize, verify connected status
- [ ] Oura: OAuth flow completes, token stored securely

### Data Fetch

- [ ] Each provider fetches heart rate data for last 7 days
- [ ] Each provider fetches step data for last 7 days
- [ ] Each provider fetches sleep data for last 7 days
- [ ] Verify all fetched records have valid IDs, timestamps, and values

### Merge / Deduplication

- [ ] Sync same metric from two providers. Verify `MergeEngine` produces deduplicated results.
- [ ] Verify `DuplicateDetector` correctly identifies overlapping records.
- [ ] Verify conflict resolution strategy is applied (priority-based by default).

### Cache

- [ ] Sync data. Kill app. Relaunch. Verify cached data is accessible.
- [ ] Clear cache. Verify data is gone. Re-sync. Verify data is restored.
- [ ] Verify `lastSyncTime` is updated after each sync.

### Cross-Provider

- [ ] Fetch steps from Apple and GHC. Verify merged view contains both sources.
- [ ] Fetch sleep from Apple and Oura. Verify extensions are preserved per provider.
- [ ] Verify `provider` field on each record correctly identifies its source.
