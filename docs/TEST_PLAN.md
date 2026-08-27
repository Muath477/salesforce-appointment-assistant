# Test Plan & Results

This plan covers the Appointment Management Assistant across three layers:
automation (Flows / Apex), the user interface (Screen Flow + LWC), and the
conversational agent (Agentforce). Statuses reflect what was verified on the
capstone Developer Edition org.

## 1. Apex unit tests (automated)

Run with `sf apex run test --test-level RunLocalTests`.

| Test class | What it verifies | Status |
|------------|------------------|--------|
| `AppointmentControllerTest.returnsOnlyUpcomingNonCancelled` | The LWC controller returns only future, non-cancelled appointments, in date order | Pass |
| `AppointmentControllerTest.nullLimitFallsBackToDefault` | A null row limit does not throw | Pass |
| `ManageAppointmentActionTest.createsAnAppointment` | Create action inserts a Scheduled appointment | Pass |
| `ManageAppointmentActionTest.createDefaultsServiceTypeWhenOmitted` | A missing service type falls back to Consultation | Pass |
| `ManageAppointmentActionTest.reschedulesAndCancels` | Reschedule sets status Rescheduled; cancel sets Cancelled | Pass |
| `ManageAppointmentActionTest.listReturnsUpcomingAppointmentsForContact` | The lookup action returns only upcoming, non-cancelled appointments for that customer | Pass |
| `ManageAppointmentActionTest.listWithNoAppointmentsIsHandled` | A customer with nothing booked gets a clean message | Pass |
| `ManageAppointmentActionTest.pastDateIsRejected` | A date in the past is refused before any record is written | Pass |
| `ManageAppointmentActionTest.missingInputsReturnFriendlyMessages` | Four incomplete requests return four ordered results — bulkification holds | Pass |
| `ManageAppointmentActionTest.unknownActionReturnsMessage` | An unknown action returns a clean error, not an exception | Pass |
| `ManageAppointmentActionTest.nullActionIsHandled` | A null action does not throw | Pass |
| `AppointmentSecurityTest.permissionSetGrantsCreateButNotDelete` | The permission set grants create/read/edit on Appointment and never delete | Pass |
| `AppointmentSecurityTest.permissionSetUserCanBookAnAppointment` | A user holding only this permission set can book through the invocable action | Pass |
| `AppointmentSecurityTest.blockedUserGetsHandledResultNotAnException` | A user without access gets a structured result and a readable message, not an unhandled exception | Pass |

`AppointmentSecurityTest` is the automated counterpart to UAT case **U5** below,
which was originally verified by hand only.

## 2. Flow / automation tests (manual)

| # | Scenario | Steps | Expected result | Status |
|---|----------|-------|-----------------|--------|
| F1 | Create appointment | Run Create Appointment Flow with a Contact, date/time, service type | New `APT-#####` record, Status = Scheduled | Pass (e.g. APT-00001) |
| F2 | Reschedule | Run Reschedule Flow with an appointment Id and a new date/time | Date updated, Status = Rescheduled | Pass |
| F3 | Cancel | Run Cancel Flow with an appointment Id | Status = Cancelled | Pass |
| F4 | Status integrity | Cancel then view record | Status stays Cancelled; no orphaned data | Pass |

## 3. User interface tests (UAT)

| # | Scenario | Steps | Expected result | Status |
|---|----------|-------|-----------------|--------|
| U1 | Booking via Screen Flow | Open Book Appointment Screen, pick service + date/time, submit | Appointment created and confirmation shown | Pass |
| U2 | Upcoming Appointments LWC | Open the Home/App page hosting the component | Next appointments listed, soonest first, cancelled ones hidden | Pass |
| U3 | LWC empty state | View with no upcoming appointments | "No upcoming appointments." message | Pass |
| U4 | Reports & dashboard | Open Appointments by Status report and dashboard | Counts grouped by status match the records | Pass |
| U5 | Field-level security | Log in as a user with only the permission set | Can create/read/edit appointments; cannot delete | Pass (also automated — see §1) |
| U6 | Past-date guard | In the Screen Flow, pick a date/time that has already passed | Flow shows a "choose a future date" screen and creates no record | Pass |
| U7 | Booking confirmation | Complete the Screen Flow | Confirmation screen shows the `APT-#####` reference, service, and date | Pass |

## 4. Conversational agent tests (Agentforce)

To be executed on an Agentforce-enabled org. Expected behaviour per
`docs/AGENTFORCE.md`.

| # | Scenario | Example input | Expected agent behaviour | Status |
|---|----------|---------------|--------------------------|--------|
| A1 | Happy-path booking | "Book a consultation next Tuesday at 2pm" | Confirms details, calls Create action, reads back confirmation | Pending (agent not activated on DE org) |
| A2 | Missing slot | "Book an appointment" | Asks for service type and date/time before acting | Pending |
| A3 | Ambiguous date | "Move it to next week" | Asks for a specific day/time before rescheduling | Pending |
| A4 | Cancel confirmation | "Cancel my appointment" | Confirms intent, then calls Cancel action | Pending |
| A5 | Out of scope | "What's the weather?" | Politely declines / hands off to human | Pending |

## 5. Summary

All automation, Apex, and UI test cases passed on the capstone org. The
conversational test cases (section 4) are specified and ready to run once
Agentforce is enabled; the same backing actions they depend on are already built
and tested (sections 1–2).
