import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../core/skino_assets.dart';
import '../../../../core/skino_image_icon.dart';

class ImageCapturePanel extends StatefulWidget {
  const ImageCapturePanel({
    required this.image,
    required this.isLoading,
    required this.error,
    required this.onCapture,
    required this.onResetScanFrame,
    required this.onAnalyze,
    required this.canShareForTraining,
    required this.allowModelTraining,
    required this.onAllowModelTrainingChanged,
    super.key,
  });

  final File? image;
  final bool isLoading;
  final String? error;
  final ValueChanged<File> onCapture;
  final VoidCallback onResetScanFrame;
  final VoidCallback? onAnalyze;
  final bool canShareForTraining;
  final bool allowModelTraining;
  final ValueChanged<bool> onAllowModelTrainingChanged;

  @override
  State<ImageCapturePanel> createState() => _ImageCapturePanelState();
}

class _ImageCapturePanelState extends State<ImageCapturePanel> {
  CameraController? _controller;
  Future<void>? _initializeCamera;
  late final FaceDetector _faceDetector;
  String? _cameraError;
  int _guideStep = 0;
  Timer? _guideTimer;
  bool _isProcessingFrame = false;
  bool _isStreaming = false;
  DateTime? _holdStartedAt;
  _ScanGateStatus _gateStatus = const _ScanGateStatus();

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,
        enableContours: false,
        enableLandmarks: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _initializeCamera = _startCamera();
    _startGuideTimer();
  }

  @override
  void dispose() {
    _guideTimer?.cancel();
    _stopQualityStream();
    _faceDetector.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ImageCapturePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image == null && _guideTimer == null) {
      _startGuideTimer();
    } else if (widget.image != null && _guideTimer != null) {
      _guideTimer?.cancel();
      _guideTimer = null;
    }
    if (oldWidget.image != null && widget.image == null) {
      setState(() {
        _guideStep = 0;
        _gateStatus = const _ScanGateStatus();
        _holdStartedAt = null;
      });
      final controller = _controller;
      if (controller != null && controller.value.isInitialized) {
        unawaited(_startQualityStream(controller));
      }
    }
  }

  void _startGuideTimer() {
    _guideTimer?.cancel();
    _guideTimer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (!mounted || widget.image != null) {
        return;
      }
      final nextStep = _nextGuideStep(_gateStatus);
      if (nextStep != _guideStep) {
        setState(() => _guideStep = nextStep);
      }
    });
  }

  int _nextGuideStep(_ScanGateStatus status) {
    if (!status.faceDetected || !status.faceDistanceOk) {
      return 0;
    }
    if (!status.enoughLight) {
      return 1;
    }
    return 2;
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.cast<CameraDescription?>().firstWhere(
        (camera) => camera?.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.isEmpty ? null : cameras.first,
      );

      if (frontCamera == null) {
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      _controller = controller;
      await controller.initialize();
      await _prepareFaceScanCamera(controller);
      await _startQualityStream(controller);

      if (mounted) {
        setState(() => _cameraError = null);
      }
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _cameraError = error.description ?? error.code);
      }
    }
  }

  Future<void> _prepareFaceScanCamera(CameraController controller) async {
    try {
      await controller.setFlashMode(FlashMode.off);
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setFocusPoint(const Offset(0.5, 0.44));
      await controller.setExposurePoint(const Offset(0.5, 0.44));
    } on CameraException {
      // Some front cameras do not support manual focus/exposure points.
    }
  }

  Future<void> _captureFrame() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        !_gateStatus.canCapture) {
      return;
    }

    await _stopQualityStream();
    final frame = await controller.takePicture();
    widget.onCapture(File(frame.path));
  }

  Future<void> _startQualityStream(CameraController controller) async {
    if (_isStreaming || widget.image != null) {
      return;
    }
    try {
      await controller.startImageStream(_processCameraImage);
      _isStreaming = true;
    } on CameraException {
      if (mounted) {
        setState(() {
          _gateStatus = _gateStatus.copyWith(
            message: 'Camera guide is warming up. Keep your face centered.',
          );
        });
      }
    }
  }

  Future<void> _stopQualityStream() async {
    final controller = _controller;
    if (!_isStreaming ||
        controller == null ||
        !controller.value.isInitialized) {
      _isStreaming = false;
      return;
    }
    try {
      await controller.stopImageStream();
    } on CameraException {
      // The camera plugin can report this when the stream is already stopped.
    } finally {
      _isStreaming = false;
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final controller = _controller;
    if (_isProcessingFrame ||
        widget.image != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    _isProcessingFrame = true;
    try {
      final brightness = _estimateBrightness(image);
      final inputImage = _inputImageFromCameraImage(
        image,
        controller.description,
      );
      if (inputImage == null) {
        _updateGateStatus(
          _gateStatus.copyWith(
            enoughLight: brightness >= 0.26 && brightness <= 0.96,
            message: 'Camera format is not ready yet.',
          ),
        );
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        _holdStartedAt = null;
        _updateGateStatus(
          _gateStatus.copyWith(
            faceDetected: false,
            faceCentered: false,
            enoughLight: brightness >= 0.26 && brightness <= 0.96,
            holdStillDone: false,
            message: brightness < 0.26
                ? 'အလင်းနည်းနေပါတယ်။ မျက်နှာကို ပိုလင်းတဲ့နေရာထားပါ။'
                : 'မျက်နှာတစ်ခုလုံး frame ထဲပါအောင်ထားပါ။',
          ),
        );
        return;
      }

      final face = faces.reduce((best, item) {
        final bestArea = best.boundingBox.width * best.boundingBox.height;
        final itemArea = item.boundingBox.width * item.boundingBox.height;
        return itemArea > bestArea ? item : best;
      });
      final faceCenter = face.boundingBox.center;
      final imageCenter = Offset(image.width / 2, image.height / 2);
      final centerDistance =
          (faceCenter - imageCenter).distance /
          math.min(image.width, image.height);
      final faceArea =
          (face.boundingBox.width * face.boundingBox.height) /
          (image.width * image.height);
      final faceCentered = centerDistance < 0.48 && faceArea > 0.035;
      final faceDistanceOk = faceArea >= 0.035 && faceArea <= 0.55;
      final enoughLight = brightness >= 0.26 && brightness <= 0.96;
      final yaw = face.headEulerAngleY ?? 0;
      final angleOk = yaw.abs() < 25;
      final straightNow =
          faceDistanceOk &&
          enoughLight &&
          yaw.abs() < 25 &&
          centerDistance < 0.58;

      if (straightNow) {
        _holdStartedAt ??= DateTime.now();
      } else {
        _holdStartedAt = null;
      }
      final holdDone =
          _holdStartedAt != null &&
          DateTime.now().difference(_holdStartedAt!) >=
              const Duration(milliseconds: 950);

      final next = _gateStatus.copyWith(
        faceDetected: true,
        faceCentered: faceCentered,
        faceDistanceOk: faceDistanceOk,
        enoughLight: enoughLight,
        angleOk: angleOk,
        lookStraightDone: _gateStatus.lookStraightDone || straightNow,
        turnLeftDone: true,
        turnRightDone: true,
        holdStillDone: _gateStatus.holdStillDone || holdDone,
        message: _gateMessage(
          enoughLight: enoughLight,
          faceCentered: faceCentered,
          faceArea: faceArea,
          faceDistanceOk: faceDistanceOk,
          yaw: yaw,
          status: _gateStatus,
          holdDone: holdDone,
        ),
      );
      _updateGateStatus(next);
    } catch (_) {
      _updateGateStatus(
        _gateStatus.copyWith(
          message: 'Quality guide is checking the camera frame.',
        ),
      );
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _updateGateStatus(_ScanGateStatus status) {
    if (!mounted) {
      return;
    }
    final nextStep = _nextGuideStep(status);
    setState(() {
      _gateStatus = status;
      _guideStep = nextStep;
    });
  }

  String _gateMessage({
    required bool enoughLight,
    required bool faceCentered,
    required double faceArea,
    required bool faceDistanceOk,
    required double yaw,
    required _ScanGateStatus status,
    required bool holdDone,
  }) {
    if (!enoughLight) {
      return 'အလင်းမညီသေးပါ။ ပြတင်းပေါက်/မီးအနီးမှာ ပြန်ထားပါ။';
    }
    if (!faceDistanceOk) {
      return faceArea > 0.55
          ? 'ဖုန်းကို နည်းနည်းဝေးဝေးကိုင်ပါ။ မျက်နှာတစ်ခုလုံးပါရင် ပိုကောင်းပါတယ်။'
          : 'ဖုန်းကို နည်းနည်းနီးနီးကိုင်ပြီး မျက်နှာကို frame ထဲထားပါ။';
    }
    if (!faceCentered || yaw.abs() >= 25) {
      return 'ရပြီ။ ပိုကောင်းချင်ရင် မျက်နှာကို နည်းနည်းတည့်တည့်ထားပါ။';
    }
    if (!holdDone && !status.holdStillDone) {
      return 'ကောင်းပါတယ်။ ဖုန်းကို ခဏငြိမ်ထားပြီး capture လုပ်ပါ။';
    }
    return 'Ready ပါပြီ။ နဖူးကို ဆံပင်မဖုံးအောင်ထားပြီး capture လုပ်ပါ။';
  }

  double _estimateBrightness(CameraImage image) {
    if (image.planes.isEmpty || image.planes.first.bytes.isEmpty) {
      return 0.5;
    }
    final bytes = image.planes.first.bytes;
    var total = 0;
    final step = math.max(1, bytes.length ~/ 1200);
    var count = 0;
    for (var index = 0; index < bytes.length; index += step) {
      total += bytes[index];
      count++;
    }
    return (total / math.max(1, count)) / 255;
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      return null;
    }

    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFrame = widget.image != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8EFE9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18123C36),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScanLensHeader(hasFrame: hasFrame),
          const SizedBox(height: 10),
          if (!hasFrame) ...[
            _ScanReadinessMeter(status: _gateStatus),
            const SizedBox(height: 10),
            _ScanPrimaryActions(
              hasFrame: hasFrame,
              isLoading: widget.isLoading,
              gateStatus: _gateStatus,
              onCapture: _captureFrame,
              onResetScanFrame: widget.onResetScanFrame,
              onAnalyze: widget.onAnalyze,
            ),
            const SizedBox(height: 12),
          ],
          AspectRatio(
            aspectRatio: 0.82,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _LensPreview(
                    image: widget.image,
                    initializeCamera: _initializeCamera,
                    controller: _controller,
                    error: _cameraError,
                  ),
                  if (!hasFrame)
                    _FaceGuideOverlay(
                      status: _gateStatus,
                      activeStep: _guideStep,
                    )
                  else
                    const _CapturedFrameOverlay(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (hasFrame) ...[
            _ScanPrimaryActions(
              hasFrame: hasFrame,
              isLoading: widget.isLoading,
              gateStatus: _gateStatus,
              onCapture: _captureFrame,
              onResetScanFrame: widget.onResetScanFrame,
              onAnalyze: widget.onAnalyze,
            ),
            const SizedBox(height: 12),
          ],
          if (hasFrame) ...[
            const _FrameReviewPanel(),
            const SizedBox(height: 12),
            const _CapturedReviewChecklist(),
            const SizedBox(height: 14),
          ],
          if (widget.isLoading) ...[
            const _AiAnalysisSequence(),
            const SizedBox(height: 14),
          ],
          _ScanQualityChecklist(hasFrame: hasFrame, status: _gateStatus),
          const SizedBox(height: 12),
          _TrainingConsentRow(
            enabled: widget.canShareForTraining && !widget.isLoading,
            value: widget.allowModelTraining,
            onChanged: widget.onAllowModelTrainingChanged,
          ),
          if (widget.error != null || _cameraError != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.error ?? _cameraError!,
              style: const TextStyle(
                color: Color(0xFF9E2732),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiAnalysisSequence extends StatefulWidget {
  const _AiAnalysisSequence();

  @override
  State<_AiAnalysisSequence> createState() => _AiAnalysisSequenceState();
}

class _AiAnalysisSequenceState extends State<_AiAnalysisSequence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _steps = [
    _AiAnalysisStep(
      icon: Icons.light_mode_outlined,
      title: 'Checking lighting',
      subtitle: 'အလင်းရောင်ညီ/မညီ စစ်နေပါတယ်',
    ),
    _AiAnalysisStep(
      icon: Icons.grid_view_rounded,
      title: 'Reading skin zones',
      subtitle: 'မျက်နှာ zone များကို ဖတ်နေပါတယ်',
    ),
    _AiAnalysisStep(
      icon: Icons.compare_arrows_rounded,
      title: 'Comparing visible concerns',
      subtitle: 'မြင်ရတဲ့ concern တွေကို နှိုင်းယှဉ်နေပါတယ်',
    ),
    _AiAnalysisStep(
      icon: Icons.spa_outlined,
      title: 'Preparing routine suggestion',
      subtitle: 'သင့်တော်တဲ့ routine ကို ပြင်ဆင်နေပါတယ်',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final activeIndex = (_controller.value * _steps.length).floor().clamp(
          0,
          _steps.length - 1,
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD0B3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFFF47C22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Skino AI is reading your scan',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF282420),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final entry in _steps.asMap().entries) ...[
                _AiAnalysisStepRow(
                  step: entry.value,
                  isActive: entry.key == activeIndex,
                  isDone: entry.key < activeIndex,
                ),
                if (entry.key != _steps.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AiAnalysisStep {
  const _AiAnalysisStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _AiAnalysisStepRow extends StatelessWidget {
  const _AiAnalysisStepRow({
    required this.step,
    required this.isActive,
    required this.isDone,
  });

  final _AiAnalysisStep step;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final accent = isDone
        ? const Color(0xFF0E5C56)
        : isActive
        ? const Color(0xFFF98128)
        : const Color(0xFFB8B0A7);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDone ? Icons.check_rounded : step.icon,
            color: accent,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  color: isActive || isDone
                      ? const Color(0xFF282420)
                      : const Color(0xFF8A837B),
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                step.subtitle,
                style: const TextStyle(
                  color: Color(0xFF68625B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanGateStatus {
  const _ScanGateStatus({
    this.faceDetected = false,
    this.faceCentered = false,
    this.faceDistanceOk = false,
    this.enoughLight = false,
    this.angleOk = false,
    this.lookStraightDone = false,
    this.turnLeftDone = false,
    this.turnRightDone = false,
    this.holdStillDone = false,
    this.message = 'မျက်နှာကို frame ထဲထားပြီး အလင်းညီအောင်ပြင်ပါ။',
  });

  final bool faceDetected;
  final bool faceCentered;
  final bool faceDistanceOk;
  final bool enoughLight;
  final bool angleOk;
  final bool lookStraightDone;
  final bool turnLeftDone;
  final bool turnRightDone;
  final bool holdStillDone;
  final String message;

  bool get canCapture =>
      faceDetected && faceDistanceOk && enoughLight && angleOk;

  int get completedCount {
    return [
      faceDetected,
      enoughLight,
      faceDistanceOk,
      angleOk,
    ].where((done) => done).length;
  }

  _ScanGateStatus copyWith({
    bool? faceDetected,
    bool? faceCentered,
    bool? faceDistanceOk,
    bool? enoughLight,
    bool? angleOk,
    bool? lookStraightDone,
    bool? turnLeftDone,
    bool? turnRightDone,
    bool? holdStillDone,
    String? message,
  }) {
    return _ScanGateStatus(
      faceDetected: faceDetected ?? this.faceDetected,
      faceCentered: faceCentered ?? this.faceCentered,
      faceDistanceOk: faceDistanceOk ?? this.faceDistanceOk,
      enoughLight: enoughLight ?? this.enoughLight,
      angleOk: angleOk ?? this.angleOk,
      lookStraightDone: lookStraightDone ?? this.lookStraightDone,
      turnLeftDone: turnLeftDone ?? this.turnLeftDone,
      turnRightDone: turnRightDone ?? this.turnRightDone,
      holdStillDone: holdStillDone ?? this.holdStillDone,
      message: message ?? this.message,
    );
  }
}

class _CapturedFrameOverlay extends StatelessWidget {
  const _CapturedFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.34),
                ],
                stops: const [0, 0.52, 1],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: _PreviewOverlayChip(
              icon: Icons.check_circle_rounded,
              label: 'Frame saved',
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: _PreviewOverlayChip(
              icon: Icons.auto_awesome_rounded,
              label: 'AI ready',
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Preview saved: check your face before AI analysis',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewOverlayChip extends StatelessWidget {
  const _PreviewOverlayChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFF47C22), size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF282420),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameReviewPanel extends StatelessWidget {
  const _FrameReviewPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD0B3)),
      ),
      child: Row(
        children: [
          const SkinoImageIcon(
            asset: SkinoAssets.iconReport,
            size: 48,
            padding: 3,
            backgroundColor: Colors.white,
            borderRadius: 16,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review before AI reading',
                  style: TextStyle(
                    color: Color(0xFF282420),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'မျက်နှာ၊ အလင်း၊ focus သေချာရင် result ပိုတိကျနိုင်ပါတယ်။',
                  style: TextStyle(
                    color: Color(0xFF625B53),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFF47C22)),
        ],
      ),
    );
  }
}

class _ScanPrimaryActions extends StatelessWidget {
  const _ScanPrimaryActions({
    required this.hasFrame,
    required this.isLoading,
    required this.gateStatus,
    required this.onCapture,
    required this.onResetScanFrame,
    required this.onAnalyze,
  });

  final bool hasFrame;
  final bool isLoading;
  final _ScanGateStatus gateStatus;
  final VoidCallback onCapture;
  final VoidCallback onResetScanFrame;
  final VoidCallback? onAnalyze;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = isLoading
        ? 'Reading scan...'
        : hasFrame
        ? 'Analyze result'
        : gateStatus.canCapture
        ? 'Capture scan'
        : 'Find face and light';
    final primaryAction = hasFrame ? onAnalyze : onCapture;

    if (!hasFrame) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: isLoading || !gateStatus.canCapture
                ? null
                : primaryAction,
            icon: gateStatus.canCapture
                ? const SkinoImageIcon(
                    asset: SkinoAssets.iconScan,
                    size: 22,
                    padding: 1,
                    backgroundColor: Colors.transparent,
                    borderRadius: 8,
                  )
                : const Icon(Icons.light_mode_outlined),
            label: Text(primaryLabel),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF98128),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFFE3D1),
              disabledForegroundColor: const Color(0xFFF98128),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            gateStatus.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF68625B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onResetScanFrame,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Scan Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF123C36),
              side: const BorderSide(color: Color(0xFFBFE6D7)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: isLoading ? null : onAnalyze,
            icon: const SkinoImageIcon.inline(asset: SkinoAssets.iconReport),
            label: Text(primaryLabel),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF98128),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanReadinessMeter extends StatelessWidget {
  const _ScanReadinessMeter({required this.status});

  final _ScanGateStatus status;

  @override
  Widget build(BuildContext context) {
    final progress = status.completedCount / 4;
    final label = status.canCapture
        ? 'Ready • forehead clear?'
        : 'Scan readiness ${status.completedCount}/4';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Row(
        children: [
          const SkinoImageIcon.inline(
            asset: SkinoAssets.iconScan,
            size: 24,
            backgroundColor: Color(0xFFFFF3EC),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: const Color(0xFFE8E1D7),
                color: status.canCapture
                    ? const Color(0xFF0E5C56)
                    : const Color(0xFFF98128),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF625B53),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapturedReviewChecklist extends StatelessWidget {
  const _CapturedReviewChecklist();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFE6D7)),
      ),
      child: const Column(
        children: [
          _ReviewCheckRow(
            title: 'Face visible',
            subtitle: 'မျက်နှာအပြည့် ပါနေရပါမယ်',
          ),
          SizedBox(height: 8),
          _ReviewCheckRow(
            title: 'Even lighting',
            subtitle: 'အရိပ်/အလင်းပြန် မများပါစေနဲ့',
          ),
          SizedBox(height: 8),
          _ReviewCheckRow(
            title: 'Clear enough',
            subtitle: 'မလှုပ်ဘဲ focus ပြတ်သားရပါမယ်',
          ),
          SizedBox(height: 8),
          _ReviewCheckRow(
            title: 'Forehead visible',
            subtitle: 'ဆံပင်/ဦးထုပ်/အရိပ်က နဖူးကို မဖုံးပါစေနဲ့',
          ),
        ],
      ),
    );
  }
}

class _ReviewCheckRow extends StatelessWidget {
  const _ReviewCheckRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF0E5C56)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF123C36),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF625B53),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanLensHeader extends StatelessWidget {
  const _ScanLensHeader({required this.hasFrame});

  final bool hasFrame;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6F1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: hasFrame
              ? const SkinoImageIcon(
                  asset: SkinoAssets.iconReport,
                  size: 38,
                  padding: 2,
                  backgroundColor: Colors.transparent,
                  borderRadius: 14,
                )
              : const Icon(
                  Icons.face_retouching_natural_rounded,
                  color: Color(0xFFF98128),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasFrame ? 'Scan preview' : 'Guided skin scan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF282420),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasFrame
                    ? 'Frame ကိုစစ်ပြီး result ကြည့်ပါ။'
                    : 'နဖူးကို ဆံပင်မဖုံးအောင်ထားပြီး capture လုပ်ပါ။',
                style: const TextStyle(
                  color: Color(0xFF68625B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _StatusPill(label: hasFrame ? 'Ready' : 'Quick guide'),
      ],
    );
  }
}

class _ScanQualityChecklist extends StatelessWidget {
  const _ScanQualityChecklist({required this.hasFrame, required this.status});

  final bool hasFrame;
  final _ScanGateStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFE6D7)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _QualityChip(
            icon: Icons.wb_sunny_outlined,
            label: hasFrame
                ? 'Light checked'
                : status.enoughLight
                ? 'Light OK'
                : 'Need light',
            done: hasFrame || status.enoughLight,
          ),
          _QualityChip(
            icon: Icons.face_6_outlined,
            label: hasFrame
                ? 'Face locked'
                : status.faceDetected
                ? 'Face found'
                : 'Find face',
            done: hasFrame || status.faceDetected,
          ),
          _QualityChip(
            icon: Icons.open_in_full_rounded,
            label: hasFrame
                ? 'Distance checked'
                : status.faceDistanceOk
                ? 'Distance OK'
                : 'Move phone',
            done: hasFrame || status.faceDistanceOk,
          ),
          _QualityChip(
            icon: Icons.screen_rotation_alt_outlined,
            label: hasFrame
                ? 'Angle checked'
                : status.angleOk
                ? 'Angle OK'
                : 'Face front',
            done: hasFrame || status.angleOk,
          ),
          _QualityChip(
            icon: Icons.content_cut_rounded,
            label: 'Hair off forehead',
            done: hasFrame || status.canCapture,
          ),
          _QualityChip(
            icon: Icons.verified_rounded,
            label: status.canCapture
                ? 'Ready'
                : '${status.completedCount}/4 OK',
            done: hasFrame || status.canCapture,
          ),
        ],
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({
    required this.icon,
    required this.label,
    this.done = false,
  });

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: done ? const Color(0xFFBFE6D7) : const Color(0xFFE8E1D7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : icon,
            color: done ? const Color(0xFF0E5C56) : const Color(0xFFB56A25),
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF123C36),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingConsentRow extends StatelessWidget {
  const _TrainingConsentRow({
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final bool enabled;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD0B3)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: enabled && value,
            onChanged: enabled
                ? (checked) => onChanged(checked ?? false)
                : null,
            activeColor: const Color(0xFFF98128),
            checkColor: Colors.white,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              enabled
                  ? 'Help improve Skino AI with this scan. Private by default.'
                  : 'Login to choose whether scans can help improve Skino AI.',
              style: const TextStyle(
                color: Color(0xFF625B53),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LensPreview extends StatelessWidget {
  const _LensPreview({
    required this.image,
    required this.initializeCamera,
    required this.controller,
    required this.error,
  });

  final File? image;
  final Future<void>? initializeCamera;
  final CameraController? controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Image.file(
        image!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      );
    }

    return FutureBuilder<void>(
      future: initializeCamera,
      builder: (context, snapshot) {
        final camera = controller;

        if (error != null) {
          return const _EmptyLens();
        }

        if (snapshot.connectionState == ConnectionState.done &&
            camera != null &&
            camera.value.isInitialized) {
          return _AlignedCameraPreview(camera: camera);
        }

        return const _EmptyLens(isLoading: true);
      },
    );
  }
}

class _AlignedCameraPreview extends StatelessWidget {
  const _AlignedCameraPreview({required this.camera});

  final CameraController camera;

  @override
  Widget build(BuildContext context) {
    final previewSize = camera.value.previewSize;

    if (previewSize == null) {
      return const _EmptyLens(isLoading: true);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewWidth = previewSize.height;
        final previewHeight = previewSize.width;
        final previewScale = math.max(
          constraints.maxWidth / previewWidth,
          constraints.maxHeight / previewHeight,
        );

        return ClipRect(
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: SizedBox(
                width: previewWidth * previewScale,
                height: previewHeight * previewScale,
                child: CameraPreview(camera),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FaceGuideOverlay extends StatelessWidget {
  const _FaceGuideOverlay({required this.status, required this.activeStep});

  final _ScanGateStatus status;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final accent = status.canCapture
        ? const Color(0xFF7EF1CF)
        : status.faceCentered && status.enoughLight
        ? const Color(0xFFF98128)
        : const Color(0xFFEAF6F1);

    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.92,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.16),
                ],
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final frameWidth = math.min(constraints.maxWidth * 0.7, 286.0);
              final frameHeight = math.min(
                constraints.maxHeight * 0.72,
                frameWidth * 1.26,
              );

              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: frameWidth,
                    height: frameHeight,
                    child: CustomPaint(
                      painter: _ModernFaceFramePainter(
                        color: accent,
                        ready: status.canCapture,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: frameWidth,
                    height: frameHeight,
                    child: _FrameLandmarkHints(
                      activeStep: activeStep,
                      color: accent,
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.46),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status.canCapture
                    ? 'Ready: keep hair off forehead, then capture'
                    : status.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameLandmarkHints extends StatelessWidget {
  const _FrameLandmarkHints({required this.activeStep, required this.color});

  final int activeStep;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const shift = 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: 64,
          height: 2,
          transform: Matrix4.translationValues(shift, 0, 0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Positioned(
          top: 26,
          child: _FrameHintPill(
            label: switch (activeStep) {
              1 => 'Light',
              2 => 'Ready',
              _ => 'Face',
            },
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FrameHintPill extends StatelessWidget {
  const _FrameHintPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ModernFaceFramePainter extends CustomPainter {
  const _ModernFaceFramePainter({required this.color, required this.ready});

  final Color color;
  final bool ready;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(18, 16, size.width - 36, size.height - 32);
    final radius = const Radius.circular(76);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: ready ? 0.22 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(rrect, shadowPaint);

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final path = Path();
    const corner = 46.0;
    path
      ..moveTo(rect.left, rect.top + corner)
      ..lineTo(rect.left, rect.top + 24)
      ..quadraticBezierTo(rect.left, rect.top, rect.left + 24, rect.top)
      ..lineTo(rect.left + corner, rect.top)
      ..moveTo(rect.right - corner, rect.top)
      ..lineTo(rect.right - 24, rect.top)
      ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + 24)
      ..lineTo(rect.right, rect.top + corner)
      ..moveTo(rect.right, rect.bottom - corner)
      ..lineTo(rect.right, rect.bottom - 24)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.right - 24, rect.bottom)
      ..lineTo(rect.right - corner, rect.bottom)
      ..moveTo(rect.left + corner, rect.bottom)
      ..lineTo(rect.left + 24, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - 24)
      ..lineTo(rect.left, rect.bottom - corner);
    canvas.drawPath(path, borderPaint);

    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.46)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(rect.left + 20, rect.center.dy),
      Offset(rect.right - 20, rect.center.dy),
      guidePaint,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top + 28),
      Offset(rect.center.dx, rect.bottom - 28),
      guidePaint..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _ModernFaceFramePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.ready != ready;
  }
}

class _EmptyLens extends StatelessWidget {
  const _EmptyLens({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E5C56),
      child: Center(
        child: Icon(
          isLoading ? Icons.camera_alt_rounded : Icons.no_photography_outlined,
          color: Colors.white.withValues(alpha: 0.82),
          size: 48,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF123C36),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
