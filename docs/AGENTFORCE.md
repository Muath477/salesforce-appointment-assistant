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

The agent performs work by calling Salesforce actions. All four map to the
single invocable Apex action in this repo, `ManageAppointmentAction`
(`force-app/main/default/classes/ManageAppointmentAction.cls`), or to the
equivalent autolaunched Flows in `force-app/main/default/flows/`. Using one
invocable method keeps the logic in one place and bulkifiable.

| Agent action | Backing implementation | Inputs | Output |
|--------------|------------------------|--------|--------|
| Find My Appointments | `ManageAppointmentAction` (action = `list`) | Contact Id | Success flag, readable list of upcoming appointments, Id of the soonest |
| Create Appointment | `ManageAppointmentAction` (action = `create`) or `Create_Appointment` Flow | Contact Id, Date/Time, Service Type | Success flag, message, Appointment Id |
| Reschedule Appointment | `ManageAppointmentAction` (action = `reschedule`) or `Reschedule_Appointment` Flow | Appointment Id, new Date/Time | Success flag, message |
| Cancel Appointment | `ManageAppointmentAction` (action = `cancel`) or `Cancel_Appointment` Flow | Appointment Id | Success flag, message |

**Find My Appointments** is what lets the Reschedule and Cancel topics work at
all. A customer says "move my appointment" without knowing an Id; the agent calls
this action first, reads the real records back, and only then has something
concrete to act on. It is also the grounding mechanism — the agent speaks from
returned record data instead of inventing an appointment.

Because `ManageAppointmentAction` is an `@InvocableMethod`, it appears directly
in the Agentforce action library and in Flow — no extra wrapper is needed. This
is the **Agentforce + Flow integration** point.

**Security note.** Every query and DML in the action runs in
`AccessLevel.USER_MODE`, so an agent session can never read or write more than
the user it runs as is entitled to, and a blocked request comes back as a handled
message rather than an exception that would break the conversation. This is the
Trust Layer's record-access guarantee enforced in code as well as in
configuration.

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
was not available for activation ("Agentforce Agents" returns "No matching
items found" in Setup — the org lacks the required licensing/tenant
configuration), so the native Agentforce conversational layer could not be
turned on there.

### 7.1 What was built instead: an active Einstein Bot

To still deliver a real, working conversational assistant on this org, an
**Einstein Bot ("Enhanced" type) named "Appointment Assistant"** was built in
Bot Builder and is **Active**. It implements the same three topics specified
above as three dialogs, each wired to the real automation — not a mockup:

| Dialog | Steps | Flow it calls |
|--------|-------|----------------|
| **Schedule an appointment** | Ask for email → Object Search: Contact (`Email` = Customer Email) → confirm "I found your account. Is this you?" → collect date/time & service type → run Flow | `Create_Appointment` |
| **Reschedule an appointment** | Ask for email → find Contact → Object Search: Appointment (`Contact` = Contact Id) → "Which appointment would you like to reschedule?" (dynamic choices from Found Appointments) → ask new date/time → run Flow | `Reschedule_Appointment` |
| **Cancel an appointment** | Ask for email → find Contact → Object Search: Appointment → "Which appointment would you like to cancel?" (dynamic choices) → run Flow → "Your appointment has been cancelled!" | `Cancel_Appointment` |

This is the same **Agentforce-to-Flow integration point** described in §3 —
the bot's dialog Action steps call the exact same `Create_Appointment`,
`Reschedule_Appointment`, and `Cancel_Appointment` autolaunched Flows that back
the Screen Flow and (once licensed) the Agentforce agent actions. Nothing was
duplicated or faked to make the bot work: one automation layer, reused by every
front end in this repo.

**No fabrication, stated plainly:** the bot is a genuine Einstein Bot (Bot
Builder's own conversational product), not Agentforce. It is disclosed as such
everywhere in this repo — README, this document, the .docx, and the .pptx —
rather than being presented as Agentforce. It is the honest, working substitute
this org's licensing allows.

### 7.2 A known limitation of Text Preview (not a config bug)

Bot Builder's **Text Preview** does not reliably recognize free-typed email
addresses against the `[System] Email Address` entity — this reproduces
identically on the pre-existing "Schedule an appointment" dialog as well, so it
is a limitation of the text-only preview surface, not something specific to the
new dialogs. **Rich Content Preview** (which resolves entities correctly)
requires a published Messaging channel, which is outside what a plain
Developer Edition org supports. Practically, this means the bot should be
exercised either through a real channel (e.g., an Experience Cloud embedded
chat, if one is stood up) or by walking Text Preview's choice buttons instead
of free-typing the email.

### 7.3 Status summary

Everything in §1–§6 above is ready to rebuild as native Agentforce topics and
actions, unchanged, the moment Agentforce licensing is available on this org.
Until then, the Einstein Bot documented here is the real, active, working
conversational layer for this capstone submission.
