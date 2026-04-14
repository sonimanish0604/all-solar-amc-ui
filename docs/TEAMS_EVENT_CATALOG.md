# Teams Coordination Event Catalog

## Purpose

This catalog defines the current event vocabulary for UI-repo Teams coordination through the shared coordination bot.

Use it to keep UI-team and cross-team alerts short, consistent, and tied to real GitHub source-of-truth updates.

This document is intentionally narrower than a general process guide. It only covers:

- what event types exist today
- when to use each event
- which fields must be present
- how event wording should stay consistent across teams

## Operating Rules

1. GitHub remains the source of truth.
2. Teams is a coordination and awareness channel, not the authoritative record.
3. Record the meaningful update in GitHub first.
4. Emit the Teams event second.
5. If a decision is made in Teams, backfill GitHub before treating it as official.

## Current Lane Intent

Current routing should be treated as:

- `ui.*` -> UI internal lane
- `coord.*` -> cross-team coordination lane

If more team families are added later, extend the catalog instead of inventing local one-off names.

## Required Fields

Every event should include:

- `event_type`
- `source_issue`
- `source_role`
- `status`
- `summary`
- `owner`
- `next_action`

Optional but strongly recommended:

- `github_url`
- `correlation_id`

Required for `coord.*` events:

- `target_repo`
- `target_role`

Recommended for `coord.*` events:

- `target_issue`
- `dependency_type`

## Field Guidance

### `event_type`

Use the exact event key from this catalog. Do not improvise similar names.

### `status`

Use short visible status text for Teams cards, for example:

- `Decision Recorded`
- `Ready for Development`
- `Blocked`
- `Review Requested`
- `Ready for Demo`
- `Ready for Backend`
- `Dependency Clarified`
- `Escalation Required`

### `summary`

The summary should answer:

- what changed
- why the other team should care
- what is now true

Keep it to one or two sentences.

### `owner`

This is the current owner of the next action, not necessarily the sender of the event.

### `next_action`

This should be direct and specific enough that the receiving team knows what to do next without opening another chat.

### `correlation_id`

Use a stable thread key for related Epic or multi-story coordination, for example:

- `epic32-bootstrap`
- `issue33-bootstrap-start-flow`

## Naming Rules

Use this pattern:

- `<family>.<intent>`

Current families:

- `ui`
- `coord`

Current intent style:

- `ready_for_development`
- `blocked_on_backend`
- `dependency_clarified`
- `ready_for_backend`

Prefer explicit, operational names. Avoid vague names like:

- `update`
- `sync`
- `notice`
- `progress`

## Event Catalog

### UI Internal Events

| Event Type | Use When | Typical Owner | Typical Lane |
| --- | --- | --- | --- |
| `ui.decision_recorded` | A UI Tech Lead or coordinating role has made a meaningful implementation or UX decision that internal UI contributors should align to | UI Coordinator or UI Tech Lead | ui-internal |
| `ui.ready_for_development` | A story or screen slice is broken down enough that implementation can start cleanly | UI Coordinator or Scrum Master | ui-internal |
| `ui.blocked` | UI work is blocked and needs help, clarification, or dependency removal within the UI team | UI Coordinator | ui-internal |
| `ui.review_requested` | The branch or issue is ready for internal review, QC, or reviewer attention | UI Developer or UI Coordinator | ui-internal |
| `ui.ready_for_demo` | UI work is complete enough for demo validation or end-to-end review | UI Coordinator | ui-internal |

### Cross-Team Coordination Events

| Event Type | Use When | Typical Owner | Typical Lane |
| --- | --- | --- | --- |
| `coord.blocked_on_backend` | UI is waiting on backend behavior, payload shape, sequencing, or contract clarification before proceeding safely | Backend PM | cross-team-coordination |
| `coord.dependency_clarified` | A dependency contract has been clarified enough for the other team to align work without guessing | Receiving team lead or coordinator | cross-team-coordination |
| `coord.ready_for_backend` | UI has reached a usable design, issue state, or contract expectation that backend can now act on | Backend PM | cross-team-coordination |
| `coord.escalation_required` | The issue needs PMO / Engineering Headquarters attention due to unresolved scope, ownership, or sequencing risk | PMO / Engineering Headquarters | cross-team-coordination |

## Recommended Usage by Situation

### Use `coord.blocked_on_backend` when:

- UI cannot proceed safely without backend clarification or implementation
- the dependency is now the critical path
- a GitHub issue already captures the blocker

Example:

- the review-and-submit screen is waiting on a visit-session payload contract

### Use `coord.dependency_clarified` when:

- the contract direction is now clear
- the other team can begin design or alignment
- implementation may still be in progress

Example:

- backend confirms that submit will keep unresolved issue placeholders and return the canonical review payload shape

### Use `coord.ready_for_backend` when:

- the UI side has enough clarity that backend should act next
- the UI issue now clearly describes the needed contract or sequencing
- the event is stronger than simple clarification

Example:

- UI flow and validation assumptions are documented and backend can now finalize the supporting endpoint behavior

### Use `ui.review_requested` when:

- the work is not a cross-team handoff
- the next useful action is internal review, QC, or tester attention

### Use `coord.escalation_required` when:

- ownership is unclear
- a merge or release sequence creates risk
- teams disagree on contract behavior
- waiting quietly would waste time

## Copy-Ready Examples

### Example 1: UI Ready for Development

```text
event_type: ui.ready_for_development
source_issue: all-solar-amc-ui#33
source_role: UI Coordinator
status: Ready for Development
summary: The bootstrap start-flow screen now has a defined UX path, state handling, and acceptance boundaries for implementation.
owner: UI Developer
next_action: Implement the start-flow screen in the UI repo and leave a structured GitHub handoff note after the first pass.
github_url: https://github.com/sonimanish0604/all-solar-amc-ui/issues/33
correlation_id: issue33-bootstrap-start-flow
```

### Example 2: Blocked on Backend

```text
event_type: coord.blocked_on_backend
source_issue: all-solar-amc-ui#35
source_role: UI Coordinator
status: Blocked
summary: The UI review-and-submit flow is blocked until the backend visit-session response payload is confirmed in GitHub.
owner: Backend PM
next_action: Review the linked backend issue and confirm the response contract in GitHub.
github_url: https://github.com/sonimanish0604/all-solar-amc-ui/issues/35
target_repo: neilsolaramc
target_issue: neilsolaramc#160
target_role: Backend PM
dependency_type: bootstrap visit-session API contract
correlation_id: epic32-bootstrap
```

### Example 3: Ready for Backend

```text
event_type: coord.ready_for_backend
source_issue: all-solar-amc-ui#33
source_role: UI Coordinator
status: Ready for Backend
summary: UI assumptions for bootstrap start-flow and review sequencing are now documented, and backend can finalize contract behavior against those expectations.
owner: Backend PM
next_action: Review the UI issue context and proceed with backend contract implementation or clarification in GitHub.
github_url: https://github.com/sonimanish0604/all-solar-amc-ui/issues/33
target_repo: neilsolaramc
target_issue: neilsolaramc#160
target_role: Backend PM
dependency_type: bootstrap visit-session lifecycle API
correlation_id: epic32-bootstrap
```

## Authoring Checklist

Before emitting an event, confirm:

- the GitHub issue or PR comment already exists
- the event type matches this catalog exactly
- the status text is short and visible
- the summary is one or two sentences
- the next action is explicit
- `coord.*` events include the target team details
- the `correlation_id` matches the Epic or cross-team thread

## Anti-Patterns

Do not use Teams events for:

- raw implementation chatter
- sub-agent internal notes
- unverified assumptions
- long change logs
- decisions that are not yet recorded in GitHub

## Current Live Vocabulary

This catalog matches the current manual workflow in:

- `.github/workflows/emit-teams-coordination.yml`

If PMO / Engineering Headquarters wants new event families or intents, update both:

- this catalog
- the workflow input options

Do not update only one side.
