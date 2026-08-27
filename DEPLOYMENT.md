# Deployment Guide

Everything the Appointment Management Assistant is made of now lives in this
repository as Salesforce source. A grader, a teammate, or a future you can stand
the whole solution up in a fresh org with one deploy command — no manual
clicking to rebuild the object, the Flows, the app, or the reports.

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`) installed
- A Salesforce org (Developer Edition, sandbox, or scratch org)
- Git

```bash
sf --version
```

## 1. Authorize your org

```bash
sf org login web --alias appt-org --set-default
```

A browser opens; log in and approve. `appt-org` is now your default org.

## 2. Deploy

Validate first, then deploy for real:

```bash
# Dry run — checks everything without saving a thing
sf project deploy start --manifest manifest/package.xml --dry-run

# Deploy
sf project deploy start --manifest manifest/package.xml
```

This deploys, in dependency order:

| Metadata | What it is |
|----------|------------|
| `CustomObject` / `CustomField` / `ListView` | The Appointment object, its five fields, and two list views |
| `ApexClass` | `AppointmentController`, `ManageAppointmentAction`, and three test classes |
| `LightningComponentBundle` | The `upcomingAppointments` LWC |
| `Flow` | Create / Reschedule / Cancel (autolaunched) and Book Appointment Screen |
| `CustomApplication` / `CustomTab` / `FlexiPage` | The Appointment Management app, its object tab, and its home page |
| `ReportType` / `Report` / `Dashboard` | Appointments Report type, Appointments by Status, Appointments Dashboard |
| `PermissionSet` | Appointment Management User |

## 3. Assign access and run the tests

```bash
sf org assign permset --name Appointment_Management_User

sf apex run test --test-level RunLocalTests --result-format human --wait 10
```

All three test classes should pass. `AppointmentSecurityTest` runs as a
permission-set-only user and proves the least-privilege design holds: that user
can book an appointment but cannot delete one.

## 4. Two things the platform will not let metadata do for you

Both take about ten seconds each in Setup, and neither blocks the deploy.

1. **Assign the home page.** Lightning page *assignments* are not part of
   FlexiPage metadata. Open **Setup → Lightning App Builder → Appointment
   Management Home → Activation** and set it as the app default for the
   Appointment Management app. Until then the app opens on the standard home
   page and the `upcomingAppointments` component is not on it — you can also
   just drag the component on from App Builder.
2. **Activate the Flows if your org deploys them inactive.** The Flow metadata
   here is marked `Active`. If your org overrides that, open each Flow in
   Setup → Flows and click Activate.

## 5. Verify it works

```bash
sf org open
```

Switch to the **Appointment Management** app, then:

1. **Appointments tab → New** — create a record; it should get an `APT-#####`
   number and default to Status = Scheduled.
2. **Book Appointment Screen Flow** — run it, pick a future date and a service
   type, and check the appointment number it hands back.
3. Try a **past date** in the same Flow — it should send you back with a message
   instead of creating the record.
4. **Home page** — the Upcoming Appointments component lists what you just
   booked, soonest first.
5. **Reports → Appointments by Status** — the new record appears under Scheduled,
   and the dashboard chart moves with it.

## 6. Deploying from source instead of the manifest

The manifest is the reliable path because it deploys in a known order. If you
prefer, the whole source directory works too:

```bash
sf project deploy start --source-dir force-app
```

## Troubleshooting

- **`You can't specify field permissions for required fields`** — this is exactly
  why `Appointment_Date_Time__c` and `Status__c` are deliberately absent from the
  permission set's `fieldPermissions`. Adding them back breaks the deploy; the
  platform grants read/edit on required fields implicitly.
- **`no Report named ... found`** — the `ReportType` must exist before the
  `Report`. The manifest already orders them correctly; this only bites when
  deploying a partial subset.
- **FlexiPage fails to deploy** — the home page depends on the
  `upcomingAppointments` LWC existing first. Deploy the full manifest rather than
  the FlexiPage on its own.
- **Apex test failures block a production deploy** — deploy to a sandbox or
  scratch org first, confirm the tests pass there, then promote.
- **LWC not visible in App Builder** — confirm your user has the
  `Appointment_Management_User` permission set assigned.

## Retrieving org changes back into Git

If you change something in the org through Setup, pull it back so the repository
stays the source of truth:

```bash
sf project retrieve start --manifest manifest/package.xml
git add force-app
git commit -m "Retrieve org changes"
```
