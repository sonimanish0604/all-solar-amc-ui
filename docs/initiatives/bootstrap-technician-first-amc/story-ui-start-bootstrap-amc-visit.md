---
name: Story
about: Capture a user-facing or platform capability with acceptance criteria
title: "Story: Technician can start a bootstrap AMC visit without a pre-created site or workorder"
---

## User Story
As a technician, I want to start a first-time AMC visit without a pre-created site or workorder, so that I can use the app immediately in the field and begin evidence capture while performing AMC steps.

## Actors
- Primary: Technician
- Secondary: Supervisor

## Context
This story covers the mobile bootstrap start and capture entry point.

The regular scheduled workorder-first flow must remain available and unchanged.

This story depends on a backend bootstrap visit-session API but should keep the technician UX focused on one-tap start, low typing effort, and evidence-first capture.

## Acceptance Criteria
- [ ] Technician can start a bootstrap AMC visit from the home flow without selecting or creating a site first
- [ ] App can resume an unfinished bootstrap visit session
- [ ] Technician can capture equipment label photos, meter photos, general photos, and notes within the bootstrap session
- [ ] Session UI clearly indicates that site information is provisional or unresolved during first-time capture

## Subtasks
- [ ] API / backend changes
- [ ] Data model / persistence
- [ ] Validation / authorization
- [ ] Tests
- [ ] Docs / notes

## Test Cases
- [ ] Happy path: technician starts a bootstrap visit and captures first evidence successfully
- [ ] Validation failure: app blocks invalid session transition or missing required submit prerequisites
- [ ] Authorization / tenancy: technician cannot resume another tenant's or another user's bootstrap session
- [ ] Edge case / retry / idempotency: technician closes and reopens the app and can continue the same draft session safely

## Dependencies
- Backend bootstrap visit-session story
- Existing mobile authentication and role resolution

## Completion Evidence
- PR:
- Test run:
- Build/deploy check:
