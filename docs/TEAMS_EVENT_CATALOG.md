# Teams Events Catalog

Status: Canonical for UI repo emission  
Owner: UI Engineering  
Last Updated: 2026-04-05

This catalog defines the Microsoft Teams coordination events that the UI repo is allowed to emit through `.github/workflows/emit-teams-coordination.yml`.

This file is intentionally conservative. Add new event types here only when:
- the shared coordination bot supports them, and
- this repo has a real workflow or GitHub note path that emits them

## Core Rules

- GitHub issues and issue comments remain the system of record.
- Teams is a notification and coordination surface only.
- UI-originated events must describe work owned by the UI repo.
- Cross-team events must target the backend role explicitly when backend action is required.
- Do not emit speculative or low-signal events.

## Canonical Event Types

| Event Type | Status | Source | Notes |
| --- | --- | --- | --- |
| `ui.decision_recorded` | Enabled | `.github/workflows/emit-teams-coordination.yml` | Use when a UI Tech Lead or coordinating role records a durable decision that helps the UI team act. |
| `ui.ready_for_development` | Enabled | `.github/workflows/emit-teams-coordination.yml` | Use when a UI story or screen is ready for implementation. |
| `ui.blocked` | Enabled | `.github/workflows/emit-teams-coordination.yml` | Use for UI-local blockers that do not need backend action. |
| `ui.review_requested` | Enabled | `.github/workflows/emit-teams-coordination.yml` | Use when UI work is ready for review or quality validation. |
| `ui.ready_for_demo` | Enabled | `.github/workflows/emit-teams-coordination.yml` | Use when a UI slice is ready to show or validate end-to-end. |
| `coord.blocked_on_backend` | Enabled | `.github/workflows/emit-teams-coordination.yml` | Use when UI work is blocked and backend action is the next dependency. |
| `coord.dependency_clarified` | Enabled | `.github/workflows/emit-teams-coordination.yml` | Use when a cross-team dependency has been clarified and the note should be surfaced into Teams. |
| `coord.ready_for_backend` | Enabled | `.github/workflows/emit-teams-coordination.yml` | Use when the UI side has completed its part and backend action is now the next required step. |
| `coord.escalation_required` | Enabled | `.github/workflows/emit-teams-coordination.yml` | Use only for durable blockers or coordination risks that need explicit attention. |

## Required Event Shape

Every emitted Teams event must include:
- `event_type`
- `source_repo`
- `source_issue`
- `source_role`
- `status`
- `summary`
- `owner`
- `next_action`
- `github_url`

Cross-team events must also include:
- `target_repo`
- `target_role`
- `target_issue` when known
- `dependency_type` when relevant

## Source Of Truth For Shape

The event payload shape is aligned with the shared coordination bot contract and the bot-side event normalization logic.

For the current UI repo workflow:
- payloads are built inside `.github/workflows/emit-teams-coordination.yml`
- `source_repo` is inferred from `${{ github.repository }}`
- `github_url` is inferred from `source_issue` when not provided manually

## Good Usage Examples

### UI Internal Readiness

Use:
- `ui.ready_for_development`

Example intent:
- UI Tech Lead has approved the review-and-submit screen flow and the UI Developer can start.

### Cross-Team Blocker

Use:
- `coord.blocked_on_backend`

Example intent:
- UI implementation is waiting on an API contract or backend issue resolution.

### Cross-Team Resolution Signal

Use:
- `coord.dependency_clarified`

Example intent:
- backend clarified a contract in GitHub and the UI team should now pull the updated context.

## What Not To Emit

Do not emit:
- raw chat transcripts
- draft thoughts with no issue link
- duplicate events for unchanged status
- backend-local implementation events from the UI repo
- vague summaries with no owner or next action

## Related Files

- `.github/workflows/emit-teams-coordination.yml`
- `design/agents/COMMUNICATION_TEMPLATE.md`
- `AI_CONTEXT.md`
- `docs/AI_WORKFLOW_RULES.md`
