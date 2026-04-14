---
name: Story
about: Capture a user-facing or platform capability with acceptance criteria
title: "Story: Backend can promote a submitted bootstrap visit into the canonical workorder lifecycle"
---

## User Story
As a platform, I want a submitted bootstrap visit to converge into the normal site and workorder lifecycle, so that downstream reporting, approvals, and future regular AMC flows continue to use the existing canonical backend model.

## Actors
- Primary: Supervisor
- Secondary: Technician

## Context
Suggested project fields: Type = Core, Area = Backend.

This story is the convergence point between the new bootstrap session model and the current workorder-first backend design.

The goal is to preserve and reuse the existing workorder, reporting, and approval foundations rather than replacing them.

## Acceptance Criteria
- [ ] Submitted bootstrap visit can be resolved into one of the supported paths: attach existing site, create new site draft, or hold for supervisor resolution
- [ ] When enough information exists, backend can create or link a canonical workorder without breaking existing workorder-first rules
- [ ] Promotion flow is idempotent and prevents duplicate canonical workorders or duplicate finalized evidence
- [ ] Existing reporting, notification, and approval services remain compatible with promoted bootstrap visits

## Subtasks
- [ ] API / backend changes
- [ ] Data model / persistence
- [ ] Validation / authorization
- [ ] Tests
- [ ] Docs / notes

## Test Cases
- [ ] Happy path: submitted bootstrap visit promotes successfully into a canonical workorder-linked flow
- [ ] Validation failure: unresolved or invalid site mapping prevents premature promotion
- [ ] Authorization / tenancy: only authorized actors can trigger or finalize promotion
- [ ] Edge case / retry / idempotency: repeated promotion attempt does not create duplicate workorders or duplicate promoted evidence

## Dependencies
- Backend bootstrap visit-session story
- Backend provisional site and asset resolution story

## Completion Evidence
- PR:
- Test run:
- Build/deploy check:
