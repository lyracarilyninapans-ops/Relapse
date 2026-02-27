# relapse_flutter

A new Flutter project.

## Firebase setup

This app now initializes Firebase in `lib/main.dart`.

### 1) Create/configure Firebase project

- Create a Firebase project.
- Add Android app with package name: `com.example.relapse_flutter`.
- Enable products you need (at minimum Firestore; optionally Auth and Messaging).

### 2) Add Android Firebase config file

- Download `google-services.json` from Firebase Console.
- Place it at: `android/app/google-services.json`.

### 3) Install dependencies and run

```bash
flutter pub get
flutter run
```

If `google-services.json` is missing, Android builds will fail.

## Google Maps setup

This project already includes `google_maps_flutter`.

### 1) Create API keys in Google Cloud

- Enable **Maps SDK for Android** and **Maps SDK for iOS**.
- Create one API key for Android and one for iOS.
- Restrict each key by platform (recommended).

### 2) Android key

Add this to `android/local.properties`:

```properties
MAPS_API_KEY=YOUR_ANDROID_GOOGLE_MAPS_API_KEY
```

The Android manifest uses this automatically via `MAPS_API_KEY` placeholder.

### 3) iOS key

Edit `ios/Flutter/MapsConfig.xcconfig` and replace:

```xcconfig
MAPS_API_KEY=YOUR_IOS_GOOGLE_MAPS_API_KEY
```

The app reads this via `Info.plist` (`GMSApiKey`) and initializes `GMSServices` in `AppDelegate`.

### 4) Fetch packages and run

```bash
flutter pub get
flutter run
```

## API key security

- Keep client keys (Maps SDK) in local, platform-scoped config (`android/local.properties`, iOS xcconfig).
- Keep server-side keys (Geocoding/Places for Cloud Functions) only in Firebase Functions secrets.
- Do not commit API key values or Firebase secret files to source control.

### 5) Basic usage example

```dart
GoogleMap(
	initialCameraPosition: const CameraPosition(
		target: LatLng(37.4219999, -122.0840575),
		zoom: 14,
	),
)
```
