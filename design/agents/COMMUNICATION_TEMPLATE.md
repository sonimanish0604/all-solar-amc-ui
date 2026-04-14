# Agent Communication Template

## Purpose

Use this guide when multiple role-based agents or contributors are working the same UI issue.

The goal is to make handoffs readable, predictable, and easy to continue without losing context.

## Canonical Communication Channel

Preferred channel:

* GitHub issue comments on the active issue

Fallback channel:

* local planning or implementation notes in this repo, then backfill the GitHub issue later

If both exist, treat the GitHub issue as the source of truth for the active handoff trail.

## Important Constraint

Agents are not automatically alerted when another role leaves a note.

That means every role must pull the latest context before starting:

1. Read the issue title, body, and acceptance criteria
2. Read the latest structured handoff note
3. Check for unresolved blockers or dependency notes
4. Only then begin work

## Required Role Tags

Use one of these tags at the top of every structured note:

* `[PO HANDOFF]`
* `[SM BREAKDOWN]`
* `[TL DECISION]`
* `[UI DEV UPDATE]`
* `[QC REVIEW]`
* `[BLOCKER]`
* `[COORDINATION NOTE]`

## Required Fields

Every structured note should include:

* Issue
* Role
* Status
* Summary
* Decisions Made
* Dependencies or Blockers
* Files or Screens
* Validation or Review Notes
* Next Role
* Next Action

## Recommended Status Values

Use short, explicit status values:

* `Drafted`
* `In Progress`
* `Blocked`
* `Needs Clarification`
* `Ready for Tech Lead`
* `Ready for Development`
* `Ready for Review`
* `Complete`

## Handoff Template

Copy this structure into the GitHub issue comment or local note:

```md
[ROLE TAG]

Issue:
Role:
Status:

Summary:
-

Decisions Made:
-

Dependencies / Blockers:
-

Files / Screens:
-

Validation / Review Notes:
-

Next Role:
-

Next Action:
-
```

## Role-Specific Usage

Product Owner should emphasize:

* problem statement
* user story
* acceptance criteria
* scope boundaries

Scrum Master should emphasize:

* execution order
* task sequencing
* external dependencies
* blockers to remove

UI Tech Lead should emphasize:

* UX or UI direction
* component and screen architecture
* state and data-flow decisions
* integration boundaries and risks

UI Developer should emphasize:

* implementation progress
* files or screens changed
* loading, error, and edge-case handling
* gaps that still need help

Quality Control should emphasize:

* acceptance criteria status
* issues found
* residual risks
* release or merge recommendation

## Parallel Work Rule

If more than one agent or contributor is working at the same time, every note must state clear ownership.

Examples:

* `Owner: UI Tech Lead for navigation and state decisions`
* `Owner: UI Developer for bootstrap visit screens under apps/mobile_app/...`

This prevents overlapping edits and makes merge or review simpler.

## Completion Rule

Do not leave the next role guessing.

A note is only complete if the next role can answer:

* What happened?
* What was decided?
* What is blocked?
* What should I do next?
