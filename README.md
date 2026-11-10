# Safro - passenger app (Flutter + Firebase)

Safe rides, by women, for women. This package is the **passenger app** built to your
screen descriptions and the Developer Brief (sections 3, 5 and 8). Backend = Firebase
Auth (phone) + Cloud Firestore.

> Written without a Flutter SDK available, so it has **not been compiled or run yet**.
> Expect to fix a few small compile or version issues on first `flutter run`.

## 1. Create the platform folders
    ./setup.sh          (Windows: setup.bat)
This runs `flutter create` for android/ios and keeps all the Safro code in `lib/`.

## 2. Firebase
1. Create a Firebase project (in your company's account - brief section 9, "Ownership").
2. Authentication > Sign-in method > enable **Phone**.
3. Firestore Database > create (production mode), then paste `firestore.rules` into Rules > Publish.
4. In this folder run:

       dart pub global activate flutterfire_cli
       flutterfire configure

   It registers the Android/iOS apps and wires up google-services.json / plist.
5. Android phone login needs your **SHA-1 and SHA-256** in Firebase project settings
   (`cd android && ./gradlew signingReport`).
6. While testing, add fixed test numbers (Authentication > Phone > "Phone numbers for testing")
   so you do not burn real SMS.

## 3. Google Maps
Enable **Maps SDK for Android** (and iOS) and **Directions API** in Google Cloud.

`android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:

    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <queries><intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="sms"/></intent></queries>

inside `<application>`:

    <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_MAPS_KEY"/>

Set `minSdk = 23` in `android/app/build.gradle(.kts)`.

iOS: add `NSLocationWhenInUseUsageDescription` to Info.plist and call
`GMSServices.provideAPIKey("YOUR_MAPS_KEY")` in AppDelegate.

## 4. Run
    flutter run --dart-define=MAPS_API_KEY=YOUR_MAPS_KEY
The dart-define key draws real road routes. Without it a straight line is drawn.

## Optional Firestore data (edit without a new release)
* `config/app`: `baseFare, perKm, perMin, minFare, acExtra, commission` (numbers)
* `drivers/{id}`: `name, plate, car, rating, trips, monthlyPrice`
If missing, built-in defaults / 3 demo drivers are used.

## Screens built (your spec)
Splash, Enter mobile (+92 default, Pakistani number check), Enter code (custom keypad,
resend timer), Home (map, locked bottom sheet, search, chips, swipeable driver cards, Safe Mode),
Trips, Plans (Meri Driver), Safety, Book a ride, Finding driver, Driver found, Driver on the way
(Ride PIN, call/chat/share), Trip in progress (3-second SOS ring), SOS sent, Arriving,
Rating + receipt. One extra screen: **name + "woman 18+" confirmation** after first login
(the Home greeting needs a name; brief P1 and section 10).

## Things you should know
* **Code length is 6, not 4.** Firebase phone auth always sends 6-digit codes. Change
  `AppConfig.otpLength` to 4 only if you add your own SMS OTP service (Cloud Function + a
  Pakistani SMS provider) that mints a Firebase custom token.
* **Driver is simulated.** There is no driver app yet. `trip_simulator.dart` plays the driver
  (accepts after 4 s, drives to pickup, waits for the PIN, drives the trip). It writes the same
  trip fields a real driver app will. Turn off with `AppConfig.simulateDriver = false`.
  Before launch, restrict those fields to drivers in `firestore.rules`.
* Demo data: a new account gets contacts Ammi and Sara and 3 past trips (`seedDemoData`).
* Place coordinates in `core/constants.dart` are approximate - check them.
* Fares come from base + per km + per minute (brief P4), so they will not always show
  exactly PKR 420 / 480 as in your mock-up. Tune `config/app`.
* Calls are a placeholder message (masked calling needs a telephony backend).
  Chat works through Firestore. SOS writes to `sos_alerts` and falls back to SMS if offline.

## Not in this package (brief items still to build)
Driver app, admin dashboard, WhatsApp bot, real payments, Urdu/RTL, selfie check,
route-deviation / long-stop alerts (S4, S5), contact SMS/WhatsApp links (S3, S13),
masked calls (S10), scheduled-ride reminders.
