# MVP Scope And Release Readiness

Status: Working founder reference
Date: 2026-04-02
Context: All Solar AMC mobile launch planning, India-first

## Purpose

This document is the shared reference point for:

- MVP scope decisions
- what we will deliberately defer
- the rollout sequence after MVP
- Android Google Play readiness
- iPhone / iOS readiness
- the mid-April 2026 demo plan in Lucknow

This is written from a co-founder perspective, not a feature-wishlist perspective.

The core question is:

What is the smallest product we can put in real technicians' hands that is useful, credible, and learnable?

## Executive View

The MVP should be built around one promise:

`A technician can start AMC work immediately, capture proof in the field, submit the visit, and the business receives a usable report plus a reviewable site/inventory draft.`

Two field-driven decisions should stay inside MVP, not after MVP:

- PDF generation and storage
- technician-initiated site configuration during AMC

Those two changes are not polish. They are core adoption enablers.

## MVP Definition

MVP is successful if, by launch:

- a technician can sign in and start work with minimal friction
- work can continue even when site master data is incomplete
- the app captures evidence in a structured way
- the visit can be reviewed and submitted without heavy data entry
- the platform can create or attach a site path from real field evidence
- a supervisor can review the outcome
- a PDF artifact exists as the operational proof of work

## MoSCoW

### Must Have

- Technician phone OTP sign-in with tenant-aware and role-aware routing
- Start AMC visit immediately without requiring a pre-created site or work order
- Resume draft visit
- Offline-lite draft persistence and safe resume behavior
- Evidence capture:
  - equipment label / serial evidence
  - meter reading evidence
  - general photo evidence
  - technician notes
- OCR-assisted extraction with manual correction path
- Lightweight technician checklist and summary note
- Review and submit flow
- Submission paths:
  - attach to existing site
  - create new site draft
  - leave unresolved for supervisor review
- Technician-initiated provisional site and asset / inventory creation
- PDF report generation and storage at submission time
- Basic supervisor review to confirm or correct site linkage and inventory
- Visit statuses that support pilot operations:
  - draft
  - submitted
  - supervisor_review
  - approved / corrected
- Backend foundations:
  - tenant isolation
  - auth and role resolution
  - media upload and secure storage references
  - idempotent submit behavior
  - audit logging
  - retry-safe sync behavior

### Should Have

- Duplicate serial / duplicate site warning before final confirmation
- Basic visit history for technicians and supervisors
- Basic supervisor notification when a visit is submitted
- Visible sync state and retry messaging
- Basic crash / error logging for pilot support
- India-first copy and input polish

### Could Have

- Nearby site suggestion from GPS
- Reverse-geocoded address suggestion
- Voice note or voice-assisted capture
- Progressive checklist templates
- Existing-site inventory update path
- Add-inventory-to-existing-site path
- Customer signature reuse if it comes cheaply from existing backend work
- Lightweight operational analytics

### Won't Have In MVP

- Advanced scheduling and dispatch optimization
- Predictive maintenance
- SCADA / OEM / inverter-cloud integrations
- Deep inventory hierarchy
- Customer self-service portal
- Advanced management dashboards
- Rich analytics as a launch blocker
- Broad automation before the manual and pilot path is proven

## Phased Roadmap

### Phase 0 - Pilot-Ready Build

Goal:
Make the app credible enough to place in real hands without pretending the platform is broader than it is.

Includes:

- finish mobile review and submit flow
- add bootstrap visit submit APIs
- persist provisional site and inventory outcome
- generate and save PDF report on submission
- add basic supervisor review bundle and confirmation path
- harden auth, uploads, retry behavior, and audit trail
- publish Android build to Google Play internal testing
- publish iPhone build through TestFlight

### Phase 1 - MVP Field Pilot

Goal:
Run the first real technician and supervisor learning loop.

Includes:

- first technician cohort on Android
- supervisor review in real operating conditions
- friction fixes in capture, OCR correction, and submission
- sync-state and failure recovery improvements
- basic visit history
- move Android to closed testing if needed

### Phase 2 - MVP + 30 Days

Goal:
Remove the most painful workflow gaps discovered in pilot.

Includes:

- existing-site inventory update path
- add inventory to existing site path
- nearby-site suggestions
- improved supervisor correction UX
- starter checklist refinement based on field learning

### Phase 3 - MVP + 90 Days

Goal:
Expand from pilot utility into stronger operating leverage.

Includes:

- customer approval / signature reuse if it proves commercially useful
- richer reports and summary insights
- better analytics and telemetry
- stronger scheduling / dispatch support
- broader site configuration maturity

## Distribution Strategy

## Android / Google Play

### Recommended path

- Short term: Google Play `Internal testing`
- Next step: Google Play `Closed testing`
- Later: production rollout only after pilot stability is proven

### Why this is the right path

- technicians use Android, so Android is the real operating platform
- internal testing is the fastest safe route into technician hands
- a closed test gives us better confidence before wider rollout
- if the Play Console is a personal account created after 2023-11-13, a closed test with at least 12 opted-in testers for 14 continuous days is required before production access

### Android readiness requirements

- real application ID, not placeholder package naming
- release signing key and secure keystore handling
- branded app name, icons, and store assets
- production-safe Firebase configuration
- privacy policy URL
- Data safety declarations for non-internal tracks
- release notes and tester instructions
- a stable submit flow

### Current repo blockers for Android release

As of 2026-04-02, the repo still shows:

- placeholder Android package ID
- debug signing for release builds
- generic app label and package metadata
- unfinished review-and-submit screen
- placeholder side paths for scheduled flow and inventory update flows

Conclusion:

Android can be pushed to Google Play testing tracks after release hardening.
It is not yet ready for a production-grade public rollout as-is.

## iPhone / iOS

### Founder recommendation

For the mid-April 2026 demo, the iPhone path should be:

- `TestFlight` for external testing if the owner needs the app on his own iPhone
- local install on your own iPhone as the fallback demo path
- do not make the meeting depend on full App Store production approval

### Why

- TestFlight is materially faster and lower-risk than App Store production review
- the school-system owner is an external person, so he is not an internal tester
- App Store production review should happen only after the MVP flow is stable

### What is required to put the app on iPhone

At minimum:

- an active Apple Developer Program account
- organization enrollment if we want the company name, not an individual's name, shown as the seller on Apple distribution surfaces
- App Store Connect app record
- unique iOS bundle identifier
- Apple signing and provisioning set up under the correct team
- release archive built from a Mac with Xcode
- branded app name and icons
- privacy policy URL
- app privacy disclosures in App Store Connect
- export compliance answers in App Store Connect
- TestFlight test information if using external testers
- screenshots and version metadata for App Store release
- review notes and demo credentials if login is required during review

### Additional iOS requirements once camera / photo / location features are real

Before shipping capture-heavy iPhone builds, the app will also need correct usage descriptions in `Info.plist`, for example:

- camera usage
- photo library usage
- photo add usage
- location when in use

If those permissions are requested without correct purpose strings, review risk goes up and runtime behavior breaks.

### Current repo blockers for iOS readiness

As of 2026-04-02, the repo still shows:

- placeholder iOS bundle ID
- generic display name
- no visible iOS Firebase `GoogleService-Info.plist`
- no visible camera / photo / location usage strings in `Info.plist`
- unfinished review-and-submit flow in the app itself

Also note:

- iOS builds cannot be properly validated from this Windows workspace alone
- real iPhone distribution will require a Mac with Xcode and Apple signing access

### TestFlight plan for the Lucknow demo

If the owner should try the app on his own iPhone:

1. create the app record in App Store Connect
2. set the final bundle ID and signing
3. upload a working beta build
4. submit for external TestFlight review
5. invite him as an external tester

This should be started at least 7 to 10 days before the meeting to absorb review delays.

Fallback:

- keep a working build on your own iPhone regardless
- do not rely on Apple review timing as the only demo path

## Mid-April 2026 Demo Plan

Target:

- founder demo with the school-system owner in Lucknow, India
- target timing: mid-April 2026
- founder device: iPhone
- prospect device: iPhone
- technician rollout platform: Android

### Demo objective

The demo should prove three things:

1. the app reduces technician friction in the field
2. the app can bootstrap site and inventory setup from real AMC work
3. the platform produces a usable report artifact, not just raw captured data

### What the demo should show

- technician sign-in
- start visit without pre-created site
- capture label / meter / notes
- provisional site or inventory path
- review and submit
- generated PDF report
- supervisor review concept

### What the demo should not depend on

- public App Store launch
- broad scheduling features
- advanced analytics
- polished side flows that are still placeholders

## Immediate Priority Decisions

From a co-founder perspective, the next initiative should focus on:

1. finishing `Review & Submit`
2. wiring backend submission, provisional site/inventory outcome, and PDF generation into one stable path
3. making Android internal testing and iPhone TestFlight possible for April 2026 demos and pilot conversations

Everything else should be judged by one question:

Does it help us get a technician into the app, complete a visit, and learn from real usage?

If not, it is probably not the next initiative.

## Repo Truth Snapshot

This recommendation is grounded in the current repo state:

- current mobile app already supports sign-in, routing shell, and evidence-capture shell
- review-and-submit is still not implemented in the live UI
- scheduled flow and existing inventory side paths are still placeholders
- the bootstrap initiative docs already define technician-first start, capture, review, submit, and supervisor review as the core path

## Verification Sources

Official sources checked on 2026-04-02:

- Google Play testing tracks:
  - https://support.google.com/googleplay/android-developer/answer/9845334?hl=en
- Google Play production access requirements for newer personal accounts:
  - https://support.google.com/googleplay/android-developer/answer/14151465?hl=en
- Google Play data safety:
  - https://support.google.com/googleplay/android-developer/answer/10787469?hl=en
- Apple Developer Program distribution overview:
  - https://developer.apple.com/support/compare-memberships/
- TestFlight overview:
  - https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Invite external testers in TestFlight:
  - https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/
- Add internal testers in TestFlight:
  - https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/
- App information and required privacy policy URL:
  - https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/
- Manage app privacy:
  - https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- App privacy reference:
  - https://developer.apple.com/help/app-store-connect/reference/app-privacy
- Export compliance:
  - https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance
- App Store screenshots:
  - https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots
- App Review guidelines:
  - https://developer.apple.com/app-store/review/
