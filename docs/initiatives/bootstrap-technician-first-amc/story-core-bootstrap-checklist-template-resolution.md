---
name: Story
about: Capture a user-facing or platform capability with acceptance criteria
title: "Story: Backend can detect, assign, or create a starter checklist template for bootstrap visits"
---

## User Story
As a platform, I want bootstrap visits to use an existing checklist template when one fits, or create a starter template when none exists, so that first-time AMC work can begin with low friction while still building a reusable checklist foundation.

## Actors
- Primary: Technician
- Secondary: Supervisor

## Context
Suggested project fields: Type = Core, Area = Backend.

The current backend resolves a coarse tenant-level active checklist template.

Bootstrap visits need a smarter selection path that can:
- detect an existing site or system-profile template
- assign a suitable template when confidence is high
- create a starter template when no usable template exists
- preserve versioned template history for later reporting and refinement

Examples to support include:
- pure on-grid plant
- on-grid plant with hybrid inverter and battery bank
- off-grid plant with battery bank
- off-grid plant with battery bank and street-light load

## Acceptance Criteria
- [ ] Backend can resolve checklist-template selection using a priority order such as site-assigned template, detected system-profile template, starter-template creation, and tenant fallback
- [ ] When no suitable template exists, backend can create a starter bootstrap template with common core checklist items plus detected profile modules
- [ ] Template assignment for a bootstrap visit is versioned and stored so historical visit records remain stable even after later template refinement
- [ ] Template resolution remains suggestive and reviewable when profile confidence is low or mixed

## Subtasks
- [ ] API / backend changes
- [ ] Data model / persistence
- [ ] Validation / authorization
- [ ] Tests
- [ ] Docs / notes

## Test Cases
- [ ] Happy path: backend assigns an existing fitting template or creates a starter template successfully for a bootstrap visit
- [ ] Validation failure: ambiguous or low-confidence profile falls back to a reviewable starter path rather than hard failure
- [ ] Authorization / tenancy: template resolution and creation remain tenant-scoped
- [ ] Edge case / retry / idempotency: repeated bootstrap-template resolution does not create uncontrolled duplicate starter templates

## Dependencies
- Backend bootstrap visit-session story
- Existing checklist template and versioning foundation in `neilsolaramc`

## Completion Evidence
- PR:
- Test run:
- Build/deploy check:
