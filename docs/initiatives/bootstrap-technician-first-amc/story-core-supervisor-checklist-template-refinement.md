---
name: Story
about: Capture a user-facing or platform capability with acceptance criteria
title: "Story: Supervisor can refine starter checklist templates with additional site-specific items"
---

## User Story
As a supervisor, I want to refine a starter checklist template with additional site-specific items, so that the app-created template becomes more accurate over time without forcing a perfect design on the first visit.

## Actors
- Primary: Supervisor
- Secondary: Manager

## Context
Suggested project fields: Type = Core, Area = Backend.

Bootstrap template creation should provide a practical starting point, not a final perfect checklist.

This story supports template refinement after field learning, including cases where supervisors add items such as a main energy meter reading or other site-specific checks that extend the detected profile.

## Acceptance Criteria
- [ ] Backend supports versioned refinement of starter checklist templates without rewriting historical checklist responses
- [ ] Supervisor can add or adjust checklist items on top of a starter template for a site or site-profile use case
- [ ] Refined templates can become the preferred template for later visits while preserving traceability to the original starter template
- [ ] Template refinement remains controlled and auditable rather than silently mutating active historical definitions

## Subtasks
- [ ] API / backend changes
- [ ] Data model / persistence
- [ ] Validation / authorization
- [ ] Tests
- [ ] Docs / notes

## Test Cases
- [ ] Happy path: supervisor refines a starter template by adding a new site-relevant checklist item and later visits resolve to the refined version
- [ ] Validation failure: invalid or duplicate checklist item definitions are rejected cleanly
- [ ] Authorization / tenancy: only authorized supervisor or manager roles can refine templates within their tenant
- [ ] Edge case / retry / idempotency: repeated refinement action does not corrupt template version history or duplicate items unexpectedly

## Dependencies
- Backend checklist-template resolution story
- Existing checklist template versioning model in `neilsolaramc`

## Completion Evidence
- PR:
- Test run:
- Build/deploy check:
