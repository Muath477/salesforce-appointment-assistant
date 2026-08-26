# Deployment Guide

This guide covers deploying the Appointment Management Assistant source in this
repository to a Salesforce org, and retrieving your existing org configuration
(Flows, Lightning App, Reports) so the whole solution lives in version control.

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`) installed
- Access to your Salesforce org (Developer Edition or a sandbox)
- Git

Check the CLI is installed:

```bash
sf --version
```

## 1. Authorize your org

```bash
sf org login web --alias appt-org --set-default
```

A browser opens; log in and approve. `appt-org` is now your default org.

## 2. Deploy the source in this repo

This deploys the custom object, fields, Apex classes, the LWC, and the
permission set.

```bash
# Validate first without saving anything (a dry run)
sf project deploy start --dry-run --manifest manifest/package.xml

# Then deploy for real
sf project deploy start --manifest manifest/package.xml
```

> **Already have the Appointment object in your org?**
> If you built the object and fields manually earlier, deploying the versions in
> `force-app/main/default/objects/` will simply update them to match (it does not
> create duplicates, because metadata is keyed by API name). If your field API
> names differ from the ones here, **retrieve your real object first** (see
> step 4) and skip re-deploying the object.

## 3. Assign the permission set and run the tests

```bash
# Give your user access to the Appointment object and Apex classes
sf org assign permset --name Appointment_Management_User

# Run the Apex tests (deployment to production requires passing tests)
sf apex run test --test-level RunLocalTests --result-format human --wait 10
```

## 4. Retrieve your existing org configuration into the repo

The Flows, Lightning App, Reports, and Dashboard you built in the org are not
yet in Git. Pull them so the repository is a complete, deployable copy of the
solution. Replace the example names with the exact API names from your org
(Setup shows them).

```bash
# Flows (Create / Reschedule / Cancel / Book Appointment Screen)
sf project retrieve start --metadata Flow

# The Lightning app, its tabs, and the custom Appointment record page
sf project retrieve start --metadata CustomApplication CustomTab FlexiPage

# Reports and the dashboard
sf project retrieve start --metadata Report ReportType Dashboard

# Security you configured (profiles / permission sets / sharing)
sf project retrieve start --metadata PermissionSet Profile
```

After retrieving, review the new files under `force-app/main/default/`, then
commit them:

```bash
git add force-app
git commit -m "Add retrieved Flows, Lightning App, and Reports metadata"
```

## 5. Deploy everything to a fresh org (grading / demo)

Once the repo holds all the metadata, a grader can stand up the whole solution
in one command against a new scratch org or sandbox:

```bash
sf project deploy start --source-dir force-app
```

## Troubleshooting

- **"Missing field: Appointment_Date_Time__c"** — a Flow or the LWC references a
  field API name that doesn't match your org. Retrieve your real object
  (`sf project retrieve start --metadata CustomObject:Appointment__c`) and align
  the names.
- **Apex test failures block deployment** — deployments to production run tests.
  Deploy to a sandbox or scratch org first, confirm tests pass, then use a
  change set or `sf project deploy start` to production.
- **LWC not visible in App Builder** — confirm `isExposed` is `true` in
  `upcomingAppointments.js-meta.xml` (it is, by default here) and that your user
  has the permission set assigned.
