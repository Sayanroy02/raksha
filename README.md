# 📱 Raksha+ Mobile Client — Project Documentation

> **AI-Powered Women Safety & Real-Time Emergency Network (Flutter iOS & Android)**  
> Mobile client built with **Flutter 3**, **GetX**, **Dio**, **Flutter Map (Geoapify)**, **Ambient Audio Evidence Recording**, **Anti-Theft Fake Switch-Off Defense**, and **Proximity Danger Radar**.

---

## 📋 Table of Contents
1. [Project Overview & Key Capabilities](#-project-overview--key-capabilities)
2. [Packages, Plugins & Libraries Used](#-packages-plugins--libraries-used)
3. [Architecture & Design Patterns](#-architecture--design-patterns)
4. [Project Directory Structure](#-project-directory-structure)
5. [Key Feature Walkthrough](#-key-feature-walkthrough)
   - [1. 3-Second SOS Emergency Trigger](#1-3-second-sos-emergency-trigger)
   - [2. Ambient Microphone Audio Capture](#2-ambient-microphone-audio-capture)
   - [3. Anti-Theft Fake Switch-Off (Power Menu Defense)](#3-anti-theft-fake-switch-off-power-menu-defense)
   - [4. 4-Digit App Lock & 365-Day Session Persistence](#4-4-digit-app-lock--365-day-session-persistence)
   - [5. Proximity Danger Zone & Road Corridor Radar](#5-proximity-danger-zone--road-corridor-radar)
   - [6. Tactical Mapping & Geocoding](#6-tactical-mapping--geocoding)
   - [7. Guardian QR Pairing & Real-Time Tracker](#7-guardian-qr-pairing--real-time-tracker)
   - [8. Multi-Sensor AI Threat Monitor](#8-multi-sensor-ai-threat-monitor)
   - [9. Evidence Vault](#9-evidence-vault)
6. [Screens & Navigation Flow (Named Routes)](#-screens--navigation-flow-named-routes)
7. [Device Permissions Setup (Android & iOS)](#-device-permissions-setup-android--ios)
8. [Environment Setup & Configuration (`.env`)](#-environment-setup--configuration-env)
9. [How to Run, Build & Release](#-how-to-run-build--release)
10. [Troubleshooting & Best Practices](#-troubleshooting--best-practices)

---

## 🌟 Project Overview & Key Capabilities

Raksha+ is a mobile safety application designed to safeguard women commuters, students, and citizens. It transforms the smartphone into a personal security hub that operates reliably even during extreme distress, network drops, or attempts by attackers to tamper with the device.

### Core Highlights:
- **Instant SOS**: 3-second hold countdown to prevent accidental triggers, with instant zero-timeout GPS lock.
- **Stealth Audio Evidence**: Records ambient microphone audio during emergencies and auto-uploads to the backend.
- **Anti-Theft Fake Shutdown**: Simulates an authentic device power-off, turns the screen pitch black to fool attackers, while secretly broadcasting live GPS coordinates and recording audio.
- **Danger Road & Area Radar**: Warns users with audible vibrations when approaching unsafe roads or crime-prone dark zones marked by emergency administrators.
- **Guardian QR Pairing**: Generates a shareable QR code allowing trusted family members to track live GPS telemetry on their own phones without cumbersome logins.
- **365-Day Login Persistence & App Lock**: Long-lived JWT sessions protected by a device-level 4-digit PIN barrier.

---

## 📦 Packages, Plugins & Libraries Used

All dependencies are defined in [pubspec.yaml](file:///e:/Raksha%20Plus/raksha_client/pubspec.yaml):

| Package / Plugin | Version | Category | Role in Raksha+ |
|---|---|---|---|
| **`flutter`** | `sdk: flutter` | Core SDK | Multi-platform native framework targeting Android and iOS. |
| **`get`** | `^4.6.6` | State & Routing | Complete framework: reactive state management (`Rx`, `Obx`), declarative named routing, and dependency injection (`Get.find`). |
| **`dio`** | `^5.7.0` | Networking | Robust HTTP client featuring request/response interceptors, Bearer token injection, retry on 401, and multipart uploads. |
| **`pretty_dio_logger`** | `^1.4.0` | Network Logging | Formats and pretty-prints API requests, headers, and responses in debug console. |
| **`flutter_secure_storage`** | `^9.2.2` | Keyring Storage | Securely stores JWT access and refresh tokens using Android Keystore and iOS Keychain. |
| **`shared_preferences`** | `^2.3.3` | Local Storage | Stores non-sensitive settings (App Lock PIN, Fake Shutdown toggle, first-launch flag). |
| **`geolocator`** | `^13.0.0` | GPS & Telemetry | High-precision GPS location streaming, distance calculations, and background location tracking. |
| **`flutter_map`** | `^8.3.2` | Interactive Maps | High-performance Leaflet-compatible interactive map widget for Flutter. |
| **`latlong2`** | `^0.10.1` | Geometry / Math | Geodesic coordinate calculations, distance calculations, and polyline points. |
| **`record`** | `^7.1.2` | Audio Recording | Records ambient microphone audio to high-fidelity AAC `.m4a` files on SOS trigger. |
| **`audioplayers`** | `^6.1.0` | Audio Playback | Plays emergency sirens, alert tones, and evidence audio streams. |
| **`camera`** | `^0.11.0+2` | Device Camera | Low-latency camera viewfinder for capturing incident photo and video evidence. |
| **`image_picker`** | `^1.1.2` | Gallery & Media | Media selector for user profile avatars and evidence vault imports. |
| **`qr_flutter`** | `^4.1.0` | QR Generation | Renders cryptographically secure Guardian QR codes for safety circle pairing. |
| **`mobile_scanner`** | `^6.0.0` | QR Scanner | High-speed camera scanner to read Guardian QR codes and start tracking targets. |
| **`permission_handler`** | `^11.3.1` | Permissions | Requests and verifies runtime permissions (Location, Camera, Microphone, Storage). |
| **`google_fonts`** | `^6.2.1` | Typography | Modern typography system rendering **Poppins** across all headings and interfaces. |
| **`flutter_animate`** | `^4.5.0` | Animations | Chainable micro-animations, slide-ins, pulses, and shimmer effects. |
| **`smooth_page_indicator`** | `^1.1.0` | UI Component | Animated page dots indicator for onboarding screens. |
| **`cached_network_image`** | `^3.4.1` | Image Caching | High-speed network image caching with memory fallback and placeholder shimmers. |
| **`path_provider`** | `^2.1.4` | File System | Accesses standard file directories (`getTemporaryDirectory`, documents vault). |
| **`url_launcher`** | `^6.3.0` | External Launch | Opens native phone dialler (`tel:112`) and WhatsApp pre-filled emergency links. |
| **`intl`** | `^0.19.0` | Formatting | Date/time localization, timestamps, and currency formatting. |
| **`uuid`** | `^4.4.2` | Identifiers | Generates unique UUIDv4 tokens for incidents and evidence filenames. |
| **`flutter_dotenv`** | `^5.2.1` | Environment | Loads runtime `.env` variables (API endpoints, Geoapify keys). |

---

## 🏗️ Architecture & Design Patterns

Raksha+ follows the **GetX Architectural Pattern** separating UI, State, Services, and Networking:

```
lib/
├── app/
│   ├── bindings/             # Dependency Injection bindings initializing controllers per route
│   ├── controllers/          # Business logic, reactive state (Rx observables), and API orchestration
│   ├── models/               # Strongly-typed data models with json_serializable parsers
│   ├── routes/               # Declarative route configuration and named route constants
│   ├── services/             # Core singleton services (Storage, API, Audio, Notifications, App Lock)
│   ├── theme/                # Curated Material 3 dark theme, gradients, and typography
│   ├── utils/                # Constants, helpers, validators, and math algorithms
│   ├── views/                # Presentation layer (Widgets, views, dialogs, bottom sheets)
│   └── widgets/              # Reusable components (Bottom nav, SOS button, status pills)
└── main.dart                 # Application entry point, service initialization, orientation lock
```

### Dependency Injection Lifecycle
- Services are initialized on startup in `main.dart` or injected via `Get.lazyPut()` in `AppBindings`.
- `ApiService` is a permanent singleton holding a unified `Dio` instance with auth and logging interceptors.
- Controllers are tied to views through `GetView<Controller>` and automatically disposed when navigating away.

---

## 📂 Project Directory Structure

```
raksha_client/
├── android/                          # Android native project and Gradle files
│   └── app/src/main/
│       └── AndroidManifest.xml       # Location, Audio, Overlay, and WakeLock permissions
├── ios/                              # iOS native project and Xcode files
│   └── Runner/Info.plist             # iOS privacy descriptions and background location keys
├── assets/                           # Static bundled assets
│   ├── animations/                   # Lottie JSON animations
│   ├── icons/                        # Custom vector icons
│   ├── images/                       # Onboarding graphics & safety banners
│   └── logo/                         # Raksha+ shield badge assets
├── lib/
│   ├── app/
│   │   ├── bindings/                 # InitialBindings, HomeBinding, LocationBinding
│   │   ├── controllers/
│   │   │   ├── auth_controller.dart          # Login, Register, Profile, 365-day session
│   │   │   ├── sos_controller.dart           # SOS hold countdown, GPS broadcast, ambient audio trigger
│   │   │   ├── location_controller.dart      # Real-time GPS stream, polyline trail, danger zone checks
│   │   │   ├── contacts_controller.dart      # Safety circle management, quick dialler
│   │   │   ├── threat_controller.dart        # AI sensor evaluation & decibel monitor
│   │   │   ├── chat_controller.dart          # In-app safety queries & helpline assistant
│   │   │   └── profile_controller.dart       # User data, emergency notes, medical info
│   │   ├── models/
│   │   │   ├── user_model.dart               # User schema
│   │   │   ├── contact_model.dart            # Safety contact schema
│   │   │   ├── incident_model.dart           # Active SOS incident
│   │   │   ├── location_log_model.dart       # GPS breadcrumbs
│   │   │   └── threat_model.dart             # AI sensor readings
│   │   ├── routes/
│   │   │   ├── app_routes.dart               # Constant path names ('/home', '/live-location', etc.)
│   │   │   └── app_pages.dart                # GetPage route definitions with custom transitions
│   │   ├── services/
│   │   │   ├── api_service.dart              # Dio HTTP client, Bearer token injection, refresh retry
│   │   │   ├── storage_service.dart          # FlutterSecureStorage & SharedPreferences wrapper
│   │   │   ├── sos_service.dart              # Emergency API calls (trigger, stop, audio link)
│   │   │   ├── audio_capture_service.dart    # Ambient microphone recording on SOS & backend upload
│   │   │   ├── fake_shutdown_service.dart    # Anti-theft power menu defense & stealth GPS beacons
│   │   │   ├── app_lock_service.dart         # 4-digit PIN setup, verification, and launch barrier
│   │   │   ├── alert_notification_service.dart # Non-safe zone proximity radar & heads-up push alerts
│   │   │   ├── geoapify_service.dart         # Reverse geocoding & IP fallback lookups
│   │   │   ├── contacts_service.dart         # Contact CRUD API calls
│   │   │   └── permission_service.dart       # Runtime permissions manager
│   │   ├── theme/
│   │   │   ├── app_colors.dart               # Primary Pink `#E91E63`, Dark Card `#1E1B24`, Gradients
│   │   │   └── app_theme.dart                # Material 3 Dark theme configuration
│   │   ├── utils/
│   │   │   └── constants.dart                # Timeouts, endpoints, shared preferences keys
│   │   ├── views/
│   │   │   ├── splash/splash_view.dart       # Animated logo splash + PIN unlock barrier check
│   │   │   ├── onboarding/onboarding_view.dart# First launch onboarding carousel
│   │   │   ├── auth/login_view.dart          # Citizen login screen
│   │   │   ├── auth/register_view.dart       # Account registration screen
│   │   │   ├── home/home_view.dart           # Main dashboard with SOS hold trigger & quick tools
│   │   │   ├── location/live_location_view.dart # Tactical GPS map, breadcrumb trails, address display
│   │   │   ├── security/fake_shutdown_view.dart # Fake power menu, black screen stealth & PIN keypad
│   │   │   ├── guardian/guardian_qr_view.dart # Generates unique pairing QR code
│   │   │   ├── guardian/guardian_scanner_view.dart # Scans family QR code to start tracking
│   │   │   ├── guardian/guardian_track_view.dart # Live remote tracking dashboard for guardians
│   │   │   ├── threat/threat_detection_view.dart # Decibel meter, motion sensors, AI risk score
│   │   │   ├── evidence/evidence_view.dart   # Audio, video, and photo evidence vault
│   │   │   ├── contacts/safety_circle_view.dart # Trusted contacts management
│   │   │   ├── notifications/notifications_view.dart # Real-time emergency & danger zone alert feed
│   │   │   └── profile/profile_view.dart     # Settings, App Lock PIN, Fake Switch-off toggle
│   │   └── widgets/
│   │       ├── bottom_nav_bar.dart           # Custom floating navigation bar
│   │       ├── sos_button.dart               # Circular hold-to-activate emergency button
│   │       └── animated_badge.dart           # Pulsing live telemetry badges
│   └── main.dart                             # Flutter app entry point
├── pubspec.yaml                              # Dependencies and asset declarations
├── .env                                      # Client environment configuration
└── README.md                                 # This detailed project documentation
```

---

## ⚡ Key Feature Walkthrough

### 1. 3-Second SOS Emergency Trigger
- Located at [home_view.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/views/home/home_view.dart) and managed by [sos_controller.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/controllers/sos_controller.dart).
- **Hold Logic**: User must hold the pulsating circular SOS button for 3 seconds (`AppConstants.sosHoldDuration`). A smooth 0–100% circular fill animation with increasing haptic pulses prevents accidental triggers.
- **Immediate Execution**:
  1. Grabs immediate GPS coordinates via `Geolocator.getCurrentPosition()`.
  2. Dispatches `POST /sos/trigger` to the backend.
  3. Sends emergency email with live map link via Resend to the safety circle.
  4. Automatically activates ambient microphone audio recording.
  5. Begins continuous location streaming every 5 seconds to `POST /sos/{incident_id}/location`.
  6. Dispatches emergency heads-up push alert notification.

### 2. Ambient Microphone Audio Capture
- Implemented in [audio_capture_service.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/services/audio_capture_service.dart).
- The moment SOS triggers, the app activates the device microphone in the background.
- Records ambient speech, background sounds, or vehicle noise to an AAC `.m4a` file (`bitRate: 128kbps`, `sampleRate: 44.1kHz`).
- When the incident concludes (or upon 20–45s auto-interval), the service automatically uploads the `.m4a` file as multipart data to `POST /sos/{incident_id}/upload-audio`.
- The audio is permanently stored in the incident dossier and made available to emergency dispatchers on the Admin panel.

### 3. Anti-Theft Fake Switch-Off (Power Menu Defense)
- Implemented in [fake_shutdown_service.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/services/fake_shutdown_service.dart) and [fake_shutdown_view.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/views/security/fake_shutdown_view.dart).
- **Scenario**: When an attacker or thief steals the phone, their first instinct is to hold the power button to switch off the device and cut off GPS tracking.
- **Defense Mechanism**:
  1. The app renders a **Hyper-Realistic OS Power Menu** mimicking native Android/iOS shutdown dialogs.
  2. When "Power off" is pressed, the screen shows a realistic "Shutting down..." spinning wheel with heavy haptic vibration.
  3. The screen turns **completely pitch black** (`Colors.black`, brightness minimized, status bars hidden). To an attacker, the phone appears powered off and dead.
  4. **Stealth Defense Active**: The phone is secretly running! It silently transmits real-time GPS coordinates every 15 seconds to the backend and covertly records ambient audio.
  5. **PIN Wake-Up**: When the owner taps the black screen, a stealth PIN unlock keypad appears. Entering the user's secret Raksha PIN unlocks the phone. Entering an incorrect PIN returns the display to pitch black.

### 4. 4-Digit App Lock & 365-Day Session Persistence
- Implemented in [app_lock_service.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/services/app_lock_service.dart).
- **365-Day Session**: Tokens are configured with 365-day lifetimes in backend. In [api_service.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/services/api_service.dart), the refresh interceptor handles silent token renewal by passing `{ "refresh_token": token }` in the JSON body, preventing frequent logouts.
- **PIN Barrier**: Users can configure a 4-digit PIN under **Profile -> App Lock & PIN Security**.
- Whenever the app launches from a cold start or resumes, [splash_view.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/views/splash/splash_view.dart) presents the security barrier to protect emergency contacts and evidence.

### 5. Proximity Danger Zone & Road Corridor Radar
- Implemented in [alert_notification_service.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/services/alert_notification_service.dart).
- Fetches active danger zones marked by administrators from `GET /places/danger-zones`.
- Supports two danger zone geometry types:
  - **🔘 Circle Areas**: Computes haversine distance to zone center. Alerts if within `radius + 120m`.
  - **🛣️ Road / Path Line Corridors**: Uses perpendicular segment projection (`_distanceToPolyline`) to calculate the exact distance from the user's GPS position to the road line. Alerts if within `220m` of the hazardous corridor.
- Dispatches high-priority audible/vibrating heads-up warning banners with detour advisories:  
  `⚠️ UNSAFE ROAD ALERT (180m away) — Unlit Canal Road: Poor visibility, zero pedestrians. Stay in well-lit areas.`

### 6. Tactical Mapping & Geocoding
- Located in [live_location_view.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/views/location/live_location_view.dart).
- Uses `flutter_map` with CartoDB Voyager / Geoapify raster tiles.
- Draws real-time breadcrumb polyline paths showing user travel movements.
- Live reverse geocoding via Geoapify API resolves raw GPS coordinates into human-readable street names and locality details.

### 7. Guardian QR Pairing & Real-Time Tracker
- Located in [guardian_qr_view.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/views/guardian/guardian_qr_view.dart) and [guardian_scanner_view.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/views/guardian/guardian_scanner_view.dart).
- The user displays their Guardian QR code.
- A family member or trusted friend scans the QR using their Raksha+ app.
- Immediately connects to `GET /sos/track/{target_id}`, opening a dedicated Guardian Tracking Dashboard that shows the user's live position, battery level, emergency status, and audio monitor without requiring account logins.

### 8. Multi-Sensor AI Threat Monitor
- Located in [threat_detection_view.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/views/threat/threat_detection_view.dart).
- Continuous background monitoring of:
  - Accelerometer jerk motion (struggle or running detection)
  - Microphone decibel meter (screams or distress noises)
  - Circadian risk factor (late night hours 23:00 - 04:00)
- Communicates with backend `POST /threat/evaluate` to generate a real-time Threat Probability Index.

### 9. Evidence Vault
- Located in [evidence_view.dart](file:///e:/Raksha%20Plus/raksha_client/lib/app/views/evidence/evidence_view.dart).
- Captures and stores time-stamped incident evidence (photos, video clips, and audio files).
- Directly encrypted and linked to incident IDs for legal admissibility and police dispatch dockets.

---

## 🗺️ Screens & Navigation Flow (Named Routes)

| Route Path | View Component | Description |
|---|---|---|
| `AppRoutes.splash` (`/`) | `SplashView` | Shield animation, token check & PIN unlock barrier |
| `AppRoutes.onboarding` (`/onboarding`) | `OnboardingView` | First-launch feature introduction & permissions guide |
| `AppRoutes.login` (`/login`) | `LoginView` | Citizen authentication with email and password |
| `AppRoutes.register` (`/register`) | `RegisterView` | New user onboarding with blood group & emergency info |
| `AppRoutes.home` (`/home`) | `HomeView` | Primary dashboard with 3-second hold SOS button |
| `AppRoutes.liveLocation` (`/live-location`)| `LiveLocationView` | Fullscreen tactical map, live breadcrumbs & address |
| `AppRoutes.threatDetection` (`/threat-detection`)| `ThreatDetectionView`| AI sensor telemetry, decibel monitor & threat score |
| `AppRoutes.evidence` (`/evidence`) | `EvidenceView` | Media vault with recorded audio, photos & videos |
| `AppRoutes.safetyCircle` (`/safety-circle`)| `SafetyCircleView` | Emergency contacts, priority toggles & quick dialler |
| `AppRoutes.guardianQr` (`/guardian-qr`) | `GuardianQrView` | Generates shareable QR code for remote tracking |
| `AppRoutes.guardianScanner` (`/guardian-scanner`)| `GuardianScannerView` | Camera scanner to pair with another user's device |
| `AppRoutes.guardianTrack` (`/guardian-track`)| `GuardianTrackView` | Remote live tracking dashboard for guardians |
| `AppRoutes.notifications` (`/notifications`)| `NotificationsView` | Feed of emergency dispatches & danger zone warnings |
| `AppRoutes.profile` (`/profile`) | `ProfileView` | User details, App Lock PIN, and Fake Switch-Off settings |
| `AppRoutes.personalInfo` (`/personal-info`)| `PersonalInfoView` | Edit blood group, home address & medical notes |

---

## 🔒 Device Permissions Setup (Android & iOS)

### Android ([android/app/src/main/AndroidManifest.xml](file:///e:/Raksha%20Plus/raksha_client/android/app/src/main/AndroidManifest.xml))
```xml
<!-- Network & Internet -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- High Precision & Background Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

<!-- Camera & Microphone -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<!-- Foreground Service for Continuous SOS Tracking -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>

<!-- Anti-Theft Fake Shutdown & Stealth Overlay -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.DISABLE_KEYGUARD"/>

<!-- Emergency Dialler & Haptics -->
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### iOS ([ios/Runner/Info.plist](file:///e:/Raksha%20Plus/raksha_client/ios/Runner/Info.plist))
```xml
<!-- Location Permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Raksha+ requires location access to share your live GPS coordinates with emergency services during an SOS.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Raksha+ requires background location access to broadcast your coordinates continuously during an active emergency.</string>

<!-- Hardware & Media Permissions -->
<key>NSCameraUsageDescription</key>
<string>Raksha+ requires camera access to capture incident evidence and scan Guardian QR codes.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Raksha+ uses the microphone to record ambient audio evidence during emergency situations.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Raksha+ saves captured evidence files to your photo library.</string>
```

---

## ⚙️ Environment Setup & Configuration (`.env`)

In the `raksha_client/` root folder, create or modify the `.env` file:

```env
# ── API Base URLs ──
# Local development backend:
# - Android Emulator: http://10.0.2.2:8000/api/v1
# - Physical Device / iOS: http://<your-machine-ip>:8000/api/v1
LOCAL_API_BASE_URL=http://10.0.2.2:8000/api/v1

# Production backend URL:
PROD_API_BASE_URL=https://raksha-plus.onrender.com/api/v1

# Set to true for production server, false for local server
USE_PRODUCTION=false

# ── Geolocation & Maps API Keys ──
GEOAPIFY_API_KEY_GEOLOCATOR=your_geoapify_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_key_here
```

---

## 🚀 How to Run, Build & Release

### 1. Prerequisites
- **Flutter SDK**: `>= 3.0.0 < 4.0.0` (Recommended: Flutter 3.24+)
- **Dart SDK**: Included with Flutter
- **Android Studio / Xcode**: For Android and iOS emulators and device drivers

### 2. Install Dependencies
```bash
cd "e:/Raksha Plus/raksha_client"
flutter pub get
```

### 3. Verify Code Quality & Static Analysis
```bash
flutter analyze
```
*Should complete with `No issues found!`*

### 4. Run on Connected Device / Emulator
```bash
# Run with local development backend
flutter run

# Run specifying device
flutter devices
flutter run -d <device-id>
```

### 5. Build for Production

#### Build Android APK (Release):
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Build Android App Bundle (Google Play):
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Build iOS Bundle (Xcode):
```bash
flutter build ios --release
```

---

## 🛠️ Troubleshooting & Best Practices

1. **Microphone Permission Denied**:
   - Ensure you tap "Allow While Using App" when prompted on first SOS trigger. On Android, you can also manually grant microphone access under `Settings -> Apps -> Raksha+ -> Permissions`.
2. **Background Location on Android 13+**:
   - Choose **"Allow all the time"** in system settings so the app can continuously beacon coordinates even when the screen is turned off or in stealth Fake Switch-Off mode.
3. **Connecting Android Emulator to Local Server**:
   - The Android Emulator routes `localhost` to `10.0.2.2`. Verify that `LOCAL_API_BASE_URL=http://10.0.2.2:8000/api/v1` in `.env`.
4. **Testing Fake Switch-Off Safely**:
   - Navigate to **Profile -> Anti-Theft Fake Switch-Off** and tap **"Test Fake Switch-Off Now"**. To exit stealth mode at any time, tap the screen and enter your 4-digit PIN.

---

*Raksha+ Mobile Client is engineered to provide women and citizens with dependable safety surveillance, seamless emergency response, and peace of mind.*
