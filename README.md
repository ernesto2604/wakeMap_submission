# WakeMap — Location-Based Alarm and AI Travel Guide Prototype

WakeMap is a cross-platform Flutter mobile application developed as a dissertation prototype. It provides two main modes:

- **Commuter Mode**: Create location-based alarms that trigger when you arrive near a destination, using geofencing and local notifications.
- **Traveller Mode**: Interact with an AI-powered travel guide that generates personalised travel plans, which can be visualised on an interactive map with numbered stops and realistic route lines.

The app supports manual alarm creation, voice-based alarm creation (using speech-to-text and AI/NLP parsing), and AI-guided trip planning (using a Node.js backend proxy connected to the Gemini API).

---

## Quick Start (Summary)

To get WakeMap running on a new machine:

```bash
# 1. Backend
cd backend
npm install
copy .env.example .env          # Windows (PowerShell/CMD)
# cp .env.example .env           # macOS/Linux
# Then edit backend/.env and add your real GEMINI_API_KEY
npm start                        # Leave this terminal running

# 2. Flutter (open a new terminal in the project root)
flutter pub get
flutter run                      # Launches on connected emulator/device
```

See detailed instructions below for each step.

---

## Main Features

- **Location-based alarms** with configurable radius and geofencing.
- **Manual alarm creation** with destination search and map selection.
- **Voice alarm creation** using speech-to-text and AI/NLP JSON parsing.
- **Radius-based activation** that triggers local notifications when the user enters the configured radius.
- **Saved alarms** persisted locally on the device.
- **Traveller Mode AI Guide** for interactive travel plan generation and refinement.
- **AI-generated travel plans** with stops, descriptions, coordinates, duration and budget.
- **Map route visualisation** with numbered stops and realistic route lines using OSRM.

---

## Technology Stack

### Frontend (Flutter)

| Technology | Purpose |
|---|---|
| Flutter / Dart | Cross-platform mobile UI framework |
| flutter_map | OpenStreetMap-based interactive map |
| latlong2 | Geographic coordinate handling |
| geolocator | Device location tracking |
| speech_to_text | Voice input for alarm creation |
| flutter_local_notifications | Local alarm notifications |
| shared_preferences | Persistent local alarm storage |
| provider | State management |
| http | HTTP client for backend communication |
| uuid | Unique alarm identifiers |

### Backend (Node.js)

| Technology | Purpose |
|---|---|
| Node.js (≥18) | Server runtime |
| Express | HTTP framework |
| Gemini API | AI plan generation and voice transcript parsing |
| dotenv | Environment variable management |
| cors | Cross-origin request handling |

### External Services

| Service | Purpose |
|---|---|
| CartoDB Positron | Map tile provider (via OpenStreetMap) |
| Nominatim (OSM) | Geocoding / location search |
| OSRM | Route line generation between stops |
| Google Gemini API | AI plan generation, plan refinement, and voice alarm parsing |

---

## Prerequisites

Before running WakeMap, ensure you have:

- **Flutter SDK** (3.41.x or compatible, Dart SDK ≥3.11.0)
- **Node.js** (≥18) and **npm**
- **Android Studio** with an Android emulator, or a physical Android device
- **Xcode** (for iOS builds, macOS only)
- A **Gemini API key** (obtain from [Google AI Studio](https://aistudio.google.com/apikey))

---

## Backend Setup

The backend is a Node.js/Express server that proxies requests to the Gemini API. The Flutter app never holds the Gemini API key directly — only the backend does.

```bash
cd backend
npm install
```

Create your local environment file from the example:

```bash
# Windows (PowerShell or CMD):
copy .env.example .env

# macOS / Linux:
cp .env.example .env
```

Edit `backend/.env` and replace the placeholder with your real Gemini API key:

```
GEMINI_API_KEY=your_real_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash
PORT=8080
CORS_ORIGIN=*
```

> **Important**: You must obtain a Gemini API key from [Google AI Studio](https://aistudio.google.com/apikey). Without it, AI features (voice alarm parsing, travel guide) will not work, but the rest of the app (manual alarms, map, geofencing) will still function.

Start the backend:

```bash
npm start
```

Or, for development with auto-reload:

```bash
npm run dev
```

Verify the backend is running:

```bash
curl http://localhost:8080/health
```

You should see `"status":"ok"` and `"geminiConfigured":true`.

---

## Flutter Setup

Open a **new terminal** in the project root (keep the backend running in the first terminal).

```bash
flutter pub get
flutter run
```

> **Note**: `flutter pub get` must be run after extracting the project on a new machine. It downloads dependencies and regenerates tooling files (`.dart_tool/`, `.flutter-plugins`, etc.) that are not included in the submission.

### Running on Android emulator

1. Open Android Studio and launch an emulator (or connect a physical device via USB with USB debugging enabled).
2. Run:

```bash
flutter run
```

The app will auto-detect the Android emulator and use `http://10.0.2.2:8080` to reach the local backend.

### iOS-specific setup (macOS only)

```bash
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios
```

iOS notes:
- Deployment target is set to 14.0.
- Location permission is configured for "When In Use" (foreground tracking).
- If testing iOS builds that connect to a local backend, an ATS exception for `localhost` is already configured in `Info.plist`.
- `pod install` is required the first time after extracting on a new macOS machine.

---

## Backend URL Configuration

The Flutter app determines which backend URL to use automatically:

| Environment | Backend URL |
|---|---|
| Debug — Android emulator | `http://10.0.2.2:8080` |
| Debug — iOS simulator / Web / Desktop | `http://localhost:8080` |
| Release builds | `https://lastversionwakemap.onrender.com` |

This logic is in `lib/config/app_config.dart`. In most cases, you do not need to configure it manually.

If you need to override the backend URL (e.g., when testing on a physical device):

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_LOCAL_IP:8080
```

**Physical device note**: The phone and computer running the backend must be on the same local network. Use your computer's local IP address (e.g., `192.168.x.x`), not `localhost`.

---

## How to Test Commuter Mode

1. Open the app and select **Commuter Mode**.
2. Tap the **create alarm** button.
3. Enter an alarm name.
4. Search for a destination using the search bar, or tap the map to select a location.
5. Adjust the alarm radius using the slider (100–1000 metres).
6. Save the alarm.
7. Confirm the alarm appears in the **Alarms** tab.
8. To trigger the alarm in a controlled test:
   - On Android emulator: use the emulator's extended controls to set a simulated GPS location within the alarm radius.
   - On iOS simulator: use Debug → Location → Custom Location to set coordinates near the destination.
9. The app should display a local notification when the simulated location enters the configured radius.

---

## How to Test Voice Alarm Creation

1. On the alarm creation screen, tap the **microphone** button.
2. Grant microphone and speech recognition permissions when prompted.
3. Speak a voice command. Example commands:
   - `"Create an alarm for York Station with a radius of 300 metres"`
   - `"Set an alarm called University for York St John University with a 200 metre radius"`
   - `"Wake me near Leeds train station at 500 metres"`
4. The voice transcript is sent to the backend for AI parsing, which returns structured JSON (alarmName, displayLocation, geocodingQuery, radiusMeters).
5. Confirm the alarm fields are populated automatically.
6. The destination is geocoded and displayed on the map.
7. Review and edit the fields if needed.
8. Save the alarm using the existing save button.

> **Note**: If the backend is unavailable, the app falls back to local regex-based parsing (less accurate but functional without AI).

---

## How to Test Traveller Mode / AI Guide

1. Open the app and select **Traveller Mode**. If you are currently in **Commuter Mode**, tap the config button and switch to **Traveller Mode**.
2. Go to the **Guide** tab.
3. Type a request, for example: `"Plan a short walking tour of York city centre"`.
4. The AI Guide will respond conversationally. You can refine your request.
5. When ready, ask for a full plan (e.g., `"Generate the plan"`).
6. The generated plan shows numbered stops with descriptions, estimated duration and budget.
7. Use the **quick action** buttons to refine the plan (e.g., cheaper, less walking, different stops) or just type a modification.
8. Go to **Map** tab to see the route.
9. Confirm numbered stop markers and connecting route lines appear on the map.

> **Note**: If the backend or Gemini API is unavailable, the app falls back to a built-in mock guide with sample plans for demonstration purposes.

---

## Privacy and Data Handling

This artifact was developed in accordance with university research ethics requirements:

- **No audio recordings are stored.** Voice input is processed in real time by the device's speech-to-text engine and immediately discarded after transcription.
- **Voice transcripts are used temporarily** to populate alarm fields via AI parsing. They are not persisted as research data.
- **AI prompts and responses are not stored** as research data. They are used transiently during the request–response cycle.
- **No participant personal data is required** to run the app.
- **No backend logs containing private transcripts, prompts, responses, IPs or timestamps** are included in this submission.

---

## Known Limitations

- This is a **dissertation prototype** built for controlled evaluation, not a production system.
- AI features (voice alarm parsing, travel guide) require an active backend and internet connection to reach the Gemini API.
- Geocoding and route generation depend on external services (Nominatim, OSRM) and require internet access.
- Location-based alarm triggering depends on device GPS accuracy and location permission settings.
- The app was evaluated using simulated locations on **Android emulator** and **iOS simulator/physical iPhone** in controlled scenarios.
- Not intended as a commercial safety-critical navigation or alarm system.

---

## Project Structure

The submission is organised as follows:

```text
WakeMap_Submission/
├── lib/                 # Flutter/Dart application source code
├── backend/             # Node.js/Express backend for Gemini API requests
│   ├── src/             # Backend source code
│   ├── .env.example     # Safe environment variable template
│   ├── package.json     # Backend dependencies and scripts
│   └── package-lock.json
├── android/             # Android platform configuration
├── ios/                 # iOS platform configuration
├── web/                 # Web platform configuration
├── test/                # Unit/widget tests
├── assets/              # App assets and fonts
├── pubspec.yaml         # Flutter dependencies
├── pubspec.lock         # Locked Flutter dependency versions
└── README.md            # Setup and testing instructions
