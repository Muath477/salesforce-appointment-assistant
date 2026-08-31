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

## 4. Conversational agent tests

Two rows here: native Agentforce (still gated by licensing on this Developer
Edition org — see `docs/AGENTFORCE.md` §7) and the Einstein Bot that was built
as its tested, working substitute. The bot dialogs call the exact same
`Create_Appointment` / `Reschedule_Appointment` / `Cancel_Appointment` Flows an
activated Agentforce agent would call, so §4.2 is real evidence that the
underlying design in §3 of `docs/AGENTFORCE.md` behaves as specified.

### 4.1 Native Agentforce agent (pending license)

Expected behaviour per `docs/AGENTFORCE.md` §1–§5, to be re-verified as-is once
Agentforce is licensed on the org (activation steps in `docs/AGENTFORCE.md`
§7.3 / §6 of the Integration Report).

| # | Scenario | Example input | Expected agent behaviour | Status |
|---|----------|---------------|--------------------------|--------|
| A1 | Happy-path booking | "Book a consultation next Tuesday at 2pm" | Confirms details, calls Create action, reads back confirmation | Pending (Agentforce not licensed on this DE org) |
| A2 | Missing slot | "Book an appointment" | Asks for service type and date/time before acting | Pending |
| A3 | Ambiguous date | "Move it to next week" | Asks for a specific day/time before rescheduling | Pending |
| A4 | Cancel confirmation | "Cancel my appointment" | Confirms intent, then calls Cancel action | Pending |
| A5 | Out of scope | "What's the weather?" | Politely declines / hands off to human | Pending |

### 4.2 Einstein Bot substitute — "Appointment Assistant" (tested)

Executed in Bot Builder's Preview against the live **Active** bot documented in
`docs/AGENTFORCE.md` §7.1. Per the §7.2 Text Preview limitation, email lookup
was driven with the preview's choice buttons rather than free-typed text; this
is a preview-surface limitation, not a dialog defect.

| # | Scenario | Dialog exercised | Expected result | Status |
|---|----------|-------------------|------------------|--------|
| E1 | Schedule dialog reaches the Flow | "Schedule an appointment" | Email lookup finds the Contact, confirms identity, collects date/time and service type, runs `Create_Appointment` | Pass |
| E2 | Reschedule dialog lists real appointments | "Reschedule an appointment" | Object Search returns the customer's real Appointment records as dynamic choices before rescheduling | Pass |
| E3 | Reschedule dialog reaches the Flow | Continue E2, pick an appointment, give a new date/time | Runs `Reschedule_Appointment`, bot confirms the change | Pass |
| E4 | Cancel dialog lists real appointments | "Cancel an appointment" | Object Search returns the customer's real Appointment records as dynamic choices before cancelling | Pass |
| E5 | Cancel dialog reaches the Flow and confirms | Continue E4, pick an appointment | Runs `Cancel_Appointment`, bot replies "Your appointment has been cancelled!" | Pass |

## 5. Summary

All automation, Apex, and UI test cases passed on the capstone org (sections
1–3). The Einstein Bot conversational substitute was exercised end-to-end in
Bot Builder Preview and passed (§4.2), proving out the same
Create/Reschedule/Cancel Flow integration a licensed Agentforce agent would use.
The native Agentforce test cases (§4.1) are specified and ready to run the
moment Agentforce licensing is enabled — no change to the backing Flows or Apex
is required.
