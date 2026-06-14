// lib/screens/session_player_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import '../services/data_store.dart';
import '../services/workout_notification_service.dart';
import '../theme/app_theme.dart';

enum _Phase { prepare, active, rest, roundRest, done }

class SessionPlayerScreen extends StatefulWidget {
  final Session session;
  final DataStore store;

  const SessionPlayerScreen(
      {super.key, required this.session, required this.store});

  @override
  State<SessionPlayerScreen> createState() => _SessionPlayerScreenState();
}

class _SessionPlayerScreenState extends State<SessionPlayerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _prepareSeconds = 5;

  late int _currentExerciseIndex;
  late int _currentRound;
  late _Phase _phase;
  late int _remaining; // seconds or reps
  late int _totalSeconds;  // total for current phase, drives circle
  bool _paused = false;
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;
  late _BipPlayer _bip;

  Timer? _timer;
  late AnimationController _circleController;

  Session get session => widget.session;
  DataStore get store => widget.store;

  SessionExercise get _currentSE =>
      session.exercises[_currentExerciseIndex];

  Exercise? get _currentExercise =>
      store.getExercise(_currentSE.exerciseId);

  Exercise? get _nextExercise {
    final nextIdx = _currentExerciseIndex + 1;
    if (nextIdx < session.exercises.length) {
      return store.getExercise(session.exercises[nextIdx].exerciseId);
    }
    return null;
  }

  bool get _isLastExercise =>
      _currentExerciseIndex == session.exercises.length - 1;
  bool get _isLastRound => _currentRound == session.rounds;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(vsync: this);
    _bip = _BipPlayer();
    _startElapsedTimer();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    // Listen to notification button taps (pause / resume / stop)
    FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        final payload = details.actionId;
        if (payload == WorkoutNotificationService.actionPause ||
            payload == WorkoutNotificationService.actionResume) {
          if (mounted) _togglePause();
        } else if (payload == WorkoutNotificationService.actionStop) {
          if (mounted) Navigator.pop(context);
        }
      },
    );
    WorkoutNotificationService.init().then((_) => _updateNotification());
    _startPrepare();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedTimer?.cancel();
    _circleController.dispose();
    _bip.dispose();
    WidgetsBinding.instance.removeObserver(this);
    WorkoutNotificationService.dismiss();
    WakelockPlus.disable();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused) _elapsedSeconds++;
    });
  }

  void _updateNotification() {
    if (_phase == _Phase.done) return;
    final ex = _currentExercise;
    WorkoutNotificationService.show(
      sessionName: session.name,
      exerciseName: _phase == _Phase.prepare
          ? 'Préparation...'
          : _phase == _Phase.rest || _phase == _Phase.roundRest
              ? 'Repos'
              : ex?.name ?? '',
      round: _currentRound,
      totalRounds: session.rounds,
      exerciseIndex: _currentExerciseIndex,
      totalExercises: session.exercises.length,
      paused: _paused,
    );
  }

  Future<void> _saveCompletion() async {
    final completion = SessionCompletion(
      id: store.newId(),
      sessionId: session.id,
      sessionName: session.name,
      completedAt: DateTime.now(),
      durationSeconds: _elapsedSeconds,
      roundsDone: session.rounds,
      exerciseCount: session.exercises.length,
    );
    await store.recordCompletion(completion);
  }

  void _startPrepare() {
    _currentExerciseIndex = 0;
    _currentRound = 1;
    _phase = _Phase.prepare;
    _remaining = _prepareSeconds;
    _totalSeconds = _prepareSeconds;
    _startCircle(_prepareSeconds);
    _startTimer();
  }

  void _startCircle(int totalSeconds, {bool infinite = false}) {
    _totalSeconds = totalSeconds;
    // AnimationController is kept only for pause/resume continuity; 
    // the circle progress is now driven by _remaining/_totalSeconds.
    _circleController.stop();
    _circleController.reset();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      setState(() {
        if (_phase == _Phase.prepare || _phase == _Phase.rest || _phase == _Phase.roundRest) {
          _remaining--;
          if (_remaining <= 0) {
            _bip.playEnd();
            _advancePhase();
          } else if (_remaining <= 3) {
            _bip.playTick();
          }
        }
      });
      _updateNotification();
    });
  }

  void _advancePhase() {
    if (_phase == _Phase.prepare) {
      _beginActiveExercise();
    } else if (_phase == _Phase.active) {
      // shouldn't be called for reps; only duration
      _beginRest();
    } else if (_phase == _Phase.rest) {
      _nextExerciseOrRound();
    } else if (_phase == _Phase.roundRest) {
      _currentRound++;
      _currentExerciseIndex = 0;
      _beginActiveExercise();
    }
  }

  void _beginActiveExercise() {
    final se = _currentSE;
    final ex = _currentExercise;
    _phase = _Phase.active;
    _remaining = se.customValue;
    _totalSeconds = se.customValue;
    if (ex?.type == ExerciseType.duration) {
      _startCircle(se.customValue);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_paused) return;
        setState(() {
          _remaining--;
          if (_remaining <= 0) {
            _bip.playEnd();
            _beginRest();
          } else if (_remaining <= 3) {
            _bip.playTick();
          }
        });
        _updateNotification();
      });
    } else {
      // Repetition: circle is static; user taps "Terminé"
      _circleController.stop();
      _circleController.reset();
      _timer?.cancel();
    }
  }

  void _beginRest() {
    if (_isLastExercise) {
      if (_isLastRound) {
        _phase = _Phase.done;
        _timer?.cancel();
        _elapsedTimer?.cancel();
        _circleController.stop();
        WorkoutNotificationService.dismiss();
        _saveCompletion();   // ← persist history + update calendar
        setState(() {});
        return;
      }
      // Between rounds
      _phase = _Phase.roundRest;
      _remaining = session.restBetweenRounds;
      _totalSeconds = session.restBetweenRounds;
      _startCircle(session.restBetweenRounds);
      _startTimer();
    } else {
      if (_currentSE.restAfter <= 0) {
        _nextExerciseOrRound();
        return;
      }
      _phase = _Phase.rest;
      _remaining = _currentSE.restAfter;
      _totalSeconds = _currentSE.restAfter;
      _startCircle(_currentSE.restAfter);
      _startTimer();
    }
    setState(() {});
  }

  void _nextExerciseOrRound() {
    _currentExerciseIndex++;
    _beginActiveExercise();
    setState(() {});
  }

  void _skipCurrent() {
    _timer?.cancel();
    if (_phase == _Phase.prepare) {
      _beginActiveExercise();
    } else if (_phase == _Phase.active) {
      _beginRest();
    } else if (_phase == _Phase.rest || _phase == _Phase.roundRest) {
      _advancePhase();
    }
    setState(() {});
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
    });
    _updateNotification();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    if (_phase == _Phase.done) return _buildDoneScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            Expanded(child: _buildPhaseContent()),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _confirmExit(),
            icon: const Icon(Icons.close, color: AppColors.textDark),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Exercice ${_currentExerciseIndex + 1}/${session.exercises.length}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Text(
            'Tour $_currentRound/${session.rounds}',
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          IconButton(
            onPressed: _skipCurrent,
            icon: const Icon(Icons.skip_next, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final total = session.exercises.length * session.rounds;
    final done = (_currentRound-1)*session.exercises.length + _currentExerciseIndex+1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: LinearProgressIndicator(
        value: total > 0 ? done / total : 0,
        backgroundColor: AppColors.border,
        color: AppColors.teal,
        minHeight: 5,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _Phase.prepare:
        return _buildPrepareView();
      case _Phase.active:
        final ex = _currentExercise;
        if (ex?.type == ExerciseType.repetitions) {
          return _buildRepsView(ex!);
        }
        return _buildTimerView(ex);
      case _Phase.rest:
        return _buildRestView(
          title: 'REPOS',
          subtitle: 'Prochain exercice',
          nextName: _nextExercise?.name ?? '',
          color: AppColors.orange,
        );
      case _Phase.roundRest:
        return _buildRestView(
          title: 'REPOS ENTRE TOURS',
          subtitle: 'Prochain tour',
          nextName: 'Tour ${_currentRound + 1}/${session.rounds}',
          color: AppColors.orange,
        );
      case _Phase.done:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPrepareView() {
    final ex = _currentExercise;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'PRÉPAREZ-VOUS',
          style: TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 14),
        ),
        const SizedBox(height: 24),
        _CircleTimer(
          progress: _totalSeconds > 0 ? _remaining / _totalSeconds : 0,
          label: 'DÉBUT DANS',
          value: _formatTime(_remaining),
          color: AppColors.teal,
          size:220
        ),
        const SizedBox(height: 24),
        Text(
          ex?.name ?? '',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildTimerView(Exercise? ex) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Fixed-height image zone — always the same height whether or not
          // there is an image, so the timer always sits at the same position.
          SizedBox(
            height: 220,
            width: double.infinity,
            child: ex?.imagePath != null && File(ex!.imagePath!).existsSync()
                ? ClipRRect(
                    child: Image.file(
                      File(ex.imagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 220,
                    ),
                  )
                : Container(
                    color: AppColors.tealLight,
                    child: const Icon(
                      Icons.fitness_center,
                      color: AppColors.teal,
                      size: 64,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            ex?.name ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 24),
          _CircleTimer(
            progress: _totalSeconds > 0 ? _remaining / _totalSeconds : 0,
            label: '',
            value: _formatTime(_remaining),
            color: AppColors.teal,
            size: 200,
          ),
          if (ex?.instructions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                ex!.instructions!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 13, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRepsView(Exercise ex) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: ex.imagePath != null && File(ex.imagePath!).existsSync()
                ? ClipRRect(
                    child: Image.file(
                      File(ex.imagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 220,
                    ),
                  )
                : Container(
                    color: AppColors.tealLight,
                    child: const Icon(
                      Icons.fitness_center,
                      color: AppColors.teal,
                      size: 64,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            ex.name,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 24),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'RÉPÉTITIONS',
                  style: TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentSE.customValue}',
                  style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _beginRest());
              },
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Terminé'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
          if (ex.instructions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                ex.instructions!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 13, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestView({
    required String title,
    required String subtitle,
    required String nextName,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleTimer(
          progress: _totalSeconds > 0 ? _remaining / _totalSeconds : 0,
          label: title,
          value: _formatTime(_remaining),
          color: color,
          size: 200,
        ),
        const SizedBox(height: 24),
        Text(subtitle,
            style:
                const TextStyle(color: AppColors.textGrey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          nextName,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    if (_phase == _Phase.active &&
        _currentExercise?.type == ExerciseType.repetitions) {
      return const SizedBox(height: 16);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: OutlinedButton.icon(
        onPressed: _togglePause,
        icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 20),
        label: Text(_paused ? 'Reprendre' : 'Pause'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.textDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildDoneScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppColors.tealLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppColors.teal, size: 60),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Séance terminée !',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bravo ! Vous avez complété ${session.rounds} tour${session.rounds > 1 ? 's' : ''} de ${session.exercises.length} exercice${session.exercises.length > 1 ? 's' : ''}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text('Retour à l\'accueil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitter la séance ?'),
        content: const Text('Votre progression sera perdue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuer')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context);
  }
}

class _CircleTimer extends StatelessWidget {
  final double progress; // 0.0 (empty) → 1.0 (full)
  final String label;
  final String value;
  final Color color;
  final double size;

  const _CircleTimer({
    required this.progress,
    required this.label,
    required this.value,
    required this.color,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: color.withOpacity(0.15),
              color: color,
            ),
          ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  if (label.isNotEmpty) const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: size * 0.22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                ],
              ),
            ],
          ),
        );
  }
}

// ── Bip player ────────────────────────────────────────────────────────────────

class _BipPlayer {
  final AudioPlayer _player = AudioPlayer();

  _BipPlayer() {
    AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  Future<void> playTick() => _play(frequency: 880, durationMs: 80);
  Future<void> playEnd()  => _play(frequency: 660, durationMs: 400);

  Future<void> _play({required double frequency, required int durationMs}) async {
    try {
      await _player.play(BytesSource(_buildWav(frequency: frequency, durationMs: durationMs)), volume: 1.0);
    } catch (_) {}
  }

  Uint8List _buildWav({required double frequency, required int durationMs}) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * 2;
    final buf = ByteData(44 + dataSize);
    buf.buffer.asUint8List(0, 4).setAll(0, 'RIFF'.codeUnits);
    buf.setUint32(4, 36 + dataSize, Endian.little);
    buf.buffer.asUint8List(8, 4).setAll(0, 'WAVE'.codeUnits);
    buf.buffer.asUint8List(12, 4).setAll(0, 'fmt '.codeUnits);
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little);
    buf.setUint16(22, 1, Endian.little);
    buf.setUint32(24, sampleRate, Endian.little);
    buf.setUint32(28, sampleRate * 2, Endian.little);
    buf.setUint16(32, 2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    buf.buffer.asUint8List(36, 4).setAll(0, 'data'.codeUnits);
    buf.setUint32(40, dataSize, Endian.little);
    for (int i = 0; i < numSamples; i++) {
      final fade = i >= (numSamples * 0.8).round()
          ? 1.0 - (i - numSamples * 0.8) / (numSamples * 0.2)
          : 1.0;
      final s = (28000.0 * fade * math.sin(2 * math.pi * frequency * i / sampleRate))
          .round().clamp(-32768, 32767);
      buf.setInt16(44 + i * 2, s, Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  void dispose() => _player.dispose();
}