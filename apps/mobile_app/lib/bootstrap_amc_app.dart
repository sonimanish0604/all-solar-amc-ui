import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:solaramcui/app_config.dart';
import 'package:solaramcui/bootstrap_visit_models.dart';
import 'package:solaramcui/bootstrap_visit_session_store.dart';
import 'package:solaramcui/technician_access_resolver.dart';
import 'package:solaramcui/technician_phone_auth.dart';

class AllSolarApp extends StatefulWidget {
  AllSolarApp({
    super.key,
    BootstrapVisitSessionStore? draftStore,
    TechnicianAccessResolver? accessResolver,
    TechnicianPhoneAuthController? phoneAuthController,
    this.restoreDelay = const Duration(milliseconds: 350),
  }) : draftStore =
           draftStore ?? const SharedPreferencesBootstrapVisitSessionStore(),
       accessResolver =
           accessResolver ??
           ApiTechnicianAccessResolver(baseUrl: AppConfig.apiBaseUri),
       phoneAuthController =
           phoneAuthController ?? FirebaseTechnicianPhoneAuthController();

  final BootstrapVisitSessionStore draftStore;
  final TechnicianAccessResolver accessResolver;
  final TechnicianPhoneAuthController phoneAuthController;
  final Duration restoreDelay;

  @override
  State<AllSolarApp> createState() => _AllSolarAppState();
}

class _AllSolarAppState extends State<AllSolarApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _organizationController = TextEditingController();

  BootstrapVisitSession? _session;
  PendingOtpVerification? _pendingOtpVerification;
  TechnicianAuthIdentity? _authIdentity;
  TechnicianRoutingResolution? _routingResolution;
  bool _checkingDraft = true;
  bool _visitReturnsToDemoHome = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _resolvingAccessPath = false;
  bool _submittingOrganization = false;
  String? _phoneValidationError;
  String? _phoneSubmissionError;
  String? _otpValidationError;
  String? _otpSubmissionError;
  String? _organizationValidationError;
  String? _organizationSubmissionError;
  AppScreen _screen = AppScreen.signInPhone;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    BootstrapVisitSession? restoredSession;
    try {
      final draftFuture = widget.draftStore.loadDraft();
      if (widget.restoreDelay > Duration.zero) {
        await Future<void>.delayed(widget.restoreDelay);
      }
      restoredSession = await draftFuture;
    } catch (_) {
      if (mounted) {
        _toast('Draft restore is unavailable right now.');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _session = restoredSession;
      _checkingDraft = false;
      _screen = AppScreen.signInPhone;
    });
  }

  Future<void> _sendOtp() async {
    final normalizedPhone = _normalizePhoneNumber(_phoneController.text);
    if (normalizedPhone == null) {
      setState(() {
        _phoneValidationError =
            'Use country code format, for example +919999999999.';
        _phoneSubmissionError = null;
      });
      return;
    }

    setState(() {
      _sendingOtp = true;
      _phoneValidationError = null;
      _phoneSubmissionError = null;
      _otpValidationError = null;
      _otpSubmissionError = null;
      _pendingOtpVerification = null;
      _authIdentity = null;
      _routingResolution = null;
      _organizationController.clear();
    });

    try {
      await widget.phoneAuthController.signOut();
    } catch (_) {}

    try {
      final pendingOtp = await widget.phoneAuthController.sendOtp(
        phoneNumber: normalizedPhone,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _phoneController.text = normalizedPhone;
        _pendingOtpVerification = pendingOtp;
        _sendingOtp = false;
        _screen = AppScreen.verifyOtp;
        _otpController.clear();
      });
      _toast('Verification code sent.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sendingOtp = false;
        _phoneSubmissionError = _messageFromError(error);
      });
    }
  }

  Future<void> _verifyOtpOrRetryAccessPath() async {
    if (_authIdentity != null) {
      await _resolveAccessPath();
      return;
    }

    final normalizedOtp = _normalizeOtp(_otpController.text);
    if (normalizedOtp == null) {
      setState(() {
        _otpValidationError = 'Enter the 6-digit OTP to continue.';
        _otpSubmissionError = null;
      });
      return;
    }

    final verification = _pendingOtpVerification;
    if (verification == null) {
      setState(() {
        _otpSubmissionError =
            'A verification session is not available. Request a new OTP.';
      });
      return;
    }

    setState(() {
      _verifyingOtp = true;
      _otpValidationError = null;
      _otpSubmissionError = null;
    });

    try {
      final identity = await widget.phoneAuthController.verifyOtp(
        verification: verification,
        smsCode: normalizedOtp,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _authIdentity = identity;
        _phoneController.text = identity.identifier;
        _verifyingOtp = false;
      });

      await _resolveAccessPath();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _verifyingOtp = false;
        _otpSubmissionError = _messageFromError(error);
      });
    }
  }

  Future<void> _resolveAccessPath() async {
    final identity = _authIdentity;
    if (identity == null) {
      return;
    }

    setState(() {
      _resolvingAccessPath = true;
      _otpSubmissionError = null;
      _organizationSubmissionError = null;
    });

    try {
      final resolution = await widget.accessResolver.resolveSession(
        identifier: identity.identifier,
        idToken: identity.idToken,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _routingResolution = resolution;
        _resolvingAccessPath = false;
        _screen = resolution.accessMode.requiresOrganizationStep
            ? AppScreen.firstAccessOrganization
            : AppScreen.routingShell;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resolvingAccessPath = false;
        _screen = AppScreen.verifyOtp;
        _otpSubmissionError = _messageFromError(error);
      });
      _toast('Retry without losing your draft state.');
    }
  }

  Future<void> _submitOrganization() async {
    final organizationName = _organizationController.text.trim();
    final identity = _authIdentity;

    if (identity == null) {
      setState(() {
        _organizationSubmissionError =
            'Your signed-in session is unavailable. Sign in again with phone + OTP.';
      });
      return;
    }

    if (organizationName.isEmpty) {
      setState(() {
        _organizationValidationError =
            'Enter an organization name to continue.';
        _organizationSubmissionError = null;
      });
      return;
    }

    setState(() {
      _submittingOrganization = true;
      _organizationValidationError = null;
      _organizationSubmissionError = null;
    });

    try {
      final resolution = await widget.accessResolver
          .submitFirstAccessOrganization(
            identifier: identity.identifier,
            organizationName: organizationName,
            idToken: identity.idToken,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _routingResolution = resolution;
        _submittingOrganization = false;
        _screen = AppScreen.routingShell;
      });
      _toast('Organization captured. Continue field work.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _submittingOrganization = false;
        _organizationSubmissionError = _messageFromError(error);
      });
    }
  }

  Future<void> _backToPhoneSignIn() async {
    try {
      await widget.phoneAuthController.signOut();
    } catch (_) {}

    if (!mounted) {
      return;
    }

    setState(() {
      _pendingOtpVerification = null;
      _authIdentity = null;
      _routingResolution = null;
      _sendingOtp = false;
      _verifyingOtp = false;
      _resolvingAccessPath = false;
      _submittingOrganization = false;
      _phoneValidationError = null;
      _phoneSubmissionError = null;
      _otpValidationError = null;
      _otpSubmissionError = null;
      _organizationValidationError = null;
      _organizationSubmissionError = null;
      _visitReturnsToDemoHome = false;
      _otpController.clear();
      _organizationController.clear();
      _screen = AppScreen.signInPhone;
    });
  }

  void _openDemoMode() {
    setState(() {
      _visitReturnsToDemoHome = false;
      _screen = AppScreen.demoHome;
    });
  }

  void _leaveDemoMode() {
    setState(() {
      _visitReturnsToDemoHome = false;
      _screen = AppScreen.signInPhone;
    });
  }

  Future<void> _startVisit({bool fromDemoMode = false}) async {
    final now = DateTime.now();
    final session = BootstrapVisitSession(
      id: 'visit-${now.millisecondsSinceEpoch}',
      startedAt: now,
      siteLabel: 'Provisional Site Draft',
      siteHint:
          'Capture evidence now. Final site mapping can be confirmed later.',
      items: const [],
    );

    setState(() {
      _session = session;
      _visitReturnsToDemoHome = fromDemoMode;
      _screen = AppScreen.visit;
      if (_routingResolution != null) {
        _routingResolution = _routingResolution!.copyWith(
          recommendedEntry: TechnicianRecommendedEntry.continueDraftVisit,
          resumeAvailable: true,
          activeBootstrapSessionId: session.id,
        );
      }
    });

    await _saveDraftSession(
      session,
      successMessage: 'Bootstrap visit started.',
    );
  }

  void _resumeVisit({bool fromDemoMode = false}) {
    if (_session == null) {
      _toast('No local draft visit is available yet.');
      return;
    }

    setState(() {
      _visitReturnsToDemoHome = fromDemoMode;
      _screen = AppScreen.visit;
    });
    _toast('Draft visit resumed.');
  }

  void _pauseVisit() {
    setState(() {
      _screen = _visitReturnsToDemoHome
          ? AppScreen.demoHome
          : AppScreen.routingShell;
    });
  }

  Future<void> _addQuickCapture(CapturedItemType type, {String? note}) async {
    final current = _session;
    if (current == null) {
      return;
    }

    final now = DateTime.now();
    final subtitle = note ?? type.subtitle;
    final updatedSession = current.addItem(
      CapturedVisitItem(
        id: '${type.storageName}-${now.microsecondsSinceEpoch}',
        type: type,
        title: type.title,
        subtitle: subtitle,
        capturedAt: now,
      ),
    );

    setState(() {
      _session = updatedSession;
      if (_routingResolution != null) {
        _routingResolution = _routingResolution!.copyWith(
          recommendedEntry: TechnicianRecommendedEntry.continueDraftVisit,
          resumeAvailable: true,
          activeBootstrapSessionId: updatedSession.id,
        );
      }
    });

    await _saveDraftSession(updatedSession, successMessage: type.feedback);
  }

  Future<void> _addNote(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add technician note'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Record what you saw in the field...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (value == null || value.isEmpty) {
      return;
    }

    await _addQuickCapture(CapturedItemType.note, note: value);
  }

  Future<void> _handlePrimaryRoutingAction() async {
    final resolution = _routingResolution;
    if (resolution == null) {
      return;
    }

    final shouldResumeLocalDraft =
        resolution.resumeAvailable && _session != null;
    if (shouldResumeLocalDraft) {
      _resumeVisit(fromDemoMode: false);
      return;
    }

    switch (resolution.recommendedEntry) {
      case TechnicianRecommendedEntry.continueDraftVisit:
        _resumeVisit(fromDemoMode: false);
        return;
      case TechnicianRecommendedEntry.startBootstrapVisit:
        if (_session != null) {
          _resumeVisit(fromDemoMode: false);
          return;
        }
        await _startVisit(fromDemoMode: false);
        return;
      case TechnicianRecommendedEntry.workorderFirst:
        _openScheduledFlow();
        return;
    }
  }

  Future<void> _openBootstrapFromRouting() async {
    if (_session != null) {
      _resumeVisit(fromDemoMode: false);
      return;
    }

    await _startVisit(fromDemoMode: false);
  }

  void _openScheduledFlow() {
    _toast(
      'Scheduled AMC workorders stay separate and will plug into this path later.',
    );
  }

  void _openUpdateInventory() {
    _toast('Existing-site inventory updates will plug in here next.');
  }

  void _openAddInventoryToExistingSite() {
    _toast('Existing-site inventory addition will plug in here next.');
  }

  void _toast(String message) {
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveDraftSession(
    BootstrapVisitSession session, {
    required String successMessage,
  }) async {
    try {
      await widget.draftStore.saveDraft(session);
      _toast(successMessage);
    } catch (_) {
      _toast('Draft persistence is unavailable right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'All Solar AMC',
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F1E8),
        cardTheme: CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE0DACC)),
          ),
        ),
      ),
      home: _checkingDraft
          ? const _DraftCheckScreen()
          : _resolvingAccessPath
          ? const _AccessResolutionScreen()
          : switch (_screen) {
              AppScreen.signInPhone => _PhoneSignInScreen(
                phoneController: _phoneController,
                validationError: _phoneValidationError,
                submissionError: _phoneSubmissionError,
                isSubmitting: _sendingOtp,
                session: _session,
                onSendOtp: _sendOtp,
                onOpenDemoMode: _openDemoMode,
              ),
              AppScreen.demoHome => _DemoHomeScreen(
                session: _session,
                onBackToSignIn: _leaveDemoMode,
                onStartVisit: () {
                  _startVisit(fromDemoMode: true);
                },
                onResumeVisit: () {
                  _resumeVisit(fromDemoMode: true);
                },
                onOpenScheduledFlow: _openScheduledFlow,
              ),
              AppScreen.verifyOtp => _OtpVerificationScreen(
                phoneNumber:
                    _pendingOtpVerification?.phoneNumber ??
                    _phoneController.text.trim(),
                otpController: _otpController,
                validationError: _otpValidationError,
                submissionError: _otpSubmissionError,
                isSubmitting: _verifyingOtp,
                hasVerifiedIdentity: _authIdentity != null,
                onChangePhone: _backToPhoneSignIn,
                onResendOtp: _sendOtp,
                onSubmit: _verifyOtpOrRetryAccessPath,
              ),
              AppScreen.firstAccessOrganization =>
                _FirstAccessOrganizationScreen(
                  controller: _organizationController,
                  identifier: _authIdentity?.identifier,
                  validationError: _organizationValidationError,
                  submissionError: _organizationSubmissionError,
                  isSubmitting: _submittingOrganization,
                  onBackToPhoneSignIn: _backToPhoneSignIn,
                  onSubmit: _submitOrganization,
                ),
              AppScreen.routingShell => _RoutingShellScreen(
                session: _session,
                resolution: _routingResolution!,
                onSignOut: _backToPhoneSignIn,
                onPrimaryAction: _handlePrimaryRoutingAction,
                onOpenBootstrapFlow: _openBootstrapFromRouting,
                onOpenScheduledFlow: _openScheduledFlow,
                onOpenUpdateInventory: _openUpdateInventory,
                onOpenAddInventoryToExistingSite:
                    _openAddInventoryToExistingSite,
              ),
              AppScreen.visit => _VisitScreen(
                session: _session!,
                backTooltip: _visitReturnsToDemoHome
                    ? 'Back to demo home'
                    : 'Back to routing shell',
                onPauseVisit: _pauseVisit,
                onAddEquipment: () {
                  _addQuickCapture(CapturedItemType.equipmentLabel);
                },
                onAddMeter: () {
                  _addQuickCapture(CapturedItemType.meterPhoto);
                },
                onAddGeneralPhoto: () {
                  _addQuickCapture(CapturedItemType.generalPhoto);
                },
                onAddNote: _addNote,
              ),
            },
    );
  }
}

class _PhoneSignInScreen extends StatelessWidget {
  const _PhoneSignInScreen({
    required this.phoneController,
    required this.validationError,
    required this.submissionError,
    required this.isSubmitting,
    required this.session,
    required this.onSendOtp,
    required this.onOpenDemoMode,
  });

  final TextEditingController phoneController;
  final String? validationError;
  final String? submissionError;
  final bool isSubmitting;
  final BootstrapVisitSession? session;
  final Future<void> Function() onSendOtp;
  final VoidCallback onOpenDemoMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD7ECE7), Color(0xFFF4F1E8)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text(
                'All Solar AMC',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF0F766E),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Technician sign in',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  color: const Color(0xFF16302B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use phone + OTP before accessing bootstrap or scheduled AMC flows. No Google or alternate sign-in options are available for technicians.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF38554E),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('phone-input'),
                        controller: phoneController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+919999999999',
                          border: const OutlineInputBorder(),
                          errorText: validationError,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Use country code format so Firebase phone verification can send the OTP to the right number.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5C665F),
                        ),
                      ),
                      if (submissionError != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(message: submissionError!),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('send-otp'),
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  onSendOtp();
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Send OTP'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need the field demo screen?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open the earlier demo shell to capture field progress or walkthrough content without going through sign-in first.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5C665F),
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        key: const ValueKey('open-demo-mode'),
                        onPressed: onOpenDemoMode,
                        icon: const Icon(Icons.slideshow_rounded),
                        label: const Text('Open Demo Mode'),
                      ),
                    ],
                  ),
                ),
              ),
              if (session != null) ...[
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local draft ready to reuse',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${session!.items.length} captured item(s) are already saved on this device. After sign-in, the app can use this local draft as a resume hint.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5C665F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: 18),
                Text(
                  'Debug API base: ${AppConfig.apiBaseLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5C665F),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoHomeScreen extends StatelessWidget {
  const _DemoHomeScreen({
    required this.session,
    required this.onBackToSignIn,
    required this.onStartVisit,
    required this.onResumeVisit,
    required this.onOpenScheduledFlow,
  });

  final BootstrapVisitSession? session;
  final VoidCallback onBackToSignIn;
  final VoidCallback onStartVisit;
  final VoidCallback onResumeVisit;
  final VoidCallback onOpenScheduledFlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: onBackToSignIn,
            child: const Text('Back To Sign In'),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD7ECE7), Color(0xFFF4F1E8)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                'All Solar AMC',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF0F766E),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Field-ready AMC,\nwithout waiting on site setup.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  color: const Color(0xFF16302B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use this demo shell for field walkthroughs, progress captures, and simple evidence collection while the technician auth path evolves.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF38554E),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Technician-first bootstrap flow',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF183A33),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Start work before site setup is complete. Evidence stays grouped under one provisional visit session.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5C665F),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey('demo-start-visit'),
                          onPressed: onStartVisit,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Start AMC Visit'),
                          ),
                        ),
                      ),
                      if (session != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F5F1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE0DACC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Draft visit ready to continue',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${session!.items.length} captured item(s) · ${_formatTimestamp(session!.startedAt)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF5C665F),
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                key: const ValueKey('demo-resume-visit'),
                                onPressed: onResumeVisit,
                                icon: const Icon(Icons.restore_rounded),
                                label: const Text('Continue Draft Visit'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled AMC Workorders',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep the regular workorder-first path separate. This demo shell should not replace assigned visits.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5C665F),
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: onOpenScheduledFlow,
                        child: const Text('Open Scheduled Flow'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpVerificationScreen extends StatelessWidget {
  const _OtpVerificationScreen({
    required this.phoneNumber,
    required this.otpController,
    required this.validationError,
    required this.submissionError,
    required this.isSubmitting,
    required this.hasVerifiedIdentity,
    required this.onChangePhone,
    required this.onResendOtp,
    required this.onSubmit,
  });

  final String phoneNumber;
  final TextEditingController otpController;
  final String? validationError;
  final String? submissionError;
  final bool isSubmitting;
  final bool hasVerifiedIdentity;
  final Future<void> Function() onChangePhone;
  final Future<void> Function() onResendOtp;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final helperText = hasVerifiedIdentity
        ? 'Phone verification already succeeded. Retry loading your access path without requesting a new OTP.'
        : 'Enter the 6-digit code sent to $phoneNumber.';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: isSubmitting
                ? null
                : () {
                    onChangePhone();
                  },
            child: const Text('Change Phone'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Enter verification code',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF16302B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              helperText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF38554E),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasVerifiedIdentity) ...[
                      TextField(
                        key: const ValueKey('otp-input'),
                        controller: otpController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '123456',
                          border: const OutlineInputBorder(),
                          errorText: validationError,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'If the code expires or fails, send a new OTP without losing your local draft state.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5C665F),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F5F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Text(
                          'Phone verified for $phoneNumber. Retry the backend routing step without requesting another OTP.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF0F766E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (submissionError != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: submissionError!),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('verify-otp'),
                        onPressed: isSubmitting
                            ? null
                            : () {
                                onSubmit();
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  hasVerifiedIdentity
                                      ? 'Retry Access Path'
                                      : 'Verify OTP',
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                onResendOtp();
                              },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Send New Code'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstAccessOrganizationScreen extends StatelessWidget {
  const _FirstAccessOrganizationScreen({
    required this.controller,
    required this.identifier,
    required this.validationError,
    required this.submissionError,
    required this.isSubmitting,
    required this.onBackToPhoneSignIn,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? identifier;
  final String? validationError;
  final String? submissionError;
  final bool isSubmitting;
  final Future<void> Function() onBackToPhoneSignIn;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: isSubmitting
                ? null
                : () {
                    onBackToPhoneSignIn();
                  },
            child: const Text('Change Phone'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Welcome. Please define your organization.',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF16302B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start Field Work',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are signed in and can continue in a provisional workflow. Final site and inventory confirmation may happen after supervisor review.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF38554E),
              ),
            ),
            if (identifier != null) ...[
              const SizedBox(height: 12),
              Text(
                'Signed in as $identifier',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5C665F),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organization Name',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('organization-input'),
                      controller: controller,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Example: Nogginhaus',
                        border: const OutlineInputBorder(),
                        errorText: validationError,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Capture the organization as the technician says it. Polishing, normalization, and spoken-input UX can follow later.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5C665F),
                      ),
                    ),
                    if (submissionError != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: submissionError!),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                onSubmit();
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Continue To Field Work'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutingShellScreen extends StatelessWidget {
  const _RoutingShellScreen({
    required this.session,
    required this.resolution,
    required this.onSignOut,
    required this.onPrimaryAction,
    required this.onOpenBootstrapFlow,
    required this.onOpenScheduledFlow,
    required this.onOpenUpdateInventory,
    required this.onOpenAddInventoryToExistingSite,
  });

  final BootstrapVisitSession? session;
  final TechnicianRoutingResolution resolution;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onOpenBootstrapFlow;
  final VoidCallback onOpenScheduledFlow;
  final VoidCallback onOpenUpdateInventory;
  final VoidCallback onOpenAddInventoryToExistingSite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocalResume = resolution.resumeAvailable && session != null;
    final resumeButtonLabel = hasLocalResume
        ? 'Continue Draft Visit'
        : resolution.recommendedEntry.label;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Choose Your Work'),
        actions: [
          TextButton(
            onPressed: () {
              onSignOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Choose the right field-work path.',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF16302B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This shell uses the backend post-OTP routing response as the source of truth for technician access and next actions.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF38554E),
              ),
            ),
            const SizedBox(height: 20),
            if (resolution.provisionalAccess) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provisional Site And Inventory',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can continue field work now. Site and inventory details are still provisional and may be reviewed or confirmed by a supervisor later.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF38554E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Action',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF0F766E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasLocalResume
                          ? 'A saved draft is ready on this device. Resume it first, then use the other actions below if you need a different path.'
                          : 'No draft needs to be resumed. Use the recommended entry below, or choose a different action if the field situation requires it.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5C665F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('primary-routing-action'),
                        onPressed: () {
                          onPrimaryAction();
                        },
                        icon: Icon(
                          hasLocalResume
                              ? Icons.restore_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(resumeButtonLabel),
                        ),
                      ),
                    ),
                    if (session != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${session!.items.length} captured item(s) · ${_formatTimestamp(session!.startedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5C665F),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Other Field Paths',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'These stay visible even when a draft resume is available so the technician is not trapped in one path.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5C665F),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 168,
                  child: _RoutingActionTile(
                    title: 'Update Inventory',
                    subtitle:
                        'Open the existing-site inventory update path when it is ready.',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF1D4ED8),
                    onTap: onOpenUpdateInventory,
                  ),
                ),
                SizedBox(
                  width: 168,
                  child: _RoutingActionTile(
                    title: 'Add Inventory',
                    subtitle:
                        'Add inventory to a site that already exists in the platform.',
                    icon: Icons.add_business_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: onOpenAddInventoryToExistingSite,
                  ),
                ),
                SizedBox(
                  width: 168,
                  child: _RoutingActionTile(
                    title: 'Create New Site / Inventory',
                    subtitle:
                        'Use the bootstrap visit shell to start a new field-led draft.',
                    icon: Icons.play_circle_outline_rounded,
                    color: const Color(0xFF0F766E),
                    onTap: () {
                      onOpenBootstrapFlow();
                    },
                  ),
                ),
                SizedBox(
                  width: 168,
                  child: _RoutingActionTile(
                    title: 'Open Scheduled Flow',
                    subtitle:
                        'Keep the workorder-first AMC path separate when scheduled work exists.',
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFFB45309),
                    onTap: onOpenScheduledFlow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitScreen extends StatelessWidget {
  const _VisitScreen({
    required this.session,
    required this.backTooltip,
    required this.onPauseVisit,
    required this.onAddEquipment,
    required this.onAddMeter,
    required this.onAddGeneralPhoto,
    required this.onAddNote,
  });

  final BootstrapVisitSession session;
  final String backTooltip;
  final VoidCallback onPauseVisit;
  final VoidCallback onAddEquipment;
  final VoidCallback onAddMeter;
  final VoidCallback onAddGeneralPhoto;
  final Future<void> Function(BuildContext context) onAddNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('AMC Visit In Progress'),
        leading: IconButton(
          tooltip: backTooltip,
          onPressed: onPauseVisit,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F5F0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            session.siteLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF0F766E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'Draft ID ${session.id}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5C665F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      session.siteHint,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2A26),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Started ${_formatTimestamp(session.startedAt)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5C665F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricPill(
                          label: 'Pending sync',
                          value: '${session.items.length}',
                          color: const Color(0xFF0F766E),
                        ),
                        _MetricPill(
                          label: 'Captured items',
                          value: '${session.items.length}',
                          color: const Color(0xFF1D4ED8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Capture hub',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This slice keeps capture lightweight and local while server-backed session sync continues to land behind the bootstrap APIs.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5C665F),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 168,
                  child: _RoutingActionTile(
                    tapKey: const ValueKey('capture-equipment'),
                    title: 'Scan Equipment Label',
                    subtitle:
                        'Create a local evidence item for a nameplate or serial label.',
                    icon: CapturedItemType.equipmentLabel.icon,
                    color: CapturedItemType.equipmentLabel.color,
                    onTap: onAddEquipment,
                  ),
                ),
                SizedBox(
                  width: 168,
                  child: _RoutingActionTile(
                    tapKey: const ValueKey('capture-meter'),
                    title: 'Capture Meter Photo',
                    subtitle:
                        'Queue local draft evidence for meter-reading capture.',
                    icon: CapturedItemType.meterPhoto.icon,
                    color: CapturedItemType.meterPhoto.color,
                    onTap: onAddMeter,
                  ),
                ),
                SizedBox(
                  width: 168,
                  child: _RoutingActionTile(
                    tapKey: const ValueKey('capture-general-photo'),
                    title: 'Capture General Photo',
                    subtitle:
                        'Add plant or equipment context to the current visit.',
                    icon: CapturedItemType.generalPhoto.icon,
                    color: CapturedItemType.generalPhoto.color,
                    onTap: onAddGeneralPhoto,
                  ),
                ),
                SizedBox(
                  width: 168,
                  child: _RoutingActionTile(
                    tapKey: const ValueKey('capture-note'),
                    title: 'Add Note',
                    subtitle:
                        'Record technician observations without leaving this session.',
                    icon: CapturedItemType.note.icon,
                    color: CapturedItemType.note.color,
                    onTap: () => onAddNote(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CountCard(
                  label: 'Label photos',
                  count: session.count(CapturedItemType.equipmentLabel),
                  color: CapturedItemType.equipmentLabel.color,
                ),
                _CountCard(
                  label: 'Meter photos',
                  count: session.count(CapturedItemType.meterPhoto),
                  color: CapturedItemType.meterPhoto.color,
                ),
                _CountCard(
                  label: 'General photos',
                  count: session.count(CapturedItemType.generalPhoto),
                  color: CapturedItemType.generalPhoto.color,
                ),
                _CountCard(
                  label: 'Notes',
                  count: session.count(CapturedItemType.note),
                  color: CapturedItemType.note.color,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (session.items.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No evidence yet. Use the capture hub above to start building this first-time visit.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5C665F),
                    ),
                  ),
                ),
              )
            else
              ...session.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: item.type.color.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: item.type.color,
                        child: Icon(item.type.icon),
                      ),
                      title: Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${item.subtitle}\n${_formatTimestamp(item.capturedAt)}',
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: null,
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Review & Submit comes in the next story'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutingActionTile extends StatelessWidget {
  const _RoutingActionTile({
    this.tapKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final Key? tapKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: tapKey,
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5C665F)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF9F1239),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5C665F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftCheckScreen extends StatelessWidget {
  const _DraftCheckScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Checking for unfinished draft visits...'),
          ],
        ),
      ),
    );
  }
}

class _AccessResolutionScreen extends StatelessWidget {
  const _AccessResolutionScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Signed in. Determining your access path...'),
          ],
        ),
      ),
    );
  }
}

String? _normalizePhoneNumber(String rawValue) {
  final normalized = rawValue.replaceAll(RegExp(r'[\s()-]'), '');
  if (!RegExp(r'^\+\d{10,15}$').hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

String? _normalizeOtp(String rawValue) {
  final normalized = rawValue.replaceAll(RegExp(r'\s+'), '');
  if (!RegExp(r'^\d{6}$').hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

String _messageFromError(Object error) {
  return switch (error) {
    TechnicianPhoneAuthException() => error.message,
    TechnicianAccessException() => error.message,
    _ => 'Something went wrong. Retry without losing your local draft state.',
  };
}

String _formatTimestamp(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final meridiem = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.month}/${value.day} $hour:$minute $meridiem';
}
