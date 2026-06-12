import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/nestly_theme.dart';
import '../services/db_service.dart';

class SimplifyScreen extends StatefulWidget {
  final NestlyUser user;
  final OnboardingProfile profile;
  final VoidCallback onExit;

  const SimplifyScreen({
    super.key,
    required this.user,
    required this.profile,
    required this.onExit,
  });

  @override
  State<SimplifyScreen> createState() => _SimplifyScreenState();
}

class _SimplifyScreenState extends State<SimplifyScreen> {
  final DbService _db = DbService();
  String? _activeMode; // null, 'overwhelm', 'low-energy', 'breathe'

  // Clock state
  late Timer _clockTimer;
  String _timeString = '';

  // Session timer
  late DateTime _sessionStart;
  int _sessionSeconds = 0;
  late Timer _sessionTimer;

  // Quotes
  int _quoteIndex = 0;

  // Tasks state
  List<HouseholdTask> _tasks = [];
  List<String> _initialTopIds = [];
  String? _lastCheckedId;

  // Rest timer
  bool _restActive = false;
  int _restRemaining = 20 * 60;
  Timer? _restTimer;

  // Breathing state
  String _breathPhase = 'inhale';
  int _breathCountdown = 4;
  int _breathCount = 0;
  String _breathPattern = 'box';
  Timer? _breathTimer;

  // Message selectors
  late String _overwhelmMsg;
  late String _lowEnergyMsg;
  late String _breathingMsg;

  final List<String> _overwhelmMessages = [
    "You don't have to do everything. Just the next one thing.",
    "Progress, not perfection. One task at a time.",
    "The list feels long, but your capacity is real. Start small.",
    "You've handled harder days than this. Breathe first, then begin.",
    "Permission granted: ignore everything below these three.",
  ];

  final List<String> _lowEnergyMessages = [
    "Low energy is real. These two things are enough for today.",
    "Conserve. Delegate. Rest. You're doing the right thing.",
    "A small win still counts. Pick one and let the day be enough.",
    "Your body is asking for gentleness. Honor that today.",
    "Slow is still moving forward. You've got this.",
  ];

  final List<String> _breathingMessages = [
    "Your nervous system is resetting. This is the work.",
    "Three slow breaths change your brain chemistry. Stay here.",
    "Stillness is productive. The pause is part of the plan.",
    "You can't pour from an empty cup. Fill it here.",
    "Let your shoulders drop. Let your jaw unclench. Breathe.",
  ];

  final List<String> _generalQuotes = [
    "Do one thing at a time. The rest can wait.",
    "Breathe in calm, breathe out chaos.",
    "Your presence matters more than your productivity.",
    "In this moment, there is enough time.",
    "The house is safe. Everything else can wait.",
    "You have done enough today.",
    "Simplicity is the ultimate sophistication.",
    "Not everything that can be done needs to happen today.",
    "Rest is not a reward — it's a requirement.",
    "The most important thing is to be where you are.",
    "You are doing better than you think.",
    "A calm home starts with a calm parent.",
    "A quiet home is a happy home.",
  ];

  final List<String> _simpleDinners = [
    'Scrambled eggs & toast',
    'Pasta with jar sauce',
    'Bean tacos with shredded cheese',
    'Grilled cheese & tomato soup',
    'Frozen pizza night 🍕',
    'Takeout — you earned it',
    'Pancakes for dinner',
  ];

  final Map<String, String> _phaseTips = {
    'inhale': 'Let your belly expand fully as you breathe in',
    'hold-in': 'Hold gently — keep your shoulders relaxed',
    'exhale': 'Let go slowly, releasing all tension with the breath',
    'hold-out': 'Rest in the stillness. Nothing to do here.',
  };

  final Map<String, String> _phaseLabels = {
    'inhale': 'Inhale',
    'hold-in': 'Hold',
    'exhale': 'Exhale',
    'hold-out': 'Rest',
  };

  final Map<String, Color> _phaseColors = {
    'inhale': NestlyColors.sage,
    'hold-in': NestlyColors.sageDark,
    'exhale': NestlyColors.accent,
    'hold-out': NestlyColors.primary,
  };

  final Map<String, Map<String, dynamic>> _breathPatterns = {
    'box': {
      'label': 'Box',
      'phases': ['inhale', 'hold-in', 'exhale', 'hold-out'],
      'durations': {'inhale': 4, 'hold-in': 4, 'exhale': 4, 'hold-out': 4},
      'desc': '4-4-4-4',
    },
    '478': {
      'label': '4-7-8',
      'phases': ['inhale', 'hold-in', 'exhale'],
      'durations': {'inhale': 4, 'hold-in': 7, 'exhale': 8},
      'desc': '4-7-8',
    },
    'deep': {
      'label': 'Deep',
      'phases': ['inhale', 'exhale'],
      'durations': {'inhale': 5, 'exhale': 7},
      'desc': '5-7',
    },
  };

  final Map<String, List<Color>> _modeGradients = {
    'overwhelm': [Color(0xFFFDF0E5), Color(0xFFF5E8DA), Color(0xFFECE0D2)],
    'low-energy': [Color(0xFFEEF0F8), Color(0xFFE7EAF5), Color(0xFFE2E5EF)],
    'breathe': [Color(0xFFE7EFE6), Color(0xFFDFE9DE), Color(0xFFD8E2D7)],
  };

  final List<Color> _defaultGradient = [Color(0xFFF2EDE7), Color(0xFFE8EBE5), Color(0xFFE4E8E5)];

  @override
  void initState() {
    super.initState();
    _db.tasksNotifier.addListener(_updateTasks);
    _updateTasks();

    _sessionStart = DateTime.now();
    _quoteIndex = Random().nextInt(_generalQuotes.length);

    _overwhelmMsg = _overwhelmMessages[Random().nextInt(_overwhelmMessages.length)];
    _lowEnergyMsg = _lowEnergyMessages[Random().nextInt(_lowEnergyMessages.length)];
    _breathingMsg = _breathingMessages[Random().nextInt(_breathingMessages.length)];

    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sessionSeconds = DateTime.now().difference(_sessionStart).inSeconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _sessionTimer.cancel();
    _restTimer?.cancel();
    _breathTimer?.cancel();
    _db.tasksNotifier.removeListener(_updateTasks);
    super.dispose();
  }

  void _updateTasks() {
    if (mounted) {
      setState(() {
        _tasks = _db.tasksNotifier.value;
      });
    }
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      setState(() {
        _timeString = '$hour:$minute';
      });
    }
  }

  int _scoreTask(HouseholdTask t) {
    int s = 0;
    if (t.priority == 'High') s += 10;
    if (t.priority == 'Medium') s += 5;
    final cat = t.category.toLowerCase();
    if (cat.contains('kids') || cat.contains('health')) s += 3;
    if (t.dueDate == DateTime.now().toIso8601String().split('T')[0]) s += 8;
    if (t.recurring.isNotEmpty && t.recurring != 'None') s += 2;
    return s;
  }

  String _getGreeting(String name, int h) {
    final first = name.split(' ')[0];
    final suffix = first.isNotEmpty ? ', $first' : '';
    if (h < 6) return 'Still awake$suffix?';
    if (h < 12) return 'Good morning$suffix.';
    if (h < 17) return 'Good afternoon$suffix.';
    if (h < 21) return 'Good evening$suffix.';
    return 'Quiet night$suffix.';
  }

  String _getContextLine(int h, OnboardingProfile profile) {
    if (h >= 21) return "The day is winding down. Let yourself release the rest of it.";
    if (h >= 17 && profile.stressPoints.dinner) return "Dinner hour is often the hardest. Keep it simple tonight.";
    if (h >= 17) return "The hard part of the day is nearly over. Breathe into the evening.";
    if (h < 9) return "Morning is the best time to reset your intentions for the day.";
    return "Take two minutes here. The household can hold on.";
  }

  void _setActiveMode(String? mode) {
    setState(() {
      _activeMode = mode;
    });

    _restTimer?.cancel();
    _restActive = false;
    _restRemaining = 20 * 60;

    _breathTimer?.cancel();

    if (mode == 'overwhelm') {
      final undone = _tasks.where((t) => !t.done).toList();
      undone.sort((a, b) => _scoreTask(b).compareTo(_scoreTask(a)));
      setState(() {
        _initialTopIds = undone.take(3).map((t) => t.id).toList();
      });
    } else if (mode == 'breathe') {
      _startBreathingEngine();
    } else {
      setState(() {
        _initialTopIds = [];
      });
    }
  }

  // --- REST TIMER ENGINE ---
  void _startRestTimer() {
    setState(() {
      _restActive = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_restRemaining <= 1) {
          timer.cancel();
          setState(() {
            _restActive = false;
            _restRemaining = 20 * 60;
          });
        } else {
          setState(() {
            _restRemaining--;
          });
        }
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restActive = false;
      _restRemaining = 20 * 60;
    });
  }

  // --- BREATHING ENGINE ---
  void _startBreathingEngine() {
    final pattern = _breathPatterns[_breathPattern]!;
    final List<String> phases = List<String>.from(pattern['phases']);
    final Map<String, int> durations = Map<String, int>.from(pattern['durations']);

    int phaseIdx = 0;
    int secInPhase = 0;

    setState(() {
      _breathPhase = phases[0];
      _breathCountdown = durations[phases[0]]!;
      _breathCount = 0;
    });

    _breathTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        secInPhase++;
        final cur = phases[phaseIdx];
        final remaining = durations[cur]! - secInPhase;

        setState(() {
          _breathCountdown = remaining > 0 ? remaining : 0;
        });

        if (secInPhase >= durations[cur]!) {
          phaseIdx = (phaseIdx + 1) % phases.length;
          secInPhase = 0;

          setState(() {
            _breathPhase = phases[phaseIdx];
            _breathCountdown = durations[phases[phaseIdx]]!;
          });

          if (phaseIdx == 0) {
            setState(() {
              _breathCount++;
            });
          }
        }
      }
    });
  }

  void _changeBreathPattern(String pKey) {
    setState(() {
      _breathPattern = pKey;
    });
    _breathTimer?.cancel();
    _startBreathingEngine();
  }

  void _handleToggleTask(HouseholdTask task) {
    final updated = task.copyWith(done: !task.done);
    _db.saveTask(updated);
    if (!task.done) {
      setState(() {
        _lastCheckedId = task.id;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _lastCheckedId = null;
          });
        }
      });
    }
  }

  // --- RENDERING FORMATTERS ---
  String _fmtSession(int s) {
    return s < 60 ? '${s}s' : '${s ~/ 60}m ${s % 60}s';
  }

  String _fmtRest(int s) {
    final min = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  // --- CORE BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final gradient = _modeGradients[_activeMode] ?? _defaultGradient;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: NestlyTheme.transitionSmooth,
                        child: _activeMode == null
                            ? KeyedSubtree(key: const ValueKey('landing'), child: _buildLandingView())
                            : _activeMode == 'overwhelm'
                                ? KeyedSubtree(key: const ValueKey('overwhelm'), child: _buildOverwhelmView())
                                : _activeMode == 'low-energy'
                                    ? KeyedSubtree(key: const ValueKey('low'), child: _buildLowEnergyView())
                                    : KeyedSubtree(key: const ValueKey('breathe'), child: _buildBreathingView()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildReturnButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _activeMode != null
            ? GestureDetector(
                onTap: () => _setActiveMode(null),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, size: 14, color: NestlyColors.textMuted),
                    SizedBox(width: 4),
                    Text('Back', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12.5, color: NestlyColors.textMuted, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : const Row(
                children: [
                  Icon(Icons.spa, size: 14, color: NestlyColors.sage),
                  SizedBox(width: 6),
                  Text(
                    'SIMPLIFY MODE',
                    style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10.5, fontWeight: FontWeight.w800, color: NestlyColors.textMuted, letterSpacing: 0.1),
                  ),
                ],
              ),
        Row(
          children: [
            if (_sessionSeconds >= 15)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.58),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Text(
                  _fmtSession(_sessionSeconds),
                  style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.bold, color: NestlyColors.textMuted),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onExit,
              child: const Text(
                'Exit ✕',
                style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, fontWeight: FontWeight.bold, color: NestlyColors.textSubtle),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildLandingView() {
    final hour = DateTime.now().hour;
    final undoneCount = _tasks.where((t) => !t.done).length;
    final easyCount = min(_tasks.where((t) => !t.done).length, 2);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clock
          Text(
            _timeString,
            style: const TextStyle(
              fontFamily: NestlyTheme.fontSans,
              fontSize: 54,
              fontWeight: FontWeight.w100,
              letterSpacing: -0.05,
              color: NestlyColors.primaryDark,
            ),
            textAlign: CenterPlay.center,
          ),
          const SizedBox(height: 6),

          // Greeting
          Text(
            _getGreeting(widget.user.name, hour),
            style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 15, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark),
            textAlign: CenterPlay.center,
          ),
          const SizedBox(height: 4),
          Text(
            _getContextLine(hour, widget.profile),
            style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, color: NestlyColors.textMuted, fontStyle: FontStyle.italic),
            textAlign: CenterPlay.center,
          ),
          const SizedBox(height: 18),

          // Quote Box
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.52),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '"${_generalQuotes[_quoteIndex]}"',
                    style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, color: NestlyColors.textMuted, fontStyle: FontStyle.italic, height: 1.55),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 13, color: NestlyColors.textSubtle),
                  onPressed: () {
                    setState(() {
                      _quoteIndex = (_quoteIndex + 1) % _generalQuotes.length;
                    });
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'HOW ARE YOU FEELING RIGHT NOW?',
            style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.w800, color: NestlyColors.textSubtle, letterSpacing: 0.09),
            textAlign: CenterPlay.center,
          ),
          const SizedBox(height: 12),

          // Modes Cards
          _buildModeButton(
            mode: 'overwhelm',
            icon: '🧠',
            title: 'Overwhelm Recovery',
            preview: '$undoneCount task${undoneCount != 1 ? 's' : ''} to sort through',
          ),
          const SizedBox(height: 10),
          _buildModeButton(
            mode: 'low-energy',
            icon: '🌙',
            title: 'Low Energy Mode',
            preview: '$easyCount gentle item${easyCount != 1 ? 's' : ''} + easy dinner',
          ),
          const SizedBox(height: 10),
          _buildModeButton(
            mode: 'breathe',
            icon: '🫁',
            title: 'Breathing Focus',
            preview: 'Resets your nervous system in ~2 min',
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String mode,
    required String icon,
    required String title,
    required String preview,
  }) {
    return GestureDetector(
      onTap: () => _setActiveMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.68),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: NestlyTheme.shadowXs,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13.5, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark)),
                  const SizedBox(height: 2),
                  Text(preview, style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, color: NestlyColors.textMuted, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: NestlyColors.textSubtle),
          ],
        ),
      ),
    );
  }

  Widget _buildOverwhelmView() {
    final displayTop = _initialTopIds
        .map((id) => _tasks.firstWhere((t) => t.id == id, orElse: () => HouseholdTask(id: '', title: '', category: '', priority: '', assignee: '', dueDate: '', recurring: '', notes: '', done: false)))
        .where((t) => t.id.isNotEmpty)
        .toList();

    final doneTopCount = displayTop.where((t) => t.done).length;
    final allTopDone = displayTop.isNotEmpty && displayTop.every((t) => t.done);
    final progress = displayTop.isNotEmpty ? (doneTopCount / displayTop.length) : 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🧠', style: const TextStyle(fontSize: 30), textAlign: CenterPlay.center),
          const SizedBox(height: 6),
          const Text('Overwhelm Recovery', style: TextStyle(fontFamily: NestlyTheme.fontSerif, fontSize: 17, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark), textAlign: CenterPlay.center),
          const SizedBox(height: 5),
          Text(_overwhelmMsg, style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, color: NestlyColors.textMuted, fontStyle: FontStyle.italic, height: 1.55), textAlign: CenterPlay.center),
          const SizedBox(height: 20),

          allTopDone
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.6)),
                  ),
                  child: Column(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 10),
                      const Text('All done. Well done.', style: TextStyle(fontFamily: NestlyTheme.fontSerif, fontSize: 18, fontWeight: FontWeight.bold, color: NestlyColors.sageDark)),
                      const SizedBox(height: 8),
                      const Text('You worked through what mattered most. The rest can wait — or not happen at all today.', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted, height: 1.65), textAlign: CenterPlay.center),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(14)),
                        child: const Text('"You\'ve done enough. You are enough."', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, fontStyle: FontStyle.italic, color: NestlyColors.sageDark), textAlign: CenterPlay.center),
                      )
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.84),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.65)),
                    boxShadow: NestlyTheme.shadowMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.star, color: NestlyColors.accent, size: 11),
                              SizedBox(width: 5),
                              Text('AI Focus', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.bold, color: NestlyColors.textMuted, letterSpacing: 0.08)),
                            ],
                          ),
                          Text('$doneTopCount/${displayTop.length} done', style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, fontWeight: FontWeight.bold, color: NestlyColors.sageDark)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(color: NestlyColors.border, borderRadius: BorderRadius.circular(2)),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [NestlyColors.sage, NestlyColors.sageDark]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Column(
                        children: List.generate(displayTop.length, (i) {
                          final task = displayTop[i];
                          final isLastChecked = _lastCheckedId == task.id;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: NestlyColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: NestlyColors.bgBase, borderRadius: BorderRadius.circular(4)),
                                  child: Text('#${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: NestlyColors.textSubtle)),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: task.done,
                                    activeColor: NestlyColors.sage,
                                    side: const BorderSide(color: NestlyColors.borderStrong),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                    onChanged: (_) => _handleToggleTask(task),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: TextStyle(
                                          fontFamily: NestlyTheme.fontSans,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: NestlyColors.primaryDark,
                                          decoration: task.done ? TextDecoration.lineThrough : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (task.category.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(color: NestlyColors.accentSoft, borderRadius: BorderRadius.circular(4)),
                                          child: Text(task.category, style: const TextStyle(fontSize: 9, color: NestlyColors.accentDeep, fontWeight: FontWeight.bold)),
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                                if (isLastChecked)
                                  const Icon(Icons.check, size: 16, color: NestlyColors.sage),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: NestlyColors.border),
                      const SizedBox(height: 10),
                      const Text(
                        'Everything else is deferred. You have permission to ignore it.',
                        style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10.5, color: NestlyColors.textSubtle, fontStyle: FontStyle.italic),
                        textAlign: CenterPlay.center,
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLowEnergyView() {
    final undone = _tasks.where((t) => !t.done).toList();
    undone.sort((a, b) => _scoreTask(a).compareTo(_scoreTask(b)));
    final easyTasks = undone.take(2).toList();
    final todayDinner = _simpleDinners[DateTime.now().weekday % 7];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🌙', style: const TextStyle(fontSize: 30), textAlign: CenterPlay.center),
          const SizedBox(height: 6),
          const Text('Low Energy Mode', style: TextStyle(fontFamily: NestlyTheme.fontSerif, fontSize: 17, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark), textAlign: CenterPlay.center),
          const SizedBox(height: 5),
          Text(_lowEnergyMsg, style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, color: NestlyColors.textMuted, fontStyle: FontStyle.italic, height: 1.55), textAlign: CenterPlay.center),
          const SizedBox(height: 20),

          // Two Easy Tasks Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.84),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.65)),
              boxShadow: NestlyTheme.shadowMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ONLY THESE TWO MATTER TODAY', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.bold, color: NestlyColors.textMuted, letterSpacing: 0.08)),
                const SizedBox(height: 12),
                easyTasks.isEmpty
                    ? const Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 30, color: NestlyColors.sage),
                            SizedBox(height: 8),
                            Text('Nothing pending. You\'re clear to rest.', style: TextStyle(fontSize: 13, color: NestlyColors.textMuted)),
                          ],
                        ),
                      )
                    : Column(
                        children: easyTasks.map((task) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: NestlyColors.border),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: task.done,
                                    activeColor: NestlyColors.sage,
                                    side: const BorderSide(color: NestlyColors.borderStrong),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                    onChanged: (_) => _handleToggleTask(task),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontFamily: NestlyTheme.fontSans,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: NestlyColors.primaryDark,
                                      decoration: task.done ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Easy Dinner Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.55)),
            ),
            child: Row(
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EASY DINNER TONIGHT', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.bold, color: NestlyColors.textSubtle, letterSpacing: 0.08)),
                      const SizedBox(height: 3),
                      Text(todayDinner, style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13.5, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark)),
                      const SizedBox(height: 2),
                      const Text('No prep required — that\'s the point.', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10.5, color: NestlyColors.textSubtle)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 20 min Timer Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFF8).withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA496BB).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('🛋️ 20-MINUTE REST', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8A7AAA), letterSpacing: 0.08)),
                const SizedBox(height: 10),
                _restActive
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmtRest(_restRemaining),
                                style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 36, fontWeight: FontWeight.w200, color: Color(0xFF6A5A8A)),
                              ),
                              ElevatedButton(
                                onPressed: _stopRestTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.6),
                                  foregroundColor: const Color(0xFF8A7AAA),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Stop', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 4,
                            decoration: BoxDecoration(color: const Color(0xFFA496BB).withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (20 * 60 - _restRemaining) / (20 * 60),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [Color(0xFFA496BB), Color(0xFF7A6A8A)]),
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    : ElevatedButton(
                        onPressed: _startRestTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.6),
                          foregroundColor: const Color(0xFF6A5A8A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0x66A496BB), width: 1.5),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Start 20-min rest →', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, fontWeight: FontWeight.bold)),
                      )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBreathingView() {
    final pattern = _breathPatterns[_breathPattern]!;
    final List<String> phases = List<String>.from(pattern['phases']);
    final Map<String, int> durations = Map<String, int>.from(pattern['durations']);
    final int phaseDur = durations[_breathPhase] ?? 4;
    final double phaseProgress = (phaseDur - _breathCountdown) / phaseDur;
    final bool breathDone = _breathCount >= 4;

    double scale = 1.0;
    if (_breathPhase == 'inhale') {
      scale = 1.0 + (0.35 * phaseProgress);
    } else if (_breathPhase == 'hold-in') {
      scale = 1.35;
    } else if (_breathPhase == 'exhale') {
      scale = 1.35 - (0.35 * phaseProgress);
    } else if (_breathPhase == 'hold-out') {
      scale = 1.0;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Column(
            children: [
              Text(
                breathDone ? 'Session Complete ✓' : '${pattern['label']} Breathing',
                style: const TextStyle(fontFamily: NestlyTheme.fontSerif, fontSize: 17, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark),
              ),
              const SizedBox(height: 4),
              Text(_breathingMsg, style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, color: NestlyColors.textMuted, fontStyle: FontStyle.italic, height: 1.5), textAlign: CenterPlay.center),
            ],
          ),
          const SizedBox(height: 12),

          // Pattern selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _breathPatterns.keys.map((k) {
              final p = _breathPatterns[k]!;
              final isSel = _breathPattern == k;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: GestureDetector(
                  onTap: () => _changeBreathPattern(k),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? NestlyColors.sageSoft : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSel ? NestlyColors.sageDark : NestlyColors.border, width: isSel ? 1.5 : 1),
                    ),
                    child: Text(
                      '${p['label']} ${p['desc']}',
                      style: TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSel ? NestlyColors.sageDark : NestlyColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),

          // Breathing Circle Animation
          Center(
            child: SizedBox(
              width: 224,
              height: 224,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Progress Arc
                  SizedBox(
                    width: 224,
                    height: 224,
                    child: CircularProgressIndicator(
                      value: phaseProgress,
                      strokeWidth: 5,
                      backgroundColor: NestlyColors.sage.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(_phaseColors[_breathPhase]),
                    ),
                  ),

                  // Animated Breathing Sphere
                  AnimatedScale(
                    scale: scale,
                    duration: const Duration(seconds: 1),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _phaseColors[_breathPhase]!,
                            _phaseColors[_breathPhase]!.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8))],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_breathCountdown',
                            style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 40, fontWeight: FontWeight.w100, color: Colors.white, height: 1),
                          ),
                          Text(
                            _phaseLabels[_breathPhase]!.toUpperCase(),
                            style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.85), letterSpacing: 0.06),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tip description
          Text(
            _phaseTips[_breathPhase]!,
            style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11.5, color: NestlyColors.textMuted, fontStyle: FontStyle.italic, height: 1.6),
            textAlign: CenterPlay.center,
          ),
          const SizedBox(height: 20),

          // Completion card / badge
          if (breathDone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE6F0E5), Color(0xFFD7E9D5)]),
                border: Border.all(color: NestlyColors.sage.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text('🌿', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 5),
                  Text('Full session complete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: NestlyColors.sageDark)),
                  SizedBox(height: 3),
                  Text('4 cycles · your nervous system has reset.', style: TextStyle(fontSize: 11, color: NestlyColors.textMuted)),
                ],
              ),
            )
          else if (_breathCount > 0)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_breathCount ${_breathCount == 1 ? 'cycle' : 'cycles'} complete ✓',
                  style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, fontWeight: FontWeight.bold, color: NestlyColors.sageDark),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Steps list indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: phases.map((ph) {
              final isCurrent = _breathPhase == ph;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.5),
                child: Column(
                  children: [
                    Opacity(
                      opacity: isCurrent ? 1.0 : 0.3,
                      child: Container(
                        width: max(24.0, durations[ph]! * 5.0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCurrent ? _phaseColors[ph] : NestlyColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _phaseLabels[ph]!.toUpperCase(),
                      style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 8, fontWeight: FontWeight.bold, color: NestlyColors.textSubtle, letterSpacing: 0.03),
                    )
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildReturnButton() {
    return GestureDetector(
      onTap: widget.onExit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF3E3028).withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x2E2E261E), blurRadius: 20, offset: Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Return to Nestly',
          style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.01),
        ),
      ),
    );
  }
}

// Center play helper class to avoid conflicts
class CenterPlay {
  static const TextAlign center = TextAlign.center;
}
