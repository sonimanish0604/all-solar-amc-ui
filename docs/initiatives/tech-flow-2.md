# FLUTTERFLOW BUILD SPEC
## Project: All Solar
## Module: Technician-First AMC Flow
## Goal
Translate the technician-first AMC product flow into a FlutterFlow-friendly page-by-page implementation plan.

---

# 1. BUILD PRINCIPLES

## Core UX principle
Do not force site creation before the technician starts work.

## Build principle
The app must support:
- immediate start of AMC visit
- evidence capture first
- structured extraction in background
- lightweight confirmation at submit time
- supervisor enrichment later

## MVP target
A technician should be able to:
1. open app
2. start visit
3. capture inverter labels / meter photos / panel photos / notes
4. review captured items
5. submit visit
6. create or attach to a site with minimal effort

---

# 2. USER ROLES

## Roles
- technician
- supervisor
- admin

## MVP focus
Primary role for this module:
- technician

Supervisor support in MVP:
- review submitted visit
- confirm site configuration
- correct inferred inventory

---

# 3. FIRESTORE COLLECTIONS

## 3.1 users
Purpose: user identity and role

Suggested fields:
- uid: string
- full_name: string
- phone_number: string
- email: string
- role: string
  - technician
  - supervisor
  - admin
- tenant_id: string
- is_active: bool
- created_at: timestamp
- updated_at: timestamp

---

## 3.2 sites
Purpose: site master records

Suggested fields:
- site_id: string
- tenant_id: string
- site_name: string
- customer_name: string
- status: string
  - draft_inferred
  - draft_user_created
  - confirmed
  - updated
- latitude: double
- longitude: double
- geo_hash: string (optional later)
- address_text: string
- location_source: string
  - device_gps
  - manual
  - inferred
- declared_plant_capacity_kw: double
- installed_inverter_capacity_kw: double
- inverter_count: int
- created_by_user_id: string
- created_from_visit_session_id: string
- created_at: timestamp
- updated_at: timestamp
- approved_by_user_id: string
- approved_at: timestamp

---

## 3.3 site_assets
Purpose: inverter/equipment inventory tied to a site

Suggested fields:
- asset_id: string
- tenant_id: string
- site_id: string
- asset_type: string
  - inverter
  - meter
  - combiner_box
  - panel_group
  - other
- manufacturer: string
- model: string
- serial_number: string
- rating_kw: double
- manufacture_date_text: string
- status: string
  - captured_unconfirmed
  - user_confirmed
  - supervisor_confirmed
  - inactive
  - replaced
- source: string
  - ocr
  - manual
  - imported
- first_seen_visit_session_id: string
- latest_seen_at: timestamp
- created_by_user_id: string
- created_at: timestamp
- updated_at: timestamp

---

## 3.4 visit_sessions
Purpose: one AMC field session

Suggested fields:
- visit_session_id: string
- tenant_id: string
- technician_user_id: string
- linked_site_id: string (nullable)
- visit_status: string
  - draft
  - in_progress
  - submitted
  - supervisor_review
  - approved
  - rejected
- site_resolution_type: string
  - existing_site
  - new_site_draft
  - unassigned_draft
- suggested_site_name: string
- suggested_address_text: string
- start_latitude: double
- start_longitude: double
- end_latitude: double
- end_longitude: double
- started_at: timestamp
- submitted_at: timestamp
- sync_status: string
  - local_only
  - queued
  - synced
  - failed
- notes_summary: string
- inferred_inverter_count: int
- inferred_total_inverter_capacity_kw: double
- created_at: timestamp
- updated_at: timestamp

---

## 3.5 visit_items
Purpose: all evidence captured during a visit

Suggested fields:
- visit_item_id: string
- tenant_id: string
- visit_session_id: string
- linked_site_id: string (nullable)
- item_type: string
  - inverter_label
  - meter_reading
  - panel_photo
  - note
  - voice_note
  - general_photo
- photo_url: string
- local_file_path: string (local/offline support; app state or local storage)
- raw_ocr_text: string
- extracted_manufacturer: string
- extracted_model: string
- extracted_serial_number: string
- extracted_rating_kw: double
- extracted_reading_value: string
- extraction_confidence: double
- extraction_status: string
  - not_started
  - processing
  - extracted
  - failed
- user_confirmation_status: string
  - pending
  - accepted
  - edited
  - rejected
- note_text: string
- voice_note_url: string
- latitude: double
- longitude: double
- captured_at: timestamp
- captured_by_user_id: string
- created_at: timestamp
- updated_at: timestamp

---

## 3.6 amc_reports
Purpose: final report object after submission

Suggested fields:
- report_id: string
- tenant_id: string
- visit_session_id: string
- site_id: string (nullable until resolved)
- technician_user_id: string
- supervisor_user_id: string (nullable)
- report_status: string
  - draft
  - submitted
  - supervisor_review
  - approved
  - rejected
- summary_text: string
- pdf_url: string (later if PDF generation added)
- submitted_at: timestamp
- approved_at: timestamp
- created_at: timestamp
- updated_at: timestamp

---

## 3.7 sync_queue
Purpose: offline-first queue

Suggested fields:
- queue_id: string
- tenant_id: string
- entity_type: string
  - visit_session
  - visit_item
  - site
  - site_asset
- entity_id: string
- action_type: string
  - create
  - update
  - upload
- payload_json: map
- queue_status: string
  - pending
  - processing
  - synced
  - failed
- retry_count: int
- last_error: string
- created_at: timestamp
- updated_at: timestamp

---

# 4. APP STATE / LOCAL STATE

## Recommended app state
Use FlutterFlow App State or local state for:

- currentVisitSessionId
- currentVisitStatus
- currentVisitSiteId
- currentDraftSiteName
- currentGPSLatitude
- currentGPSLongitude
- nearbySiteId
- nearbySiteName
- pendingUploadCount
- isOfflineMode
- currentUserRole

## Local page state examples
Useful for forms and review:
- extractedManufacturer
- extractedModel
- extractedSerial
- extractedRating
- selectedSubmissionMode
- selectedSiteOption

---

# 5. PAGE-BY-PAGE BUILD SPEC

# PAGE 1: home_page

## Purpose
Landing page for technician.
Allow immediate start or resume of AMC work.

## Visible to
- technician
- supervisor (can have separate actions later)

## Main widgets
- AppBar
  - title: "All Solar"
- Welcome text
  - "Start or continue your AMC work"
- Primary button
  - "Start AMC Visit"
- Conditional card
  - "Continue Draft Visit"
- Conditional nearby site card
  - "Looks like you are near [site]"
  - buttons:
    - Continue at this site
    - Start New Draft
- Bottom navigation
  - Home
  - Visits
  - Profile

## Backend queries
- Query current user profile from users
- Query open visit_sessions where:
  - technician_user_id == current user
  - visit_status in [draft, in_progress]
  - order by updated_at desc
  - limit 1
- Optional: query nearby sites if GPS available

## Actions
### On page load
- fetch current GPS
- set App State:
  - currentGPSLatitude
  - currentGPSLongitude
- check for draft session
- optionally run nearby-site matching logic later through backend/custom action

### On tap: Start AMC Visit
- create new document in visit_sessions:
  - technician_user_id = current user
  - tenant_id = current tenant
  - visit_status = in_progress
  - started_at = current timestamp
  - start_latitude = current GPS
  - start_longitude = current GPS
  - sync_status = synced or local_only depending on connectivity
- store created doc id in App State: currentVisitSessionId
- navigate to visit_session_page

### On tap: Continue Draft Visit
- set App State currentVisitSessionId
- navigate to visit_session_page

### On tap: Continue at this site
- create new visit_session with linked_site_id populated
- set currentVisitSessionId
- navigate to visit_session_page

---

# PAGE 2: visit_session_page

## Purpose
Main technician work screen.
All capture actions start here.

## Main widgets
- AppBar
  - title: "AMC Visit In Progress"
- Status chip
  - site name if known, else "Unnamed Site Draft"
- Four large action cards/buttons
  - Scan Equipment Label
  - Capture Meter Reading
  - Capture Panel Photo
  - Add Note
- Optional action
  - Add Voice Note
- Section: "Captured so far"
  - small stats cards:
    - equipment labels count
    - meter photos count
    - general photos count
    - notes count
- Sticky bottom button
  - "Review & Submit"

## Backend queries
- query visit_sessions by App State currentVisitSessionId
- query visit_items where visit_session_id == currentVisitSessionId

## Actions
### On tap: Scan Equipment Label
- navigate to camera_capture_page with parameter:
  - captureType = inverter_label

### On tap: Capture Meter Reading
- navigate to camera_capture_page with parameter:
  - captureType = meter_reading

### On tap: Capture Panel Photo
- open camera / upload image
- create visit_item with:
  - item_type = panel_photo
  - photo_url
  - latitude/longitude
  - captured_at
  - user_confirmation_status = accepted
- return to same page

### On tap: Add Note
- open bottom sheet or dialog with text input
- save visit_item:
  - item_type = note
  - note_text
  - captured_at
  - latitude/longitude

### On tap: Add Voice Note
- optional for MVP
- record audio
- upload and save visit_item

### On tap: Review & Submit
- navigate to captured_items_page or directly review_submit_page
- recommended: first go to captured_items_page

---

# PAGE 3: camera_capture_page

## Purpose
Capture image and process OCR result.

## Input parameter
- captureType
  - inverter_label
  - meter_reading

## Main widgets
- Camera widget / image picker
- Capture button
- Retake button
- After capture:
  - image preview
  - OCR result card
  - editable text fields:
    - manufacturer
    - model
    - serial number
    - rating
    - reading value (for meter)
  - confidence display
- Buttons:
  - Accept
  - Edit & Save
  - Retake

## Processing flow
### After image capture
- upload image to Firebase Storage
- run OCR through:
  - custom action
  - cloud function
  - external OCR pipeline
- parse returned result
- populate local state fields

## Save logic
### If captureType = inverter_label
Create visit_item with:
- item_type = inverter_label
- photo_url
- raw_ocr_text
- extracted_manufacturer
- extracted_model
- extracted_serial_number
- extracted_rating_kw
- extraction_status = extracted
- user_confirmation_status = accepted or edited
- latitude/longitude
- captured_at
- captured_by_user_id

### If captureType = meter_reading
Create visit_item with:
- item_type = meter_reading
- photo_url
- raw_ocr_text
- extracted_reading_value
- extraction_status = extracted
- user_confirmation_status = accepted or edited
- latitude/longitude
- captured_at
- captured_by_user_id

## Navigation
- after save:
  - navigate back to visit_session_page

---

# PAGE 4: captured_items_page

## Purpose
Give technician confidence about what was captured before submission.

## Main widgets
- AppBar
  - title: "Captured Items"
- Tab or segmented control:
  - Equipment
  - Readings
  - Photos
  - Notes
- Repeating list of visit_items
- Each row/card shows:
  - thumbnail if image exists
  - item type
  - extracted summary
  - status chip
- Edit icon
- Delete icon
- Bottom button:
  - Continue to Review

## Queries
- query visit_items by currentVisitSessionId ordered by captured_at desc

## Actions
### On tap item
- open detail sheet or simple edit screen
- allow edit of extracted fields

### On tap delete
- soft delete or hard delete
- recommended MVP:
  - hard delete visit_item

### On page load background calculations
Compute inferred values from visit_items:
- count unique serial numbers for inverter_label items
- sum rating_kw for unique confirmed/accepted inverter labels
Store results in local state or write back to visit_sessions:
- inferred_inverter_count
- inferred_total_inverter_capacity_kw

### On tap: Continue to Review
- optionally update visit_sessions with inferred values
- navigate to review_submit_page

---

# PAGE 5: review_submit_page

## Purpose
Minimal confirmation before technician submits visit.

## Main widgets
- AppBar
  - title: "Review & Submit"
- Section: Visit Summary
  - total items captured
  - labels detected
  - meter readings captured
  - notes count
- Section: Suggested Site Details
  - suggested location text
  - detected inverter count
  - suggested installed inverter capacity
- Section: Site Resolution
  - radio options:
    - Attach to Existing Site
    - Save as New Site Draft
    - Leave as Unassigned Draft
- Conditional widget if Attach to Existing Site
  - dropdown/searchable list of sites
- Conditional widget if Save as New Site Draft
  - text field: site name
  - optional text field: customer name
- Optional text area
  - visit summary note
- Submit button

## Queries
- query sites by tenant_id for attach-to-existing option
- read current visit_session
- read visit_items if needed for counts

## Rules
- inferred values must be displayed as suggestions
- do not present them as final truth

## Actions
### On submit
Branch logic:

#### Option 1: Attach to Existing Site
- update visit_session:
  - linked_site_id = selected site
  - site_resolution_type = existing_site
  - visit_status = submitted
  - submitted_at = now
- for each inverter_label item with accepted/edited status:
  - create or upsert site_asset under selected site
- create amc_report
- navigate to submission_success_page

#### Option 2: Save as New Site Draft
- create new site document:
  - status = draft_user_created
  - site_name = entered name
  - customer_name = optional
  - latitude/longitude = GPS from visit
  - installed_inverter_capacity_kw = inferred value
  - inverter_count = inferred value
  - created_from_visit_session_id = current visit
- update visit_session:
  - linked_site_id = new site id
  - site_resolution_type = new_site_draft
  - visit_status = submitted
- create site_assets from inverter_label items
- create amc_report
- navigate to submission_success_page

#### Option 3: Leave as Unassigned Draft
- update visit_session:
  - site_resolution_type = unassigned_draft
  - visit_status = submitted
- create amc_report without site_id or with nullable site_id
- navigate to submission_success_page

---

# PAGE 6: submission_success_page

## Purpose
Give a clean close to technician session.

## Main widgets
- Success icon
- Title:
  - "Visit Submitted"
- Visit reference card
- Sync status card
- Info text depending on submission path:
  - "Site draft created and sent for review"
  - "Visit added to existing site"
  - "Visit saved as unassigned draft"
- Buttons:
  - Start Another Visit
  - View Submitted Visit
  - Go Home

## Actions
### Start Another Visit
- clear App State:
  - currentVisitSessionId
  - currentVisitSiteId
  - currentDraftSiteName
- navigate to home_page

### Go Home
- clear App State as needed
- navigate to home_page

---

# 6. OPTIONAL SUPERVISOR PAGES FOR MVP+

# PAGE 7: supervisor_review_list_page
Purpose:
List visits needing review

Widgets:
- list of submitted visit_sessions
- filters:
  - all
  - needing site confirmation
  - needing approval

# PAGE 8: supervisor_review_detail_page
Purpose:
Review visit evidence and confirm site configuration

Widgets:
- visit summary
- captured items
- extracted inverter details
- site details edit form
- approve / reject buttons

Actions:
- confirm site
- update inventory
- mark assets as supervisor_confirmed
- mark visit_session approved
- update amc_report approved

---

# 7. NAVIGATION RULES

## Technician navigation
- home_page
  -> visit_session_page
  -> camera_capture_page
  -> visit_session_page
  -> captured_items_page
  -> review_submit_page
  -> submission_success_page
  -> home_page

## Role guard rules
- technician sees technician flow pages
- supervisor sees review pages
- admin later sees reporting/admin pages

## Back navigation rules
- from review_submit_page back to captured_items_page
- from captured_items_page back to visit_session_page
- from submission_success_page do not return into old session accidentally

---

# 8. FIRESTORE RELATIONSHIP RULES

## One visit_session has many visit_items
Relationship:
- visit_items.visit_session_id -> visit_sessions.visit_session_id

## One site has many site_assets
Relationship:
- site_assets.site_id -> sites.site_id

## One visit_session may link to one site
Relationship:
- visit_sessions.linked_site_id -> sites.site_id

## One amc_report belongs to one visit_session
Relationship:
- amc_reports.visit_session_id -> visit_sessions.visit_session_id

---

# 9. DUPLICATE HANDLING RULES

## For inverter labels
Before creating a new site_asset on submit:
- check if same serial_number already exists for tenant/site
- if exists:
  - do not blindly duplicate
  - either update latest_seen_at
  - or flag duplicate for supervisor review

## For site matching
If GPS is near an existing site:
- suggest match
- do not auto-force attach

---

# 10. OFFLINE-FIRST IMPLEMENTATION NOTES

## MVP reality
FlutterFlow can support local state and limited offline behavior, but full robust offline sync may need custom actions and backend support.

## Minimal offline MVP approach
- allow image capture locally
- queue pending writes in sync_queue
- mark visit_session sync_status as local_only or queued
- when online restored:
  - push queued documents
  - update sync status

## UI requirements
Always show:
- online/offline indicator
- pending sync count
- upload failed warning if needed

---

# 11. CUSTOM ACTIONS / FUNCTIONS NEEDED

## Likely custom actions
1. getCurrentLocation
2. runOCRFromImage
3. parseInverterLabelText
4. parseMeterReadingText
5. computeUniqueInverterCount
6. computeTotalInverterCapacity
7. reverseGeocodeLocation
8. queueOfflineWrite
9. syncPendingQueue

## Recommended separation
- FlutterFlow handles page UI and standard Firestore writes
- custom actions / cloud functions handle OCR parsing and heavier logic

---

# 12. WIDGET-LEVEL GUIDELINES

## Design principles
- large touch targets
- very little typing
- high-contrast buttons
- minimal text density
- one primary action per screen

## Preferred widget types
- large buttons
- cards
- chips
- bottom sheets
- short editable text inputs
- list views with clear icons
- sticky bottom CTA buttons

## Avoid
- long forms
- multi-step required setup
- too many dropdowns
- dense tables on technician screens

---

# 13. VALIDATION RULES

## Minimal submission validation
Technician can submit if:
- at least one visit_item exists
- current visit_session exists
- site resolution option selected

## Soft validations
Warn, but do not block unnecessarily:
- no inverter labels captured
- no meter reading captured
- no notes added

## Hard validations
Block submission only if:
- no evidence captured at all
- current user role invalid
- visit session missing

---

# 14. ACCEPTANCE CRITERIA FOR BUILD

## AC1
Technician can start a new visit from home_page in one tap.

## AC2
Technician can capture inverter label image and save OCR result.

## AC3
Technician can capture panel photo and notes without pre-creating a site.

## AC4
Captured items display correctly in captured_items_page.

## AC5
Review page shows inferred inverter count and total capacity.

## AC6
Technician can choose:
- attach existing site
- create site draft
- leave unassigned

## AC7
Submission creates:
- updated visit_session
- amc_report
- site and site_assets when appropriate

## AC8
App supports later supervisor review and correction.

---

# 15. IMPLEMENTATION ORDER

## Phase 1
- users
- visit_sessions
- visit_items
- home_page
- visit_session_page
- camera_capture_page
- captured_items_page
- review_submit_page
- submission_success_page

## Phase 2
- sites
- site_assets
- basic site attach/create logic

## Phase 3
- OCR integration
- inferred totals logic
- reverse geocoding
- duplicate serial handling

## Phase 4
- supervisor review pages
- offline sync improvement
- PDF/report generation

---

# 16. ONE-LINE INSTRUCTION FOR CODEX

Build a FlutterFlow-based technician-first AMC module using Firestore collections for visit sessions, visit items, sites, and site assets, where technicians can start work immediately, capture equipment and meter evidence, review inferred site details, and submit with minimal friction before supervisor confirmation.