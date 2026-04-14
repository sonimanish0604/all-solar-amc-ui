---
name: Story
about: Capture a user-facing or platform capability with acceptance criteria
title: "Story: Technician can review and submit a bootstrap AMC visit with minimal confirmation"
---

## User Story
As a technician, I want to review a bootstrap AMC visit and submit it with minimal confirmation, so that I can complete field work without being forced through full site-master setup.

## Actors
- Primary: Technician
- Secondary: Supervisor

## Context
This story covers the review and submit part of the mobile bootstrap flow.

The technician should see evidence summary and suggested values, but inferred values must be clearly labeled as suggestions and not final truth.

## Acceptance Criteria
- [ ] Review flow shows captured evidence summary, suggested site details, and inferred equipment summary in a lightweight technician-friendly format
- [ ] Technician can choose to attach to an existing site, create a new site draft, or leave the visit unresolved for review
- [ ] Only minimal fields are required before submission, consistent with technician-first design
- [ ] Submission success state clearly shows sync/result status and next-step messaging without implying final site confirmation

## Subtasks
- [ ] API / backend changes
- [ ] Data model / persistence
- [ ] Validation / authorization
- [ ] Tests
- [ ] Docs / notes

## Test Cases
- [ ] Happy path: technician submits a bootstrap visit successfully with one of the supported resolution paths
- [ ] Validation failure: submission is blocked only when no usable evidence exists or required minimal choice is missing
- [ ] Authorization / tenancy: technician can submit only their own active bootstrap visit session
- [ ] Edge case / retry / idempotency: repeated submit action does not create duplicate submission outcomes

## Dependencies
- Mobile bootstrap start-and-capture story
- Backend provisional site and asset resolution story

## Completion Evidence
- PR:
- Test run:
- Build/deploy check:
