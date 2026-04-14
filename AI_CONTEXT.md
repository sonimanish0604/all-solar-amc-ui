# AI Context

Last updated: 2026-03-26

Use this file as the first-read context for new chats in this repository.

## Mandatory First Read

Before proposing implementation steps or making code changes, also read:
- `docs/AI_WORKFLOW_RULES.md`
- `design/agents/AGENTS.md`
- `design/agents/COMMUNICATION_TEMPLATE.md`

Treat `docs/AI_WORKFLOW_RULES.md` as the repository operating guide.
If there is any conflict between ad hoc implementation ideas and repo workflow rules, follow the workflow rules unless the user explicitly redirects for a specific case.

Treat `design/agents/AGENTS.md`, `design/agents/COMMUNICATION_TEMPLATE.md`, and the role files under `design/agents/skills/` as the guide for choosing agent roles and handling handoffs in this repo.

## Project Summary

`all-solar-amc-ui` is the mobile/UI repository for the broader All Solar AMC platform.

Primary purpose:
- mobile app implementation
- UI and UX work for field workflows
- mobile-side integration with backend APIs and Firebase services
- design and implementation support for the broader product

## This Repository

- Repo: `https://github.com/sonimanish0604/all-solar-amc-ui`
- Local workspace: `C:\code\all-solar-amc-ui`
- Expected day-to-day branch: `develop` unless the user says otherwise
- Current structure includes a Flutter app scaffold under `apps/mobile_app/`

Treat this repo as the mobile implementation source of truth.

## Related Repositories

- Core backend repo: `https://github.com/sonimanish0604/neilsolaramc`
- Website repo: `https://github.com/sonimanish0604/all-solar-amc-website`

Backend repo role:
- source of truth for API behavior
- source of truth for business logic and workflow rules
- linked to GCP Cloud Build and Cloud services

Website repo role:
- website-related implementation work

Note:
- Existing docs in this repo still reference `all-solar-amc-web`
- User-provided context in this chat says the website repo is `all-solar-amc-website`
- Verify the canonical website repo name before doing broad doc cleanup

## Planning And Tracking

- Cross-repo issues and planning are tracked in GitHub Project 5
- Project link: `https://github.com/users/sonimanish0604/projects/5`
- This UI repo is one of three repositories linked to that project

Use Project 5 as the shared backlog and planning reference across:
- UI/mobile
- backend
- website

## Working Assumptions For New Chats

- Read this file before starting substantial work
- Read `docs/AI_WORKFLOW_RULES.md` before implementation work
- Read `design/agents/AGENTS.md` before choosing or assigning agent roles
- Read `design/agents/COMMUNICATION_TEMPLATE.md` before using role-based handoffs
- Inspect the local codebase before making assumptions
- If backend behavior is unclear, defer to `neilsolaramc`
- If issue or priority context is needed, check Project 5 and repo issues
- Keep implementation work in this repo unless the user explicitly redirects to backend or website work
- Call out cross-repo dependencies early when they affect delivery

## Agent Role Guidance

If using role-specific agents in this repo, use the UI team guidance under:
- `design/agents/AGENTS.md`
- `design/agents/COMMUNICATION_TEMPLATE.md`
- `design/agents/skills/product_owner/SKILL.md`
- `design/agents/skills/scrum-master/SKILL.md`
- `design/agents/skills/ui-tech-lead/SKILL.md`
- `design/agents/skills/ui-developer/SKILL.md`
- `design/agents/skills/quality-control/SKILL.md`

Default role mapping in this repo:
- Product Owner: clarify feature intent, user story, acceptance criteria, and scope
- Scrum Master: break work into UI tasks and external dependencies
- UI Tech Lead: define UI architecture, UX guardrails, state or data-flow decisions, and integration boundaries
- UI Developer: implement mobile UI behavior and backend API consumption in this repo
- Quality Control: review against acceptance criteria, edge cases, and UX or integration risks

Default communication pattern in this repo:
- Use GitHub issue comments as the canonical role handoff trail when possible
- Use the role tags and fields from `design/agents/COMMUNICATION_TEMPLATE.md`
- Always read the latest structured handoff note before continuing work

Use backend or website repos only as dependency context unless the user explicitly redirects work there.

## Good Kickoff Context For A New Chat

If starting a fresh chat, a short message like this is enough:

```text
Please read AI_CONTEXT.md first.
Then read docs/AI_WORKFLOW_RULES.md and use it as the repo operating guide.
Then read design/agents/AGENTS.md and use the UI agent-role files if role-based delegation is helpful.
Then read design/agents/COMMUNICATION_TEMPLATE.md and use it for structured issue handoffs when multiple roles are involved.

We are working in C:\code\all-solar-amc-ui on branch develop.
Use this repo as the active workspace.

Task for this chat:
<describe the feature, bug, setup step, or issue link>

Constraints:
<optional notes such as target environment, deadlines, or decisions already made>
```

## Maintenance

Update this file when any of these change:
- canonical repo relationships
- tracking board or process
- source-of-truth decisions
- default branch or workspace expectations
- major architecture or tooling direction
