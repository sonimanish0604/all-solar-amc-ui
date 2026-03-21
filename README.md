# All Solar AMC UI

Mobile/UI repository for the All Solar AMC project.

This repository is intended for mobile application and UI-focused work, aligned to the broader platform architecture documented in the backend repository.

## Repository Role

- Mobile app and field UI development
- FlutterFlow-exported or Flutter-managed application code
- Shared UI assets and design references for mobile workflows
- Mobile integration notes for backend APIs, Firebase Auth, Firestore sync, and offline capture

## Multi-Repo Layout

- UI / mobile app: `all-solar-amc-ui`
- Website: `https://github.com/sonimanish0604/all-solar-amc-web`
- Backend / core platform: `https://github.com/sonimanish0604/neilsolaramc`

## Product Context

The broader product supports solar AMC field operations:

- technicians execute work orders on mobile
- mobile flows support offline-first capture
- Firebase Auth and Firestore support mobile identity and sync workflows
- backend APIs remain the source of truth for finalized business records

Current backend documentation describes the frontend/mobile direction as FlutterFlow-based for owner, manager, supervisor, and technician experiences.

## Issue Tracking

Cross-repo planning and delivery tracking are managed in GitHub Project 5:

- `https://github.com/sonimanish0604/projects/5`

Use issues and PRs to track changes. Keep repo-specific implementation details here, but treat the GitHub project as the shared source of backlog truth across UI, website, and backend work.

## Initial Structure

```text
all-solar-amc-ui/
  apps/
    mobile_app/
  design/
  docs/
```

## Current Status

This repository has been initialized with documentation and folder structure only. No generated FlutterFlow export or Flutter application scaffold has been committed yet.

## Recommended Next Steps

1. Decide whether the source of truth for app UI will be FlutterFlow exports, hand-maintained Flutter code, or a hybrid model.
2. Add the initial mobile application scaffold under `apps/mobile_app/`.
3. Document environment setup for Flutter, Firebase, and backend API connectivity.
4. Link the first UI/mobile issues from GitHub Project 5 to concrete repo tasks.
