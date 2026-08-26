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

---

## Repository structure

```
salesforce-appointment-assistant/
├── README.md                         ← this file
├── DEPLOYMENT.md                     ← how to deploy this source and retrieve org config
├── force-app/main/default/           ← deployable Salesforce source
│   ├── objects/Appointment__c/       ← custom object + fields
│   ├── classes/                      ← Apex: AppointmentController, ManageAppointmentAction (+ tests)
│   ├── lwc/upcomingAppointments/     ← custom Lightning Web Component
│   └── permissionsets/               ← Appointment Management User permission set
├── manifest/package.xml              ← metadata manifest for deployment
├── docs/
│   ├── AGENTFORCE.md                 ← agent topics, actions, prompt engineering, Trust Layer
│   └── TEST_PLAN.md                  ← test plan & results (Apex, Flow, UI, agent)
├── Appointment_Management_Project_Documentation.docx
├── Appointment_Assistant_Capstone.pptx
├── Agentforce_Integration_Report.pdf
└── Screenshots/                      ← visual evidence (11 images)
```

> The Flows, Lightning App, Reports, and Dashboard were built in the org and are
> documented below with screenshots. Pull them into `force-app/` with the
> retrieve commands in **DEPLOYMENT.md** so the repository becomes a complete,
> one-command-deployable copy of the solution.

---

## Data Model

Custom object **Appointment** (`Appointment__c`, Record Name = Auto Number `APT-{00000}`):

| Field (API name) | Type |
|------------------|------|
| Appointment Number | Auto Number — `APT-{00000}` (Record Name) |
| Contact (`Contact__c`) | Lookup → Contact |
| Appointment Date/Time (`Appointment_Date_Time__c`) | Date/Time |
| Status (`Status__c`) | Picklist — Scheduled · Rescheduled · Completed · Cancelled |
| Service Type (`Service_Type__c`) | Picklist — Consultation · Follow-up · Support · Other |
| Notes (`Notes__c`) | Long Text Area |

Deployable metadata: `force-app/main/default/objects/Appointment__c/`.
_See `Screenshots/01_Data_Model_Appointment_Fields.png`._

---

## Automation

**Autolaunched Flows (all Active):** Create, Reschedule, and Cancel Appointment.
_See `Screenshots/02–04`._

**Invocable Apex action — `ManageAppointmentAction`:** a single
`@InvocableMethod` that creates, reschedules, or cancels an appointment. It is
callable from **both** Agentforce agent actions and Flow, which is the
Agentforce-to-Flow integration point. Source:
`force-app/main/default/classes/ManageAppointmentAction.cls` (with test class).

---

## Screen Flow — Booking Interface

**"Book Appointment Screen"** (Active) collects Date/Time and Service Type and
creates the appointment on submission — a real, user-facing booking front-end and
a working alternative to the conversational agent.
_See `Screenshots/05–06`._

---

## Custom Lightning Web Component

**`upcomingAppointments`** — a custom LWC that lists the next upcoming,
non-cancelled appointments (soonest first) in a table, with an admin-configurable
row count and a clean empty state. It is backed by the `AppointmentController`
Apex class (SOQL with security enforced) and is exposed to Home, App, and Record
pages in App Builder. Source: `force-app/main/default/lwc/upcomingAppointments/`.

---

## Lightning App

**"Appointment Management"** Lightning App with tabs: Appointments, Contacts,
Reports, Dashboards, and a custom Home Page hosting the LWC and key reports.
_See `Screenshots/07–08`._

---

## Reports & Dashboard

- **Report:** "Appointments by Status" (Custom Report Type) — grouped by Status with a chart.
- **Dashboard:** "Appointments Dashboard".

_See `Screenshots/09–11`._

---

## Security & Access

Object- and field-level access is packaged as the **Appointment Management User**
permission set (`force-app/main/default/permissionsets/`): create/read/edit on
Appointment and its fields, no delete, plus access to the Apex classes. Assign it
with `sf org assign permset --name Appointment_Management_User`.

---

## Agentforce

The conversational agent — topics (Schedule / Reschedule / Cancel), instructions,
actions, prompt-engineering notes, and Einstein Trust Layer settings — is fully
specified in **`docs/AGENTFORCE.md`**. Its actions map to the built-and-tested
`ManageAppointmentAction` and Flows.

**Honest status:** activation was constrained by the Developer Edition org
(missing Agentforce licensing/tenant configuration), so the conversational layer
could not be turned on there. The Screen Flow was delivered as an equivalent
working booking interface, and the agent is ready to build as-is on any
Agentforce-enabled org. Full detail in `Agentforce_Integration_Report.pdf`.

---

## Deployment

See **`DEPLOYMENT.md`** for the full workflow: authorize an org, deploy this
source, run the Apex tests, assign the permission set, and retrieve your existing
Flows / App / Reports into version control. Quick start:

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
| Secure, scalable data model | `objects/Appointment__c/`, permission set |
| Security & Access Management | `permissionsets/Appointment_Management_User` |
| Flow Builder (Screen / Autolaunched) | Flows in org + `ManageAppointmentAction` + Screenshots 02–06 |
| Custom Lightning Web Component | `lwc/upcomingAppointments/` |
| Agentforce (topics, actions, prompt engineering, Trust Layer) | `docs/AGENTFORCE.md`, `ManageAppointmentAction`, `Agentforce_Integration_Report.pdf` |
| Agentforce ↔ Flow integration | `ManageAppointmentAction` (`@InvocableMethod`) |
| Lightning App, Home/Record pages | Lightning App in org + Screenshots 07–08 |
| Reports & Dashboards | Reports/Dashboard in org + Screenshots 09–11 |
| Testing, debugging, UAT | `docs/TEST_PLAN.md` + Apex test classes |
| Deployment & Activation | `DEPLOYMENT.md`, `manifest/package.xml` |
| Version Control (Git) | this repository |
| Documentation & Presentation | `.docx`, `.pptx`, `Agentforce_Integration_Report.pdf` |

---

## Demo Video

Paste the public URL (YouTube / Google Drive) into the **Demo Video Link** field
on the submission page.
