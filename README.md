# AI-Powered Appointment Management Assistant

**Domain:** Customer Relationship Management (CRM) · **Platform:** Salesforce + Agentforce
**Author:** Muath Al-Mutairi · **Type:** Capstone Project

---

## Overview

An appointment management solution built on Salesforce that automates the
scheduling, rescheduling, and cancellation of customer appointments. Business
logic runs on reusable Flows and an invocable Apex action, a Screen Flow provides
a working booking interface for end users, a custom Lightning Web Component
surfaces upcoming appointments, and a Lightning App plus reports and a dashboard
give administrators full operational visibility. The automation is designed to be
**agent-ready**: an Agentforce agent calls the same actions to fulfil
natural-language requests once licensing is enabled.

Every component is checked in as Salesforce source. `sf project deploy start`
rebuilds the entire solution in an empty org — see **[DEPLOYMENT.md](DEPLOYMENT.md)**.

---

## Repository structure

```
salesforce-appointment-assistant/
├── README.md                         ← this file
├── DEPLOYMENT.md                     ← one-command deploy, verification steps, troubleshooting
├── force-app/main/default/           ← deployable Salesforce source
│   ├── objects/Appointment__c/       ← custom object, fields, list views
│   ├── classes/                      ← Apex: AppointmentController, ManageAppointmentAction (+ 3 test classes)
│   ├── lwc/upcomingAppointments/     ← custom Lightning Web Component
│   ├── flows/                        ← Create / Reschedule / Cancel + Book Appointment Screen
│   ├── applications/                 ← Appointment Management Lightning App
│   ├── tabs/                         ← Appointment object tab
│   ├── flexipages/                   ← app Home page hosting the LWC
│   ├── reportTypes/                  ← Appointments Report custom report type
│   ├── reports/                      ← Appointments by Status
│   ├── dashboards/                   ← Appointments Dashboard
│   └── permissionsets/               ← Appointment Management User permission set
├── manifest/package.xml              ← metadata manifest for deployment
├── docs/
│   ├── AGENTFORCE.md                 ← agent topics, instructions, actions, prompt engineering, Trust Layer
│   └── TEST_PLAN.md                  ← test plan & results (Apex, Flow, UI, agent)
├── Appointment_Management_Project_Documentation.docx
├── Appointment_Assistant_Capstone.pptx
├── Agentforce_Integration_Report.pdf
└── Screenshots/                      ← visual evidence from the org (11 images)
```

---

## Data Model

Custom object **Appointment** (`Appointment__c`, Record Name = Auto Number `APT-{00000}`):

| Field (API name) | Type |
|------------------|------|
| Appointment Number | Auto Number — `APT-{00000}` (Record Name) |
| Contact (`Contact__c`) | Lookup → Contact |
| Appointment Date/Time (`Appointment_Date_Time__c`) | Date/Time — required |
| Status (`Status__c`) | Picklist (restricted) — Scheduled · Rescheduled · Completed · Cancelled |
| Service Type (`Service_Type__c`) | Picklist (restricted) — Consultation · Follow-up · Support · Other |
| Notes (`Notes__c`) | Long Text Area |

Cancelling sets `Status__c = 'Cancelled'` rather than deleting the record, so
cancellations stay visible in reporting and the object never needs delete
permission.

Source: `force-app/main/default/objects/Appointment__c/`.
_See `Screenshots/01_Data_Model_Appointment_Fields.png`._

---

## Automation

**Autolaunched Flows** — `Create_Appointment`, `Reschedule_Appointment`,
`Cancel_Appointment`. Each is a no-trigger autolaunched Flow with input/output
variables, so it can be invoked from another Flow, from Apex, or as an Agentforce
agent action. Source: `force-app/main/default/flows/`.
_See `Screenshots/02–04`._

**Invocable Apex action — `ManageAppointmentAction`:** one `@InvocableMethod`
handling four actions — `create`, `reschedule`, `cancel`, and `list`. It is
callable from **both** Agentforce agent actions and Flow, which is the
Agentforce-to-Flow integration point. It runs every query and DML in
`AccessLevel.USER_MODE`, so the platform enforces the running user's object- and
field-level security, and it returns a friendly message rather than throwing —
so a failure never breaks an agent conversation mid-sentence.

The `list` action is what keeps the agent grounded: before rescheduling or
cancelling, the agent asks for the customer's real upcoming appointments and
reads those back, instead of inventing details.

---

## Screen Flow — Booking Interface

**`Book_Appointment_Screen`** (Active) collects date/time, service type, and
optional notes, uses a Decision element to reject dates in the past, creates the
appointment, and confirms the `APT-#####` reference back to the user. Launched
standalone or from a Contact record page, where it links the appointment to that
customer automatically. A real, user-facing booking front-end and a working
alternative to the conversational agent.
_See `Screenshots/05–06`._

---

## Custom Lightning Web Component

**`upcomingAppointments`** — lists the next upcoming, non-cancelled appointments
(soonest first) in a table, with an admin-configurable row count and a clean
empty state. Backed by `AppointmentController` (SOQL `WITH USER_MODE`) and
exposed to Home, App, and Record pages in App Builder. It ships pre-placed on the
`Appointment_Management_Home` FlexiPage. Source:
`force-app/main/default/lwc/upcomingAppointments/`.

---

## Lightning App

**"Appointment Management"** Lightning App with tabs: Home, Appointments,
Contacts, Reports, Dashboards. Source: `force-app/main/default/applications/`
and `tabs/`, with the home page in `flexipages/`.
_See `Screenshots/07–08`._

---

## Reports & Dashboard

- **Report type:** "Appointments Report" — a custom object cannot be reported on
  without one.
- **Report:** "Appointments by Status" — summary format grouped by Status, with a
  column chart.
- **Dashboard:** "Appointments Dashboard" — runs as the logged-in user.

Source: `force-app/main/default/reportTypes/`, `reports/`, `dashboards/`.
_See `Screenshots/09–11`._

---

## Security & Access

Object- and field-level access is packaged as the **Appointment Management User**
permission set: create/read/edit on Appointment, **no delete**, field access,
the Apex classes, the app, and the tab. Least privilege by design.

`AppointmentSecurityTest` proves it automatically — it builds a user on a
minimum-access profile, grants nothing but this permission set, and asserts under
`System.runAs` that the user can book an appointment and cannot delete one.

```bash
sf org assign permset --name Appointment_Management_User
```

> **Note:** `Appointment_Date_Time__c` and `Status__c` are universally required
> fields. Salesforce grants read/edit on required fields implicitly and rejects
> any deployment that declares field permissions for them, so they are
> intentionally absent from the permission set.

---

## Agentforce

The conversational agent — topics (Schedule / Reschedule / Cancel), instructions,
actions, prompt-engineering notes, and Einstein Trust Layer settings — is fully
specified in **[docs/AGENTFORCE.md](docs/AGENTFORCE.md)**. Its actions map to the
built-and-tested `ManageAppointmentAction` and the Flows above.

**Honest status:** activation was constrained by the Developer Edition org
(missing Agentforce licensing/tenant configuration), so the conversational layer
could not be turned on there. The Screen Flow was delivered as an equivalent
working booking interface, and the agent is ready to build as-is on any
Agentforce-enabled org. Full detail in `Agentforce_Integration_Report.pdf`.

---

## Deployment

Full workflow in **[DEPLOYMENT.md](DEPLOYMENT.md)**. Quick start:

```bash
sf org login web --alias appt-org --set-default
sf project deploy start --manifest manifest/package.xml
sf org assign permset --name Appointment_Management_User
sf apex run test --test-level RunLocalTests --result-format human --wait 10
```

---

## Requirements coverage

| Requirement / skill | Where it lives |
|---------------------|----------------|
| Secure, scalable data model | `objects/Appointment__c/` |
| Security & Access Management | `permissionsets/`, `USER_MODE` in Apex, `AppointmentSecurityTest` |
| Data Management | list views, restricted picklists, required fields, auto-number key |
| Flow Builder — autolaunched | `flows/Create_Appointment`, `Reschedule_Appointment`, `Cancel_Appointment` |
| Flow Builder — screen flow | `flows/Book_Appointment_Screen` (screen, decision, create, get, confirm) |
| Flow elements and logic | Decision element rejecting past dates in the Screen Flow |
| Custom Lightning Web Component | `lwc/upcomingAppointments/` |
| Lightning App Builder / App & Home pages | `applications/`, `tabs/`, `flexipages/` |
| Agentforce — topics, instructions, prompt engineering, Trust Layer | `docs/AGENTFORCE.md`, `Agentforce_Integration_Report.pdf` |
| Agentforce ↔ Flow integration | `ManageAppointmentAction` (`@InvocableMethod`), callable from both |
| Reports & Dashboards | `reportTypes/`, `reports/`, `dashboards/` |
| Testing, debugging, UAT | `docs/TEST_PLAN.md` + 3 Apex test classes |
| Deployment & Activation | `DEPLOYMENT.md`, `manifest/package.xml` |
| Version Control (Git) | this repository |
| Documentation & Presentation | `.docx`, `.pptx`, `Agentforce_Integration_Report.pdf` |

---

## Demo Video

_Paste the public URL (YouTube / Google Drive, set to "anyone with the link") here
and in the **Demo Video Link** field on the submission page:_

**Demo video:** `<add link here>`

Suggested three-minute run of show: book an appointment through the Screen Flow →
show it appear in the Upcoming Appointments component → reschedule it → cancel it
→ show the dashboard move.
