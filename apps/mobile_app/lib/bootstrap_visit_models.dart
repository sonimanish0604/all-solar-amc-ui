import 'package:flutter/material.dart';

enum AppScreen {
  signInPhone,
  demoHome,
  verifyOtp,
  firstAccessOrganization,
  routingShell,
  visit,
}

enum TechnicianAccessMode { firstAccessRequired, firstAccessCreated, returning }

extension TechnicianAccessModePresentation on TechnicianAccessMode {
  bool get requiresOrganizationStep =>
      this == TechnicianAccessMode.firstAccessRequired;

  bool get isFirstAccess =>
      this == TechnicianAccessMode.firstAccessRequired ||
      this == TechnicianAccessMode.firstAccessCreated;
}

TechnicianAccessMode technicianAccessModeFromWire(String value) {
  return switch (value.toUpperCase()) {
    'FIRST_ACCESS_REQUIRED' => TechnicianAccessMode.firstAccessRequired,
    'FIRST_ACCESS_CREATED' => TechnicianAccessMode.firstAccessCreated,
    'RETURNING' => TechnicianAccessMode.returning,
    _ => throw FormatException('Unsupported access mode: $value'),
  };
}

enum TechnicianRecommendedEntry {
  continueDraftVisit,
  startBootstrapVisit,
  workorderFirst,
}

TechnicianRecommendedEntry technicianRecommendedEntryFromWire(String value) {
  return switch (value.toUpperCase()) {
    'CONTINUE_DRAFT_VISIT' => TechnicianRecommendedEntry.continueDraftVisit,
    'START_BOOTSTRAP_VISIT' => TechnicianRecommendedEntry.startBootstrapVisit,
    'WORKORDER_FIRST' => TechnicianRecommendedEntry.workorderFirst,
    _ => TechnicianRecommendedEntry.startBootstrapVisit,
  };
}

extension TechnicianRecommendedEntryPresentation on TechnicianRecommendedEntry {
  String get label => switch (this) {
    TechnicianRecommendedEntry.continueDraftVisit => 'Continue Draft Visit',
    TechnicianRecommendedEntry.startBootstrapVisit => 'Start AMC Visit',
    TechnicianRecommendedEntry.workorderFirst => 'Open Scheduled Flow',
  };
}

class TechnicianRoutingResolution {
  const TechnicianRoutingResolution({
    this.tenantId,
    this.userId,
    required this.accessMode,
    required this.recommendedEntry,
    required this.resumeAvailable,
    this.activeBootstrapSessionId,
    required this.provisionalAccess,
    required this.supervisorReviewRequired,
    this.hasScheduledWorkorders = false,
  });

  final String? tenantId;
  final String? userId;
  final TechnicianAccessMode accessMode;
  final TechnicianRecommendedEntry recommendedEntry;
  final bool resumeAvailable;
  final String? activeBootstrapSessionId;
  final bool provisionalAccess;
  final bool supervisorReviewRequired;
  final bool hasScheduledWorkorders;

  factory TechnicianRoutingResolution.fromJson(Map<String, dynamic> json) {
    return TechnicianRoutingResolution(
      tenantId: _stringValue(json['tenant_id']),
      userId: _stringValue(json['user_id']),
      accessMode: technicianAccessModeFromWire(
        json['access_mode']?.toString() ?? 'RETURNING',
      ),
      recommendedEntry: technicianRecommendedEntryFromWire(
        json['recommended_entry']?.toString() ?? 'START_BOOTSTRAP_VISIT',
      ),
      resumeAvailable: _boolValue(json['resume_available']),
      activeBootstrapSessionId: _stringValue(
        json['active_bootstrap_session_id'],
      ),
      provisionalAccess: _boolValue(json['provisional_access']),
      supervisorReviewRequired: _boolValue(json['supervisor_review_required']),
      hasScheduledWorkorders: _boolValue(json['has_scheduled_workorders']),
    );
  }

  TechnicianRoutingResolution copyWith({
    String? tenantId,
    String? userId,
    TechnicianAccessMode? accessMode,
    TechnicianRecommendedEntry? recommendedEntry,
    bool? resumeAvailable,
    String? activeBootstrapSessionId,
    bool? provisionalAccess,
    bool? supervisorReviewRequired,
    bool? hasScheduledWorkorders,
  }) {
    return TechnicianRoutingResolution(
      tenantId: tenantId ?? this.tenantId,
      userId: userId ?? this.userId,
      accessMode: accessMode ?? this.accessMode,
      recommendedEntry: recommendedEntry ?? this.recommendedEntry,
      resumeAvailable: resumeAvailable ?? this.resumeAvailable,
      activeBootstrapSessionId:
          activeBootstrapSessionId ?? this.activeBootstrapSessionId,
      provisionalAccess: provisionalAccess ?? this.provisionalAccess,
      supervisorReviewRequired:
          supervisorReviewRequired ?? this.supervisorReviewRequired,
      hasScheduledWorkorders:
          hasScheduledWorkorders ?? this.hasScheduledWorkorders,
    );
  }
}

String? _stringValue(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == 'null') {
    return null;
  }
  return text;
}

bool _boolValue(dynamic value) {
  return switch (value) {
    true => true,
    false => false,
    String() => value.toLowerCase() == 'true',
    num() => value != 0,
    _ => false,
  };
}

enum CapturedItemType { equipmentLabel, meterPhoto, generalPhoto, note }

extension CapturedItemTypePresentation on CapturedItemType {
  String get storageName => switch (this) {
    CapturedItemType.equipmentLabel => 'equipment-label',
    CapturedItemType.meterPhoto => 'meter-photo',
    CapturedItemType.generalPhoto => 'general-photo',
    CapturedItemType.note => 'note',
  };

  String get title => switch (this) {
    CapturedItemType.equipmentLabel => 'Equipment label photo',
    CapturedItemType.meterPhoto => 'Meter photo',
    CapturedItemType.generalPhoto => 'General photo',
    CapturedItemType.note => 'Technician note',
  };

  String get subtitle => switch (this) {
    CapturedItemType.equipmentLabel =>
      'Local draft evidence for a nameplate or serial label.',
    CapturedItemType.meterPhoto =>
      'Local draft evidence for meter-reading capture.',
    CapturedItemType.generalPhoto =>
      'Local draft evidence for plant or equipment context.',
    CapturedItemType.note => 'Technician note saved locally.',
  };

  String get feedback => switch (this) {
    CapturedItemType.equipmentLabel => 'Equipment label capture saved.',
    CapturedItemType.meterPhoto => 'Meter photo capture saved.',
    CapturedItemType.generalPhoto => 'General photo capture saved.',
    CapturedItemType.note => 'Note saved.',
  };

  IconData get icon => switch (this) {
    CapturedItemType.equipmentLabel => Icons.qr_code_scanner_rounded,
    CapturedItemType.meterPhoto => Icons.electric_meter_rounded,
    CapturedItemType.generalPhoto => Icons.photo_camera_back_rounded,
    CapturedItemType.note => Icons.sticky_note_2_rounded,
  };

  Color get color => switch (this) {
    CapturedItemType.equipmentLabel => const Color(0xFF0F766E),
    CapturedItemType.meterPhoto => const Color(0xFFB45309),
    CapturedItemType.generalPhoto => const Color(0xFF1D4ED8),
    CapturedItemType.note => const Color(0xFF7C3AED),
  };
}

CapturedItemType capturedItemTypeFromStorageName(String value) {
  return switch (value) {
    'equipment-label' => CapturedItemType.equipmentLabel,
    'meter-photo' => CapturedItemType.meterPhoto,
    'general-photo' => CapturedItemType.generalPhoto,
    'note' => CapturedItemType.note,
    _ => CapturedItemType.note,
  };
}

class BootstrapVisitSession {
  const BootstrapVisitSession({
    required this.id,
    required this.startedAt,
    required this.siteLabel,
    required this.siteHint,
    required this.items,
  });

  final String id;
  final DateTime startedAt;
  final String siteLabel;
  final String siteHint;
  final List<CapturedVisitItem> items;

  int count(CapturedItemType type) =>
      items.where((item) => item.type == type).length;

  BootstrapVisitSession addItem(CapturedVisitItem item) {
    return BootstrapVisitSession(
      id: id,
      startedAt: startedAt,
      siteLabel: siteLabel,
      siteHint: siteHint,
      items: [item, ...items],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'siteLabel': siteLabel,
      'siteHint': siteHint,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory BootstrapVisitSession.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => CapturedVisitItem.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList()
        : <CapturedVisitItem>[];

    return BootstrapVisitSession(
      id: json['id']?.toString() ?? 'unknown-draft',
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      siteLabel: json['siteLabel']?.toString() ?? 'Provisional Site Draft',
      siteHint:
          json['siteHint']?.toString() ??
          'Capture evidence now. Final site mapping can be confirmed later.',
      items: items,
    );
  }
}

class CapturedVisitItem {
  const CapturedVisitItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.capturedAt,
  });

  final String id;
  final CapturedItemType type;
  final String title;
  final String subtitle;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.storageName,
      'title': title,
      'subtitle': subtitle,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }

  factory CapturedVisitItem.fromJson(Map<String, dynamic> json) {
    return CapturedVisitItem(
      id: json['id']?.toString() ?? 'unknown-item',
      type: capturedItemTypeFromStorageName(json['type']?.toString() ?? ''),
      title: json['title']?.toString() ?? 'Captured item',
      subtitle: json['subtitle']?.toString() ?? '',
      capturedAt:
          DateTime.tryParse(json['capturedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
