# M Grow 2.0

A healthy-lifestyle app for all ages (6+): calorie and macro goals, weekly meal plan, daily timetable,
free-text food and workout logging, step counting, an AI coach, allergy and medical profile,
feedback and a privacy policy. 7 languages: English, Hindi, Bengali, Tamil, Telugu, Marathi, Spanish.

IMPORTANT: this code was written without a Flutter compiler. Expect to fix a few small errors on your
first build. Run `flutter analyze` and send me any errors and I will fix them.

## 1. Run it
1. Install Flutter (free): https://docs.flutter.dev/get-started/install  (Flutter 3.22 or newer)
2. flutter create --org com.yourname --project-name m_grow m_grow_app
3. Copy `lib/`, `assets/` and `pubspec.yaml` from this folder into `m_grow_app`
   (replace the existing ones).
4. Edit `android/app/src/main/AndroidManifest.xml`:
   - Inside <manifest>, before <application>, add:

         <uses-permission android:name="android.permission.INTERNET"/>
         <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
         <queries>
           <intent>
             <action android:name="android.intent.action.SENDTO"/>
             <data android:scheme="mailto"/>
           </intent>
         </queries>

   - Set `android:label="M Grow"` on <application>.
5. flutter pub get, then flutter run

## 2. Edit `lib/config.dart`
- `feedbackEmail`: where suggestions and bug reports arrive.
- `developerName`: shown in the privacy policy.
- `aiEndpoint` and `appToken`: see the AI coach section. Leave `aiEndpoint` empty to switch the coach off.

## 3. AI coach (this part is NOT free)
The coach needs a small server so your AI key is never inside the app (apps can be unpacked and keys stolen).
`backend/worker.js` is a ready Cloudflare Worker (free hosting plan). Steps are at the top of that file.
The AI provider charges per message, so:
- set a monthly spending limit in the provider dashboard,
- bind a KV namespace named RATE to enable the per-person daily limit,
- start with the coach off if you want zero running cost. Everything else in the app works offline.

Safety built in: it is not allowed to diagnose or change medicines, teens never get weight-loss or calorie
advice, crisis words are caught on the phone before anything is sent, and under-13s cannot use the coach.

## 4. How the safety rules work
- Under 18: no weight-loss goals, no calorie deficit, no calorie add-back from exercise, 60 min activity goal.
- Adults: never more than 20% below maintenance, floor of 1500 kcal (men) / 1200 kcal (women).
- Pregnancy, kidney, heart, diabetes, eating-disorder history: no weight-loss targets.
  Eating-disorder history also hides calorie, weight and BMI numbers.
- Allergies and intolerances remove foods from the meal plan. The free-text logger does not block foods,
  so people must still read labels.

## 5. Publish on Google Play
Cost: one-time $25 developer fee.
1. Create a developer account: https://play.google.com/console
2. Create a signing key and keep it safe:
   keytool -genkey -v -keystore ~/m-grow-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mgrow
3. Wire the key in: https://docs.flutter.dev/deployment/android
4. flutter build appbundle --release
5. Upload build/app/outputs/bundle/release/app-release.aab in Play Console.
6. Required forms: store listing, privacy policy URL (host a copy of assets/privacy_policy.md as a web page,
   for example on GitHub Pages), Data safety, Health apps declaration, Content rating.
7. Target audience: because the app is for under-13s, Google's Families policy applies. Read it first:
   https://support.google.com/googleplay/android-developer/answer/9893335
   Child privacy laws (COPPA in the US, GDPR for children in the EU, India's DPDP Act) also apply. Please
   have a lawyer review the privacy policy and the child-user setup before you release publicly.
8. New personal accounts must usually run a closed test with a group of testers for some weeks first. Check
   the current rule in Play Console.

## 6. Before you launch, please check
- Have native speakers review each language file in `lib/strings_*.dart`. They are machine-written.
- Food calories are approximate averages. Have a dietitian review `foods.dart` and the safety rules.
- In the log box, food and exercise names must be typed in English letters for now. Regional-name
  support means adding names to the `aliases` in `foods.dart` and `exercises.dart`.
- Test on real phones: step counting, mailto feedback, and each language.
- Add more languages: copy `strings_en.dart` to `strings_xx.dart`, translate, register it in `l10n.dart`.
- App icon: replace with your own using the `flutter_launcher_icons` package.

## Disclaimer
General wellness guidance only, not medical advice.
