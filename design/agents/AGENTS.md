# AGENTS.md

## PURPOSE

This repository is part of a multi-repo Solar AMC SaaS project.
Codex must operate using structured UI-focused roles, GitHub issue-driven workflow, and explicit handoffs.

---

## CORE RULES

1. ALWAYS read the linked GitHub issue and latest structured handoff note before starting work
2. Treat "Acceptance Criteria" as the source of truth
3. Do NOT assume requirements outside the issue
4. Do NOT modify feature scope unless explicitly asked
5. Keep changes minimal and focused
6. Update relevant sections in issue or handoff notes after work
7. Use `design/agents/COMMUNICATION_TEMPLATE.md` for cross-role notes
8. If work is blocked, leave the blocker, owner, and next action explicitly

---

## MULTI-REPO CONTEXT

This project has 3 repos:

* backend (API and business logic)
* ui (this repo, Flutter mobile app)
* website (marketing/docs)

You are currently operating in: **ui repo**

---

## RESPONSIBILITIES IN THIS REPO

* Build mobile UI flows
* Integrate existing backend APIs
* Handle app state, loading, errors, and usability
* Ensure UI test coverage where practical

DO NOT:

* Implement backend APIs in this repo
* Change backend contracts without explicit coordination
* Treat website work as part of normal UI implementation scope

---

## WORKFLOW

1. Use Product Owner skill -> refine feature intent and acceptance criteria when needed
2. Use Scrum Master skill -> break into UI tasks and external dependencies
3. Use UI Tech Lead skill -> define UI architecture, UX guardrails, and integration boundaries
4. Use UI Developer skill -> implement
5. Use Quality Control skill -> validate before completion

---

## ROLE MAP

* Product Owner: clarify feature intent, user value, acceptance criteria, and MVP boundaries
* Scrum Master: break work into UI tasks, dependencies, and execution order
* UI Tech Lead: shape screen architecture, UX flow, component reuse, and state or data-flow decisions
* UI Developer: implement UI behavior and backend API consumption in this repo
* Quality Control: validate acceptance criteria, UX behavior, and delivery risks

---

## COMMUNICATION REQUIREMENT (MANDATORY)

Every role-based handoff must:

* happen in the GitHub issue when possible
* use the role tags and template from `design/agents/COMMUNICATION_TEMPLATE.md`
* capture current status, key decisions, blockers, validation, next role, and next action
* mention file or screen ownership when multiple contributors are working in parallel

Important:

* Agents are not passively alerted when someone else leaves a note
* Before starting, read the latest issue description and handoff notes
* After finishing or pausing, leave a structured note for the next role

---

## UI HANDOFF REQUIREMENT (MANDATORY)

Every UI feature MUST include:

* affected screens or flows
* state and loading behavior
* API dependency notes if backend integration is involved
* error handling notes
* device or emulator notes if relevant

---

## TESTING

* Run relevant UI tests before marking complete
* Validate device or emulator behavior when needed
* Ensure no breaking changes

---

## COMPLETION CRITERIA

Do NOT mark task complete unless:

* Acceptance criteria met
* UI behavior and dependency notes documented where needed
* No critical issues found
