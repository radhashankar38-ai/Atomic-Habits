# Privacy Policy for Atomic-Habits

**Effective Date:** November 28, 2026  
**App Name:** Atomic-Habits  
**Package Name:** `com.atomichabits.atomic_habits`  
**Developer:** `saisriram Sr`  
**Contact Email:** `srsaisriram@gmail.com`  
**Source Repository:** https://github.com/radhashankar38-ai/Atomic-Habits

---

## 1. Overview
Atomic-Habits is an offline-first habit tracker, daily checklist, analytics tool, and home-screen widget companion. We respect your privacy and do **not** require user accounts, collect personal telemetry, run advertising SDKs, or sell any user data.

## 2. Information Stored Locally on Your Device
All application data you create inside Atomic-Habits is stored strictly **locally on your device** via Android `SharedPreferences`:
- Your optional display name (used only for in-app greetings and completion certificates)
- Habit names, target day goals, categories, completion timestamps, and reflection notes
- To-Do checklist items and optional reminder times
- Notification customization settings (daily frequency, alert timings, habit/task alert toggles) and haptic settings
- Cached Daily Motivation quote for offline viewing and Android home-screen widget synchronization

You can export or delete all local app data at any time inside **Settings** (`Clear Data`, or JSON backup export/import).

## 3. Permissions Used
- **Internet (`android.permission.INTERNET`):** Used optionally to fetch a Daily Motivation quote (`https://dummyjson.com/quotes/random`) and load typography fonts (`Inter` / `JetBrains Mono`) when online. Built-in public-domain fallback quotes work offline with zero network calls.
- **Notifications (`android.permission.POST_NOTIFICATIONS` on Android 13+):** Used strictly to display local habit check-ins, To-Do summaries, and task time reminders you configure in Settings.
- **Run at Startup (`android.permission.RECEIVE_BOOT_COMPLETED`):** Used strictly to re-schedule your configured local `AlarmManager` reminder notifications and refresh home-screen widgets after a device reboot.

## 4. Third-Party Services & Payments
- Atomic-Habits contains **no analytics trackers**, **no ad networks**, and **no Google Play Services / Firebase SDKs**.
- The **Support Developer** option in Settings shows a static local UPI/GPay QR image (`assets/images/gpay_qr.png`). Any voluntary contribution takes place outside Atomic-Habits in your chosen UPI payment app; Atomic-Habits never collects or processes financial or card details.

## 5. Children's Privacy
Atomic-Habits does not knowingly collect personal information from anyone, including children under 13.

## 6. Changes to This Policy
Updates to this Privacy Policy will be posted directly in this document inside the official repository.

## 7. Contact
If you have questions about privacy or app ownership verification, contact:
- **Email:** `srsaisriram@gmail.com`
- **GitHub:** https://github.com/radhashankar38-ai/Atomic-Habits
