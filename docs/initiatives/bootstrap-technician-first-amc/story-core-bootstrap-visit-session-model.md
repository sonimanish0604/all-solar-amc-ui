---
name: Story
about: Capture a user-facing or platform capability with acceptance criteria
title: "Story: Backend can create and manage bootstrap visit sessions separate from canonical workorders"
---

## User Story
As a technician, I want the backend to persist a bootstrap visit session before a site or workorder exists, so that first-time AMC work can begin without office setup and later converge into the normal platform flow.

## Actors
- Primary: Technician
- Secondary: Supervisor

## Context
Suggested project fields: Type = Core, Area = Backend.

Current backend behavior is workorder-first and assumes a known `site_id` and planned visit context.

This story introduces a separate bootstrap visit-session layer rather than weakening the existing canonical workorder model.

## Acceptance Criteria
- [ ] Backend supports create, resume, fetch, and update operations for bootstrap visit sessions without requiring a canonical `site_id` or `workorder_id` at session start
- [ ] Visit-session state is tenant-scoped, user-scoped, auditable, and safe to resume from mobile draft flow
- [ ] Session states support at least draft, in progress, submitted, requires review, and resolved behavior
- [ ] Existing workorder-first APIs and persistence rules remain intact and do not regress

## Subtasks
- [ ] API / backend changes
- [ ] Data model / persistence
- [ ] Validation / authorization
- [ ] Tests
- [ ] Docs / notes

## Test Cases
- [ ] Happy path: technician creates and resumes a bootstrap visit session successfully
- [ ] Validation failure: invalid session status transition is rejected cleanly
- [ ] Authorization / tenancy: cross-tenant or non-owner session access is blocked
- [ ] Edge case / retry / idempotency: repeated create or resume calls do not create duplicate active sessions unexpectedly

## Dependencies
- Existing auth, tenancy, and audit foundations in `neilsolaramc`
- Mobile bootstrap entry flow in `all-solar-amc-ui`

## Completion Evidence
- PR:
- Test run:
- Build/deploy check:
