import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TechnicianPhoneAuthException implements Exception {
  const TechnicianPhoneAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PendingOtpVerification {
  const PendingOtpVerification({
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
}

class TechnicianAuthIdentity {
  const TechnicianAuthIdentity({
    required this.identifier,
    required this.idToken,
    this.firebaseUid,
  });

  final String identifier;
  final String idToken;
  final String? firebaseUid;
}

abstract class TechnicianPhoneAuthController {
  Future<PendingOtpVerification> sendOtp({required String phoneNumber});

  Future<TechnicianAuthIdentity> verifyOtp({
    required PendingOtpVerification verification,
    required String smsCode,
  });

  Future<void> signOut();
}

class FirebaseTechnicianPhoneAuthController
    implements TechnicianPhoneAuthController {
  FirebaseTechnicianPhoneAuthController({
    FirebaseAuth? firebaseAuth,
    this.timeout = const Duration(seconds: 45),
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  final Duration timeout;

  @override
  Future<PendingOtpVerification> sendOtp({required String phoneNumber}) async {
    final completer = Completer<PendingOtpVerification>();
    debugPrint('[PhoneAuth] Starting OTP request for $phoneNumber');

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: (_) {
        debugPrint('[PhoneAuth] verificationCompleted received.');
      },
      verificationFailed: (error) {
        debugPrint(
          '[PhoneAuth] verificationFailed code=${error.code} message=${error.message}',
        );
        if (!completer.isCompleted) {
          completer.completeError(
            TechnicianPhoneAuthException(_messageForFirebaseError(error)),
          );
        }
      },
      codeSent: (verificationId, resendToken) {
        debugPrint(
          '[PhoneAuth] codeSent verificationId=$verificationId resendToken=$resendToken',
        );
        if (!completer.isCompleted) {
          completer.complete(
            PendingOtpVerification(
              phoneNumber: phoneNumber,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        debugPrint(
          '[PhoneAuth] codeAutoRetrievalTimeout verificationId=$verificationId',
        );
        if (!completer.isCompleted) {
          completer.complete(
            PendingOtpVerification(
              phoneNumber: phoneNumber,
              verificationId: verificationId,
            ),
          );
        }
      },
    );

    return completer.future.timeout(
      timeout + const Duration(seconds: 5),
      onTimeout: () {
        throw const TechnicianPhoneAuthException(
          'OTP delivery is taking too long. Retry and confirm the device has network access.',
        );
      },
    );
  }

  @override
  Future<TechnicianAuthIdentity> verifyOtp({
    required PendingOtpVerification verification,
    required String smsCode,
  }) async {
    debugPrint(
      '[PhoneAuth] Verifying OTP for ${verification.phoneNumber} verificationId=${verification.verificationId}',
    );
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verification.verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const TechnicianPhoneAuthException(
          'Phone verification succeeded, but the user session is unavailable. Retry the sign-in flow.',
        );
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw const TechnicianPhoneAuthException(
          'Phone verification succeeded, but the Firebase session token is unavailable. Retry the sign-in flow.',
        );
      }

      return TechnicianAuthIdentity(
        identifier: user.phoneNumber ?? verification.phoneNumber,
        idToken: idToken,
        firebaseUid: user.uid,
      );
    } on FirebaseAuthException catch (error) {
      debugPrint(
        '[PhoneAuth] verifyOtp failed code=${error.code} message=${error.message}',
      );
      throw TechnicianPhoneAuthException(_messageForFirebaseError(error));
    }
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}

String _messageForFirebaseError(FirebaseAuthException error) {
  final message = error.message?.trim();
  if (message != null && message.isNotEmpty) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('unusual activity')) {
      return 'Firebase has temporarily blocked OTP requests from this device due to unusual activity. Use a Firebase test number for now, or wait and retry from a different device or network.';
    }
    if (lowerMessage.contains('recaptcha')) {
      return 'Firebase phone auth app verification is not completing. Confirm the Android package, SHA fingerprints, Play Services, and Firebase phone auth setup, then retry.';
    }
  }

  return switch (error.code) {
    'invalid-phone-number' =>
      'Use a valid phone number with country code, for example +919999999999.',
    'invalid-verification-code' =>
      'That OTP is invalid. Enter the latest code and retry.',
    'session-expired' => 'The OTP has expired. Request a new code and retry.',
    'too-many-requests' =>
      'Too many OTP attempts were made. Wait a moment, then retry.',
    'network-request-failed' =>
      'The phone-auth request could not reach Firebase. Check the device connection and retry.',
    'captcha-check-failed' =>
      'Firebase app verification failed during reCAPTCHA or Play Integrity checks. Retry once after reopening the app, or use a Firebase test number while device verification is unstable.',
    'quota-exceeded' =>
      'Firebase phone-auth quota is exhausted right now. Wait and retry later, or use a Firebase test number for local development.',
    _ =>
      message ??
          'Phone verification could not be completed right now. Retry the sign-in flow.',
  };
}
