import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solaramcui/bootstrap_amc_app.dart';
import 'package:solaramcui/bootstrap_visit_models.dart';
import 'package:solaramcui/bootstrap_visit_session_store.dart';
import 'package:solaramcui/technician_access_resolver.dart';
import 'package:solaramcui/technician_phone_auth.dart';

void main() {
  testWidgets('demo mode stays available from the sign-in screen', (
    WidgetTester tester,
  ) async {
    await _setTestSurface(tester);
    await tester.pumpWidget(
      _buildApp(
        draftStore: _InMemoryBootstrapVisitSessionStore(),
        accessResolver: _FakeTechnicianAccessResolver.returning(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('open-demo-mode')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-demo-mode')));
    await tester.pumpAndSettle();

    expect(
      find.text('Field-ready AMC,\nwithout waiting on site setup.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('demo-start-visit')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demo-start-visit')));
    await tester.pumpAndSettle();

    expect(find.text('AMC Visit In Progress'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to demo home'));
    await tester.pumpAndSettle();

    expect(
      find.text('Field-ready AMC,\nwithout waiting on site setup.'),
      findsOneWidget,
    );
  });

  testWidgets('technician can start and resume a bootstrap visit', (
    WidgetTester tester,
  ) async {
    await _setTestSurface(tester);
    final store = _InMemoryBootstrapVisitSessionStore();

    await tester.pumpWidget(
      _buildApp(
        draftStore: store,
        accessResolver: _FakeTechnicianAccessResolver.returning(),
      ),
    );
    await tester.pumpAndSettle();

    await _signInReturningTechnician(tester);

    expect(find.text('Start AMC Visit'), findsOneWidget);
    expect(find.text('Continue Draft Visit'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('primary-routing-action')));
    await tester.pumpAndSettle();

    expect(find.text('AMC Visit In Progress'), findsOneWidget);
    expect(find.text('Provisional Site Draft'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to routing shell'));
    await tester.pumpAndSettle();

    expect(find.text('Continue Draft Visit'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('primary-routing-action')));
    await tester.pumpAndSettle();

    expect(find.text('AMC Visit In Progress'), findsOneWidget);
    expect(store.draftSession, isNotNull);
  });

  testWidgets(
    'first-time technician can submit organization and enter routing shell',
    (WidgetTester tester) async {
      await _setTestSurface(tester);
      await tester.pumpWidget(
        _buildApp(
          draftStore: _InMemoryBootstrapVisitSessionStore(),
          accessResolver: _FakeTechnicianAccessResolver.firstAccess(),
        ),
      );
      await tester.pumpAndSettle();

      await _signInFirstAccessTechnician(tester);

      expect(
        find.text('Welcome. Please define your organization.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('organization-input')),
        'Nogginhaus',
      );
      await _scrollToContinueButton(tester);
      await tester.tap(find.text('Continue To Field Work'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Work'), findsOneWidget);
      expect(find.text('Provisional Site And Inventory'), findsOneWidget);
    },
  );

  testWidgets('blank organization name is rejected cleanly', (
    WidgetTester tester,
  ) async {
    await _setTestSurface(tester);
    await tester.pumpWidget(
      _buildApp(
        draftStore: _InMemoryBootstrapVisitSessionStore(),
        accessResolver: _FakeTechnicianAccessResolver.firstAccess(),
      ),
    );
    await tester.pumpAndSettle();

    await _signInFirstAccessTechnician(tester);
    await _scrollToContinueButton(tester);
    await tester.tap(find.text('Continue To Field Work'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter an organization name to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('organization submission retry keeps the typed value', (
    WidgetTester tester,
  ) async {
    await _setTestSurface(tester);
    await tester.pumpWidget(
      _buildApp(
        draftStore: _InMemoryBootstrapVisitSessionStore(),
        accessResolver: _FakeTechnicianAccessResolver.firstAccess(
          failOrganizationSubmissionCount: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _signInFirstAccessTechnician(tester);
    await tester.enterText(
      find.byKey(const ValueKey('organization-input')),
      'Nogginhaus',
    );
    await _scrollToContinueButton(tester);
    await tester.tap(find.text('Continue To Field Work'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Organization capture is unavailable right now. Retry without losing your entry.',
      ),
      findsOneWidget,
    );

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('organization-input')),
    );
    expect(field.controller?.text, 'Nogginhaus');

    await _scrollToContinueButton(tester);
    await tester.tap(find.text('Continue To Field Work'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Work'), findsOneWidget);
  });

  testWidgets('returning technician sees routing shell actions', (
    WidgetTester tester,
  ) async {
    await _setTestSurface(tester);
    await tester.pumpWidget(
      _buildApp(
        draftStore: _InMemoryBootstrapVisitSessionStore(),
        accessResolver: _FakeTechnicianAccessResolver.returning(),
      ),
    );
    await tester.pumpAndSettle();

    await _signInReturningTechnician(tester);

    expect(find.text('Update Inventory'), findsOneWidget);
    expect(find.text('Add Inventory'), findsOneWidget);
    expect(find.text('Create New Site / Inventory'), findsOneWidget);
    expect(find.text('Open Scheduled Flow'), findsOneWidget);
  });

  testWidgets(
    'resume state makes continue draft visit primary when a draft exists',
    (WidgetTester tester) async {
      await _setTestSurface(tester);
      final store = _InMemoryBootstrapVisitSessionStore(
        draftSession: _draftSession(),
      );

      await tester.pumpWidget(
        _buildApp(
          draftStore: store,
          accessResolver: _FakeTechnicianAccessResolver.returning(
            resumeAvailable: true,
            recommendedEntry: TechnicianRecommendedEntry.continueDraftVisit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _signInReturningTechnician(tester);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('primary-routing-action')),
          matching: find.text('Continue Draft Visit'),
        ),
        findsOneWidget,
      );
      expect(find.text('1 captured item(s) · 3/27 10:30 AM'), findsOneWidget);
    },
  );
}

Widget _buildApp({
  required BootstrapVisitSessionStore draftStore,
  required TechnicianAccessResolver accessResolver,
}) {
  return AllSolarApp(
    draftStore: draftStore,
    accessResolver: accessResolver,
    phoneAuthController: _FakeTechnicianPhoneAuthController(),
    restoreDelay: Duration.zero,
  );
}

Future<void> _signInReturningTechnician(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('phone-input')),
    '+919999999999',
  );
  await tester.tap(find.byKey(const ValueKey('send-otp')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('otp-input')), '123456');
  await tester.tap(find.byKey(const ValueKey('verify-otp')));
  await tester.pumpAndSettle();
}

Future<void> _signInFirstAccessTechnician(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('phone-input')),
    '+919999999999',
  );
  await tester.tap(find.byKey(const ValueKey('send-otp')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('otp-input')), '123456');
  await tester.tap(find.byKey(const ValueKey('verify-otp')));
  await tester.pumpAndSettle();
}

Future<void> _scrollToContinueButton(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Continue To Field Work'),
    120,
    scrollable: find.byType(Scrollable).first,
  );
}

Future<void> _setTestSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 960));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

BootstrapVisitSession _draftSession() {
  return BootstrapVisitSession(
    id: 'visit-persisted',
    startedAt: DateTime(2026, 3, 27, 10, 30),
    siteLabel: 'Provisional Site Draft',
    siteHint: 'Restored from local persistence for resume.',
    items: [
      CapturedVisitItem(
        id: 'equipment-1',
        type: CapturedItemType.equipmentLabel,
        title: 'Equipment label photo',
        subtitle: 'Restored from local draft storage.',
        capturedAt: DateTime(2026, 3, 27, 10, 32),
      ),
    ],
  );
}

class _InMemoryBootstrapVisitSessionStore
    implements BootstrapVisitSessionStore {
  _InMemoryBootstrapVisitSessionStore({this.draftSession});

  BootstrapVisitSession? draftSession;

  @override
  Future<void> clearDraft() async {
    draftSession = null;
  }

  @override
  Future<BootstrapVisitSession?> loadDraft() async {
    return draftSession;
  }

  @override
  Future<void> saveDraft(BootstrapVisitSession session) async {
    draftSession = session;
  }
}

class _FakeTechnicianPhoneAuthController
    implements TechnicianPhoneAuthController {
  @override
  Future<PendingOtpVerification> sendOtp({required String phoneNumber}) async {
    return PendingOtpVerification(
      phoneNumber: phoneNumber,
      verificationId: 'verification-001',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<TechnicianAuthIdentity> verifyOtp({
    required PendingOtpVerification verification,
    required String smsCode,
  }) async {
    if (smsCode != '123456') {
      throw const TechnicianPhoneAuthException(
        'That OTP is invalid. Enter the latest code and retry.',
      );
    }

    return TechnicianAuthIdentity(
      identifier: verification.phoneNumber,
      idToken: 'fake-firebase-token',
      firebaseUid: 'firebase-tech-001',
    );
  }
}

class _FakeTechnicianAccessResolver implements TechnicianAccessResolver {
  _FakeTechnicianAccessResolver.returning({
    this.resumeAvailable = false,
    this.recommendedEntry = TechnicianRecommendedEntry.startBootstrapVisit,
  }) : _initialMode = TechnicianAccessMode.returning,
       failOrganizationSubmissionCount = 0;

  _FakeTechnicianAccessResolver.firstAccess({
    this.failOrganizationSubmissionCount = 0,
  }) : _initialMode = TechnicianAccessMode.firstAccessRequired,
       resumeAvailable = false,
       recommendedEntry = TechnicianRecommendedEntry.startBootstrapVisit;

  final TechnicianAccessMode _initialMode;
  final bool resumeAvailable;
  final TechnicianRecommendedEntry recommendedEntry;
  int failOrganizationSubmissionCount;

  @override
  Future<TechnicianRoutingResolution> resolveSession({
    required String identifier,
    required String idToken,
  }) async {
    if (_initialMode == TechnicianAccessMode.firstAccessRequired) {
      return const TechnicianRoutingResolution(
        accessMode: TechnicianAccessMode.firstAccessRequired,
        recommendedEntry: TechnicianRecommendedEntry.startBootstrapVisit,
        resumeAvailable: false,
        activeBootstrapSessionId: null,
        provisionalAccess: true,
        supervisorReviewRequired: false,
      );
    }

    return TechnicianRoutingResolution(
      tenantId: 'tenant-debug-001',
      userId: 'tech-debug-001',
      accessMode: TechnicianAccessMode.returning,
      recommendedEntry: recommendedEntry,
      resumeAvailable: resumeAvailable,
      activeBootstrapSessionId: resumeAvailable ? 'server-draft-001' : null,
      provisionalAccess: resumeAvailable,
      supervisorReviewRequired: false,
      hasScheduledWorkorders: true,
    );
  }

  @override
  Future<TechnicianRoutingResolution> submitFirstAccessOrganization({
    required String identifier,
    required String organizationName,
    required String idToken,
  }) async {
    if (failOrganizationSubmissionCount > 0) {
      failOrganizationSubmissionCount -= 1;
      throw const TechnicianAccessException(
        'Organization capture is unavailable right now. Retry without losing your entry.',
      );
    }

    return TechnicianRoutingResolution(
      tenantId: 'tenant-nogginhaus',
      userId: 'tech-first-access',
      accessMode: TechnicianAccessMode.firstAccessCreated,
      recommendedEntry: TechnicianRecommendedEntry.startBootstrapVisit,
      resumeAvailable: false,
      activeBootstrapSessionId: null,
      provisionalAccess: true,
      supervisorReviewRequired: true,
    );
  }
}
