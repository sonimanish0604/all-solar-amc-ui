import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:solaramcui/bootstrap_visit_models.dart';

class TechnicianAccessException implements Exception {
  const TechnicianAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class TechnicianAccessResolver {
  Future<TechnicianRoutingResolution> resolveSession({
    required String identifier,
    required String idToken,
  });

  Future<TechnicianRoutingResolution> submitFirstAccessOrganization({
    required String identifier,
    required String organizationName,
    required String idToken,
  });
}

class ApiTechnicianAccessResolver implements TechnicianAccessResolver {
  ApiTechnicianAccessResolver({
    required Uri baseUrl,
    http.Client? httpClient,
    this.requestTimeout = const Duration(seconds: 12),
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUrl;
  final http.Client _httpClient;
  final Duration requestTimeout;

  @override
  Future<TechnicianRoutingResolution> resolveSession({
    required String identifier,
    required String idToken,
  }) async {
    final json = await _postJson(
      '/auth/session',
      body: {'identifier': identifier},
      idToken: idToken,
    );
    return TechnicianRoutingResolution.fromJson(json);
  }

  @override
  Future<TechnicianRoutingResolution> submitFirstAccessOrganization({
    required String identifier,
    required String organizationName,
    required String idToken,
  }) async {
    final json = await _postJson(
      '/auth/technician-first-access',
      body: {'identifier': identifier, 'organization_name': organizationName},
      idToken: idToken,
    );
    return TechnicianRoutingResolution.fromJson(json);
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    required Map<String, dynamic> body,
    required String idToken,
  }) async {
    final uri = _baseUrl.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
    debugPrint('[TechAccess] POST $uri body=${jsonEncode(body)}');

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: {
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer $idToken',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(requestTimeout);

      debugPrint(
        '[TechAccess] Response ${response.statusCode} from $uri body=${response.body}',
      );
      final json = _decodeJsonObject(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TechnicianAccessException(
          _messageForHttpFailure(response.statusCode, json),
        );
      }

      return json;
    } on SocketException catch (error) {
      debugPrint('[TechAccess] SocketException for $uri: $error');
      throw TechnicianAccessException(
        'The app could not reach the API at $uri. Confirm the backend is running, the phone can reach your laptop, and SOLAR_API_BASE_URL points to the correct host and port.',
      );
    } on TimeoutException catch (error) {
      debugPrint('[TechAccess] TimeoutException for $uri: $error');
      throw const TechnicianAccessException(
        'The API took too long to respond. Retry without losing your local draft state.',
      );
    } on FormatException catch (error) {
      debugPrint('[TechAccess] FormatException for $uri: $error');
      throw const TechnicianAccessException(
        'The API returned an unexpected response shape. Confirm the backend branch for #195 is running locally.',
      );
    }
  }
}

Uri _normalizeBaseUrl(Uri baseUrl) {
  final value = baseUrl.toString();
  return Uri.parse(value.endsWith('/') ? value : '$value/');
}

Map<String, dynamic> _decodeJsonObject(String body) {
  if (body.trim().isEmpty) {
    return <String, dynamic>{};
  }

  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const FormatException('Expected a JSON object.');
}

String _messageForHttpFailure(int statusCode, Map<String, dynamic> json) {
  final detail = json['detail']?.toString();
  final message = json['message']?.toString();
  final backendMessage = detail ?? message;
  if (backendMessage != null && backendMessage.isNotEmpty) {
    return backendMessage;
  }

  return switch (statusCode) {
    400 =>
      'The request was rejected by the backend. Confirm the phone number, OTP session, and organization entry, then retry.',
    401 || 403 =>
      'The technician session could not be verified. Sign in again with phone + OTP.',
    404 =>
      'The backend route is unavailable. Confirm the #195 backend branch is the service you are running locally.',
    409 =>
      'The backend detected a conflicting first-access state. Retry once, then review the backend logs if it persists.',
    _ =>
      'The backend returned an unexpected error ($statusCode). Check the local backend logs and retry.',
  };
}
