# 📱 Raksha+ Mobile Client — Project Documentation

> **AI-Powered Women Safety & Real-Time Emergency Network (Flutter iOS & Android)**  
> Mobile client built with **Flutter 3**, **GetX**, **Dio**, **Flutter Map (Geoapify)**, **Ambient Audio Evidence Recording**, **High Noise (>50 dB) Auto-SOS Sentinel**, **Loud Siren Alarm**, **Fake Switch Stealth Defense**, **Nearby Police & Hospital Navigation**, and **Guardian QR Pairing**.

---

## 📋 Table of Contents
1. [Project Overview & Key Capabilities](#-project-overview--key-capabilities)
2. [Packages, Plugins & Libraries Used](#-packages-plugins--libraries-used)
3. [Architecture & Design Patterns](#-architecture--design-patterns)
4. [Project Directory Structure](#-project-directory-structure)
5. [Key Feature Walkthrough](#-key-feature-walkthrough)
   - [1. 2-Second Hold SOS Emergency Trigger](#1-2-second-hold-sos-emergency-trigger)
   - [2. Ambient Microphone Audio Evidence Recording](#2-ambient-microphone-audio-evidence-recording)
   - [3. High Noise (>50 dB) Auto-SOS Sentinel](#3-high-noise-50-db-auto-sos-sentinel)
   - [4. Loud Emergency Siren Alarm](#4-loud-emergency-siren-alarm)
   - [5. Fake Switch (Stealth Power-Off Defense)](#5-fake-switch-stealth-power-off-defense)
   - [6. Admin Danger Zones & Road Corridors Radar](#6-admin-danger-zones--road-corridors-radar)
   - [7. Nearby Police Stations & Hospitals (Google Maps Navigation)](#7-nearby-police-stations--hospitals-google-maps-navigation)
   - [8. Complete Profile Suite (Personal Info, Safety Circle, QR Code)](#8-complete-profile-suite-personal-info-safety-circle-qr-code)
   - [9. Device Lock & 4-Digit PIN Security](#9-device-lock--4-digit-pin-security)
6. [Bottom Navigation Layout & Routes](#-bottom-navigation-layout--routes)
7. [Device Permissions Setup (Android & iOS)](#-device-permissions-setup-android--ios)
8. [Environment Setup & Configuration (`.env`)](#-environment-setup--configuration-env)
9. [How to Run, Build & Release](#-how-to-run-build--release)
10. [Troubleshooting & Splash Screen Resilience](#-troubleshooting--splash-screen-resilience)

---

## 🌟 Project Overview & Key Capabilities

Raksha+ is a safety application designed to safeguard women commuters, students, and citizens. It transforms the smartphone into a personal security hub that operates reliably during extreme distress, network drops, or attempts by attackers to tamper with the device.

### Core Highlights:
- **Instant SOS**: 2-second hold countdown to prevent accidental triggers, with instant zero-timeout GPS lock.
- **Continuous Ambient Audio Recording**: Captures live microphone audio in chunks and auto-uploads to backend evidence during any emergency trigger.
- **High Noise (>50 dB) Auto-SOS**: Listens for screams, shouting, or violent crashes and automatically triggers emergency SOS and siren alarm.
- **Loud Siren Alarm**: Blasts a piercing emergency siren audio stream (`emergency_siren.wav`) with synchronized heavy haptics to deter assailants, with on-screen mute control.
- **Fake Switch (Stealth)**: Disguises the phone as switched off with simulated OS shutdown animation and pitch-black screen while covertly tracking GPS and recording audio.
- **Admin Danger Zones Radar**: Real-time polling and visual rendering of admin-marked danger circles and road line corridors on the live interactive map with "Fly to" camera focus.
- **Nearby Emergency Services**: GPS proximity directory of local Police Stations and Hospitals; tapping opens Google Maps externally and begins turn-by-turn navigation.
- **Guardian QR Pairing**: Generates a shareable QR code allowing trusted family members to track live GPS telemetry on their own phones without cumbersome logins.
- **Full Profile Suite**: Personal safety information, blood group, one-tap GPS address detection, Safety Circle with offline caching, and QR pairing scanner.

---

## 📦 Packages, Plugins & Libraries Used

All dependencies are defined in [`pubspec.yaml`](./pubspec.yaml):

| Package / Plugin | Version | Category | Role in Raksha+ |
|---|---|---|---|
| **`flutter`** | `sdk: flutter` | Core SDK | Multi-platform native framework targeting Android and iOS. |
| **`get`** | `^4.6.6` | State & Routing | Complete framework: reactive state management (`Rx`, `Obx`), declarative named routing, and dependency injection (`Get.find`, `Get.lazyPut(..., fenix: true)`). |
| **`dio`** | `^5.7.0` | Networking | Robust HTTP client featuring request/response interceptors, Bearer token injection, retry on 401, and multipart uploads. |
| **`pretty_dio_logger`** | `^1.4.0` | Network Logging | Formats and pretty-prints API requests, headers, and responses in debug console. |
| **`flutter_secure_storage`** | `^9.2.2` | Keyring Storage | Securely stores JWT access and refresh tokens using Android Keystore and iOS Keychain with `resetOnError: true`. |
| **`shared_preferences`** | `^2.3.3` | Local Storage | Stores non-sensitive settings (App Lock PIN, offline contacts cache, first-launch flag). |
| **`geolocator`** | `^13.0.0` | GPS & Telemetry | High-precision GPS location streaming, distance calculations, and background location tracking. |
| **`flutter_map`** | `^8.3.2` | Interactive Maps | High-performance Leaflet-compatible interactive map widget for Flutter. |
| **`latlong2`** | `^0.10.1` | Geometry / Math | Geodesic coordinate calculations, distance calculations, and polyline points. |
| **`record`** | `^7.1.2` | Audio Recording | Records ambient microphone audio to high-fidelity AAC `.m4a` files on SOS trigger & ambient noise decibel sampling. |
| **`audioplayers`** | `^6.1.0` | Audio Playback | Plays looping emergency sirens (`emergency_siren.wav`), alert tones, and evidence audio streams. |
| **`camera`** | `^0.11.0+2` | Device Camera | Low-latency camera viewfinder for capturing incident photo and video evidence. |
| **`image_picker`** | `^1.1.2` | Gallery & Media | Media selector for user profile avatars and evidence vault imports. |
| **`qr_flutter`** | `^4.1.0` | QR Generation | Renders cryptographically secure Guardian QR codes for safety circle pairing. |
| **`mobile_scanner`** | `^6.0.0` | QR Scanner | High-speed camera scanner to read Guardian QR codes with torch toggle, camera flip, and manual entry dialog. |
| **`permission_handler`** | `^11.3.1` | Permissions | Requests and verifies runtime permissions (Location, Camera, Microphone, Storage). |
| **`local_auth`** | `^2.3.0` | Biometrics | Authenticates using device screen lock (Biometrics, PIN, Pattern, or Fingerprint). |
| **`google_fonts`** | `^6.2.1` | Typography | Modern typography system rendering **Poppins** across all headings and interfaces. |
| **`flutter_animate`** | `^4.5.0` | Animations | Chainable micro-animations, slide-ins, pulses, and shimmer effects. |
| **`smooth_page_indicator`** | `^1.1.0` | UI Component | Animated page dots indicator for onboarding screens. |
| **`cached_network_image`** | `^3.4.1` | Image Caching | High-speed network image caching with memory fallback and placeholder shimmers. |
| **`path_provider`** | `^2.1.4` | File System | Accesses standard file directories (`getTemporaryDirectory`, documents vault). |
| **`url_launcher`** | `^6.3.0` | External Launch | Opens native phone dialler (`tel:112`), external Google Maps navigation, and WhatsApp pre-filled emergency links. |
| **`intl`** | `^0.19.0` | Formatting | Date/time localization, timestamps, and currency formatting. |
| **`uuid`** | `^4.4.2` | Identifiers | Generates unique UUIDv4 tokens for incidents and evidence filenames. |
| **`flutter_dotenv`** | `^5.2.1` | Environment | Loads runtime `.env` variables (API endpoints, Geoapify keys). |

---

## 🏗️ Architecture & Design Patterns

Raksha+ follows the **GetX Architectural Pattern** separating UI, State, Services, and Networking:

```
raksha_client/
├── lib/
│   ├── app/
│   │   ├── bindings/             # Dependency Injection bindings (SplashBinding, HomeBinding, LocationBinding)
│   │   ├── controllers/          # Business logic, reactive state (Rx observables), and API orchestration
│   │   ├── models/               # Strongly-typed data models (User, Contact, LocationLog, DangerZone)
│   │   ├── routes/               # Declarative route configuration and named route constants
│   │   ├── services/             # Core services (Storage, API, Audio, Noise, Siren, App Lock, Geoapify)
│   │   ├── theme/                # Curated Material 3 dark theme, gradients, and typography
│   │   ├── utils/                # Constants, helpers, validators, and math algorithms
│   │   ├── views/                # Presentation layer (Home, Map, Nearby, Profile, Fake Shutdown, QR)
│   │   └── widgets/              # Reusable components (Bottom nav, SOS button, Tactical map, FeatureCard)
│   └── main.dart                 # Application entry point, service initialization, orientation lock
├── assets/
│   ├── animations/               # Lottie animations
│   ├── icons/                    # App icons
│   ├── images/                   # UI graphic banners
│   ├── logo/                     # Raksha+ logo assets
│   └── sounds/                   # Emergency siren sound files (emergency_siren.wav)
├── pubspec.yaml                  # Flutter dependencies & assets
└── .env                          # Mobile client environment variables
```

---

## 🎯 Key Feature Walkthrough

### 1. 2-Second Hold SOS Emergency Trigger
* Pressing the central SOS button initiates a 2-second hold animation. Releasing early cancels the countdown to eliminate false alarms.
* Once triggered, it captures instant GPS coordinates with zero timeouts, initiates real-time location broadcasting, sends emergency email alerts with live Google Maps links via Resend, and triggers automatic audio recording & siren alarm.

### 2. Ambient Microphone Audio Evidence Recording
* [`AudioCaptureService`](./lib/app/services/audio_capture_service.dart) runs automatically on SOS trigger.
* Records ambient microphone audio in continuous 15-second chunks using high-fidelity AAC encoding.
* Uploads each chunk to backend incident evidence so responders and police dispatchers can hear ambient sounds in real time.
* If network connectivity is lost, audio chunks are cached securely on the local device filesystem.

### 3. High Noise (>50 dB) Auto-SOS Sentinel
* [`NoiseDetectionService`](./lib/app/services/noise_detection_service.dart) runs continuous ambient decibel monitoring via microphone amplitude readings.
* Converts digital amplitude (dBFS) to Sound Pressure Level (SPL) decibels:
  $$\text{SPL dB} = (\text{dBFS} + 85.0)_{\text{clamped}[15, 110]}$$
* When screaming, distress shouting, or loud impact noise **exceeds 50 dB**, it automatically triggers an emergency SOS broadcast, starts audio recording, and blares the siren alarm.
* Includes an on-screen live decibel meter and a **"Test >50dB"** trigger button on the Home screen.

### 4. Loud Emergency Siren Alarm
* [`AlarmSoundService`](./lib/app/services/alarm_sound_service.dart) uses `audioplayers` to play [`assets/sounds/emergency_siren.wav`](./assets/sounds/emergency_siren.wav).
* Plays in maximum-volume loop (`ReleaseMode.loop`, volume 1.0) paired with synchronized pulsing haptic vibrations.
* Includes a prominent **"🚨 LOUD ALARM BLARING · Mute Siren"** control bar on the Home screen so the user can silence or restart the alarm at any time. Automatically stops when SOS is resolved.

### 5. Fake Switch (Stealth Power-Off Defense)
* Accessible directly from the Home screen and Profile settings via [`FakeShutdownView`](./lib/app/views/security/fake_shutdown_view.dart).
* When an attacker demands that the victim switch off their phone:
  1. The user taps **Fake Switch**, displaying a realistic simulated OS power menu ("Power off / Restart").
  2. Tapping "Power off" displays an authentic "Shutting down..." animation.
  3. The screen transitions into full pitch-black stealth mode (`immersiveSticky`), rendering the phone completely dark and unresponsive.
  4. In the background, it silently activates emergency SOS, broadcasts real-time GPS coordinates, and records ambient microphone audio.
  5. The authorized user taps the black screen to reveal a discreet 4-digit PIN pad to exit stealth mode safely.

### 6. Admin Danger Zones & Road Corridors Radar
* Danger zones marked by administrators in the web command center (circles and road line corridors) are fetched via `/api/v1/places/danger-zones`.
* Background polling automatically synchronizes newly marked zones every 15 seconds.
* Visualized on [`RakshaVisualMap`](./lib/app/widgets/raksha_visual_map.dart):
  * **Circle Zones**: Rendered with translucent danger fill, high-risk red/orange borders, and center warning icons.
  * **Road Corridors**: Rendered with bold polylines along the marked roadway and warning pins at corridor terminals.
* The Live Map features an interactive **`⚠️ X Danger Zones on Map`** chip that opens a drawer of all marked zones with descriptions and a **"Fly to"** camera button.

### 7. Nearby Police Stations & Hospitals (Google Maps Navigation)
* Accessible via the **Nearby** tab in the bottom navigation bar ([`NearbyServicesView`](./lib/app/views/nearby/nearby_services_view.dart)).
* Calculates real-time distance from the user's current GPS location to all emergency facilities.
* Filter chips: **All Services**, **🚓 Police Stations**, and **🏥 Hospitals**.
* Search bar to quickly find facilities by name or address.
* **"Open in Google Maps" Button**: Launches the official external Google Maps application (`https://www.google.com/maps/dir/?api=1&destination=LAT,LNG`) with `LaunchMode.externalApplication`, immediately setting destination coordinates and launching turn-by-turn navigation.
* **"Call" Button**: Direct dialer shortcut for immediate phone calls (`tel:112` or local police station).

### 8. Complete Profile Suite (Personal Info, Safety Circle, QR Code)
* **Personal Information ([`personal_info_view.dart`](./lib/app/views/profile/personal_info_view.dart))**: Full editing for Name, Email, Phone, Blood Group dropdown, Safe Address with one-tap Geoapify GPS detection, Guardian Phone, Police Station, Post Office, and Medical Notes. Updates both backend (`PATCH /auth/me`) and local storage.
* **My Guardian QR Code ([`guardian_qr_view.dart`](./lib/app/views/guardian/guardian_qr_view.dart))**: Generates a shareable QR code pairing the user's phone for remote live GPS tracking and audio listening.
* **Scan Guardian QR ([`guardian_scanner_view.dart`](./lib/app/views/guardian/guardian_scanner_view.dart))**: High-speed camera scanner with torch toggle, camera flip, camera error handling, and manual ID/email entry dialog.
* **Safety Circle ([`safety_circle_view.dart`](./lib/app/views/safety_circle/safety_circle_view.dart))**: Manage trusted contacts with local `SharedPreferences` persistence fallback, ensuring contacts are preserved and functional even offline.
* **Live Location ([`live_location_view.dart`](./lib/app/views/live_location/live_location_view.dart))**: Live interactive map with pinpoint accuracy, polyline breadcrumbs, danger zones overlay, and WhatsApp sharing.

### 9. Device Lock & 4-Digit PIN Security
* [`AppLockService`](./lib/app/services/app_lock_service.dart) provides device-level screen lock (Fingerprint/Biometrics or 4-digit PIN) to prevent unauthorized access to live tracking, emergency contacts, or evidence records.

---

## 🧭 Bottom Navigation Layout & Routes

The bottom navigation bar features 4 tabs:

| Index | Label | Icon | Route | View |
|---|---|---|---|---|
| **0** | **Home** | `Icons.home_rounded` | `AppRoutes.home` | Main SOS trigger, Noise Sentinel, Fake Switch card, Feature grid |
| **1** | **Map** | `Icons.map_rounded` | `AppRoutes.liveLocation` | Live GPS visual map, Danger Zones overlay, WhatsApp share |
| **2** | **Nearby** | `Icons.local_hospital_rounded` | `AppRoutes.nearbyServices` | Directory of nearby Police Stations & Hospitals with external Google Maps navigation |
| **3** | **Profile** | `Icons.person_outline_rounded` | `AppRoutes.profile` | Personal Info, App Lock, Fake Switch, Guardian QR, Safety Circle |

---

## ⚙️ Environment Setup & Configuration (`.env`)

Configure your `.env` file in the root of `raksha_client`:

```env
# Google Maps Platform API Key
GOOGLE_MAPS_API_KEY=AIzaSyAu4M-9XYXvSJ-cS-1rdT1ckbGSuHgKhwQ

# Geoapify Geolocation Services API Key
GEOAPIFY_API_KEY_GEOLOCATOR=68303e200cd24f6c95b43074c4cdf193

# Production Backend on Render
PROD_API_BASE_URL=https://raksha-plus.onrender.com/api/v1

# Local Development Backend (Android Emulator: 10.0.2.2, Web/iOS: localhost)
LOCAL_API_BASE_URL=http://10.0.2.2:8000/api/v1

# Toggle production (true) or local (false)
USE_PRODUCTION=false
```

---

## 🚀 How to Run, Build & Release

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Analyze code for static correctness
dart analyze

# 3. Run on connected device / emulator
flutter run

# 4. Build release Android APK
flutter build apk --release

# 5. Build release Android App Bundle (AAB) for Google Play Store
flutter build appbundle --release
```

---

## 🛠️ Troubleshooting & Splash Screen Resilience

### Resolved Splash Screen Hang:
* **Lazy Controllers (`fenix: true`)**: Replaced eager `Get.put()` with `Get.lazyPut(() => ..., fenix: true)` in `SplashBinding`. Zero network calls and zero GPS permission requests run on startup.
* **Resilient KeyStore Storage**: Configured `FlutterSecureStorage` with `resetOnError: true` and added a `SharedPreferences` fallback to prevent Android Keystore decryption hangs on fresh installs.
* **4.0-Second Hard Failsafe Timer**: `SplashView` includes a hard backup timer that guarantees the splash screen will dismiss and navigate to Onboarding or Login under all device conditions.
* **Interceptors Guarded**: Protected the 401 error handler in `api_service.dart` so it never redirects while the user is on the Splash or Onboarding screens.
