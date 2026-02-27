# Relapse — Complete UI Specification

> **Purpose:** This document describes every visual element of the Relapse Flutter app so it can be recreated to be **pixel-identical**. It covers color tokens, gradients, typography, iconography, spacing, component patterns, and the full screen-by-screen layout. Only UI is specified — no business logic.

---

## Table of Contents

1. [Global Design System](#1-global-design-system)
2. [Reusable Components](#2-reusable-components)
3. [Navigation](#3-navigation)
4. [Screens](#4-screens)
   - [Splash Screen](#41-splash-screen)
   - [Login Screen](#42-login-screen)
   - [Sign Up Screen](#43-sign-up-screen)
   - [Forgot Password Screen](#44-forgot-password-screen)
   - [Main Screen (Shell)](#45-main-screen-shell)
   - [Home Screen](#46-home-screen)
   - [Memory Screen (Map)](#47-memory-screen-map)
   - [Memory Details Screen](#48-memory-details-screen)
   - [Memory Reminder List Screen](#49-memory-reminder-list-screen)
   - [Create Memory Reminder Screen](#410-create-memory-reminder-screen)
   - [Safe Zone Map Screen](#411-safe-zone-map-screen)
   - [Safe Zone Configuration Screen](#412-safe-zone-configuration-screen)
   - [Routines Screen](#413-routines-screen)
   - [Activity Screen](#414-activity-screen)
   - [Add Patient Screen](#415-add-patient-screen)
   - [Patient Setup Screen](#416-patient-setup-screen)
   - [Edit Patient Profile Screen](#417-edit-patient-profile-screen)
   - [Edit Caregiver Profile Screen](#418-edit-caregiver-profile-screen)
   - [Settings Screen](#419-settings-screen)
   - [Offline Maps Setup Screen](#420-offline-maps-setup-screen)
5. [Assets](#5-assets)
6. [Responsive Behaviour](#6-responsive-behaviour)

---

## 1. Global Design System

### 1.1 Material & Theme

- **Material Design 3** (`useMaterial3: true`)
- Base theme: `ColorScheme.light()`
- No custom font family — uses Flutter's default (Roboto on Android, SF Pro on iOS)

### 1.2 Color Palette

#### Background Gradient Colors (Primary branding)

| Token | Hex | Description |
|---|---|---|
| `gradientStart` | `#90CAF9` | Blue 200 — light sky blue |
| `gradientMiddle` | `#80CBC4` | Teal 200 — light teal |
| `gradientEnd` | `#C8E6C9` | Green 100 — pale mint green |

#### Button Gradient Colors (Not actively used in most buttons)

| Token | Hex | Description |
|---|---|---|
| `buttonGradientStart` | `#42A5F5` | Blue 400 |
| `buttonGradientMiddle` | `#673AB7` | Deep Purple 500 |
| `buttonGradientEnd` | `#E91E63` | Pink 500 |

#### Material 3 Semantic Colors

| Token | Hex | Usage |
|---|---|---|
| `primaryColor` | `#386A20` | Dark green — primary actions, text headers, icons |
| `onPrimaryColor` | `#FFFFFF` | Text/icons on primary |
| `primaryContainerColor` | `#B8F398` | Light green — container fills, avatar backgrounds |
| `onPrimaryContainerColor` | `#002201` | Dark green-black — text on primary container |
| `secondaryColor` | `#53634E` | Muted green — secondary text, subtle icons |
| `onSecondaryColor` | `#FFFFFF` | Text on secondary |
| `secondaryContainerColor` | `#D6E8CD` | Light sage — container fills |
| `onSecondaryContainerColor` | `#111F0F` | Dark — text on secondary container |
| `tertiaryColor` | `#38656B` | Teal — accent highlights |
| `onTertiaryColor` | `#FFFFFF` | Text on tertiary |
| `errorColor` | `#BA1A1A` | Red — errors, delete actions, danger zones |
| `onErrorColor` | `#FFFFFF` | Text on error |
| `surfaceColor` | `#FFFFFF` | White — cards, input fields, bottom sheets |
| `onSurfaceColor` | `#1A1C18` | Near-black — primary body text |
| `backgroundColor` | `#FDFDFB` | Off-white — screen scaffolds |

#### Status/Feedback Colors (inline usage)

| Usage | Color |
|---|---|
| Safe zone — inside | Green `#4CAF50` → `#66BB6A` gradient |
| Safe zone — outside | Red `#F44336` → `#E57373` gradient |
| Watch connected banner | `#2E7D32` (green) |
| Watch disconnected banner | `#C62828` (red) |
| Info boxes | `Colors.blue.shade50` background, `Colors.blue.shade200` border, `Colors.blue.shade700`/`shade900` text |
| Offline maps warning | `Colors.orange` with alpha backgrounds |

### 1.3 Gradients

| Name | Colors | Direction | Used On |
|---|---|---|---|
| **Background Gradient** | `[gradientStart, gradientMiddle, gradientEnd]` | `topCenter → bottomCenter` | `AppBackground` widget, splash screen |
| **Button/Pill Gradient** | `[gradientStart, gradientMiddle]` | `centerLeft → centerRight` | `GradientButton`, `GradientButtonWithIcon`, FABs |
| **Icon/Text Gradient** | `[gradientStart, gradientMiddle, gradientEnd]` | `topLeft → bottomRight` | `GradientText`, gradient icons via `ShaderMask` |
| **Card Border Gradient** | `[gradientStart, gradientMiddle, gradientEnd]` | `topLeft → bottomRight` | Patient overview card outer border |
| **Primary Action Gradient** | `[gradientStart, gradientMiddle, gradientEnd]` | `topLeft → bottomRight` | Full-width CTA buttons (56h, rounded 12) |

### 1.4 Typography Scale

Uses Flutter default font family. Key sizes used throughout:

| Context | Size | Weight | Color | Notes |
|---|---|---|---|---|
| Splash app name | 36 | Bold | `Colors.black87` | `letterSpacing: 1.2` |
| Splash tagline | 18 | w400 | `Colors.black` @ 0.7 alpha | |
| Screen titles (AppBar) | 20 | Bold | Gradient text (`GradientText`) | |
| Section headers | 18 (responsive) | Bold | Gradient text | `letterSpacing: 0.5` |
| Card titles | 20 (responsive) | Bold | `primaryColor` | |
| Card subtitles / hints | 12-14 (responsive) | Normal | `Colors.grey[600]` | |
| Body text | 14-16 | Normal | `onSurfaceColor` or `Colors.black87` | |
| Button text (pill) | default | Bold | `Colors.white` | |
| Button text (CTA 56h) | 18 | Bold | `Colors.white` | |
| Stat numbers | 24 (responsive) | Bold | Varies per stat card color | |
| Feature card title | 15 (responsive) | Bold | `primaryColor` | centered, max 2 lines |
| Feature card subtitle | 11 (responsive) | Normal | `Colors.grey[600]` | centered, 1 line |
| Status pill text | 11 | Bold | `Colors.white` | `letterSpacing: 0.5` |
| Pairing code input | 24 | Bold | Default | `letterSpacing: 8` |
| Login "Welcome Back" | 24 | Bold | Gradient text | |
| SignUp "Create Your Account" | 26 | Bold | Gradient text | |
| Forgot Password title | 28 | Bold | Gradient text | |
| Instruction step title | 14 (responsive) | Bold | `primaryColor` | |
| Instruction step body | 12 (responsive) | Normal | `Colors.grey[600]` | |
| Form labels | Default Material | Default | Default | |
| Hint text | Default | Normal | `Colors.black` @ 0.5 alpha | |

**Responsive font sizing:** `fontSize * (screenWidth / 375.0)` — scales linearly from a 375pt base.

### 1.5 Elevation & Shadows

| Element | Shadow |
|---|---|
| Bottom navigation bar | `color: black @ 0.1 alpha, blur: 10, offset: (0, -3)` |
| Feature cards | `color: black @ alpha 100, blur: 15, offset: (0, 5)` |
| Stat cards | `color: black @ alpha 80, blur: 12, offset: (0, 4)` |
| CTA buttons (gradient 56h) | `color: gradientMiddle @ 0.4 alpha, blur: 12, offset: (0, 6)` |
| Patient overview card | None (border gradient instead) |
| Map containers | `color: black @ alpha 38, blur: 10, offset: (0, 4)` |
| Settings section cards | `color: black @ alpha 26, blur: 8, offset: (0, 2)` |
| Memory list cards | Material `elevation: 4` |
| Info card (map screen) | Material `elevation: 4` |

### 1.6 Border Radii

| Element | Radius |
|---|---|
| Pill-shaped buttons (`GradientButton`) | 50 |
| CTA buttons (full-width gradient) | 12 |
| Cards (feature, stat, settings) | 12 |
| Patient overview card (outer) | 16 |
| Patient overview card (inner) | 13 |
| Feature cards | 16 |
| Map containers | 12 |
| Input fields (form screens) | 12 |
| Status pills (safe zone) | 20 |
| Media chips | 16 |
| Bottom sheet reminder cards | 12 |
| Profile image circle | `BoxShape.circle` |
| Popup menu | 12 |

### 1.7 Icon System

All icons use **Material Icons** (`Icons.*`). Key icons per feature:

| Feature/Location | Icon | Notes |
|---|---|---|
| Home nav | `Icons.home_outlined` | |
| Memory nav | `Icons.map_outlined` | |
| Safe Zone nav | `Icons.shield_outlined` | |
| Routines nav | `Icons.list_outlined` | |
| Activity nav | `Icons.show_chart_outlined` | |
| App logo (AppBar) | `assets/images/logo.png` | 32×32, gradient ShaderMask |
| Settings popup | `Icons.settings_outlined` | |
| Profile popup | `Icons.person_outline` | |
| Logout popup | `Icons.logout` | Red colored |
| Edit patient | `Icons.edit` | White, inside gradient circle (20px) |
| Watch connected | `Icons.watch` | |
| Watch disconnected | `Icons.watch_off` | |
| Patient overview time | `Icons.access_time` | 16px, grey |
| Add patient (no patient) | `Icons.person_add_outlined` | 80px, `gradientMiddle` |
| Add patient CTA | `Icons.add_circle_outline` | 24px, white |
| Upload memories | `Icons.cloud_upload_outlined` | |
| Manage routines | `Icons.calendar_today_outlined` | |
| Set safe zone | `Icons.shield_outlined` | |
| Activity monitoring | `Icons.show_chart_outlined` | |
| Quick stats: memories | `Icons.photo_library_outlined` | |
| Quick stats: routines | `Icons.schedule_outlined` | |
| Quick stats: safe zones | `Icons.location_on_outlined` | |
| Email field | `Icons.email` | `primaryColor` |
| Password field | `Icons.lock` | `primaryColor` |
| Visibility toggle | `Icons.visibility` / `Icons.visibility_off` | |
| Full name field | `Icons.person` | `primaryColor` |
| Forgot password icon | `Icons.lock_reset` | 80px |
| Email sent icon | `Icons.mark_email_read` | 100px |
| Info | `Icons.info_outline` | |
| Camera | `Icons.camera_alt` | White, in gradient circle |
| Person placeholder | `Icons.person` | 60px, grey |
| Age field | `Icons.cake_outlined` | |
| Notes field | `Icons.notes_outlined` | |
| Phone field | `Icons.phone_outlined` | |
| Email (read-only) | `Icons.email_outlined` | |
| Pin/pairing code | `Icons.pin_outlined` | |
| Watch instruction | `Icons.watch` | `gradientStart` color |
| Check circle | `Icons.check_circle_outline` | 64px white |
| Map search | `Icons.search` | `primaryColor` |
| Location on | `Icons.location_on` | `primaryColor` or `secondaryColor` |
| Warning | `Icons.warning` / `Icons.warning_amber_rounded` | `errorColor` or orange |
| Save | `Icons.save` | |
| Delete | `Icons.delete` / `Icons.delete_outline` | `errorColor` |
| Edit location | `Icons.edit_location_alt` | `primaryColor` |
| Center focus | `Icons.center_focus_strong` | `primaryColor` |
| Download | `Icons.download` | |
| Link off (unpair) | `Icons.link_off` | Red accent |
| Save alt | `Icons.save_alt` | |
| Photo camera | `Icons.photo_camera` | |
| Photo library | `Icons.photo_library` | |
| Mic (audio) | `Icons.mic` | |
| Videocam | `Icons.videocam` | |
| Audiotrack | `Icons.audiotrack` | |
| Label | `Icons.label` | `primaryColor` |
| Radar | `Icons.radar` | `primaryColor` |
| Preview | `Icons.preview` | `primaryColor` |
| History | `Icons.history` | `primaryColor` |
| Settings gear | `Icons.settings` | `primaryColor` |
| Arrow back | `Icons.arrow_back` | `Colors.black87` |
| Close | `Icons.close` | `errorColor` (media remove) |
| Check (radio/step) | `Icons.check` / `Icons.check_circle` | `primaryColor` or white |

**Gradient Icons:** Created using `ShaderMask` with `LinearGradient(colors: [gradientStart, gradientMiddle, gradientEnd], topLeft → bottomRight)`. The child `Icon` has `color: Colors.white` so the shader mask can apply the gradient.

For **selected** bottom nav icons, the gradient is applied. For **unselected**, the icon uses `Colors.grey.shade600`.

---

## 2. Reusable Components

### 2.1 `AppBackground`

- Full-screen `Container` with `BoxDecoration`
- `LinearGradient`: `[gradientStart, gradientMiddle, gradientEnd]`, `topCenter → bottomCenter`
- Used as wrapper around child widget

### 2.2 `GradientButton` (Pill Button)

- Full width by default (`double.infinity`), or custom `width`
- Outer `Container`:
  - Gradient: `[gradientStart, gradientMiddle]`, `centerLeft → centerRight`
  - Border radius: **50** (pill shape)
  - Border: **2px white**
- Inner `ElevatedButton`:
  - Transparent background, no shadow, no elevation
  - Same pill shape (radius 50)
  - Padding: vertical **16**
  - Text: **bold**, white

### 2.3 `GradientButtonWithIcon`

- Same as `GradientButton` but with a `Row` containing:
  - `Icon` (24px)
  - `SizedBox(width: 12)`
  - `Text` (bold, 16px)
- Default padding: vertical **16**, horizontal **24**

### 2.4 `GradientText`

- Uses `ShaderMask` with gradient `[gradientStart, gradientMiddle, gradientEnd]`, `centerLeft → centerRight`
- Child `Text` with `color: Colors.white` (so the shader applies)
- Accepts custom `TextStyle` and `TextAlign`

### 2.5 Full-Width CTA Button (Gradient Container + InkWell)

Used on: Add Patient, Patient Setup, Edit Profile screens.

- Container height: **56**
- Gradient: `[gradientStart, gradientMiddle, gradientEnd]` `topLeft → bottomRight`
- Border radius: **12**
- Box shadow: `gradientMiddle` @ 0.4 alpha, blur 12, offset (0, 6)
- Inner `Material(transparent)` + `InkWell` with matching radius
- Text: white, 18px, bold
- Loading state: `CircularProgressIndicator(color: white)` replaces text

### 2.6 Profile Picture Circle

Used on: Patient Setup, Edit Patient Profile, Edit Caregiver Profile.

- Outer `Container`: 120×120, circle, `Colors.grey[200]`, border: 3px `gradientMiddle`
- `ClipOval` child:
  - If local `File` selected → `Image.file(fit: cover)`
  - If network URL → `CachedNetworkImage(fit: cover)` with `CircularProgressIndicator` placeholder
  - Fallback: `Icon(Icons.person, 60px, Colors.grey[400])`
- Camera button: `Positioned(bottom: 0, right: 0)`:
  - Container: gradient `[gradientStart, gradientMiddle]`, circle shape, 2px white border
  - `IconButton(Icons.camera_alt, white, 24px)`
- Upload overlay (if uploading): `Positioned.fill`, circle, `black @ 0.5 alpha`, centered white `CircularProgressIndicator`

### 2.7 Input Fields (Form Screens)

Standard TextFormField with InputDecoration:
- `OutlineInputBorder` with radius **12**
- `focusedBorder`: `gradientMiddle` color, width 2
- `filled: true`, `fillColor: surfaceColor`
- Prefix icons in `primaryColor` (auth screens) or default (other screens)
- Hint text color: `Colors.black` @ 0.5 alpha

### 2.8 Info Box

- Container: `Colors.blue` @ 0.1 alpha background, radius 12
- Border: `Colors.blue` @ 0.3 alpha
- Row: `Icons.info_outline` (blue, 24px) + 12px gap + `Text` (13px responsive, `Colors.blue[700]`)

### 2.9 Alert Dialogs

Standard Material `AlertDialog`:
- Title: `Text` with default styling
- Content: `Text`
- Actions: `TextButton` with `primaryColor` foreground, or `errorColor` for destructive actions
- Some dialogs include `TextField` for confirmation (e.g., unpair dialog)

---

## 3. Navigation

### 3.1 Bottom Navigation Bar (`CustomBottomNavigationBar`)

- Outer `Container`:
  - `backgroundColor` fill
  - Box shadow: `black @ 0.1 alpha, blur: 10, offset: (0, -3)`
- Inner: Material 3 `NavigationBar`
  - `backgroundColor: transparent`
  - **5 destinations:**

| Index | Label | Icon (outlined) |
|---|---|---|
| 0 | Home | `Icons.home_outlined` |
| 1 | Memory | `Icons.map_outlined` |
| 2 | Safe Zone | `Icons.shield_outlined` |
| 3 | Routines | `Icons.list_outlined` |
| 4 | Activity | `Icons.show_chart_outlined` |

- Icon rendering: `ShaderMask` with gradient `[gradientStart, gradientMiddle, gradientEnd]` (`topLeft → bottomRight`)
  - Selected: icon `color: Colors.white` (gradient shows through)
  - Unselected: icon `color: Colors.grey.shade600` (no gradient visible)

### 3.2 Main Screen Structure

- `Scaffold(backgroundColor: #FDFDFD)`
- Body: `IndexedStack` with 5 children:
  - `HomeScreen`
  - `MemoryScreen(patientId)`
  - Safe Zone widget (either `SafeZoneMapScreen` if safe zone exists, or `SafeZoneScreen` if not, or placeholder if no patient)
  - `RoutinesScreen`
  - `ActivityScreen`
- `bottomNavigationBar`: `CustomBottomNavigationBar`
- Placeholder when no patient linked: Column with `Icons.shield_outlined` (80px, grey), "No Patient Linked" (22px bold), description (16px grey)

---

## 4. Screens

### 4.1 Splash Screen

**Scaffold** (no AppBar):
- Body: `Container` with gradient background:
  - `LinearGradient`: `[Colors.blue.shade100, Colors.teal.shade100, Colors.green.shade100]`
  - Direction: `topLeft → bottomRight`
- Center Column:
  1. `Hero(tag: 'app_logo')` → `Image.asset('assets/images/logo.png', 200×200, BoxFit.contain)`
  2. SizedBox(height: 32)
  3. Text "Relapse" — 36px, bold, `Colors.black87`, `letterSpacing: 1.2`
  4. SizedBox(height: 16)
  5. Text "Memory Care Support" — 18px, w400, `Colors.black @ 0.7 alpha`
  6. SizedBox(height: 48)
  7. `CircularProgressIndicator(valueColor: teal)`

---

### 4.2 Login Screen

**Scaffold** — `backgroundColor: #FDFDFD`, no AppBar.

Body: `Center` → `SingleChildScrollView` — horizontal padding: **24**.

Column (center aligned):

1. **Logo** — `ShaderMask` gradient `[#90CAF9, #80CBC4, #C8E6C9]` (`topLeft → bottomRight`), child: `Image.asset('logo.png', 120×120, color: white)`
2. SizedBox(24)
3. **GradientText** "Welcome Back" — 24px, bold
4. SizedBox(8)
5. **Subtitle** "Sign in to continue" — 16px, `Colors.black @ 0.6 alpha`
6. SizedBox(32)
7. **Form:**
   - **Email field** — hint "Email Address", prefix `Icons.email` (primaryColor), email keyboard, autofill email
   - SizedBox(16)
   - **Password field** — hint "Password", prefix `Icons.lock` (primaryColor), suffix visibility toggle, obscured by default
   - SizedBox(8)
   - **Align right:** TextButton "Forgot Password?" (primaryColor, w600)
8. SizedBox(24)
9. **GradientButton** "LOG IN" (or `CircularProgressIndicator` while loading)
10. SizedBox(24)
11. **Footer Row:** Text "Don't have an account? " + TextButton "Sign Up"

---

### 4.3 Sign Up Screen

**Scaffold** — `backgroundColor: #FDFDFD`
**AppBar** — transparent, elevation 0, back button: `Icons.arrow_back` `Colors.black87`

Body: `Center` → `SingleChildScrollView` — horizontal padding: **24**.

Column:

1. **Logo** — same gradient ShaderMask as Login but 100×100
2. SizedBox(16)
3. **GradientText** "Create Your Account" — 26px, bold
4. SizedBox(8)
5. **Subtitle** "Join us to get started" — 16px, `Colors.black @ 0.6 alpha`
6. SizedBox(32)
7. **Form** (crossAxisAlignment: start):
   - **Full Name** — hint "Full Name", prefix `Icons.person` (primaryColor)
   - SizedBox(16)
   - **Email** — same as Login
   - SizedBox(16)
   - **Password** — same as Login, plus `onChanged` for strength tracking
   - *Conditionally* (when password not empty):
     - SizedBox(8)
     - **Password strength bar**: `LinearProgressIndicator` (value: strength/4, height 4, grey background, colored fill based on strength) + strength label text (12px, w600)
     - SizedBox(4)
     - Hint "Use 8+ characters with uppercase, lowercase, number & symbol" (11px, `Colors.black @ 0.5 alpha`)
   - SizedBox(16)
   - **Confirm Password** — hint "Confirm Password", same styling
8. SizedBox(16)
9. **Terms Checkbox Row:**
   - `Checkbox` (activeColor: primaryColor)
   - Wrap text: "I agree to the " + underlined "Terms of Service" (primaryColor, w600) + " and " + underlined "Privacy Policy" (primaryColor, w600)
   - Padding on text: top 12
10. SizedBox(24)
11. **GradientButton** "SIGN UP"
12. SizedBox(24)
13. **Footer Row:** "Already have an account? " + TextButton "Login"

**Dialogs:**
- Terms of Service — AlertDialog, long text, CLOSE button
- Privacy Policy — AlertDialog, bullet points, CLOSE button
- Error — AlertDialog "Sign Up Failed"
- Success — AlertDialog with text, OK navigates to Login

---

### 4.4 Forgot Password Screen

**Scaffold** — `backgroundColor: #FDFDFD`
**AppBar** — transparent, elevation 0, `Icons.arrow_back` black87

Body: `Center` → `SingleChildScrollView` — horizontal padding: **24**.

**Two views toggled by `_emailSent` flag:**

#### Form View (default):

Column (center, stretch):

1. `Icons.lock_reset` — 80px, `primaryColor`
2. SizedBox(24)
3. **GradientText** "Forgot Password?" — 28px, bold, center
4. SizedBox(16)
5. Description text — 16px, `Colors.black @ 0.6 alpha`, center
6. SizedBox(32)
7. **Email TextFormField** — same styling as Login email field
8. SizedBox(32)
9. **GradientButton** "SEND RESET LINK"

#### Success View:

Column (center, stretch):

1. `Icons.mark_email_read` — 100px, `primaryColor`
2. SizedBox(24)
3. **GradientText** "Check Your Email" — 28px, bold, center
4. SizedBox(16)
5. "We've sent a password reset link to:" — 16px, 0.6 alpha, center
6. SizedBox(8)
7. Email address — 16px, bold, `Colors.black87`, center
8. SizedBox(32)
9. **Info box:**
   - Container: `Colors.blue.shade50` bg, radius 12, `Colors.blue.shade200` border 1px
   - Header row: `Icons.info_outline` (blue700, 20px) + "Next Steps:" (bold, blue900)
   - SizedBox(8)
   - Numbered steps text (14px, blue900, lineHeight 1.5)
10. SizedBox(32)
11. **GradientButton** "BACK TO LOGIN"
12. SizedBox(16)
13. TextButton "Didn't receive the email? Try again"

---

### 4.5 Main Screen (Shell)

See [Navigation section](#32-main-screen-structure).

---

### 4.6 Home Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:**
- `backgroundColor: backgroundColor`, elevation 0
- Title: Row → gradient-masked logo (32×32, white base) + SizedBox(8) + GradientText "Relapse" (20px, bold)
- Actions:
  - `PopupMenuButton` wrapped around a `CircleAvatar`:
    - If profile image exists: `CachedNetworkImageProvider` background
    - Else: `primaryColor` background, first letter of name (white text)
  - Popup offset: (0, 50), shape: RoundedRectangleBorder radius 12
  - Menu items:
    1. Settings — `Icons.settings_outlined` + "Settings"
    2. Profile — `Icons.person_outline` + "Profile"
    3. `PopupMenuDivider`
    4. Logout — `Icons.logout` (red) + "Logout" (red)
  - SizedBox(width: 8) after popup button

**Body (with patient linked):** `SingleChildScrollView`, padding: **16**

1. SizedBox(8)
2. **Watch Status Banner** — see below
3. SizedBox(16)
4. **Section Header** "PATIENT OVERVIEW" with `Icons.person_outline`
5. SizedBox(16)
6. **Patient Overview Card** — see below
7. SizedBox(32)
8. **Quick Stats Row** — see below
9. SizedBox(32)
10. **Section Header** "QUICK ACTIONS" with `Icons.dashboard_outlined`
11. SizedBox(16)
12. **Feature Grid** (2×2) — see below
13. SizedBox(16)

**Body (no patient):** `SingleChildScrollView`, padding: **24**

1. Large gradient circle container (padding 32): `Icons.person_add_outlined` (80px, `gradientMiddle`)
2. SizedBox(32)
3. "No Patient Linked" — 28px responsive, bold, `primaryColor`, center
4. SizedBox(16)
5. Description text — 16px responsive, `grey[600]`, lineHeight 1.5, center
6. SizedBox(40)
7. **Full-width CTA button** (56h, gradient, radius 12): `Icons.add_circle_outline` + "Add Patient" (18px bold white)

#### Watch Status Banner

- Container: full width, padding 16, radius 12
- Background: `baseColor @ 0.1 alpha`
- Border: `baseColor @ 0.4 alpha`, width 1.2
- Connected: `baseColor = #2E7D32`, icon = `Icons.watch`, title = "Watch Connected"
- Disconnected: `baseColor = #C62828`, icon = `Icons.watch_off`, title = "Watch Offline"
- Layout: Row
  - Circle icon container: `baseColor @ 0.15 alpha`, padding 10, icon 24px
  - SizedBox(16)
  - Column: title (`titleMedium`, baseColor, w600) + SizedBox(4) + message (`bodyMedium`, black87)

#### Section Header

- Row:
  - Gradient icon (28px)
  - SizedBox(12)
  - Column:
    - GradientText (18px responsive, bold, letterSpacing 0.5)
    - SizedBox(4)
    - Gradient underline bar: 3px height, 40px width, gradient fill, radius 2

#### Patient Overview Card

- Outer Container: gradient border (`[gradientStart, gradientMiddle, gradientEnd]` topLeft→bottomRight), radius 16, padding 3
- Inner Container: `surfaceColor` fill, radius 13, padding 20
- Row layout:
  - **Avatar:** Gradient ring (3px) → circle container (responsive, 20% of screen width, clamped 64-140) → `primaryContainerColor` fill → `ClipOval` with `CachedNetworkImage` or initials text
  - SizedBox(16)
  - **Info column (Expanded):**
    - Name: 20px responsive, bold, `primaryColor`
    - SizedBox(4)
    - Last active: Row of `Icons.access_time` (16px, grey600) + text (12px responsive, grey600)
    - SizedBox(12)
    - **Status pill:** Container, 12px horizontal + 6px vertical padding, gradient fill (green or red), radius 20, glow shadow
      - Row: 8×8 white circle dot + SizedBox(8) + status text (11px, bold white, letterSpacing 0.5)
  - **Edit IconButton:** gradient circle container → `Icons.edit` (white, 20px)

#### Quick Stats Row

- 3 equal `Expanded` children with SizedBox(12) gap
- Each stat card:
  - Container: `surfaceColor`, radius 12, shadow (black alpha 80, blur 12, offset 0,4)
  - Padding 16
  - Column (center): Icon (32px, custom color) → SizedBox(8) → count (24px responsive, bold, color) → label (12px responsive, grey600)
  - Stats: Memories (gradientStart), Routines (gradientMiddle), Safe Zones (gradientEnd)

#### Feature Grid

- `GridView.count`: 2 columns, shrinkWrap, NeverScrollableScrollPhysics
- Spacing: main 16, cross 16
- `childAspectRatio: 0.85`
- Each card:
  - `Material(transparent)` → `InkWell` (radius 16)
  - Container: `surfaceColor`, radius 16, shadow (black alpha 100, blur 15, offset 0,5)
  - Padding 16, Column (center):
    - Icon container: gradient fill (alpha 10), radius 12, padding 12 → gradient icon (32px)
    - SizedBox(8)
    - Title: 15px responsive, bold, `primaryColor`, center, 2-line max
    - SizedBox(4)
    - Subtitle: 11px responsive, grey600, center, 1-line max
  - Cards:
    1. `Icons.cloud_upload_outlined` / "Upload Memory Cues" / "Photos, Audio, Video"
    2. `Icons.calendar_today_outlined` / "Manage Routines" / "Task & Schedules"
    3. `Icons.shield_outlined` / "Set Safe Zone" / "Define Geo-Boundary"
    4. `Icons.show_chart_outlined` / "Activity Monitoring" / "Location History"

---

### 4.7 Memory Screen (Map)

**Scaffold** with AppBar:
- Title: GradientText "Memories" (20px, bold) — OR search TextField when searching (white text, "Search memories..." hint in white70, no border)
- Actions: search/close icon toggle

**Body:** Google Map (full screen, normal type, no location button, no zoom controls, no toolbar)

- If empty, overlay centered card: white, radius 16, padding 24, margin H32
  - `Icons.photo_library_outlined` (64px, grey400)
  - SizedBox(16)
  - "No memories added yet" (titleLarge, grey700, bold, center)
  - SizedBox(8)
  - "Tap the + button..." (bodyMedium, grey600, center)

- If searching with results, top overlay: white container, margin 8, radius 8, shadow
  - `ListView.separated` (max 5 items), each with `Icons.location_on` (blue) + memory name

**Floating Action Buttons (bottom-right column):**
- Gradient FAB: Container with gradient `[gradientStart, gradientMiddle]`, radius 50, 2px white border
  - `FloatingActionButton`: transparent bg, no elevation, `Icons.add` (white, 32px)

---

### 4.8 Memory Details Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** `backgroundColor: backgroundColor`, elevation 0
- Title: `GradientText(reminder.name, 20px, bold)`
- `iconTheme: gradientStart`

**Body:** `SingleChildScrollView`, padding 16

1. **Photo** (if exists): `ClipRRect` radius 12, `CachedNetworkImage` height 250, full width, cover. Placeholder: 250h container, `secondaryContainerColor`, centered spinner. Error: container with `Icons.broken_image` (64px, secondaryColor)
2. SizedBox(16)
3. **Location row:** `Icons.location_on` (20px, secondaryColor) + SizedBox(8) + coordinates (titleMedium, onSurfaceColor)
4. SizedBox(16)
5. **Audio section** (if exists): "Audio Reminder" (titleLarge, bold) + placeholder container (50h, primaryContainerColor)
6. **Video section** (if exists): "Video Reminder" (titleLarge, bold) + placeholder container (200h, primaryContainerColor)
7. SizedBox(24)
8. **Action buttons row (spaceEvenly):**
   - Edit: `ElevatedButton.icon(Icons.edit)`, `primaryColor` bg, white fg, padding V12, radius 8
   - Delete: `ElevatedButton.icon(Icons.delete)`, `errorColor` bg, white fg, padding V12, radius 8

---

### 4.9 Memory Reminder List Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** `backgroundColor: backgroundColor`, elevation 0
- Title: GradientText "Memory Reminders" (20px, bold)
- `iconTheme: gradientStart`

**Body:** StreamBuilder list:
- Loading: centered `CircularProgressIndicator` (primaryColor)
- Error: centered column — `Icons.error_outline` (64px, errorColor) + title + error text
- Empty: centered column — `Icons.location_off` (64px, secondaryColor) + "No memory reminders yet" + "Tap the + button to create one"
- List: `ListView.builder`, padding 16

**Each reminder card:**
- `Card`: margin bottom 16, elevation 4, radius 12
- Photo (if exists): `CachedNetworkImage`, 200h, full width, top corners rounded 12
- Padding 16 column:
  - Name: 18px, bold, onSurfaceColor
  - SizedBox(8)
  - Location row: `Icons.location_on` (16px, secondaryColor) + coordinates (14px, secondaryColor)
  - SizedBox(12)
  - Media chips row:  Each chip = container with `primaryContainerColor`, radius 16, H8 V4 padding, icon (14px, primaryColor) + label (12px, primaryColor, w500)
  - SizedBox(12)
  - Delete button: `TextButton.icon(Icons.delete)`, errorColor

**Bottom bar:** SafeArea with `GradientButtonWithIcon` "Create Memory Reminder" with `Icons.add`

---

### 4.10 Create Memory Reminder Screen

**Scaffold** — `backgroundColor: backgroundColor`, `resizeToAvoidBottomInset: false`

**AppBar:** backgroundColor, elevation 0, GradientText "Create Memory Reminder" (20px bold), iconTheme gradientStart

**Body:** ScrollView column:

1. SizedBox(8)
2. **Step Indicator** — Container margin H16 V8, padding 16, `surfaceColor @ 128 alpha`, radius 12
   - Row (spaceEvenly): 3 step items with arrows between
   - Each step: 40×40 circle (gradient if complete, grey if not, 2px border), icon or checkmark (white 20px), label below (12px)
   - Steps: 1-Name, 2-Location, 3-Media
3. SizedBox(16)
4. **Name TextField** — padding H16, outlined radius 12, label "Memory Name", prefix `Icons.label` (primaryColor), suffix green check when filled
5. SizedBox(16)
6. **"Select Location"** header: Row — `Icons.location_on` (primaryColor, 20) + text (16px, bold white)
7. SizedBox(12)
8. **Search bar** — TextField: hint "Search address or place...", filled surfaceColor, outlined radius 12, prefix search icon, suffix clear button
9. SizedBox(12)
10. **Map Container** — 40% screen height (min 250, max 500), margin H16, radius 12, 2px border (white alpha 26), shadow
    - `GoogleMap` inside ClipRRect radius 12
11. SizedBox(12)
12. **Selected location card** (if selected):
    - Container: surfaceColor, radius 12, primaryColor border 2px alpha 128
    - Row: gradient icon container (checkmark) + SizedBox(14) + Column ("Location Selected" 15px bold white + address 12px grey)
    - Or italic prompt "Tap on the map to select a location" if none selected
13. SizedBox(24)
14. **Radius Selector** — Container: surfaceColor, radius 12, shadow, primaryColor border 1.5px
    - Header: `Icons.radar` (primaryColor) + "Trigger Radius" (16px bold onSurfaceColor)
    - "Radius: X meters" (onSurfaceColor, w600)
    - Slider: 20–200m, primaryColor active, primaryColor alpha 70 inactive
    - Helper text (12px, grey400)
15. SizedBox(24)
16. **Media Upload Cards** — "Add Media" header with `Icons.add_photo_alternate`
    - 3 cards (Photo required, Audio optional, Video optional):
      - Card: elevation 2, surfaceColor, radius 12, green border if has media
      - InkWell radius 12, padding 16, Row: icon (28px primaryColor) + text column + status icon (check green or add primaryColor, 28px)
17. SizedBox(16)
18. **Media Preview** (if any media selected):
    - Container: surfaceColor, radius 12, shadow
    - Header: "Media Preview" with `Icons.preview`
    - Each media item: Container with backgroundColor, radius 8, padding 12
      - Header row: type icon + label + spacer + file size + close button (errorColor)
      - Photo shown as image preview (150h, cover)
      - Audio shows duration text
19. SizedBox(24)
20. **Save button:** `GradientButtonWithIcon` "Save Memory" with `Icons.save`
21. SizedBox(24)

**Upload overlay:** Full screen `black @ 128 alpha`, centered white container (radius 12, padding 24), spinner + "Uploading... X%" (16px, bold, onSurfaceColor)

---

### 4.11 Safe Zone Map Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** backgroundColor, elevation 0
- Title: GradientText "Safe Zone Map" (20px bold)
- iconTheme: gradientStart
- Action: `Icons.edit_location_alt` (primaryColor) — "Edit Safe Zone"

**Body:** Stack over full-screen `GoogleMap`

1. **Google Map** — markers (patient=blue/red depending on status, safe zone center=green), circles (green fill @ 0.2 alpha, green stroke 2px)
2. **Status Banner** (Positioned top 16, left/right 16):
   - Material elevation 4, radius 12
   - Background: `green.shade50` (inside) or `red.shade50` (outside)
   - Border: `primaryColor` or `errorColor`, 2px
   - Row: check/warning icon + "[Name] is inside/OUTSIDE the safe zone" (bold, colored)
3. **Info Card** (Positioned bottom 16, left/right 16):
   - Material elevation 4, radius 16
   - surfaceColor background, padding 16
   - "Patient: [Name]" (16px, bold, primaryColor)
   - SizedBox(8)
   - Location row: `Icons.location_on` (16px, primaryColor) + address/coordinates
   - Radius text
   - Status row: `Icons.my_location` (16px, primaryColor) + status label
   - SizedBox(16)
   - `GradientButtonWithIcon` "Modify Safe Zone" with `Icons.edit`
4. **Recenter FAB** (Positioned right 16, top 16):
   - `FloatingActionButton.mini`: surfaceColor bg, `Icons.center_focus_strong` (primaryColor)

---

### 4.12 Safe Zone Configuration Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** backgroundColor, elevation 0
- Title: GradientText "Safe Zone Configuration" (20px bold)
- iconTheme: gradientStart
- Action (if safe zone exists): delete icon `Icons.delete_outline` (errorColor)

**Body:** ScrollView column:

1. SizedBox(8)
2. **Status Card** (if safe zone + status):
   - Container: surfaceColor, radius 12, `statusColor` border 2px alpha 128, shadow
   - Row: icon container (statusColor bg alpha 51, radius 12, statusIcon 32px) + SizedBox(16) + Column ("Patient Status" 12px grey400, status text 18px bold colored)
3. **Offline Maps Warning** (if not confirmed):
   - Container: `orange @ alpha 26`, radius 12, orange border alpha 77
   - Header: warning icon + "Offline Maps Not Configured" (orange, 16px bold)
   - SizedBox(12)
   - Description text (14px, black87, lineHeight 1.4)
   - SizedBox(12)
   - Button: "Setup Offline Maps" (orange bg, white text, radius 8)
4. **Map Container** — 45% screen height (min 300, max 550), margin 16, shadow, radius 12, 2px border (white alpha 26)
   - Google Map with tap-to-select, markers, circles
5. **Selected Center card** (if selected):
   - Container: surfaceColor, margin H16, padding 16, radius 12, primaryColor border 2px alpha 128
   - "Selected Center Location" (15px bold white)
   - Address or coordinates (12px grey400)
   - Or prompt "Tap on the map to select safe zone center" (14px grey400 italic center)
6. SizedBox(16)
7. **Radius Slider** — same pattern as geo reminder radius but range 20–2000m, 198 divisions
8. SizedBox(16)
9. **Settings Section** — Container: surfaceColor, margin 16, padding 16, radius 12
   - Header: `Icons.settings` (primaryColor) + "Safety Settings" (16px bold)
   - SizedBox(16)
   - "Watch Behavior on Exit" (titleMedium, w600)
   - Radio list tiles (3 options):
     - radio_button_checked/off icon (primaryColor/grey)
     - Title text + subtitle text (12px grey400)
     - Check mark trailing if selected
   - Divider
   - SwitchListTile "Alert on Exit" (activeTrackColor: primaryColor)
   - Divider
   - SwitchListTile "Auto Navigation" (activeTrackColor: primaryColor)
10. **Event Logs** (if any):
    - Container: surfaceColor, margin 16, padding 16, radius 12
    - Header: `Icons.history` (primaryColor) + "Recent Events" (16px bold)
    - Up to 5 log items:
      - Container: backgroundColor, radius 8, margin bottom 8, padding 12, errorColor border alpha 77
      - Row: warning icon (errorColor, 20px) + event type (14px bold) + time (12px grey400) + status chip (radius 12, errorColor or grey background)
11. SizedBox(16)
12. **Save button:** `GradientButtonWithIcon` "Save Safe Zone" with `Icons.save`, padding 16

**Saving overlay:** `black @ alpha 128`, centered `CircularProgressIndicator` (primaryColor)

---

### 4.13 Routines Screen

**Placeholder screen:**
- Centered `Text('Routines Screen')`
- No custom styling yet

---

### 4.14 Activity Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** GradientText "Activity" (20px, bold), backgroundColor, elevation 0
- Action: `Icons.calendar_today_outlined` (GradientIcon, 22px) — future date range picker

**Body:** SingleChildScrollView, padding 16, Column (crossAxisAlignment: start):

1. **Date Filter Row** — 3 `Expanded` chips: "Today" / "This Week" / "This Month"
   - Selected: gradient button fill (`AppGradients.button`), white bold text, shadow (gradientMiddle alpha 80, blur 8, offset 0,3)
   - Unselected: surfaceColor, grey300 border, grey600 w500 text
   - Radius 12, vertical padding 10, AnimatedContainer 200ms
   - 6px horizontal gap between chips

2. SizedBox(20)

3. **Current Location Card** — gradient border (cardBorder, 2.5px padding), inner surfaceColor radius 13.5
   - **Map placeholder area** (height 160): faint gradient bg (start/middle/end alpha 40), top-rounded corners
     - Grid lines: 3 horizontal + 5 vertical, gradientMiddle alpha 30, 0.5px
     - **Center pin:** gradient circle (button gradient, padding 10, shadow), `Icons.person_pin_circle` white 28px, small dot below (gradientMiddle alpha 80, 8×8 circle)
     - **"LIVE" badge** (top-left 12,12): safeZoneInsideStart pill, radius 20, shadow; white circle 6px + "LIVE" white 10px bold letterSpacing 1
   - **Location info row** (padding 16): gradient icon container (start/middle alpha 30, radius 12, padding 10) with `Icons.location_on` GradientIcon 24px + Column:
     - Address: 15px responsive w600 primaryColor
     - Row: clock icon 14px grey500 + "Updated X min ago" 12px responsive grey500 + "Safe Zone" pill (safeZoneInsideStart alpha 26, radius 8, 10px w600 safeZoneInsideStart)

4. SizedBox(28)

5. **Section Header:** `Icons.bar_chart_rounded` / "DAILY SUMMARY" (same pattern as HomeScreen `_SectionHeader`)

6. SizedBox(16)

7. **Daily Summary Row** — 3 `Expanded` stat cards:
   - Each: surfaceColor, radius 12, shadow (black alpha 80, blur 12, offset 0,4), padding V16 H8
   - Icon in colored circle (color alpha 26), icon 24px colored
   - Value: 18px responsive bold primaryColor
   - Label: 11px responsive grey600
   - Cards: (`Icons.directions_walk` / "1.2 km" / "Distance" / gradientStart), (`Icons.timer_outlined` / "3h 20m" / "Time Outside" / gradientMiddle), (`Icons.place_outlined` / "4" / "Places" / gradientEnd)

8. SizedBox(28)

9. **Section Header:** `Icons.show_chart_outlined` / "MOVEMENT PATTERN"

10. SizedBox(16)

11. **Movement Chart Card** — surfaceColor, radius 16, shadow, padding 20
    - Legend row: gradient square (12×12, radius 3) + "Activity Level" 12px grey600 + Spacer + "Peak: 10 AM" 12px w600 gradientStart
    - Bar chart (height 100): 24 bars (hourly), gradient fill (start→middle, alpha scaled by value), top-rounded radius 2
    - Hour labels: "12 AM", "6 AM", "12 PM", "6 PM", "12 AM" — 9px grey500

12. SizedBox(28)

13. **Section Header:** `Icons.notifications_outlined` / "RECENT ACTIVITY"

14. SizedBox(16)

15. **Recent Activity Feed** — surfaceColor container, radius 16, shadow
    - List of event tiles, divider (0.5px grey200) between items
    - Each tile: H-padding 16, V-padding 14, Row:
      - Icon circle: event color alpha 26, icon 20px event color
      - Title: 14px responsive w600 primaryColor
      - Subtitle: 12px responsive grey600
      - Time: 11px responsive grey500 w500
    - Event types (color-coded):
      - Safe zone enter (safeZoneInsideStart / `Icons.shield_outlined`)
      - Memory reminder (gradientStart / `Icons.notifications_active_outlined`)
      - Routine completed (gradientMiddle / `Icons.check_circle_outline`)
      - Safe zone exit/alert (safeZoneOutsideStart / `Icons.warning_amber_outlined`)
      - Walking/location (tertiaryColor / `Icons.directions_walk`)

16. SizedBox(28)

17. **Section Header:** `Icons.location_on_outlined` / "LOCATION HISTORY"

18. SizedBox(16)

19. **Location History Timeline** — vertical timeline with dot+line track
    - Track column (width 32): dot 14×14 (current: gradient button fill + shadow; past: grey300) + 2px grey300 line
    - Each entry card: surfaceColor, radius 12, shadow (black alpha 40, blur 8, offset 0,2), margin bottom 12, padding 14
      - Current entry: gradientStart alpha 60 border 1.5px
      - Row: icon container (current: gradientStart alpha 26; past: grey100, radius 10, padding 8) + Column (name 14px w600, address 11px grey600, time 10px grey500) + duration pill (grey100, radius 8, 10px w600 grey700)

---

### 4.15 Add Patient Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** "Add Patient", backgroundColor, elevation 0

**Body:** ScrollView, padding 24, Form:

1. SizedBox(20)
2. **Header Icon:** Gradient circle container (padding 24) → `Icons.person_add_outlined` (64px, white)
3. SizedBox(32)
4. **Title:** "Link Patient Device" (24px responsive, bold, primaryColor, center)
5. SizedBox(16)
6. **Instructions Card:** surfaceColor, radius 16, shadow (0.08 alpha, blur 12, offset 0,4), padding 20
   - Header row: gradient icon container (8px padding, gradientStart/Middle alpha 0.2, radius 8) with `Icons.watch` (gradientStart, 24) + "Setup Instructions" (18px responsive bold primaryColor)
   - 4 instruction steps:
     - Each: gradient numbered circle (32×32, bold 16px white) + title (14px responsive bold primaryColor) + subtitle (12px responsive grey600)
7. SizedBox(32)
8. **Pairing Code Input:** TextFormField
   - Label: "Pairing Code", hint: "Enter 6-digit code"
   - Prefix: `Icons.pin_outlined`
   - Outlined border radius 12, focused border: gradientMiddle 2px
   - Filled surfaceColor
   - Center aligned, 24px bold, letterSpacing 8
   - maxLength 6 (shows counter)
9. SizedBox(32)
10. **Full-width CTA button** "Link Patient"
11. SizedBox(24)
12. **Info box** (blue variant) — "Need help? Contact support..."

---

### 4.16 Patient Setup Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** "Setup Patient Profile", backgroundColor, elevation 0
- Action: TextButton "Skip"

**Body:** ScrollView, padding 24, Form:

1. SizedBox(20)
2. **Success Icon:** Gradient circle → `Icons.check_circle_outline` (64px white)
3. SizedBox(24)
4. **Title:** "Patient Linked Successfully!" (24px responsive bold primaryColor center)
5. SizedBox(8)
6. **Subtitle:** "Now let's set up their profile" (16px responsive grey600 center)
7. SizedBox(32)
8. **Profile Picture** (120×120 circle — see reusable component)
9. SizedBox(32)
10. **Name input** — "Patient Name *", `Icons.person_outline` prefix
11. SizedBox(16)
12. **Age input** — "Age (Optional)", `Icons.cake_outlined` prefix, number keyboard
13. SizedBox(16)
14. **Notes input** — "Notes (Optional)", `Icons.notes_outlined` prefix, 3 lines, 500 max
15. SizedBox(32)
16. **Full-width CTA** "Complete Setup"
17. SizedBox(16)
18. **Info box** "You can update this information anytime..."

---

### 4.17 Edit Patient Profile Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** "Edit Patient Profile", backgroundColor, elevation 0

**Body (loading):** Centered `CircularProgressIndicator`

**Body (loaded):** ScrollView, padding 24, Form:

1. SizedBox(20)
2. **Profile Picture** (120×120 — same component)
3. SizedBox(32)
4. **Name** — "Patient Name *", `Icons.person_outline`, required
5. SizedBox(16)
6. **Age** — "Age (Optional)", `Icons.cake_outlined`
7. SizedBox(16)
8. **Notes** — "Notes (Optional)", `Icons.notes_outlined`, 3 lines, 500 max
9. SizedBox(32)
10. **Full-width CTA** "Save Changes"

---

### 4.18 Edit Caregiver Profile Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** "Edit Your Profile", backgroundColor, elevation 0

**Body (loading):** Centered `CircularProgressIndicator`

**Body (loaded):** ScrollView, padding 24, Form:

1. SizedBox(20)
2. **Profile Picture** (120×120 — same component)
3. SizedBox(32)
4. **Email** (read-only) — `Icons.email_outlined`, `grey[100]` fill, disabled
5. SizedBox(16)
6. **Full Name** — "Full Name *", `Icons.person_outline`
7. SizedBox(16)
8. **Phone** — "Phone Number (Optional)", `Icons.phone_outlined`
9. SizedBox(16)
10. **Bio** — "Bio (Optional)", `Icons.notes_outlined`, 3 lines, 500 max
11. SizedBox(32)
12. **Full-width CTA** "Save Changes" (shadow uses `gradientMiddle.withAlpha(100)`)

---

### 4.19 Settings Screen

**Scaffold** with standard AppBar "Settings"

**Body:** SafeArea → ScrollView, padding 16:

1. **"Reminder Cooldown"** — 18px, w600
2. SizedBox(8)
3. Description body text
4. SizedBox(16)
5. **Dropdown** — `InputDecorator` with OutlinedBorder, label "Cooldown (minutes)"
   - DropdownButton with options: 15, 30, 45, 60, 90, 120, 180, 240
6. SizedBox(16)
7. Error text (if any) — redAccent
8. Unsaved changes text (if any) — orangeAccent
9. **FilledButton.icon** "Save Changes" with `Icons.save_alt`
10. SizedBox(32)
11. **Divider**
12. SizedBox(16)
13. **"Danger Zone"** — 18px, w600
14. SizedBox(8)
15. Unpair description
16. SizedBox(16)
17. **OutlinedButton.icon** "Unpair Device" — `Icons.link_off`, redAccent color, redAccent border

**Unpair Confirmation Dialog:**
- Title: "Confirm Unpairing"
- TextField: type patient name to confirm
- Cancel + Confirm buttons

---

### 4.20 Offline Maps Setup Screen

**Scaffold** — `backgroundColor: backgroundColor`

**AppBar:** backgroundColor, GradientText "Offline Maps Setup" (20px bold), iconTheme gradientStart

**Body:** ScrollView, padding 20:

1. **Warning card:** `errorColor @ 0.1 alpha` bg, radius 12, errorColor border @ 0.3 alpha
   - `Icons.warning_amber_rounded` (errorColor, 32px) + bold text (14px errorColor)
2. SizedBox(24)
3. **Section: "Why Offline Maps?"** — surfaceColor card, radius 12, padding 16
   - `Icons.info_outline` (primaryColor) + title (16px bold primaryColor)
   - Content text (14px black87 lineHeight 1.5)
4. SizedBox(20)
5. **Section: "What to Download"** — same card style
6. SizedBox(20)
7. **Section: "How to Download"** — same card style, numbered instructions
8. SizedBox(24)
9. **GradientButtonWithIcon** "Open Google Maps" with `Icons.map`
10. SizedBox(16)
11. **OutlinedButton.icon** "Show Safe Zone in Maps" — primaryColor, full width, radius 12, min height 50
12. SizedBox(24)
13. **Confirmation checkbox card:** surfaceColor, radius 12
    - `CheckboxListTile` (activeColor primaryColor, checkColor white)
    - Title + subtitle text
14. SizedBox(16)
15. **GradientButtonWithIcon** "Confirm & Continue" with `Icons.check_circle` (disabled if not confirmed)
16. SizedBox(16)
17. **TextButton** "Skip for now (Not Recommended)" — grey600

**Skip Warning Dialog:** AlertDialog with surfaceColor bg, errorColor title, white body text, "Go Back" (primaryColor) and "Skip Anyway" (errorColor)

---

## 5. Assets

### 5.1 Image Assets

| File | Path | Usage |
|---|---|---|
| `logo.png` | `assets/images/logo.png` | App logo — used on splash (200×200), login (120×120), sign up (100×100), home AppBar (32×32). Often rendered through a gradient `ShaderMask` with `color: Colors.white` |
| `logo.svg` | `assets/images/logo.svg` | SVG version of logo (not actively used in code) |
| `launcher_icon.png` | `assets/images/launcher_icon.png` | Android/iOS launcher icon |

### 5.2 Map Tiles

- Google Maps (`google_maps_flutter`) used for: Memory Screen, Safe Zone Map, Safe Zone Configuration, Create Memory Reminder
- Default `MapType.normal`
- Common settings: `myLocationButtonEnabled: false`, `zoomControlsEnabled: false`, `mapToolbarEnabled: false`, `compassEnabled: false` (varies per screen)

---

## 6. Responsive Behaviour

### 6.1 Font Scaling

```
scaledSize = baseSize * (screenWidth / 375.0)
```

Applied to: section headers, card titles/subtitles, stat numbers, instruction steps, main titles on patient management screens.

### 6.2 Avatar Scaling

Patient overview avatar: `(screenWidth * 0.20).clamp(64.0, 140.0)`

### 6.3 Map Heights

- Memory screen: full body
- Safe Zone config: `45% of screen height`, clamped `[300, 550]`
- Create Memory: `40% of screen height`, clamped `[250, 500]`

### 6.4 Layout

- All scrollable content uses `SingleChildScrollView`
- Feature grid: `GridView.count(crossAxisCount: 2, childAspectRatio: 0.85)`
- Bottom nav: standard `NavigationBar`
- No tablet/landscape specific layouts

---

## Quick Reference: Screen → Background Color

| Screen | Background |
|---|---|
| Splash | Gradient (blue/teal/green shades 100) |
| Login | `#FDFDFD` |
| Sign Up | `#FDFDFD` |
| Forgot Password | `#FDFDFD` |
| Home | `backgroundColor (#FDFDFD)` |
| Memory | Default Scaffold |
| Memory Details | `backgroundColor` |
| Memory Reminder List | `backgroundColor` |
| Create Memory | `backgroundColor` |
| Safe Zone Map | `backgroundColor` |
| Safe Zone Config | `backgroundColor` |
| Add Patient | `backgroundColor` |
| Patient Setup | `backgroundColor` |
| Edit Patient | `backgroundColor` |
| Edit Caregiver | `backgroundColor` |
| Settings | Default Scaffold |
| Offline Maps | `backgroundColor` |
