import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:solaramcui/bootstrap_visit_models.dart';

abstract class BootstrapVisitSessionStore {
  Future<BootstrapVisitSession?> loadDraft();

  Future<void> saveDraft(BootstrapVisitSession session);

  Future<void> clearDraft();
}

class SharedPreferencesBootstrapVisitSessionStore
    implements BootstrapVisitSessionStore {
  const SharedPreferencesBootstrapVisitSessionStore();

  static const _draftSessionKey = 'bootstrap_visit_draft_session';

  @override
  Future<BootstrapVisitSession?> loadDraft() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedDraft = preferences.getString(_draftSessionKey);

    if (encodedDraft == null || encodedDraft.isEmpty) {
      return null;
    }

    try {
      final jsonMap = jsonDecode(encodedDraft);
      if (jsonMap is! Map<String, dynamic>) {
        return null;
      }

      return BootstrapVisitSession.fromJson(jsonMap);
    } on FormatException {
      await clearDraft();
      return null;
    }
  }

  @override
  Future<void> saveDraft(BootstrapVisitSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_draftSessionKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clearDraft() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_draftSessionKey);
  }
}
