# Relapse Companion App — Phone Prototype Descriptions

---

## Image 7 — Login & Registration

![Login & Registration](file:///c:/Users/hehe03/Desktop/Relapse/Relapse/Relapse%20Prototype%20-%20Phone/7.png)

This figure depicts the authentication flow of the Relapse Caregiver Companion App. The **Login Screen** (left) welcomes the returning caregiver with the Relapse logo rendered through a gradient shader and the heading "Welcome Back" with the subtitle "Sign in to continue." The form provides two input fields — **Email Address** and **Password** — each styled with a green-themed prefix icon and rounded borders. The Password field includes a visibility toggle to show or hide the entered characters. A "Forgot Password?" link is positioned below the fields, directing users to a dedicated password recovery screen. The large gradient "LOG IN" button initiates Firebase Authentication, and a "Don't have an account? Sign Up" prompt at the bottom navigates to the registration screen.

The **Sign Up Screen** (right) mirrors the login aesthetic with the same gradient Relapse logo and a "Create Your Account" title with the subtitle "Join us to get started." The registration form requires four fields: **Full Name**, **Email Address**, **Password**, and **Confirm Password**. Both password fields feature visibility toggle icons. The Password field incorporates a real-time **password strength indicator** that evaluates length, uppercase characters, digits, and symbols, displaying a color-coded progress bar (from red "Very Weak" to green "Very Strong") with a hint to "Use 8+ characters with uppercase, lowercase, number & symbol." Users must check the "I agree to the Terms of Service and Privacy Policy" checkbox — both of which are tappable links that open their respective policy dialogs — before the gradient "SIGN UP" button becomes active. An "Already have an account? Login" link at the bottom returns the user to the login screen.

---

## Image 6 — Add Patient / Device Pairing

![Add Patient / Device Pairing](file:///c:/Users/hehe03/Desktop/Relapse/Relapse/Relapse%20Prototype%20-%20Phone/6.png)

This figure illustrates the multi-step patient device pairing process in Relapse. The **Add Patient** screen is presented after the caregiver has logged in but has no patient linked. At the top, a gradient circle displays a smartwatch icon, followed by the heading "Enter Watch Code." A **Setup Instructions** card provides a four-step guide: (1) **Open Watch App** — Open the Relapse app on the patient's watch, (2) **Find the Code** — A 6-digit code will appear on the watch screen, (3) **Enter Code Below** — Type the code shown on the watch into the fields below, and (4) **Wait for Connection** — The devices will connect automatically. Each step is marked with a numbered gradient circle.

Below the instructions, the **Pairing Code** input area contains six individual digit fields enclosed in gradient-bordered boxes. The fields are interconnected so that entering a digit automatically advances focus to the next field, and pressing backspace on an empty field moves focus backward. Once all six digits are entered, the system auto-submits the code. While the system is verifying the code, a "Connecting to watch..." spinner is displayed. The "Connect Watch" call-to-action button provides a manual submission option, and a help info box at the bottom directs users to contact support at support@relapsecare.com for assistance with device pairing.

Upon successful code verification, if the caregiver already has existing patient profiles, a **"Complete Pairing"** dialog (shown on the right) appears, offering the option to either "Create New" patient profile or "Use Existing" to re-pair the watch with a previously created patient. If no existing patients are found, the flow proceeds directly to the **Patient Setup** screen, which confirms "Patient Linked Successfully!" with a success icon and the subtitle "Now let's set up their profile." The setup form includes a profile photo picker, a mandatory **Patient Name** field, an optional **Age** field, and an optional **Notes** field (up to 500 characters). The caregiver can finalize with the "Complete Setup" button or tap "Skip" to create a placeholder patient and proceed to the main dashboard immediately.

---

## Image 1 — Home Dashboard

![Home Dashboard](file:///c:/Users/hehe03/Desktop/Relapse/Relapse/Relapse%20Prototype%20-%20Phone/1.png)

This figure showcases the Relapse Home Dashboard, the central hub for the caregiver after successfully linking a patient device. The app bar displays the Relapse logo and name in a gradient style, with a profile avatar (showing the caregiver's initial) in the top right that opens a popup menu with options for **Settings**, **Profile**, and **Logout**.

The left screen shows the full dashboard view. At the top, the **Watch Status Banner** indicates the real-time connectivity state of the patient's smartwatch — in this case, "Watch Connected" with the message "Patient device is online and reporting live status." A battery status pill displays the current watch battery level (e.g., "Battery: 46%"), color-coded by charge level (green for healthy, orange for low, red for critical).

Below this, the **PATIENT OVERVIEW** section presents a gradient-bordered card containing the patient's avatar (or initials), name, last update timestamp (e.g., "37 min ago"), and a real-time **Safe Zone status badge** indicating whether the patient is "Inside Safe Zone" or "Outside Safe Zone," rendered as a color-coded pill with a gradient background.

The **Quick Stats Row** provides three metric cards showing live counts for: **Memories** (number of memory reminders created), **Activity** (total activity events for the day), and **Safe Zones** (number of configured safe zones).

The **QUICK ACTIONS** section (visible when scrolling, shown in full on the right screen) presents a 2-column grid of tappable feature cards: **Upload Memory Cues** ("Photos, Audio, Video") which navigates to the Memory Reminder list, **Set Safe Zone** ("Define Geo-Boundary") which opens the Safe Zone Configuration screen, and **Activity Monitoring** ("Location History") which switches to the Activity tab.

The bottom navigation bar provides four tabs: **Home**, **Memory**, **Safe Zone**, and **Activity**, implemented as an IndexedStack for persistent tab state.

---

## Image 2 — Create Memory Reminder

![Create Memory Reminder](file:///c:/Users/hehe03/Desktop/Relapse/Relapse/Relapse%20Prototype%20-%20Phone/2.png)

This figure details the process for a caregiver to create a location-based memory reminder using the Relapse companion app. The **"Create Memory Reminder"** screen uses a three-stage step indicator at the top: **Location**, **Name**, and **Media**, each represented by an icon within a gradient circle that progresses as steps are completed.

The left screen shows the **Location** and **Name** stages. The **Select Location** section features an integrated Google Maps interface where the caregiver can either tap directly on the map to place a marker or use the embedded search bar ("Search address or place...") at the top of the map to geocode an address. A center-on-patient FAB allows quick map recentering on the patient's live location. Below the map, a status card displays "Tap on the map to select a location" when no location is set, or shows the selected coordinates once a point is chosen. The **Memory Name** field accepts up to 25 characters with a live character counter (e.g., "0/25").

The right screen shows the **Trigger Radius** and **Media** sections. The **Trigger Radius** control displays a slider (range: 1–200 meters, default 50 meters) that defines the geo-fence boundary around the selected location; this slider is disabled until a location is selected, showing "Select a location first to set radius." The **Add Media** section explains the allowed media combinations: Photo only, Audio only, Photo + Audio, or Video only — with the constraint that Video cannot be combined with Photo or Audio. File constraints are noted: "Max 50MB per file. Audio and videos max 2 minutes." Three media cards — **Photo** ("Use alone or with Audio"), **Audio** ("Use alone or with Photo, max 2 min"), and **Video** ("Use alone only") — each have a '+' button that opens a source selection dialog (Camera or Gallery for photos/videos, file picker for audio). Media cards that conflict with the current selection are automatically disabled. The "Select a location to save" button at the bottom dynamically updates its label based on completion status (e.g., "Enter a name to save," "Add media to save," "Save Memory") and becomes active only when all three stages are fulfilled.

---

## Image 3 — Safe Zone Configuration

![Safe Zone Configuration](file:///c:/Users/hehe03/Desktop/Relapse/Relapse/Relapse%20Prototype%20-%20Phone/3.png)

This figure presents the Safe Zone Configuration screen, where the caregiver defines a geographic safety boundary for the patient. The app bar shows the title "Safe Zone Configuration" with a delete (trash) icon for removing the existing safe zone configuration.

The left screen displays the upper portion of the configuration. The **Patient Status** card at the top shows the real-time status — "Inside Safe Zone" (green with a check circle icon) or "Outside Safe Zone" (red with a warning icon). Below this, an **Offline Maps Not Configured** warning banner (amber-colored) advises the caregiver to "Download offline maps for the safe zone area to ensure the watch can navigate even without internet," with a "Setup Offline Maps" button that navigates to the offline maps download screen.

The **Google Maps** interface allows the caregiver to tap anywhere on the map to set the safe zone center, displayed with a marker. A circular overlay visually represents the configured radius boundary. A re-center FAB allows quick navigation to the patient's live position. Below the map, a card shows the selected center coordinates or prompts "Tap on the map to select safe zone center." The **Safe Zone Radius** slider (range: 1–2000 meters) lets the caregiver adjust the geo-fence boundary with the current value displayed (e.g., "Radius: 500 meters").

The right screen shows the **Safety Settings** section. The **Watch Behavior on Exit** offers three radio options: **Vibrate Only** ("Watch vibrates when leaving zone"), **Sound Alarm** ("Watch plays alarm sound"), and **Vibrate + Alarm** ("Both vibration and alarm"). These options are visually dimmed and non-interactive when the "Alert on Exit" toggle is disabled. The **Alert on Exit** toggle switch enables or disables exit notifications entirely.

The **Recent Events** section displays a chronological log of safe zone transitions, with each event showing an icon (green check for "Zone Enter," red warning triangle for "Zone Exit"), the event type label, and a formatted timestamp (e.g., "Apr 24, 3:15 AM"). The last 5 events are displayed. The "Save Safe Zone" gradient button at the bottom persists the configuration to Firestore.

---

## Image 4 — Activity Monitoring

![Activity Monitoring](file:///c:/Users/hehe03/Desktop/Relapse/Relapse/Relapse%20Prototype%20-%20Phone/4.png)

This figure details the Activity Monitoring screen, which provides the caregiver with comprehensive insight into the patient's movement and daily patterns. The app bar displays the title "Activity" with a calendar icon that opens a date range picker for custom date filtering.

The left screen shows the complete top section. A **date filter row** with four selectable chips — **Today**, **This Week**, **This Month**, and **Custom** — allows the caregiver to control the timeframe of displayed data, with the active filter highlighted using a gradient background.

The **Current Location Card** presents a live Google Maps snapshot showing the patient's latest position with a "LIVE" badge, the reverse-geocoded place name (e.g., "Tangub, Bacolod"), the last update time (e.g., "Updated 1h ago"), and a "Safe Zone" tag when the patient is within the configured boundary.

The **DAILY SUMMARY** section provides three metric cards: **Distance** (total distance traveled, e.g., "1.5 km," calculated via Haversine formula from location update records), **Time Outside** (cumulative time spent outside the safe zone, e.g., "0m"), and **Places** (distinct geographic cells visited, e.g., "8").

The middle screen continues with the **MOVEMENT PATTERN** section, displaying an hourly activity bar chart spanning 12 AM to 12 AM. Each of the 24 bars represents the normalized activity level for that hour, with gradient coloring that intensifies with higher activity. A peak indicator (e.g., "Peak: 3 AM") highlights the most active hour.

The **RECENT ACTIVITY** feed presents a chronological list of significant events, including "Memory Reminder Triggered" ("Geo-reminder activated"), "Entered Safe Zone" ("Returned to safe area"), and "Left Safe Zone" ("Exited safe area boundary"), each with a descriptive icon and timestamp.

The right screen shows the **LOCATION HISTORY** timeline, a vertical chronological feed displaying individual location updates as cards with a location pin icon, the reverse-geocoded place name (e.g., "Tangub, Bacolod"), and the recorded time (e.g., "4:31 AM"). A vertical line with dot indicators connects entries to form a visual timeline.

---

## Image 5 — Settings

![Settings](file:///c:/Users/hehe03/Desktop/Relapse/Relapse/Relapse%20Prototype%20-%20Phone/5.png)

This figure shows the Settings screen accessible from the Home Dashboard's profile menu. The screen provides application-wide configuration options organized into distinct sections.

The left screen displays the full settings layout from the top. The **Reminder Cooldown** section allows the caregiver to set the "Minimum time between memory reminder triggers" using a dropdown selector labeled "Cooldown (minutes)" with predefined options (15, 30, 45, 60, 90, 120, 180, 240 minutes). The selected cooldown value is synced to the patient's Firestore document so the WearOS watch app can enforce the same interval. The default value is 30 minutes.

The **Notifications** section contains a **Notification Sound** toggle switch ("Play sound for alerts and reminders") that enables or disables audio notifications for incoming alerts.

The **Daily Report** section provides a **Report Time** selector (displaying the currently configured time, e.g., "8:00 PM") that opens the system time picker when tapped, allowing the caregiver to schedule when daily activity summary reports are generated.

The **Appearance** section offers three theme radio options: **System Default**, **Light**, and **Dark**, controlling the application's visual theme mode.

The right screen shows the scrolled continuation, revealing the **Danger Zone** section at the bottom, visually separated by a divider and styled with a red heading. The warning text explains: "Unpairing will disconnect the watch. Patient profile and history are kept. Monitoring will stop until you pair again." The **"Unpair Device"** button is styled with a red outline and link-off icon. Tapping it triggers a confirmation dialog that requires the caregiver to type the patient's exact name to proceed, serving as a safeguard against accidental unpairing. Upon confirmation, the system clears the watch linkage from Firestore and navigates back to the Add Patient screen.
