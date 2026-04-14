---
name: Story
about: Capture a user-facing or platform capability with acceptance criteria
title: "Story: Backend can build provisional site and asset suggestions from first-visit evidence"
---

## User Story
As a supervisor or system, I want first-visit technician evidence to build provisional site and asset suggestions, so that the platform can bootstrap site master data from field work without forcing the technician to complete full setup first.

## Actors
- Primary: Supervisor
- Secondary: Technician

## Context
Suggested project fields: Type = Core, Area = Backend.

This story covers the backend logic that turns captured label photos, readings, notes, and GPS context into provisional site and asset suggestions.

The output must remain suggestive and reviewable, not final truth.

## Acceptance Criteria
- [ ] Backend can persist provisional asset information from first-visit evidence before final site inventory is confirmed
- [ ] Backend can store inferred values such as suggested site linkage, inferred inverter count, and inferred total inverter capacity as suggestions
- [ ] Backend can create a draft site record or unresolved resolution payload from a submitted bootstrap session
- [ ] Duplicate-match candidates for sites or assets are flagged for review rather than blindly merged

## Subtasks
- [ ] API / backend changes
- [ ] Data model / persistence
- [ ] Validation / authorization
- [ ] Tests
- [ ] Docs / notes

## Test Cases
- [ ] Happy path: first-visit evidence produces a usable draft site and provisional asset summary
- [ ] Validation failure: incomplete or low-confidence evidence is marked for review instead of being treated as final
- [ ] Authorization / tenancy: site and asset suggestions remain tenant-scoped
- [ ] Edge case / retry / idempotency: repeated evidence sync does not create uncontrolled duplicate provisional assets

## Dependencies
- Backend bootstrap visit-session story
- Equipment label, OCR, and evidence-capture pipeline decisions

## Completion Evidence
- PR:
- Test run:
- Build/deploy check:
