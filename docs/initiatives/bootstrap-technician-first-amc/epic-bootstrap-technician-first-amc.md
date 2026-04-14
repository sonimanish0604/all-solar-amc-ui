---
name: Epic
about: Track a larger outcome spanning multiple stories
title: "Epic: Bootstrap technician-first AMC flow for first-time sites"
---

## Objective
Add a bootstrap AMC flow that lets a technician start work immediately on a first-time site visit without requiring pre-created site master data or a pre-generated workorder, while preserving the existing workorder-first flow for regular planned visits.

## Why This Matters
Field adoption will remain low if the technician can only use the app after office setup is complete.

This epic reduces first-use friction by allowing:
- work first
- evidence capture first
- site and asset structure to be built from field evidence
- supervisor confirmation after technician submission

## Scope
In scope:
- Bootstrap first-visit technician flow in mobile app
- Backend visit-session model separate from canonical workorders
- Provisional site and asset capture from technician evidence
- Checklist template detection, starter-template creation, and progressive checklist execution for first-time sites
- Review and submit flow with attach/create/unresolved resolution paths
- Promotion of resolved bootstrap visits into the normal site/workorder lifecycle
- Supervisor review and confirmation of site and inventory suggestions

Out of scope:
- Replacing or removing the existing manager/supervisor-led workorder-first flow
- Advanced AI quality scoring beyond basic evidence review hooks
- Full automatic site matching without supervisor confirmation

## Success Criteria
- [ ] Technician can start a bootstrap AMC visit in the field without a pre-created site or workorder
- [ ] Existing site-first and workorder-first planning flow remains supported and unchanged for regular visits
- [ ] Bootstrap visit can be reviewed and submitted with minimal required confirmation
- [ ] Submitted bootstrap visit can resolve into an existing site, a new site draft, or a supervisor review queue
- [ ] Bootstrap visit can use a detected or app-created starter checklist template when no finalized site template exists
- [ ] Supervisors can refine starter templates over time without breaking historical visit records
- [ ] Resolved bootstrap visits can converge back into the canonical workorder, reporting, and approval lifecycle

## Child Stories
- [ ] Story: Technician can start a bootstrap AMC visit without a pre-created site or workorder
- [ ] Story: Backend can create and manage bootstrap visit sessions separate from canonical workorders
- [ ] Story: Backend can build provisional site and asset suggestions from first-visit evidence
- [ ] Story: Backend can detect, assign, or create a starter checklist template for bootstrap visits
- [ ] Story: Technician can complete a progressive checklist during a bootstrap visit
- [ ] Story: Technician can review and submit a bootstrap AMC visit with minimal confirmation
- [ ] Story: Backend can promote a submitted bootstrap visit into the canonical workorder lifecycle
- [ ] Story: Supervisor can refine starter checklist templates with additional site-specific items
- [ ] Story: Supervisor can review bootstrap visits and confirm site and inventory before regular flow continues

## Risks / Dependencies
- Bootstrap session design must not weaken the existing workorder and reporting lifecycle
- Duplicate site and duplicate asset handling will need careful review and idempotency rules
- Checklist-template selection must remain versioned and auditable so later refinements do not rewrite historical visit behavior
- Supervisor confirmation flow depends on reliable evidence grouping and provisional asset mapping
- Backend/core changes will need coordination with `neilsolaramc`

## Completion Evidence
- PRs:
- Test evidence:
- Deployment/build evidence:
