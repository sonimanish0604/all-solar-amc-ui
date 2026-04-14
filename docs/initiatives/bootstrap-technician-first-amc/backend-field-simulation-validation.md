# Backend Field Simulation Validation Reference

## Purpose

This document captures the current Tech Lead and Quality Control view of how to validate first-time site bootstrap behavior **before** a true on-site technician run is available.

The immediate goal is **not** to prove live mobile capture in the field. The immediate goal is to prove that backend services can accept synthetic evidence "as if it came from UI" and correctly:

- infer a first site from clustered evidence
- create provisional inventory
- normalize inverter serial details
- avoid duplicate or corrupted records
- preserve a clean path to later supervisor review and canonical inventory promotion

This document is intended as a working reference for backend analysis and implementation in `neilsolaramc`.

## Current Position

For this stage, the work is primarily **backend-led**.

Why:

- real field validation depends on an actual technician being physically on site
- UI can only simulate photo capture and GPS capture until that field run happens
- the higher-risk logic right now is backend inference, clustering, OCR normalization, duplicate handling, and provisional record creation

So the recommended next artifact is:

- a backend simulation fixture
- a backend runner or script
- deterministic assertions against database results and service outputs

## Validation Levels

Use three distinct validation levels.

### 1. Pure simulation

Use synthetic payloads with mocked OCR output and synthetic GPS.

Purpose:

- validate backend logic deterministically
- validate clustering, inference, duplicate handling, and DB writes
- avoid OCR variability while core behavior is still being shaped

### 2. Semi-realistic simulation

Use real sample images plus synthetic GPS and a real OCR pipeline.

Purpose:

- validate that OCR output can be converted into usable backend records
- validate extraction quality against real labels
- validate error handling when OCR is ambiguous or incomplete

### 3. True field validation

Use a real technician device on site with real camera and GPS.

Purpose:

- validate real mobile capture conditions
- validate technician behavior and UX under actual field conditions
- validate whether the end-to-end product works outside the lab

For now, target level 1 first and level 2 next.

## Example Simulation Scenario

Use this as the first shared backend validation scenario.

### Site hint

- probable site name: `Lucknow Public School`
- coordinates: `26.79626604580073, 80.91688813629251`
- address hint: `QWW8+GJW, Sector I, LDA Colony, Kanpur Rd, Sector I, Ashiyana, Lucknow, Uttar Pradesh 226012, India`
- plant size hint: `150 kW`
- make: `SMA`
- inverter count: `6`

### Technician context

- technician has already completed phone + OTP sign-in
- technician session is valid
- request should be treated as a first-time bootstrap visit

### Inverter evidence set

Use six inverter evidence items with GPS points within roughly 20-25 feet of the base location.

Suggested power-unit serials:

- `3005035719`
- `3005035720`
- `3005035721`
- `3005035722`
- `3005035723`
- `3005035724`

Important detail from the sample image:

- one label may contain the **power unit / inverter serial**
- another label may contain the **connection unit serial**

Backend must not simply "find any serial number." It should distinguish at least:

- manufacturer
- probable model
- power unit serial
- connection unit serial, when present

## What Should Be Simulated

The simulation should behave as if UI submitted:

- technician identity context
- bootstrap visit session context
- evidence items with image references or OCR payloads
- GPS coordinates
- timestamps
- optional plant/site hints

This should be treated as a first-visit evidence-first submission, not a preconfigured site flow.

## Recommended Fixture Shape

Use one shared fixture format that both backend and UI can reference later.

Suggested top-level sections:

- `technician`
- `session`
- `site_hints`
- `evidence_items`
- `expected_outcomes`

Suggested evidence item fields:

- `asset_type`
- `capture_type`
- `captured_at`
- `gps.latitude`
- `gps.longitude`
- `gps.accuracy_meters`
- `image_path` or `image_uri`
- `ocr_mode`
- `mocked_ocr`
- `expected_serial_type`

Suggested JSON sketch:

```json
{
  "technician": {
    "phone_number": "+1XXXXXXXXXX",
    "identifier_type": "phone_otp"
  },
  "session": {
    "bootstrap_visit_id": "bootstrap-lucknow-school-001",
    "started_at": "2026-04-07T10:30:00Z"
  },
  "site_hints": {
    "name": "Lucknow Public School",
    "address_hint": "QWW8+GJW, Sector I, LDA Colony, Kanpur Rd, Sector I, Ashiyana, Lucknow, Uttar Pradesh 226012, India",
    "plant_size_kw": 150
  },
  "evidence_items": [
    {
      "asset_type": "solar_inverter",
      "capture_type": "label_photo",
      "captured_at": "2026-04-07T10:31:00Z",
      "gps": {
        "latitude": 26.79626604580073,
        "longitude": 80.91688813629251,
        "accuracy_meters": 8
      },
      "ocr_mode": "mocked",
      "mocked_ocr": {
        "manufacturer": "SMA",
        "model_hint": "Sunny Boy",
        "power_unit_serial": "3005035719"
      }
    }
  ],
  "expected_outcomes": {
    "provisional_site_count": 1,
    "provisional_inverter_count": 6
  }
}
```

## Backend Behaviors To Prove

The backend simulation should prove the following.

### Site inference and clustering

- six nearby inverter captures resolve to **one** probable site, not six sites
- reverse geocoding produces a usable site/address hint
- raw GPS remains stored as source truth
- resolved place/address is stored separately from raw coordinates

### Inventory inference

- six provisional inverter records are created
- manufacturer is normalized to `SMA`
- probable model is captured when available
- correct serial field is extracted and stored
- connection-unit serial is not confused with the main inverter serial

### Workflow safety

- assets remain provisional until review or confirmation rules are met
- canonical inventory is not polluted by weak or ambiguous evidence
- replaying the same fixture does not create unsafe duplicates
- duplicate serial handling is explicit and reviewable

### Resilience

- missing GPS does not crash the flow
- ambiguous OCR does not force canonical creation
- incomplete labels produce review-required states instead of silent bad data

## Quality Control Assertions

Quality Control should ask backend to prove all of the following.

- one site candidate is inferred from the clustered data
- six inverter candidates exist after processing
- each inverter candidate is linked to the same bootstrap visit or inferred site cluster
- reverse geocode output is present and separately traceable from raw GPS
- duplicate rerun behavior is deterministic
- provisional vs canonical status is explicit
- audit trail exists for source evidence and inference steps
- OCR raw output is preserved, not only normalized output

## Tech Lead Guidance

The backend should support two execution modes.

### OCR mocked mode

Use deterministic mocked OCR payloads.

Best for:

- repeatable backend tests
- issue isolation
- validating site clustering and inventory writes

### OCR real-image mode

Use real sample images and the live OCR pipeline.

Best for:

- confidence testing
- validating label extraction quality
- testing serial-type classification

Recommended order:

1. mocked OCR mode first
2. real-image OCR mode second
3. real field technician run later

## Location Resolution Guidance

Backend should **not** depend on scraping Google Maps labels as the primary truth source.

Preferred behavior:

- store raw coordinates as truth
- reverse geocode using a supported provider
- store the resolved place/address as derived metadata
- keep confidence or source metadata when available

## Suggested Outputs From The Backend Runner

The backend simulation runner should produce a readable validation report with:

- bootstrap visit id
- inferred site count
- inferred site label
- reverse-geocoded address
- number of provisional inverters created
- normalized serials
- duplicate warnings
- review-required flags
- canonical records created, if any

This can be console output, a JSON report, or both.

## Questions For Backend Analysis

Backend Codex should explicitly answer these questions.

- What is the exact payload shape to submit evidence "as if from UI"?
- Can current bootstrap APIs accept image evidence plus GPS per item?
- Is reverse geocoding already implemented, or still required?
- Where does OCR output land: raw, normalized, or both?
- How will backend distinguish power-unit serial vs connection-unit serial from the same image set?
- What is the duplicate behavior on replay with the same six serials?
- At what point are provisional assets promoted to canonical inventory?
- What script, management command, or test harness should own this simulation?

## Recommended Next Step

Before more UI work for live field capture, backend should implement:

1. a shared bootstrap field fixture
2. a deterministic backend simulation runner
3. a validation report for this Lucknow Public School scenario

Once that is working, UI can later send the same payload shape from real field capture and compare actual results against the simulation baseline.
