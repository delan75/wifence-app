# WiFence App

This is the Flutter mobile app for WiFence.

The app is not the enforcement engine.
It is the control surface for the local gateway.

That distinction matters:

- the phone shows devices, profiles, limits, and warnings
- the gateway stores policy and applies enforcement
- the app talks to the gateway over the local network

## What Is In The App Right Now

Current screens and flows in the codebase:

- first-owner setup
- local sign-in
- pairing by one-time code
- pairing by QR code scan
- dashboard
- pulse
- device detail
- grouped controls through the Modes screen
- enforcement settings
- trusted-device management
- audit log
- build log

## Main Screens

### Auth

The app starts in a local gateway auth flow.

It supports:

- checking if the gateway already has an owner
- creating the first owner account
- signing in with local credentials
- pairing a new phone with a code
- scanning a QR pairing payload
- showing gateway readiness before setup

### Dashboard

The dashboard is wired to live gateway state.

It currently shows:

- gateway mode
- gateway readiness status
- device totals
- online, paused, and quota-exhausted counts
- quick actions derived from live device state
- discovered devices

Operational warnings on the dashboard are meant to come from real gateway data, not placeholder copy.
Brand labels and section titles are still static UI text by design.

### Pulse

The Pulse tab is now the network-status surface.

It currently shows:

- overall gateway state
- quick line-check probe replies
- gateway-run speed test
- phone-side speed test
- enforcement posture
- resolver lock and encrypted-DNS posture
- impacted devices
- recent gateway changes

From Pulse, the app can lead a person into:

- device detail
- enforcement settings
- audit history
- grouped routines

### Device Detail

The device detail screen supports:

- pause and resume
- daily time-limit updates
- category block creation
- moving a device into a group or profile

### Modes

The Modes area is where grouped controls live.

It currently supports:

- profile-based schedules
- profile pause and resume
- preset-style routines such as bedtime or study mode
- creating and renaming profiles

### More

The More area currently includes:

- trusted-device management
- enforcement settings
- audit log
- build log

## Trusted Devices In The App

The app now reflects the trusted-device model used by the gateway.

That means:

- a phone is either approved or not approved
- approved phones have a role
- roles affect what the phone can do

Current roles:

- `owner`
- `manager`
- `viewer`

The trusted-device screen allows:

- generating pairing passes
- showing the pairing pass as a QR code
- changing another phone's approval role
- revoking another phone

## Audit Log In The App

The audit screen reads from the gateway and shows recent actions such as:

- pairing code generation
- phone pairing claims
- trusted-device role changes
- trusted-device revocation
- policy changes
- gateway setting changes

## Current App Assumptions

For Android emulator development, the app points to:

- `http://10.0.2.2:8000`

That comes from the API client in the project today.
If the gateway host changes, that base URL needs to change too.

## What The App Does Not Do By Itself

The app does not directly:

- block packets
- rewrite DNS
- pause a home network on its own
- measure traffic on its own

Those responsibilities belong to the gateway.

## Run The App

1. Make sure the WiFence gateway is running on port `8000`
2. `flutter pub get`
3. `flutter run`

## Current Development Notes

The app is already beyond a visual shell.
It is wired into real local auth, pairing, roles, audit, device control, grouped control, and gateway settings.

What still depends on the backend environment:

- real packet-block validation
- real Linux enforcement application
- final gateway deployment testing outside Windows dev mode

## Related Files

- [lib/main.dart](/mnt/c/Users/delan/Desktop/Chisolution%20Inc/networkApp/Wifence-app/lib/main.dart)
- [lib/screens/dashboard_screen.dart](/mnt/c/Users/delan/Desktop/Chisolution%20Inc/networkApp/Wifence-app/lib/screens/dashboard_screen.dart)
- [lib/screens/auth_screen.dart](/mnt/c/Users/delan/Desktop/Chisolution%20Inc/networkApp/Wifence-app/lib/screens/auth_screen.dart)
- [lib/screens/trusted_devices_screen.dart](/mnt/c/Users/delan/Desktop/Chisolution%20Inc/networkApp/Wifence-app/lib/screens/trusted_devices_screen.dart)
- [lib/screens/audit_log_screen.dart](/mnt/c/Users/delan/Desktop/Chisolution%20Inc/networkApp/Wifence-app/lib/screens/audit_log_screen.dart)
