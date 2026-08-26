# Agentforce Configuration Document

This document specifies the conversational AI agent for the Appointment
Management Assistant: its topics, instructions, actions, prompt engineering, and
the Einstein Trust Layer settings that govern it. It is written so the agent can
be rebuilt exactly once Agentforce is enabled on the org.

## 1. Agent overview

| Setting | Value |
|---------|-------|
| Agent name | Appointment Assistant |
| Type | Agentforce Service Agent (customer-facing) |
| Primary language | English |
| Company / brand voice | Friendly, concise, professional |
| Channels | Experience Cloud site / embedded chat |

**Persona / role instructions (system prompt):**

> You are the Appointment Assistant for our company. You help customers book,
> reschedule, and cancel appointments. Be warm, brief, and clear. Always confirm
> the date, time, and service type before making a change. If a request is
> outside appointments, politely hand off to a human agent. Never invent
> availability or appointment details — only use the data returned by your
> actions.

## 2. Topics and instructions

Agentforce routes a conversation to a **topic** based on the user's intent. Each
topic has scope instructions and a set of allowed actions.

### Topic: Schedule Appointment
- **Scope:** Use when the customer wants to book a new appointment.
- **Instructions:** Collect the service type and the preferred date/time. If the
  customer is not already identified, ask for enough detail to find their
  Contact. Confirm the details, then call the **Create Appointment** action.
- **Sample utterances:**
  - "I'd like to book a consultation next Tuesday at 2pm."
  - "Can I schedule a support session?"
  - "Set up an appointment for me."

### Topic: Reschedule Appointment
- **Scope:** Use when the customer wants to move an existing appointment.
- **Instructions:** Identify the existing appointment (by number or by looking up
  the customer's upcoming appointments). Collect the new date/time, confirm, then
  call the **Reschedule Appointment** action.
- **Sample utterances:**
  - "Move my appointment to Friday morning."
  - "I need to reschedule APT-00004."
  - "Can we change the time of my booking?"

### Topic: Cancel Appointment
- **Scope:** Use when the customer wants to cancel.
- **Instructions:** Identify the appointment, confirm the customer really wants
  to cancel, then call the **Cancel Appointment** action.
- **Sample utterances:**
  - "Cancel my appointment."
  - "I can't make APT-00002 anymore."
  - "Please remove my booking for tomorrow."

## 3. Agent actions

The agent performs work by calling Salesforce actions. All three map to the
single invocable Apex action in this repo, `ManageAppointmentAction`
(`force-app/main/default/classes/ManageAppointmentAction.cls`), or to the
equivalent autolaunched Flows. Using one invocable method keeps the logic in one
place and bulkifiable.

| Agent action | Backing implementation | Inputs | Output |
|--------------|------------------------|--------|--------|
| Create Appointment | `ManageAppointmentAction` (action = `create`) or `Create Appointment` Flow | Contact Id, Date/Time, Service Type | Success flag, message, Appointment Id |
| Reschedule Appointment | `ManageAppointmentAction` (action = `reschedule`) or `Reschedule Appointment` Flow | Appointment Id, new Date/Time | Success flag, message |
| Cancel Appointment | `ManageAppointmentAction` (action = `cancel`) or `Cancel Appointment` Flow | Appointment Id | Success flag, message |

Because `ManageAppointmentAction` is an `@InvocableMethod`, it appears directly
in the Agentforce action library and in Flow — no extra wrapper is needed. This
is the **Agentforce + Flow integration** point.

## 4. Prompt engineering notes

- **Slot filling:** Instructions ask the model to gather *all* required fields
  (service type + date/time for booking) before calling an action, so the action
  never fails on missing input. The Apex action also validates and returns a
  friendly message if something is still missing — defense in depth.
- **Confirmation step:** The agent restates the parsed date/time back to the
  customer before committing. This catches natural-language ambiguity ("next
  Tuesday") before a record is created.
- **Grounding:** The agent is told to use only the values returned by its actions
  and never to invent appointment details or availability. The action's returned
  `message` is what the agent reads back, so confirmations are always accurate.
- **Graceful hand-off:** Out-of-scope requests route to a human rather than the
  model guessing.

## 5. Einstein Trust Layer

| Control | Setting for this agent |
|---------|------------------------|
| Data masking | Mask PII (names, phone, email) before it reaches the LLM |
| Zero data retention | Enabled — prompts/responses are not retained by the model provider |
| Toxicity / safety scoring | Enabled on responses |
| Audit trail | Prompt and response logging enabled for review |
| Grounding source | Salesforce records via the actions above only |

## 6. Testing the agent

See `docs/TEST_PLAN.md` for the conversational test cases (happy path, missing
slot, ambiguous date, cancel confirmation, out-of-scope hand-off) and expected
results.

## 7. Deployment status (honest note)

The agent above is fully specified and the backing actions
(`ManageAppointmentAction`, the Flows) are built and deployable. On the
Developer Edition org used for the capstone, the **Agentforce Agents** feature
was not available for activation (the org lacked the required licensing/tenant
configuration), so the conversational layer could not be turned on there. The
Screen Flow (`Book Appointment Screen`) was delivered as a working, user-facing
booking interface that exercises the same underlying logic. Everything in this
document is ready to build as-is on any org where Agentforce is enabled.
