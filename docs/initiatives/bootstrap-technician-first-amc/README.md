# Bootstrap Technician-First AMC Issue Drafts

This folder contains issue-ready drafts for the first-time bootstrap AMC flow.

Intent:
- preserve the existing workorder-first flow for normal visits
- add a bootstrap first-visit path for technicians when site setup does not yet exist
- keep backend/core work clearly separated so related stories can be implemented in `neilsolaramc`

Primary source docs:
- `docs/initiatives/tech-flow-1.md`
- `docs/initiatives/tech-flow-2.md`
- `docs/initiatives/backendneeded.md`

Supporting validation docs:
- `docs/initiatives/bootstrap-technician-first-amc/backend-field-simulation-validation.md`

Issue set in this folder:

| Draft | Suggested Type | Primary Repo | Notes |
| --- | --- | --- | --- |
| `epic-bootstrap-technician-first-amc.md` | Epic | `all-solar-amc-ui` | Parent epic for the overall effort |
| `story-ui-start-bootstrap-amc-visit.md` | Story | `all-solar-amc-ui` | Mobile technician start and capture flow |
| `story-core-bootstrap-visit-session-model.md` | Core / Backend | `neilsolaramc` | New backend session model separate from canonical workorders |
| `story-core-provisional-site-and-asset-resolution.md` | Core / Backend | `neilsolaramc` | Provisional site and asset inference from first-visit evidence |
| `story-core-bootstrap-checklist-template-resolution.md` | Core / Backend | `neilsolaramc` | Detect, assign, or create a starter checklist template for bootstrap visits |
| `story-ui-review-and-submit-bootstrap-visit.md` | Story | `all-solar-amc-ui` | Mobile review and submit UX for bootstrap flow |
| `story-ui-progressive-bootstrap-checklist.md` | Story | `all-solar-amc-ui` | Progressive checklist experience during first-time field execution |
| `story-core-promote-bootstrap-visit-to-canonical-workorder.md` | Core / Backend | `neilsolaramc` | Promotion path into the existing workorder/reporting lifecycle |
| `story-core-supervisor-checklist-template-refinement.md` | Core / Backend | `neilsolaramc` | Supervisor can refine or extend starter templates with site-specific items |
| `story-core-supervisor-review-and-confirmation.md` | Core / Backend | `neilsolaramc` | Review and confirmation APIs for site and inventory resolution |

Recommended creation order:
1. Create the epic
2. Create the two UI stories
3. Create the checklist/template stories
4. Create the remaining backend/core stories
5. Link all stories back to the epic in GitHub Project 5

Important product framing:
- This is a first-time site bootstrap flow, not a replacement for scheduled AMC work
- Existing site creation and manager/supervisor-created workorders must remain supported
- Bootstrap visits should converge back into the normal site/workorder lifecycle once resolved
- Checklist selection should prefer detection and assignment first, then create a starter template only when no usable template exists
- Starter templates should be easy for supervisors to refine later through versioned additions instead of forcing perfect design up front
