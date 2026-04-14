---
name: Story
about: Capture a user-facing or platform capability with acceptance criteria
title: "Story: Supervisor can review bootstrap visits and confirm site and inventory before regular flow continues"
---

## User Story
As a supervisor, I want to review bootstrap visits and confirm or correct site and inventory details, so that first-time technician evidence becomes trustworthy site master data for future regular AMC work.

## Actors
- Primary: Supervisor
- Secondary: Technician

## Context
Suggested project fields: Type = Core, Area = Backend.

This story focuses on the backend review and confirmation workflow for first-time bootstrap visits.

Related website or supervisor-facing UI work may be tracked separately, but the backend review bundle and confirmation behaviors should be defined here.

## Acceptance Criteria
- [ ] Backend exposes a pending-review view or review bundle for submitted bootstrap visits requiring confirmation
- [ ] Supervisor can confirm or correct site linkage, provisional assets, and key inferred values before final resolution
- [ ] Review outcome updates the bootstrap visit resolution state and prepares the site for future standard workorder-first AMC visits
- [ ] Review flow preserves evidence history and auditability when supervisor corrections are applied

## Subtasks
- [ ] API / backend changes
- [ ] Data model / persistence
- [ ] Validation / authorization
- [ ] Tests
- [ ] Docs / notes

## Test Cases
- [ ] Happy path: supervisor reviews a bootstrap visit and confirms site and inventory successfully
- [ ] Validation failure: invalid asset or site confirmation payload is rejected with clear feedback
- [ ] Authorization / tenancy: only authorized supervisors or equivalent roles can review and confirm visits
- [ ] Edge case / retry / idempotency: repeated confirmation call does not produce conflicting final states

## Dependencies
- Backend provisional site and asset resolution story
- Backend promotion to canonical workorder story

## Completion Evidence
- PR:
- Test run:
- Build/deploy check:
