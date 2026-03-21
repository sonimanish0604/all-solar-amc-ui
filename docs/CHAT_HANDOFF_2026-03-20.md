# Chat Handoff

Date: 2026-03-20

## Repositories

- UI / mobile app repo: `https://github.com/sonimanish0604/all-solar-amc-ui`
- Website repo: `https://github.com/sonimanish0604/all-solar-amc-web`
- Core backend repo: `https://github.com/sonimanish0604/neilsolaramc`
- Shared GitHub Project: `https://github.com/users/sonimanish0604/projects/5`

## Current Understanding

- `all-solar-amc-ui` is the dedicated mobile/UI repository for the broader All Solar AMC product.
- `neilsolaramc` is the technical source of truth for backend behavior, APIs, auth, workflow rules, and core architecture.
- GitHub Project 5 is the shared planning and backlog board across repos, not just the backend repo.
- FlutterFlow is the intended UI/app design direction.

## What Was Done

- Cloned and initialized the UI repo locally in WSL2.
- Added initial scaffold files:
  - `README.md`
  - `.gitignore`
  - `docs/README.md`
  - `apps/mobile_app/README.md`
  - `design/README.md`
- Created local branch `develop`.
- Verified GitHub CLI auth and access to:
  - the UI repo
  - the backend repo metadata
  - Project 5
- Added `all-solar-amc-ui#1` to Project 5 and set it as:
  - `Type = Epic`
  - `Area = Mobile`
  - `Status = Todo`
  - `Story State = Draft`
- Added UI issues `#2` through `#10` to Project 5 and attempted to apply:
  - `Area = Mobile`
  - `Status = Todo`
  - `Story State = Draft`
  - `Type = Story` for `#2, #3, #4, #5, #6, #8, #9, #10`
  - `Type = Epic` for `#7`

## Important Note On Project Verification

- `gh project item-add` returned item ids for UI issues `#1` through `#10`.
- `gh project item-edit` commands were issued for the field values above.
- `gh project item-list` did not immediately reflect the new UI items reliably, which may be a GitHub CLI listing lag or API quirk.
- The user later linked the UI repo to Project 5 directly in the GitHub UI as well.

## Key Product / Workflow Context

- Mobile app flows are expected to connect to backend capabilities already delivered in `neilsolaramc`.
- Backend phases already tracked in Project 5 include:
  - Phase 0
  - 1A
  - 1B
  - 1C
  - 1D
  - 1E
  - 1F
  - 2A
- This means the backend should be treated as a mature foundation, not a blank slate.

## UI Issues Mentioned

- Epic `#1`: Mobile demo mode for AI-assisted field reading
- Stories `#2` to `#6`
- Epic `#7`: Mobile onboarding and organization setup after demo mode
- Stories `#8` to `#10`

## Architecture / Tooling Discussion

- FlutterFlow is the visual app builder layer, not the full local engineering toolchain.
- Recommended workflow:
  - use FlutterFlow for screens, flows, auth wiring, and basic API/state setup
  - export code into `all-solar-amc-ui`
  - use Flutter SDK locally for real runs, debugging, and custom code
- For this machine setup:
  - backend repos can stay in WSL2
  - the UI repo should move to Windows for smoother Flutter/Android tooling

## Environment Decision

- Recommended Windows location for the UI repo:
  - `C:\code\all-solar-amc-ui`
- Recommendation was to avoid manually copying files between WSL2 and Windows.
- Use git as the sync mechanism instead of dragging files between folders.

## Mental Model Agreed In Chat

- Project 5 is the single planning / backlog reference across repos.
- `neilsolaramc` is the backend implementation source of truth.
- `all-solar-amc-ui` should become the mobile implementation source of truth.
- Start mobile work in a structured way rather than trying to build the whole app in FlutterFlow at once.

## Recommended Next Step In New Chat

Start from the Windows clone of `all-solar-amc-ui` and continue with:

1. verify Flutter SDK installation with `flutter doctor`
2. set up Android Studio / Android SDK / emulator
3. define the first mobile vertical slice from Epic `#1` and Epic `#7`
4. create a mobile architecture/setup doc in this repo for FlutterFlow + Flutter + backend integration

## Suggested Prompt For New Chat

Use this repo as the active workspace: `C:\code\all-solar-amc-ui`

Context:
- This repo is the mobile/UI repo for the All Solar AMC project.
- Website repo: `sonimanish0604/all-solar-amc-web`
- Backend repo: `sonimanish0604/neilsolaramc`
- Shared planning board: Project 5 at `https://github.com/users/sonimanish0604/projects/5`
- FlutterFlow is the intended UI direction.
- Backend is already substantially developed and tracked through multiple phases in Project 5.
- UI issues `#1` to `#10` exist in `all-solar-amc-ui`; `#1` and `#7` are epics.
- We decided the UI repo should be worked from Windows for Flutter tooling.

Please continue by helping set up the local Flutter toolchain and define the first practical mobile implementation slice.
