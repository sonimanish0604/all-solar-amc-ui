import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

const _demoSeenKey = 'demo_seen';
const _demoImageBase64 = 'ZGVtby1pbWFnZQ==';
const _maxUploadBytes = 1536 * 1024;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SolarAmcApp());
}

class SolarAmcApp extends StatelessWidget {
  const SolarAmcApp({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1C6E4A),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'All Solar AMC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: palette,
        scaffoldBackgroundColor: const Color(0xFFF5F1E8),
        useMaterial3: true,
      ),
      home: const AppBootstrapPage(),
    );
  }
}

class AppBootstrapPage extends StatefulWidget {
  const AppBootstrapPage({super.key});

  @override
  State<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends State<AppBootstrapPage> {
  bool? _showDemoFirst;

  @override
  void initState() {
    super.initState();
    _loadFirstLaunchState();
  }

  Future<void> _loadFirstLaunchState() async {
    final prefs = await SharedPreferences.getInstance();
    final seenDemo = prefs.getBool(_demoSeenKey) ?? false;
    if (!mounted) {
      return;
    }
    setState(() {
      _showDemoFirst = !seenDemo;
    });
  }

  Future<void> _markDemoSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoSeenKey, true);
  }

  Future<void> _goToSignIn() async {
    await _markDemoSeen();
    if (!mounted) {
      return;
    }
    setState(() {
      _showDemoFirst = false;
    });
  }

  Future<void> _startDemo() async {
    await _markDemoSeen();
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DemoFlowPage(
          onExitToSignIn: _goToSignIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showDemoFirst = _showDemoFirst;
    if (showDemoFirst == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (showDemoFirst) {
      return DemoLandingPage(
        onStartDemo: _startDemo,
        onSkipDemo: _goToSignIn,
      );
    }

    return SignInPlaceholderPage(
      onEnterDemoAgain: _startDemo,
    );
  }
}

class DemoLandingPage extends StatelessWidget {
  const DemoLandingPage({
    super.key,
    required this.onStartDemo,
    required this.onSkipDemo,
  });

  final Future<void> Function() onStartDemo;
  final Future<void> Function() onSkipDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'AI demo mode',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Turn a field photo into a readable answer.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This guided demo shows how All Solar AMC can read handwritten notes, meters, and equipment labels before anyone signs in.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _InfoCard(
                title: 'What you will see',
                body:
                    'Start with a lightweight note-reading example, then continue into meter and serial demos as we expand the flow.',
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Privacy-safe demo',
                body:
                    'Demo requests are illustrative only and stay separate from tenant work orders, reports, and production records.',
              ),
              const Spacer(),
              FilledButton(
                onPressed: onStartDemo,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Start demo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onSkipDemo,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Skip to sign-in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DemoFlowPage extends StatefulWidget {
  const DemoFlowPage({
    super.key,
    required this.onExitToSignIn,
  });

  final Future<void> Function() onExitToSignIn;

  @override
  State<DemoFlowPage> createState() => _DemoFlowPageState();
}

class _DemoFlowPageState extends State<DemoFlowPage> {
  final DemoApiClient _apiClient = DemoApiClient();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();
  DemoCaptureType _selectedType = DemoCaptureType.note;
  DemoInputMode _selectedInputMode = DemoInputMode.image;
  DemoCaptureResult? _result;
  VoiceRecordingDebug? _recordingDebug;
  SelectedImageDebug? _selectedImageDebug;
  String? _error;
  String? _infoMessage;
  bool _isLoading = false;
  bool _isRecording = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _playRecordedAudio() async {
    final debug = _recordingDebug;
    if (debug == null) {
      return;
    }

    final file = File(debug.filePath);
    if (!await file.exists()) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'The recorded audio file is no longer available for playback.';
      });
      return;
    }

    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(debug.filePath));
  }

  Future<void> _runImageDemo({required DemoSample sample}) async {
    setState(() {
      _isLoading = true;
      _result = null;
      _recordingDebug = null;
      _selectedImageDebug = null;
      _error = null;
      _infoMessage = null;
    });

    try {
      final result = await _apiClient.analyzeImage(
        captureType: _selectedType,
        fileName: sample.fileName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _captureOrPickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        setState(() {
          _error = 'Camera permission is required for live photo capture.';
          _infoMessage =
              'You can still use the sample image buttons below while camera access is unavailable.';
        });
        return;
      }
    }

    XFile? file;
    try {
      file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to access ${source == ImageSource.camera ? 'camera' : 'photo library'}: $error';
      });
      return;
    }

    if (file == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _infoMessage = source == ImageSource.camera
            ? 'Live photo capture was cancelled.'
            : 'Image selection was cancelled.';
      });
      return;
    }

    setState(() {
      _result = null;
      _recordingDebug = null;
      _selectedImageDebug = null;
      _error = null;
      _infoMessage = null;
    });

    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxUploadBytes) {
        throw Exception(
          'The selected image is ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB after compression. Please choose a smaller image or retake the photo.',
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImageDebug = SelectedImageDebug(
          filePath: file!.path,
          fileName: _extractFileName(file.path),
          contentType: _guessImageContentType(file.path),
          byteLength: bytes.length,
          bytes: bytes,
          source: source,
        );
        _infoMessage = source == ImageSource.camera
            ? 'Review the captured image before sending it to the public ${_selectedType.pathSegment} endpoint.'
            : 'Review the selected image before sending it to the public ${_selectedType.pathSegment} endpoint.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<void> _sendSelectedImage() async {
    final image = _selectedImageDebug;
    if (image == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _recordingDebug = null;
      _error = null;
      _infoMessage = 'Uploading image to the public ${_selectedType.pathSegment} endpoint...';
    });

    try {
      final result = await _apiClient.analyzeCapturedImage(
        captureType: _selectedType,
        imageBase64: base64Encode(image.bytes),
        imageContentType: image.contentType,
        fileName: image.fileName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _infoMessage = image.source == ImageSource.camera
            ? 'Live camera photo was sent to the public ${_selectedType.pathSegment} endpoint.'
            : 'Selected image was sent to the public ${_selectedType.pathSegment} endpoint.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareSelectedImage() async {
    final image = _selectedImageDebug;
    if (image == null) {
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final sharePath = '${tempDir.path}/${image.fileName}';
      final shareFile = File(sharePath);
      await shareFile.writeAsBytes(image.bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(sharePath, mimeType: image.contentType)],
          text: 'Debug capture exported from the All Solar AMC demo app.',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to share the selected image: $error';
      });
    }
  }

  String _guessImageContentType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _extractFileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isNotEmpty ? segments.last : 'demo-capture.jpg';
  }

  Future<void> _runVoiceDemo({required DemoVoiceSample sample}) async {
    setState(() {
      _isLoading = true;
      _result = null;
      _recordingDebug = null;
      _selectedImageDebug = null;
      _error = null;
      _infoMessage = null;
    });

    try {
      final result = await _apiClient.analyzeVoiceTranscript(
        captureType: _selectedType,
        spokenText: sample.spokenText,
        sampleHint: sample.sampleHint,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      await _stopAndSendVoiceRecording();
      return;
    }
    await _startVoiceRecording();
  }

  Future<void> _startVoiceRecording() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      setState(() {
        _error = 'Microphone permission is required for live voice capture.';
        _infoMessage =
            'Use the transcript fallback buttons below if microphone access is unavailable.';
        _recordingDebug = null;
      });
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${_selectedType.pathSegment}_demo_voice.wav';
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        numChannels: 1,
        sampleRate: 16000,
      ),
      path: filePath,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecording = true;
      _result = null;
      _recordingDebug = null;
      _error = null;
      _infoMessage = 'Recording... speak clearly, then tap stop to send.';
    });
  }

  Future<void> _stopAndSendVoiceRecording() async {
    setState(() {
      _isLoading = true;
      _isRecording = false;
      _result = null;
      _selectedImageDebug = null;
      _error = null;
      _infoMessage = 'Uploading microphone audio to the demo voice API...';
    });

    try {
      final path = await _audioRecorder.stop();
      if (path == null) {
        throw Exception('No audio recording was captured.');
      }

      final bytes = await File(path).readAsBytes();
      final debug = VoiceRecordingDebug.fromBytes(
        filePath: path,
        bytes: bytes,
      );

      if (debug.isTooSmall) {
        throw Exception(
          'The recorded audio looks too small to transcribe reliably. Please record for a little longer and speak more clearly.',
        );
      }

      final result = await _apiClient.analyzeVoiceAudio(
        captureType: _selectedType,
        audioBase64: base64Encode(bytes),
        audioContentType: 'audio/wav',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _recordingDebug = debug;
        _infoMessage = result.provider == 'deepgram'
            ? 'Live microphone audio was processed by Deepgram.'
            : 'Live microphone audio was processed by the current voice provider.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _infoMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exitToSignIn() async {
    await widget.onExitToSignIn();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentCopy = _selectedType.copy;
    final currentMode = _selectedInputMode;
    final primaryImageSample = _selectedType.primarySample;
    final secondaryImageSample = _selectedType.secondarySample;
    final primaryVoiceSample = _selectedType.primaryVoiceSample;
    final secondaryVoiceSample = _selectedType.secondaryVoiceSample;
    final showVoiceMode = _selectedType.supportsVoice;
    final voiceModeActive = currentMode == DemoInputMode.voice;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided demo'),
        actions: [
          TextButton(
            onPressed: _exitToSignIn,
            child: const Text('Exit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            currentCopy.stepLabel,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            currentCopy.description,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          SegmentedButton<DemoCaptureType>(
            segments: DemoCaptureType.values
                .map(
                  (type) => ButtonSegment<DemoCaptureType>(
                    value: type,
                    label: Text(type.label),
                  ),
                )
                .toList(),
            selected: {_selectedType},
            onSelectionChanged: _isLoading
                ? null
                : (selection) {
                    setState(() {
                      _selectedType = selection.first;
                      if (!selection.first.supportsVoice) {
                        _selectedInputMode = DemoInputMode.image;
                      }
                      _result = null;
                      _recordingDebug = null;
                      _error = null;
                      _infoMessage = null;
                      _isRecording = false;
                    });
                  },
            ),
          if (showVoiceMode) ...[
            const SizedBox(height: 16),
            SegmentedButton<DemoInputMode>(
              segments: const [
                ButtonSegment<DemoInputMode>(
                  value: DemoInputMode.image,
                  label: Text('Photo'),
                ),
                ButtonSegment<DemoInputMode>(
                  value: DemoInputMode.voice,
                  label: Text('Voice'),
                ),
              ],
              selected: {_selectedInputMode},
              onSelectionChanged: _isLoading
                  ? null
                  : (selection) {
                      setState(() {
                        _selectedInputMode = selection.first;
                        _result = null;
                        _recordingDebug = null;
                        _selectedImageDebug = null;
                        _error = null;
                      });
                    },
            ),
          ],
          const SizedBox(height: 20),
          _InfoCard(
            title: 'How this slice works',
            body: currentMode == DemoInputMode.image
                ? currentCopy.howItWorks
                : currentCopy.voiceHowItWorks ?? currentCopy.howItWorks,
          ),
          if (!voiceModeActive) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Capture tips',
              body: currentCopy.imageGuidance,
            ),
          ],
          const SizedBox(height: 20),
          if (voiceModeActive) ...[
            FilledButton(
              onPressed: _isLoading ? null : _toggleVoiceRecording,
              child: Text(
                _isRecording
                    ? 'Stop recording and send'
                    : 'Record live voice sample',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () => _runVoiceDemo(sample: primaryVoiceSample!),
              child: Text(primaryVoiceSample!.buttonLabel),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () => _runVoiceDemo(sample: secondaryVoiceSample!),
              child: Text(secondaryVoiceSample!.buttonLabel),
            ),
          ] else ...[
            FilledButton(
              onPressed: _isLoading
                  ? null
                  : () => _captureOrPickImage(ImageSource.camera),
              child: const Text('Capture live photo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () => _captureOrPickImage(ImageSource.gallery),
              child: const Text('Choose existing photo'),
            ),
            const SizedBox(height: 16),
            Text(
              'Sample fallbacks',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isLoading
                  ? null
                  : () => _runImageDemo(sample: primaryImageSample),
              child: Text(primaryImageSample.buttonLabel),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () => _runImageDemo(sample: secondaryImageSample),
              child: Text(secondaryImageSample.buttonLabel),
            ),
          ],
          const SizedBox(height: 24),
          if (_infoMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _infoMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_recordingDebug != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _VoiceDebugCard(
                debug: _recordingDebug!,
                onPlay: _playRecordedAudio,
              ),
            ),
          if (_selectedImageDebug != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ImageDebugCard(
                debug: _selectedImageDebug!,
                onSend: _isLoading ? null : _sendSelectedImage,
                onShare: _isLoading ? null : _shareSelectedImage,
                onRetake: _isLoading
                    ? null
                    : () => _captureOrPickImage(_selectedImageDebug!.source),
              ),
            ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _ErrorCard(message: _error!)
          else if (_result != null)
            _ResultCard(result: _result!),
          const SizedBox(height: 24),
          Text(
            'Later steps',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const _InfoCard(
            title: 'Meter and serial capture',
            body:
                'The next stories add camera capture, permissions, sample-image fallback, and stronger polish around these same API-backed result states.',
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _exitToSignIn,
            child: const Text('Continue to sign-in'),
          ),
        ],
      ),
    );
  }
}

class SignInPlaceholderPage extends StatelessWidget {
  const SignInPlaceholderPage({
    super.key,
    required this.onEnterDemoAgain,
  });

  final Future<void> Function() onEnterDemoAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign-in'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Normal app flow placeholder',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is where the authenticated mobile experience and onboarding flow will land. For now, returning users can intentionally re-enter the demo from here.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onEnterDemoAgain,
              child: const Text('Try demo again'),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoApiClient {
  DemoApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<DemoCaptureResult> analyzeImage({
    required DemoCaptureType captureType,
    required String fileName,
  }) async {
    return analyzeCapturedImage(
      captureType: captureType,
      imageBase64: _demoImageBase64,
      imageContentType: 'image/jpeg',
      fileName: fileName,
    );
  }

  Future<DemoCaptureResult> analyzeCapturedImage({
    required DemoCaptureType captureType,
    required String imageBase64,
    required String imageContentType,
    required String fileName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/demo/${captureType.pathSegment}');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(
        {
          'image_base64': imageBase64,
          'image_content_type': imageContentType,
          'file_name': fileName,
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Demo API failed: ${response.statusCode} ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return DemoCaptureResult.fromJson(payload);
  }

  Future<DemoCaptureResult> analyzeVoiceTranscript({
    required DemoCaptureType captureType,
    required String spokenText,
    String? sampleHint,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/demo/${captureType.pathSegment}/voice');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(
        {
          'spoken_text': spokenText,
          if (sampleHint != null) 'sample_hint': sampleHint,
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Voice demo API failed: ${response.statusCode} ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return DemoCaptureResult.fromJson(payload);
  }

  Future<DemoCaptureResult> analyzeVoiceAudio({
    required DemoCaptureType captureType,
    required String audioBase64,
    required String audioContentType,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/demo/${captureType.pathSegment}/voice');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(
        {
          'audio_base64': audioBase64,
          'audio_content_type': audioContentType,
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Voice demo API failed: ${response.statusCode} ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return DemoCaptureResult.fromJson(payload);
  }
}

class ApiConfig {
  static const String _androidDebugBaseUrl = 'http://127.0.0.1:8001';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8001';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidDebugBaseUrl;
      default:
        return 'http://localhost:8001';
    }
  }
}

class DemoCaptureResult {
  const DemoCaptureResult({
    required this.captureType,
    required this.provider,
    required this.status,
    required this.reviewRequired,
    required this.confidenceScore,
    required this.transcriptText,
    required this.extractedText,
    required this.extractedValue,
    required this.normalizedText,
    required this.errorCode,
    required this.retryGuidance,
  });

  factory DemoCaptureResult.fromJson(Map<String, dynamic> json) {
    return DemoCaptureResult(
      captureType: json['capture_type'] as String? ?? 'note',
      provider: json['provider'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'failed',
      reviewRequired: json['review_required'] as bool? ?? false,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      transcriptText: json['transcript_text'] as String?,
      extractedText: json['extracted_text'] as String?,
      extractedValue: (json['extracted_value'] as num?)?.toDouble(),
      normalizedText: json['normalized_text'] as String?,
      errorCode: json['error_code'] as String?,
      retryGuidance: json['retry_guidance'] as String?,
    );
  }

  final String captureType;
  final String provider;
  final String status;
  final bool reviewRequired;
  final double? confidenceScore;
  final String? transcriptText;
  final String? extractedText;
  final double? extractedValue;
  final String? normalizedText;
  final String? errorCode;
  final String? retryGuidance;
}

class VoiceRecordingDebug {
  const VoiceRecordingDebug({
    required this.filePath,
    required this.byteLength,
    required this.headerHex,
    required this.isLikelyWav,
    required this.isTooSmall,
    required this.audioFormatCode,
    required this.channelCount,
    required this.sampleRate,
    required this.bitsPerSample,
  });

  factory VoiceRecordingDebug.fromBytes({
    required String filePath,
    required List<int> bytes,
  }) {
    final headerBytes = bytes.take(12).toList();
    final headerHex = headerBytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    final asciiHeader = String.fromCharCodes(
      bytes.take(4),
    );
    final waveMarker = bytes.length >= 12
        ? String.fromCharCodes(bytes.sublist(8, 12))
        : '';

    return VoiceRecordingDebug(
      filePath: filePath,
      byteLength: bytes.length,
      headerHex: headerHex,
      isLikelyWav: asciiHeader == 'RIFF' && waveMarker == 'WAVE',
      isTooSmall: bytes.length < 4096,
      audioFormatCode: bytes.length >= 22
          ? bytes[20] | (bytes[21] << 8)
          : null,
      channelCount: bytes.length >= 24
          ? bytes[22] | (bytes[23] << 8)
          : null,
      sampleRate: bytes.length >= 28
          ? bytes[24] |
                (bytes[25] << 8) |
                (bytes[26] << 16) |
                (bytes[27] << 24)
          : null,
      bitsPerSample: bytes.length >= 36
          ? bytes[34] | (bytes[35] << 8)
          : null,
    );
  }

  final String filePath;
  final int byteLength;
  final String headerHex;
  final bool isLikelyWav;
  final bool isTooSmall;
  final int? audioFormatCode;
  final int? channelCount;
  final int? sampleRate;
  final int? bitsPerSample;
}

class SelectedImageDebug {
  const SelectedImageDebug({
    required this.filePath,
    required this.fileName,
    required this.contentType,
    required this.byteLength,
    required this.bytes,
    required this.source,
  });

  final String filePath;
  final String fileName;
  final String contentType;
  final int byteLength;
  final Uint8List bytes;
  final ImageSource source;
}

enum DemoInputMode {
  image,
  voice,
}

enum DemoCaptureType {
  note,
  meter,
  serial;

  String get label => switch (this) {
        DemoCaptureType.note => 'Note',
        DemoCaptureType.meter => 'Meter',
        DemoCaptureType.serial => 'Serial',
      };

  String get pathSegment => name;

  bool get supportsVoice => switch (this) {
        DemoCaptureType.note => false,
        DemoCaptureType.meter => true,
        DemoCaptureType.serial => true,
      };

  DemoCopy get copy => switch (this) {
        DemoCaptureType.note => const DemoCopy(
            stepLabel: 'Step 1 of 3: handwritten note',
            description:
                'We are starting with a sample note request so the app shell and backend contract are proven before camera capture is added.',
            howItWorks:
                'The app sends a demo image payload to the public note endpoint and renders the response with success, review, or retry guidance.',
            imageGuidance:
                'Fill most of the frame with the note, keep the writing centered, avoid shadows across the page, and hold the phone steady until the text looks crisp.',
          ),
        DemoCaptureType.meter => const DemoCopy(
            stepLabel: 'Step 2 of 3: energy meter',
            description:
                'This meter example is closer to the field workflow and shows how numeric extraction can come back with a result or a review-needed state.',
            howItWorks:
                'The app sends the same demo payload shape to the public meter endpoint and prefers numeric output with retry guidance when confidence is low.',
            imageGuidance:
                'Move closer so the digits fill the frame, square the phone to the display, reduce glare, and make sure the full reading is visible before you send.',
            voiceHowItWorks:
                'The voice path records microphone audio and sends it to the public meter voice endpoint. Transcript fallback buttons stay available for development and forced-state testing.',
          ),
        DemoCaptureType.serial => const DemoCopy(
            stepLabel: 'Step 3 of 3: serial number',
            description:
                'This serial example shows how equipment identifiers can be captured from labels and returned in a readable format without touching production records.',
            howItWorks:
                'The app calls the public serial endpoint and renders either a clean identifier or an unreadable retry state depending on the sample used.',
            imageGuidance:
                'Keep the label flat in the frame, avoid angled shots, make the serial text large enough to read, and retake if glare or blur covers any characters.',
            voiceHowItWorks:
                'The voice path records microphone audio and sends it to the public serial voice endpoint. Transcript fallback buttons stay available for development and forced-state testing.',
          ),
      };

  DemoSample get primarySample => switch (this) {
        DemoCaptureType.note => const DemoSample(
            fileName: 'note-demo-service-visit.jpg',
            buttonLabel: 'Run sample note demo',
          ),
        DemoCaptureType.meter => const DemoSample(
            fileName: 'meter-review-reading-182345_7.jpg',
            buttonLabel: 'Run meter review sample',
          ),
        DemoCaptureType.serial => const DemoSample(
            fileName: 'serial-sn-demo-2026-001.jpg',
            buttonLabel: 'Run serial success sample',
          ),
      };

  DemoSample get secondarySample => switch (this) {
        DemoCaptureType.note => const DemoSample(
            fileName: 'note-unreadable.jpg',
            buttonLabel: 'Try unreadable note sample',
          ),
        DemoCaptureType.meter => const DemoSample(
            fileName: 'meter-unreadable.jpg',
            buttonLabel: 'Try unreadable meter sample',
          ),
        DemoCaptureType.serial => const DemoSample(
            fileName: 'serial-unreadable.jpg',
            buttonLabel: 'Try unreadable serial sample',
          ),
      };

  DemoVoiceSample? get primaryVoiceSample => switch (this) {
        DemoCaptureType.note => null,
        DemoCaptureType.meter => const DemoVoiceSample(
            spokenText: 'meter reading 182345.7',
            buttonLabel: 'Use transcript fallback sample',
          ),
        DemoCaptureType.serial => const DemoVoiceSample(
            spokenText: 'serial sn demo 2026 001',
            buttonLabel: 'Use transcript fallback sample',
          ),
      };

  DemoVoiceSample? get secondaryVoiceSample => switch (this) {
        DemoCaptureType.note => null,
        DemoCaptureType.meter => const DemoVoiceSample(
            spokenText: 'meter reading 182345.7',
            sampleHint: 'review',
            buttonLabel: 'Use transcript fallback review sample',
          ),
        DemoCaptureType.serial => const DemoVoiceSample(
            spokenText: 'serial garbled',
            sampleHint: 'noisy',
            buttonLabel: 'Use transcript fallback unreadable sample',
          ),
      };
}

class DemoCopy {
  const DemoCopy({
    required this.stepLabel,
    required this.description,
    required this.howItWorks,
    required this.imageGuidance,
    this.voiceHowItWorks,
  });

  final String stepLabel;
  final String description;
  final String howItWorks;
  final String imageGuidance;
  final String? voiceHowItWorks;
}

class DemoSample {
  const DemoSample({
    required this.fileName,
    required this.buttonLabel,
  });

  final String fileName;
  final String buttonLabel;
}

class DemoVoiceSample {
  const DemoVoiceSample({
    required this.spokenText,
    required this.buttonLabel,
    this.sampleHint,
  });

  final String spokenText;
  final String buttonLabel;
  final String? sampleHint;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final DemoCaptureResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = switch (result.status) {
      'success' => Colors.green.shade50,
      'review_required' => Colors.amber.shade50,
      'unreadable' => Colors.orange.shade50,
      _ => Colors.red.shade50,
    };

    final primaryValue = result.extractedValue != null
        ? result.extractedValue!.toString()
        : result.extractedText ?? result.normalizedText ?? 'No extraction returned';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo result',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            primaryValue,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text('Status: ${result.status}'),
          Text('Provider: ${result.provider}'),
          if (result.confidenceScore != null)
            Text('Confidence: ${result.confidenceScore!.toStringAsFixed(1)}'),
          if (result.transcriptText != null)
            Text('Transcript: ${result.transcriptText!}'),
          if (result.errorCode != null)
            Text('Error code: ${result.errorCode!}'),
          if (result.retryGuidance != null) ...[
            const SizedBox(height: 12),
            Text(
              result.retryGuidance!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(message),
    );
  }
}

class _VoiceDebugCard extends StatelessWidget {
  const _VoiceDebugCard({
    required this.debug,
    required this.onPlay,
  });

  final VoiceRecordingDebug debug;
  final Future<void> Function() onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice debug',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: OutlinedButton(
              onPressed: onPlay,
              child: const Text('Play recorded audio'),
            ),
          ),
          const SizedBox(height: 12),
          Text('Bytes: ${debug.byteLength}'),
          Text('Likely WAV: ${debug.isLikelyWav ? 'yes' : 'no'}'),
          Text('Format code: ${debug.audioFormatCode ?? 'unknown'}'),
          Text('Channels: ${debug.channelCount ?? 'unknown'}'),
          Text('Sample rate: ${debug.sampleRate ?? 'unknown'} Hz'),
          Text('Bits per sample: ${debug.bitsPerSample ?? 'unknown'}'),
          Text('Header: ${debug.headerHex}'),
          Text(
            debug.isTooSmall
                ? 'Recording looks very small. Try speaking longer before stopping.'
                : 'Recording size looks plausible for upload.',
          ),
        ],
      ),
    );
  }
}

class _ImageDebugCard extends StatelessWidget {
  const _ImageDebugCard({
    required this.debug,
    required this.onSend,
    required this.onShare,
    required this.onRetake,
  });

  final SelectedImageDebug debug;
  final Future<void> Function()? onSend;
  final Future<void> Function()? onShare;
  final Future<void> Function()? onRetake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizeInMb = debug.byteLength / (1024 * 1024);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image preview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              debug.bytes,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text('File: ${debug.fileName}'),
          Text('Content type: ${debug.contentType}'),
          Text(
            'Size: ${sizeInMb.toStringAsFixed(2)} MB (${debug.byteLength} bytes)',
          ),
          Text(
            debug.source == ImageSource.camera
                ? 'Source: live camera capture'
                : 'Source: existing photo selection',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onSend == null ? null : () => onSend!.call(),
            child: const Text('Send photo now'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onShare == null ? null : () => onShare!.call(),
            child: const Text('Share image'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetake == null ? null : () => onRetake!.call(),
            child: Text(
              debug.source == ImageSource.camera
                  ? 'Retake photo'
                  : 'Choose another photo',
            ),
          ),
        ],
      ),
    );
  }
}
