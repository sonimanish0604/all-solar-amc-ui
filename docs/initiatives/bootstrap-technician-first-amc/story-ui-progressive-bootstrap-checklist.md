---
name: Story
about: Capture a user-facing or platform capability with acceptance criteria
title: "Story: Technician can complete a progressive checklist during a bootstrap visit"
---

## User Story
As a technician, I want the checklist during a bootstrap visit to start simple and adapt as the system type becomes clearer, so that I can keep working in the field without being blocked by a long or mismatched checklist.

## Actors
- Primary: Technician
- Secondary: Supervisor

## Context
Bootstrap visits should not assume the plant is fully classified before field work starts.

The checklist should begin with a common AMC core and then reveal additional sections or items based on:
- detected equipment profile
- selected or assigned starter template
- supervisor-defined additions where applicable

## Acceptance Criteria
- [ ] Technician can begin a bootstrap visit with a small common core checklist instead of a fully expanded form
- [ ] App can progressively reveal or enable additional checklist sections when the assigned template or detected profile requires them
- [ ] Checklist UI clearly distinguishes common core items from template- or profile-specific items
- [ ] Progressive checklist updates do not discard already captured technician responses unexpectedly

## Subtasks
- [ ] API / backend changes
- [ ] Data model / persistence
- [ ] Validation / authorization
- [ ] Tests
- [ ] Docs / notes

## Test Cases
- [ ] Happy path: technician starts with core checklist and sees additional relevant sections appear as profile/template data becomes available
- [ ] Validation failure: app handles missing template-specific data gracefully without blocking core capture flow too early
- [ ] Authorization / tenancy: technician receives only checklist content assigned within their tenant context
- [ ] Edge case / retry / idempotency: progressive template refresh does not duplicate questions or lose previously saved answers

## Dependencies
- Backend checklist-template resolution story
- Mobile bootstrap start-and-capture story

## Completion Evidence
- PR:
- Test run:
- Build/deploy check:
