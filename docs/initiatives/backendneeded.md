# SERVICE INVENTORY FOR TECHNICIAN-FIRST AMC FLOW
## Project: All Solar
## Purpose
List the backend/application services needed to support the FlutterFlow technician-first AMC flow.
Codex should compare this inventory against existing implemented services and classify each as:
- already exists
- partially exists
- needs update
- not started

---

# 1. SERVICE CLASSIFICATION MODEL

## Service status labels
- EXISTS
- PARTIAL
- UPDATE_NEEDED
- NOT_STARTED

## Priority labels
- P0 = required for MVP core flow
- P1 = needed soon after MVP
- P2 = enhancement / later

---

# 2. CORE SERVICES OVERVIEW

## P0 CORE SERVICES
1. Auth Service
2. User Profile / Role Service
3. Visit Session Service
4. Visit Item Service
5. Media Upload Service
6. OCR Extraction Service
7. OCR Parsing / Field Normalization Service
8. Site Draft Resolution Service
9. Site Service
10. Site Asset / Inventory Service
11. AMC Submission Service
12. Supervisor Review Service
13. Sync / Offline Queue Service

## P1 SUPPORTING SERVICES
14. Reverse Geocoding / Location Enrichment Service
15. Nearby Site Matching Service
16. Duplicate Asset Detection Service
17. Report / PDF Generation Service
18. Notification Service

## P2 LATER SERVICES
19. Audit / Activity Log Service
20. Analytics / Telemetry Service
21. OEM / External Asset Lookup Adapter
22. AI-assisted Quality Check Service

---

# 3. DETAILED SERVICE LIST

# SERVICE 1: AUTH SERVICE
## Priority
P0

## Purpose
Authenticate user into app.

## Responsibilities
- sign in via phone OTP
- sign in via Google where applicable
- issue identity token / session
- support logout
- expose current authenticated user

## Expected consumers
- mobile app
- all backend services via auth context

## Key outputs
- user_id
- tenant_id
- role
- auth token / session context

## Notes
This may already exist via Firebase Auth, but confirm role mapping and tenant linkage.

---

# SERVICE 2: USER PROFILE / ROLE SERVICE
## Priority
P0

## Purpose
Resolve app user identity, role, tenant, and permissions.

## Responsibilities
- fetch user profile by uid
- resolve role
- resolve tenant_id
- determine allowed screens/actions

## Expected consumers
- home_page
- navigation guards
- supervisor review flow

## Core data
- users collection/table

## Notes
If authentication exists but role/tenant lookup is weak, mark as UPDATE_NEEDED.

---

# SERVICE 3: VISIT SESSION SERVICE
## Priority
P0

## Purpose
Create and manage AMC visit sessions.

## Responsibilities
- create visit session
- resume open visit session
- update visit status
- attach visit to site if known
- store GPS start/end
- store inferred totals
- store submission path:
  - existing_site
  - new_site_draft
  - unassigned_draft

## Main operations
- createVisitSession
- getOpenVisitSessionForUser
- getVisitSessionById
- updateVisitSession
- submitVisitSession

## Core data
- visit_sessions collection/table

## Notes
This is one of the backbone services.

---

# SERVICE 4: VISIT ITEM SERVICE
## Priority
P0

## Purpose
Store evidence captured during a visit.

## Responsibilities
- create visit item
- list visit items for visit
- update extracted fields
- update confirmation status
- delete visit item
- group items by type

## Supported item types
- inverter_label
- meter_reading
- panel_photo
- note
- voice_note
- general_photo

## Main operations
- createVisitItem
- listVisitItems
- updateVisitItem
- deleteVisitItem

## Core data
- visit_items collection/table

---

# SERVICE 5: MEDIA UPLOAD SERVICE
## Priority
P0

## Purpose
Upload and retrieve photos/audio captured during field work.

## Responsibilities
- upload image to storage
- upload voice note if used
- return storage URL/path
- associate media with visit_item
- support queued uploads for offline mode later

## Main operations
- uploadVisitPhoto
- uploadVoiceNote
- getMediaUrl

## Likely storage
- Firebase Storage or equivalent object storage

## Notes
If image upload exists in any form, Codex should confirm if it is reusable for visit_items.

---

# SERVICE 6: OCR EXTRACTION SERVICE
## Priority
P0

## Purpose
Extract raw text from captured equipment labels and meter images.

## Responsibilities
- receive image reference
- run OCR engine
- return raw text and confidence
- support at least:
  - inverter labels
  - meter readings

## Main operations
- extractTextFromImage
- extractMeterReadingText
- extractEquipmentLabelText

## Inputs
- image URL/path
- capture type

## Outputs
- raw_ocr_text
- confidence
- optional bounding boxes later

## Notes
This may already exist partially if meter OCR was built before.

---

# SERVICE 7: OCR PARSING / FIELD NORMALIZATION SERVICE
## Priority
P0

## Purpose
Turn raw OCR text into structured fields.

## Responsibilities
- parse manufacturer
- parse model
- parse serial number
- parse inverter rating
- parse manufacture date text
- parse meter reading value
- normalize units / numeric values

## Main operations
- parseInverterLabel
- parseMeterReading
- normalizeOCRFields

## Outputs
Structured object like:
- manufacturer
- model
- serial_number
- rating_kw
- manufacture_date_text
- reading_value
- confidence

## Notes
This should be separate from OCR itself.
OCR reads text. Parsing interprets it.

---

# SERVICE 8: SITE DRAFT RESOLUTION SERVICE
## Priority
P0

## Purpose
Create a probable site draft from visit evidence.

## Responsibilities
- inspect visit items and visit GPS
- infer inverter count
- infer total installed inverter capacity
- derive suggested location
- prepare suggested site summary for review screen

## Main operations
- buildSiteDraftSuggestion
- inferInverterCount
- inferTotalCapacity
- deriveSuggestedLocation

## Inputs
- visit_session
- visit_items

## Outputs
- suggested_site_name (maybe blank)
- suggested_address_text
- inferred_inverter_count
- inferred_total_inverter_capacity_kw

## Notes
This is inference only, not final confirmation.

---

# SERVICE 9: SITE SERVICE
## Priority
P0

## Purpose
Create and manage site records.

## Responsibilities
- create new site draft
- update site details
- fetch sites by tenant
- fetch site by id
- transition status:
  - draft_inferred
  - draft_user_created
  - confirmed
  - updated

## Main operations
- createSite
- updateSite
- getSite
- listSitesForTenant

## Core data
- sites collection/table

---

# SERVICE 10: SITE ASSET / INVENTORY SERVICE
## Priority
P0

## Purpose
Manage site equipment inventory such as inverters.

## Responsibilities
- create site assets from accepted visit items
- update asset status
- track first seen / latest seen
- support later correction
- support asset replacement/inactive states

## Main operations
- createSiteAsset
- createAssetsFromVisit
- listSiteAssets
- updateSiteAsset
- markAssetInactive
- markAssetReplaced

## Core data
- site_assets collection/table

## Notes
This is critical because your product becomes more than checklisting here.

---

# SERVICE 11: AMC SUBMISSION SERVICE
## Priority
P0

## Purpose
Finalize technician visit submission.

## Responsibilities
- validate visit can be submitted
- handle submit path:
  - attach to existing site
  - create new site draft
  - leave unassigned
- update visit status to submitted
- create AMC report object
- link created/updated site and assets

## Main operations
- submitVisitToExistingSite
- submitVisitAsNewSiteDraft
- submitVisitAsUnassigned
- createAmcReport

## Notes
This is orchestration logic, not just CRUD.

---

# SERVICE 12: SUPERVISOR REVIEW SERVICE
## Priority
P0

## Purpose
Support manager/supervisor confirmation of site and inventory.

## Responsibilities
- list visits awaiting review
- fetch visit evidence
- fetch inferred site details
- approve or correct site configuration
- approve visit
- confirm assets

## Main operations
- listPendingReviews
- getReviewBundle
- approveSiteDraft
- correctSiteDraft
- approveVisit
- rejectVisit

## Notes
Even if supervisor UI is Phase 2, service design should exist early.

---

# SERVICE 13: SYNC / OFFLINE QUEUE SERVICE
## Priority
P0/P1 depending on implementation depth

## Purpose
Support delayed sync when network is weak or unavailable.

## Responsibilities
- queue pending writes
- queue media uploads
- retry failed sync
- expose sync state to UI
- reconcile uploaded records

## Main operations
- queueWrite
- queueUpload
- processPendingQueue
- markSyncSuccess
- markSyncFailure

## Core data
- sync_queue collection/table or local-first queue mechanism

## Notes
For MVP, lightweight support may be enough.
Full robust sync can be iterative.

---

# SERVICE 14: REVERSE GEOCODING / LOCATION ENRICHMENT SERVICE
## Priority
P1

## Purpose
Convert GPS coordinates into human-friendly location text.

## Responsibilities
- reverse geocode latitude/longitude
- return address text
- store suggested address on visit/site draft

## Main operations
- reverseGeocode
- enrichVisitLocation

## Outputs
- address_text
- locality
- city
- state
- country

---

# SERVICE 15: NEARBY SITE MATCHING SERVICE
## Priority
P1

## Purpose
Suggest whether technician is near an already known site.

## Responsibilities
- compare current GPS to known sites
- suggest likely match within threshold
- return best match candidates

## Main operations
- findNearbySites
- suggestSiteForVisit

## Notes
Useful for reducing duplicate site creation.

---

# SERVICE 16: DUPLICATE ASSET DETECTION SERVICE
## Priority
P1

## Purpose
Prevent blind duplication of inverter inventory.

## Responsibilities
- check if serial number already exists
- check within site and tenant scope
- flag duplicates for review
- update latest_seen_at when appropriate

## Main operations
- findAssetBySerial
- detectDuplicateAsset
- resolveDuplicateAssetDecision

---

# SERVICE 17: REPORT / PDF GENERATION SERVICE
## Priority
P1

## Purpose
Generate a formal AMC report after submission.

## Responsibilities
- build report payload from visit/session/items/site
- generate PDF
- store PDF URL
- support approval-ready report later

## Main operations
- generateAmcReportPdf
- getReportByVisit
- regenerateReport

## Notes
Can be added after submission service is stable.

---

# SERVICE 18: NOTIFICATION SERVICE
## Priority
P1

## Purpose
Notify supervisor/manager/admin after visit submission or review events.

## Responsibilities
- send submission notification
- send review pending notification
- send approval notification
- support email first, WhatsApp later

## Main operations
- notifyVisitSubmitted
- notifyReviewPending
- notifyVisitApproved

## Notes
You already have notification/event concepts in prior backend work. Codex should check reuse potential.

---

# SERVICE 19: AUDIT / ACTIVITY LOG SERVICE
## Priority
P2

## Purpose
Track who changed what and when.

## Responsibilities
- record site creation/update
- record asset creation/update
- record supervisor approval/rejection
- record submission events

## Main operations
- logActivity
- listEntityHistory

---

# SERVICE 20: ANALYTICS / TELEMETRY SERVICE
## Priority
P2

## Purpose
Measure product usage and operational quality.

## Responsibilities
- capture funnel metrics
- capture drop-off points
- capture OCR success rate
- capture submission completion rate
- capture sync failures

## Main operations
- trackEvent
- trackScreenView
- trackOcrOutcome
- trackSubmissionOutcome

---

# SERVICE 21: OEM / EXTERNAL ASSET LOOKUP ADAPTER
## Priority
P2

## Purpose
Optional future lookup from external systems or OEM portals.

## Responsibilities
- search device info if supported externally
- enrich asset data where possible

## Notes
Do not make MVP dependent on this.

---

# SERVICE 22: AI-ASSISTED QUALITY CHECK SERVICE
## Priority
P2

## Purpose
Evaluate whether captured evidence is usable.

## Responsibilities
- detect blurry label photo
- detect poor meter image
- prompt retake before submission

## Notes
Nice enhancement later, not core MVP.

---

# 4. ORCHESTRATION FLOWS

# FLOW A: START VISIT
Services involved:
- Auth Service
- User Profile / Role Service
- Visit Session Service
- Nearby Site Matching Service (optional)

---

# FLOW B: CAPTURE EQUIPMENT LABEL
Services involved:
- Media Upload Service
- OCR Extraction Service
- OCR Parsing / Field Normalization Service
- Visit Item Service

---

# FLOW C: REVIEW & INFER SITE DRAFT
Services involved:
- Visit Session Service
- Visit Item Service
- Site Draft Resolution Service
- Reverse Geocoding Service (optional)

---

# FLOW D: SUBMIT VISIT AS NEW SITE DRAFT
Services involved:
- AMC Submission Service
- Site Service
- Site Asset / Inventory Service
- Visit Session Service
- Notification Service (optional)
- Report / PDF Generation Service (optional in MVP)

---

# FLOW E: SUPERVISOR APPROVES SITE CONFIGURATION
Services involved:
- Supervisor Review Service
- Site Service
- Site Asset / Inventory Service
- AMC Submission Service or report update path
- Notification Service

---

# 5. CODEX TASKING INSTRUCTIONS

## Task 1
Inspect current backend/services and map them to this inventory.

## Task 2
Produce a gap report with columns:
- service_name
- priority
- current_status
- evidence_found
- required_action

## Task 3
Identify reusable components already built for:
- auth
- notifications
- OCR
- uploads
- report generation
- queueing
- role handling

## Task 4
Recommend implementation order based on P0 first.

---

# 6. MVP IMPLEMENTATION ORDER

## Phase 1
- Auth Service
- User Profile / Role Service
- Visit Session Service
- Visit Item Service
- Media Upload Service

## Phase 2
- OCR Extraction Service
- OCR Parsing / Field Normalization Service
- Site Draft Resolution Service

## Phase 3
- Site Service
- Site Asset / Inventory Service
- AMC Submission Service

## Phase 4
- Supervisor Review Service
- Reverse Geocoding Service
- Notification Service

## Phase 5
- Sync / Offline Queue Service hardening
- Duplicate Asset Detection Service
- Report / PDF Generation Service

---

# 7. ONE-LINE INSTRUCTION FOR CODEX

Audit the current codebase against this service inventory for the technician-first AMC flow, classify each service as existing/partial/update_needed/not_started, identify reusable components, and prioritize missing P0 services needed to support immediate field capture, OCR extraction, inferred site draft creation, and lightweight visit submission.