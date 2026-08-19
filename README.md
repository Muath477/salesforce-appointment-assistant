# AI-Powered Appointment Management Assistant

**Domain:** Customer Relationship Management (CRM) · **Platform:** Salesforce
**Author:** Muath Al-Mutairi · **Type:** Capstone Project

---

## Overview

An appointment management solution built on Salesforce that automates the
scheduling, rescheduling, and cancellation of customer appointments. Business
logic is implemented with reusable Flows, a Screen Flow provides a working
booking interface for end users, and a Lightning App plus reports and a
dashboard give administrators full operational visibility. The automation is
designed to be "agent-ready" so an Agentforce agent can call the same Flows once
licensing is enabled.

---

## Data Model

Custom object **Appointment** (Record Name = Auto Number `APT-{00000}`):

| Field | Type |
|-------|------|
| Appointment Number | Auto Number — `APT-{00000}` (Record Name) |
| Contact (Customer) | Lookup → Contact |
| Appointment Date/Time | Date/Time |
| Status | Picklist — Scheduled · Rescheduled · Completed · Cancelled |
| Service Type | Picklist — Consultation · Follow-up · Support · Other |
| Notes | Long Text Area |

_See `Screenshots/01_Data_Model_Appointment_Fields.png`._

---

## Automation — Autolaunched Flows (all Active)

- **Create Appointment** — inputs: Contact Id, Date/Time, Service Type → creates a record and returns the Appointment Id.
- **Reschedule Appointment** — inputs: Appointment Id, New Date/Time → updates the date and sets Status = Rescheduled.
- **Cancel Appointment** — input: Appointment Id → sets Status = Cancelled.

_See `Screenshots/02_Flow_Create_Appointment.png`, `03_Flow_Reschedule_Appointment.png`, `04_Flow_Cancel_Appointment.png`._

---

## Screen Flow — Booking Interface

**"Book Appointment Screen"** (Active) collects Date/Time and Service Type from
the user and creates the appointment record on submission. It serves as a real,
user-facing booking front-end and a working alternative to the conversational AI
agent.

_See `Screenshots/05_Screen_Flow_Book_Appointment_Builder.png`, `06_Screen_Flow_Booking_Screen.png`._

---

## Lightning App

**"Appointment Management"** Lightning App with tabs: Appointments, Contacts,
Reports, Dashboards. Includes a custom tab for the Appointment object and is
assigned to the System Administrator profile.

_See `Screenshots/07_Appointments_List_View.png`, `08_Appointment_Record_APT-00004.png`._

---

## Reports & Dashboard

- **Report:** "Appointments by Status" (Custom Report Type "Appointments Report") — grouped by Status with a chart.
- **Dashboard:** "Appointments Dashboard" visualizing the data.

_See `Screenshots/09_Report_Appointments_by_Status.png`, `10_Dashboards_List.png`, `11_Appointments_Dashboard.png`._

---

## Agentforce — Honest Status

Agentforce was part of the architecture from the start. Activation was
constrained by the Developer Edition org (missing tenant configuration and
licensing); "Agentforce Agents" returned "No matching items found" in Setup.
Mitigation: the Flows were built as agent-ready actions and a fully working
Screen Flow was delivered as an equivalent booking interface. The integration
path is documented and ready once licensing is enabled.

---

## Testing & Results

- Data model, Flows, Screen Flow, App, and Reports all built and Active.
- Live appointment records created and verified (e.g. `APT-00001` … `APT-00004`).
- Create / Reschedule / Cancel logic validated on real records.
- Status transitions confirmed: Scheduled → Rescheduled / Cancelled.

---

## Package Contents

```
Appointment Management Assistant/
├── README.md                                        ← this file
├── Appointment_Management_Project_Documentation.docx ← full project documentation
├── Appointment_Assistant_Capstone.pptx               ← final presentation
└── Screenshots/                                       ← visual evidence (11 images)
```

## Demo Video

The screen-recorded demo is shared as a link (not bundled, to keep this package
lightweight). Paste the public URL (YouTube / Google Drive) into the
**Demo Video Link** field on the submission page:

`Demo Video: <paste your public link here>`

---

## Skills Demonstrated

Salesforce data modeling · Security & access · Flow Builder (Autolaunched &
Screen Flows) · Lightning App Builder · Custom tabs · Reports & Dashboards ·
Custom Report Types · AI-ready solution design · Requirement analysis ·
Testing & documentation.
