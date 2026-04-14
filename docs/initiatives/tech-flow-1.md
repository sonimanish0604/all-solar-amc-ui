# TECHNICIAN-FIRST MOBILE FLOW
## Project: All Solar
## Module: AMC Field Visit Flow
## Goal
Allow a technician to start and complete an AMC visit with minimal friction.
The app must not require full site setup before work begins.
The app should capture evidence first, infer structure in the background, and ask for confirmation only at the right moment.

---

# 1. PRODUCT PRINCIPLE

## Core rule
Do not force the technician to create site master data before starting work.

## Desired behavior
- Technician opens app
- Starts AMC immediately
- Captures photos, readings, notes
- App extracts serial numbers / equipment details / GPS silently
- App groups captured evidence into a visit session
- App proposes site and inventory draft near submission time
- Supervisor or manager can later confirm or enrich site configuration

## Why
Field technicians are time-pressed.
Any up-front setup friction will reduce adoption.

---

# 2. PRIMARY USER

## Primary user
Technician

## Secondary users
- Supervisor / Manager
- Admin / Office Staff

## UX bias
All design decisions should favor technician speed and low typing effort.

---

# 3. FLOW SUMMARY

## End-to-end flow
1. Technician logs in
2. Technician lands on Home screen
3. Technician starts AMC visit
4. Technician captures photos / readings / notes during visit
5. App extracts structured details in background
6. App groups captured evidence into a draft visit + probable site
7. Technician reviews a lightweight summary
8. Technician submits visit
9. Supervisor receives report / draft site configuration for approval
10. Supervisor confirms site and inventory if needed

---

# 4. SCREEN FLOW (MAX 6 SCREENS)

## SCREEN 1 - HOME / START VISIT
### Purpose
Let technician begin work in one tap.

### UI elements
- Button: Start AMC Visit
- Button: Continue Draft Visit
- Optional card: Nearby Site Detected
- Bottom nav: Home / Visits / Profile

### Logic
- If technician has an unfinished session, show Continue Draft Visit
- If GPS is near a known site, show:
  - "Looks like you are near [Site Name]"
  - Actions:
    - Continue at this site
    - Start as new draft

### Notes
Do not ask for full site details here.

---

## SCREEN 2 - VISIT SESSION / CAPTURE HUB
### Purpose
Main working screen for the technician.

### UI elements
- Header: AMC Visit In Progress
- Optional chip: Site = Unknown Draft or detected site name
- Action cards / buttons:
  - Scan Equipment Label
  - Capture Meter Reading
  - Capture Panel Photos
  - Add Note
  - Add Voice Note
  - View Captured Items
- Sticky action button:
  - Review & Submit

### Logic
Every action should save evidence to current visit session.

### Session metadata captured automatically
- visit_session_id
- technician_id
- timestamp_start
- current GPS
- device info
- online/offline state

---

## SCREEN 3 - CAMERA CAPTURE / OCR RESULT
### Purpose
Capture equipment label or meter photo and extract data.

### Entry points
- Scan Equipment Label
- Capture Meter Reading

### UI elements
- Camera preview
- Capture button
- Retake button
- OCR result card after capture

### OCR result fields
- Manufacturer
- Model
- Serial Number
- Capacity / Rating
- Manufacture Date
- Confidence indicator

### User actions
- Accept
- Edit
- Retake

### Logic
If accepted:
- Save photo
- Save extracted fields
- Tag item type:
  - inverter_label
  - meter_reading
  - equipment_nameplate
- Link to visit session

### Important rule
Mark extracted fields as:
- source = OCR
- status = captured_unconfirmed

---

## SCREEN 4 - CAPTURED ITEMS / VISIT TIMELINE
### Purpose
Show technician what has already been collected.

### UI elements
- List of captured evidence:
  - Equipment labels
  - Meter readings
  - Panel photos
  - Notes
  - Voice notes
- Status markers:
  - OCR extracted
  - Needs confirmation
  - Synced / Not synced

### User actions
- Tap item to review/edit
- Delete item
- Add another item

### Logic
App should group repeated inverter scans and maintain unique serial numbers.

### Background inference
As items are captured, system may infer:
- probable site draft
- probable equipment count
- probable installed inverter capacity

Do not force technician to confirm yet unless required.

---

## SCREEN 5 - REVIEW & SUBMIT
### Purpose
Ask for only the minimum confirmation needed before submission.

### UI elements
#### Section A - Visit summary
- Total photos captured
- Meter readings captured
- Notes added
- Equipment labels detected

#### Section B - Suggested site details
- Suggested site name = blank or nearby detected site
- Suggested location = GPS-derived address or coordinates
- Detected inverter count
- Suggested inverter capacity total
- Example:
  - 3 inverters detected
  - 50 kW each
  - Suggested installed inverter capacity = 150 kW

#### Section C - User decisions
- Attach to Existing Site
- Save as New Site Draft
- Leave as Unassigned Draft

#### Section D - Minimal required fields
- Site name only if new draft is being created
- Optional customer name
- Optional quick note

### Submit button
- Submit AMC Visit

### Key rule
All inferred values must be labeled as suggested, not final.

### Example wording
- "Detected 3 inverters"
- "Suggested installed inverter capacity: 150 kW"
- "Please confirm or edit"

---

## SCREEN 6 - SUBMISSION SUCCESS
### Purpose
Close the technician flow cleanly.

### UI elements
- Success message
- Visit reference number
- Sync status
- Next actions:
  - Start another visit
  - View submitted visit
  - Go Home

### If site draft was created
Show:
- "Site draft created and sent for supervisor review"

### If attached to existing site
Show:
- "Visit added to [Site Name]"

---

# 5. SUPERVISOR FOLLOW-UP FLOW

## Purpose
Supervisor confirms site configuration after technician submits.

## Supervisor actions
- Review visit evidence
- Review extracted equipment
- Confirm or edit:
  - site name
  - location
  - inverter inventory
  - total installed inverter capacity
- Approve AMC report
- Mark site as confirmed

## Key rule
Supervisor handles data enrichment, not technician unless needed.

---

# 6. DATA STATES

## Visit states
- draft
- in_progress
- submitted
- supervisor_review
- approved
- rejected

## Site states
- not_created
- draft_inferred
- draft_user_created
- confirmed
- updated

## Equipment states
- captured_unconfirmed
- user_confirmed
- supervisor_confirmed
- inactive
- replaced

---

# 7. FIELD CLASSIFICATION MODEL

## Auto-captured
- timestamp
- GPS coordinates
- technician ID
- photo
- device metadata
- OCR raw text
- extracted serial number
- extracted model
- extracted equipment rating

## Inferred
- probable site
- probable site address
- probable inverter count
- suggested installed inverter capacity
- probable grouping of equipment into one site

## User-confirmed
- site name
- attach to existing site vs create new
- corrected serial number if OCR was wrong
- corrected equipment type
- final visit submission

## Supervisor-confirmed
- final site configuration
- final inventory
- approved plant capacity
- final AMC acceptance

---

# 8. BUSINESS RULES

## Rule 1
Technician must be able to start a visit without pre-created site master data.

## Rule 2
No more than 1-2 required fields before first capture.

## Rule 3
Photos and evidence are first-class data inputs.

## Rule 4
OCR output is never treated as final truth without confirmation path.

## Rule 5
Site and asset records can evolve over time.

## Rule 6
Missing one inverter during first visit is acceptable.
System must support later addition or correction.

## Rule 7
GPS should come from device/app at capture time, not from image metadata alone.

## Rule 8
Every captured item must be linked to:
- visit_session_id
- user_id
- timestamp
- GPS snapshot if available

---

# 9. OFFLINE-FIRST RULES

## Requirements
- Technician must be able to capture photos and notes offline
- Data should queue locally for sync
- UI should clearly show sync status
- Submission should work as:
  - fully submitted if online
  - locally saved and pending sync if offline

## Local queue items
- visit session
- images
- OCR results
- notes
- location metadata

---

# 10. MVP SCOPE

## Include in MVP
- Start visit
- Capture equipment label photo
- OCR extraction
- Capture meter reading photo
- Add notes
- Visit review
- Submit visit
- Suggested site draft creation
- Supervisor review of draft site configuration

## Exclude from MVP
- advanced analytics
- predictive maintenance
- automatic warranty lookup from OEM portals
- deep inventory hierarchy
- complex work order scheduling
- customer self-service portal

---

# 11. FLUTTERFLOW IMPLEMENTATION NOTES

## Suggested page list
1. home_page
2. visit_session_page
3. camera_capture_page
4. captured_items_page
5. review_submit_page
6. submission_success_page

## Suggested collections / tables
- users
- visit_sessions
- visit_items
- sites
- site_assets
- amc_reports
- sync_queue

## Suggested visit_items types
- inverter_label
- meter_reading
- panel_photo
- note
- voice_note
- general_photo

---

# 12. ACCEPTANCE CRITERIA

## AC1
Technician can start a visit in 1 tap from home screen.

## AC2
Technician can capture an inverter label photo and see extracted serial/model/rating.

## AC3
Technician can continue visit without creating site manually first.

## AC4
App can group multiple captured inverter labels into one visit session.

## AC5
App can suggest inverter count and installed inverter capacity during review.

## AC6
Technician can submit visit with minimal confirmation.

## AC7
Supervisor can review submitted visit and confirm/edit site configuration.

## AC8
System supports later addition of missed inverter(s) without breaking prior records.

---

# 13. DESIGN INTENT STATEMENT

This mobile flow is intentionally designed around real field behavior:
- work first
- structure later
- evidence before forms
- suggestion before typing
- supervisor enrichment after technician submission

This is not a strict master-data-first workflow.
This is a technician-first evidence-capture workflow.

---

# 14. ONE-LINE SUMMARY FOR CODEX

Build a technician-first AMC mobile flow where a user can start a visit immediately, capture equipment and meter evidence with camera/OCR, let the app infer site/inventory details in the background, and only ask for lightweight confirmation at review/submit time, with supervisor approval of final site configuration.