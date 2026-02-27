# Flutter Screen Roles

This document gives a simple, one-line description of what each Flutter screen is responsible for.

## App Flow Screens

- `SplashScreen`: Initial loading/entry screen that decides where the user should go next.
- `LoginScreen`: Auth screen for caregiver sign-in.
- `SignUpScreen`: Account creation screen for new caregivers.
- `ForgotPasswordScreen`: Password recovery flow.

## Main Shell & Primary Tabs

- `MainScreen`: Main app shell with bottom navigation and tab switching.
- `HomeScreen`: Dashboard/overview of patient and system status.
- `MemoryScreen`: Hub for memory reminders and related content.
- `SafeZoneMapScreen`: Safe-zone map view and location context.
- `ActivityScreen`: Timeline/activity feed for recent events.

## Memory Reminder Screens

- `MemoryDetailsScreen`: Shows full details for a selected memory/reminder item.
- `MemoryReminderListScreen`: List view of memory reminders.
- `CreateMemoryReminderScreen`: Creates a new memory reminder.

## Safe-Zone & Maps Screens

- `SafeZoneConfigScreen`: Configures safe-zone settings (radius/behavior).
- `OfflineMapsScreen`: Offline map management and usage.

## Patient & Profile Management Screens

- `AddPatientScreen`: Adds/links a patient profile.
- `PatientSetupScreen`: Guided patient setup/onboarding flow.
- `EditPatientProfileScreen`: Edits patient profile information.
- `EditCaregiverProfileScreen`: Edits caregiver profile information.

## Settings

- `SettingsScreen`: App/account settings and configuration options.