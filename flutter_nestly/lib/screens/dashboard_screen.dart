import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/nestly_theme.dart';
import '../services/db_service.dart';

class DashboardScreen extends StatefulWidget {
  final NestlyUser user;
  final OnboardingProfile profile;
  final VoidCallback onToggleSimplify;
  final Function(String) setActiveTab;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.profile,
    required this.onToggleSimplify,
    required this.setActiveTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final DbService _db = DbService();

  List<HouseholdTask> _tasks = [];
  List<CalendarEvent> _events = [];
  Map<String, MealPlan> _meals = {};
  List<FamilyFeedItem> _timeline = [];

  bool _isAudioPlaying = false;
  String _activeTrack = 'Cozy Rainfall';
  List<Map<String, dynamic>> _aiTips = [];

  late AnimationController _soundWaveController;
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();

    _soundWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryFade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _db.tasksNotifier.addListener(_updateTasks);
    _db.eventsNotifier.addListener(_updateEvents);
    _db.mealsNotifier.addListener(_updateMeals);
    _db.timelineNotifier.addListener(_updateTimeline);

    _updateTasks();
    _updateEvents();
    _updateMeals();
    _updateTimeline();

    _generateAiTips();
    _entryController.forward();
  }

  @override
  void dispose() {
    _db.tasksNotifier.removeListener(_updateTasks);
    _db.eventsNotifier.removeListener(_updateEvents);
    _db.mealsNotifier.removeListener(_updateMeals);
    _db.timelineNotifier.removeListener(_updateTimeline);
    _soundWaveController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _updateTasks() {
    if (mounted) setState(() => _tasks = _db.tasksNotifier.value);
  }

  void _updateEvents() {
    if (mounted) setState(() => _events = _db.eventsNotifier.value);
  }

  void _updateMeals() {
    if (mounted) setState(() => _meals = _db.mealsNotifier.value);
  }

  void _updateTimeline() {
    if (mounted) setState(() => _timeline = _db.timelineNotifier.value);
  }

  String _getCurrentDay() {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[DateTime.now().weekday % 7];
  }

  String _getDynamicGreeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning, ${widget.user.name}. ☀️';
    if (h >= 12 && h < 17) return 'Good afternoon, ${widget.user.name}.';
    if (h >= 17 && h < 21) return 'Good evening, ${widget.user.name}. 🌆';
    return 'Quiet night, ${widget.user.name}. 🌙';
  }

  String _getSubGreeting() {
    final h = DateTime.now().hour;
    if (widget.profile.stressPoints.dinner && h >= 16) {
      return "Tonight may feel busy — focus only on dinner and the kids' gear.";
    }
    if (h < 12) {
      return "Morning checklist is looking good. Focus on only 3 priorities today.";
    }
    return "You have a lighter afternoon. Keep tasks brief and take time to breathe.";
  }

  void _generateAiTips() {
    final tips = <Map<String, dynamic>>[];
    final todayMeal = _meals[_getCurrentDay()]?.dinner ?? '';

    if (widget.profile.sportsActivities.trim().isNotEmpty) {
      tips.add({
        'id': 'tip-sports',
        'icon': '⚽',
        'title': 'Pack sports gear early',
        'description': '${widget.profile.sportsActivities} practice is approaching. Toss water bottles and uniforms in the car before 2 PM.',
        'actionText': 'Add to tasks',
        'action': () {
          _db.saveTask(HouseholdTask(
            id: 'task-sports-ai-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Load sports gear into trunk',
            category: 'Kids',
            priority: 'High',
            assignee: widget.user.role,
            dueDate: DateTime.now().toIso8601String().split('T')[0],
            recurring: 'None',
            notes: 'Generated from sports schedule recommendation.',
            done: false,
          ));
          _dismissTip('tip-sports');
        }
      });
    }

    if (widget.profile.stressPoints.dinner) {
      tips.add({
        'id': 'tip-dinner',
        'icon': '🍲',
        'title': 'Calm the dinner rush',
        'description': 'Prep tonight\'s dinner (${todayMeal.isNotEmpty ? todayMeal : 'pasta'}) during lunch to bypass the 4 PM crunch.',
        'actionText': 'Remind me at 12 PM',
        'action': () => _dismissTip('tip-dinner')
      });
    }

    if (widget.profile.stressPoints.laundry || widget.profile.laundryRoutine.contains('Daily')) {
      tips.add({
        'id': 'tip-laundry',
        'icon': '🧺',
        'title': 'Small laundry loop',
        'description': 'Running one load before 3 PM keeps the basket empty. Don\'t let it pile up.',
        'actionText': 'Log laundry started',
        'action': () => _dismissTip('tip-laundry')
      });
    }

    if (tips.isEmpty) {
      tips.add({
        'id': 'tip-calm',
        'icon': '🫁',
        'title': 'Take a breathing moment',
        'description': 'You\'ve completed several tasks today. The rest can wait. Take 2 minutes for yourself.',
        'actionText': 'Enter Simplify Mode',
        'action': widget.onToggleSimplify
      });
    }

    setState(() {
      _aiTips = tips;
    });
  }

  void _dismissTip(String id) {
    setState(() {
      _aiTips = _aiTips.where((t) => t['id'] != id).toList();
    });
  }

  void _handleToggleTask(HouseholdTask task) {
    final updated = task.copyWith(done: !task.done);
    _db.saveTask(updated);
    _db.addTimelineItem(
      widget.user.name,
      updated.done ? 'completed' : 'reopened',
      updated.title,
    );
  }

  String _getDayLoad(int offset) {
    final d = DateTime.now().add(Duration(days: offset));
    final dateStr = d.toIso8601String().split('T')[0];
    final count = _events.where((e) => e.date == dateStr).length;
    if (count == 0) return 'Calm';
    if (count <= 2) return 'Moderate';
    return 'Busy';
  }

  Color _getLoadColor(String load) {
    switch (load) {
      case 'Calm':
        return NestlyColors.sage;
      case 'Moderate':
        return NestlyColors.lavender;
      case 'Busy':
      default:
        return NestlyColors.accent;
    }
  }

  Color _getLoadBg(String load) {
    switch (load) {
      case 'Calm':
        return NestlyColors.sageSoft;
      case 'Moderate':
        return NestlyColors.lavenderSoft;
      case 'Busy':
      default:
        return NestlyColors.accentSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _tasks.length;
    final completedCount = _tasks.where((t) => t.done).length;
    final progressPct = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    // Wrap whole content in entry animation
    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: _buildContent(totalCount, completedCount, progressPct),
      ),
    );
  }

  Widget _buildContent(int totalCount, int completedCount, double progressPct) {
    final undoneTasks = _tasks.where((t) => !t.done).toList();
    final priorityTasks = undoneTasks.take(4).toList();
    final isOverwhelmed = undoneTasks.length > 5 || DateTime.now().hour >= 20;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768; // Tablet breakpoint

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 5,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildGreetingBanner(progressPct, completedCount, totalCount),
                    const SizedBox(height: 16),
                    if (isOverwhelmed) ...[
                      _buildOverwhelmAlert(),
                      const SizedBox(height: 16),
                    ],
                    _buildPrioritiesSection(priorityTasks),
                    const SizedBox(height: 16),
                    _buildSoundscapeCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right Column
              Expanded(
                flex: 4,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildWeeklyLoadSection(),
                    const SizedBox(height: 16),
                    if (_aiTips.isNotEmpty) ...[
                      _buildAiRecommendationsSection(),
                      const SizedBox(height: 16),
                    ],
                    _buildScheduleDinnerGrid(),
                    const SizedBox(height: 16),
                    _buildFamilyFeedSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        }

        // Mobile Layout (Single Column)
        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildGreetingBanner(progressPct, completedCount, totalCount),
            const SizedBox(height: 12),

            if (isOverwhelmed) ...[
              _buildOverwhelmAlert(),
              const SizedBox(height: 12),
            ],

            _buildPrioritiesSection(priorityTasks),
            const SizedBox(height: 12),

            _buildSoundscapeCard(),
            const SizedBox(height: 12),

            _buildWeeklyLoadSection(),
            const SizedBox(height: 12),

            if (_aiTips.isNotEmpty) ...[
              _buildAiRecommendationsSection(),
              const SizedBox(height: 12),
            ],

            _buildScheduleDinnerGrid(),
            const SizedBox(height: 12),

            _buildFamilyFeedSection(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildGreetingBanner(double progressPct, int completed, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: NestlyGradients.warmSunrise,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: NestlyTheme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDynamicGreeting(),
                      style: NestlyTheme.serifHeading(fontSize: 22, color: NestlyColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(left: 10),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: NestlyColors.sage, width: 2.5)),
                      ),
                      child: Text(
                        _getSubGreeting(),
                        style: const TextStyle(
                          fontFamily: NestlyTheme.fontSans,
                          fontSize: 12.5, height: 1.55,
                          color: NestlyColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Animated task count badge
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: total - completed),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.75),
                    border: Border.all(color: NestlyColors.sage.withOpacity(0.3), width: 2),
                    boxShadow: NestlyTheme.shadowXs,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$value',
                        style: const TextStyle(
                          fontFamily: NestlyTheme.fontSans,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: NestlyColors.primaryDark,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        'left',
                        style: TextStyle(
                          fontFamily: NestlyTheme.fontSans,
                          fontSize: 9,
                          color: NestlyColors.textSubtle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Animated progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    height: 6,
                    color: Colors.white.withOpacity(0.55),
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progressPct),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [NestlyColors.sage, NestlyColors.sageDark]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completed/$total done',
                style: const TextStyle(
                  fontFamily: NestlyTheme.fontSans,
                  fontSize: 11.0, fontWeight: FontWeight.w700,
                  color: NestlyColors.sageDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverwhelmAlert() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFEF3E8), Color(0xFFFDF6EE)]),
        border: Border.all(color: NestlyColors.accent.withOpacity(0.22)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: NestlyTheme.shadowXs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateTime.now().hour >= 20 ? '🌙 It\'s getting late' : '🧠 pending tasks overload',
                  style: const TextStyle(
                    fontFamily: NestlyTheme.fontSans,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: NestlyColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Simplify Mode can help you wind down.',
                  style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11.0, color: NestlyColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: widget.onToggleSimplify,
            style: ElevatedButton.styleFrom(
              backgroundColor: NestlyColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, fontWeight: FontWeight.bold),
              elevation: 2,
            ),
            child: const Text('Simplify'),
          )
        ],
      ),
    );
  }

  Widget _buildPrioritiesSection(List<HouseholdTask> priorityTasks) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: NestlyColors.bgCard,
        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
        border: const Border(
          left: BorderSide(color: NestlyColors.sage, width: 3.0),
          top: BorderSide(color: NestlyColors.border),
          right: BorderSide(color: NestlyColors.border),
          bottom: BorderSide(color: NestlyColors.border),
        ),
        boxShadow: NestlyTheme.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: NestlyColors.sage, size: 15),
                  SizedBox(width: 7),
                  Text(
                    'Today\'s Priorities',
                    style: TextStyle(
                      fontFamily: NestlyTheme.fontSans,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: NestlyColors.primaryDark,
                    ),
                  )
                ],
              ),
              InkWell(
                onTap: () => widget.setActiveTab('plan'),
                child: const Row(
                  children: [
                    Text(
                      'All',
                      style: TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: NestlyColors.accentDeep,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward, size: 11, color: NestlyColors.accentDeep),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          if (priorityTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: Text(
                  '🎉 All priorities checked! Enjoy the calm.',
                  style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: priorityTasks.length,
              itemBuilder: (context, index) {
                final task = priorityTasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11.0),
                  child: Row(
                    alignment: Alignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: task.done,
                          activeColor: NestlyColors.sage,
                          side: const BorderSide(color: NestlyColors.borderStrong, width: 1.5),
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
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                                color: task.done ? NestlyColors.textSubtle : NestlyColors.textMain,
                                decoration: task.done ? TextDecoration.lineThrough : null,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: NestlyColors.accentSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    task.category,
                                    style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 9, fontWeight: FontWeight.bold, color: NestlyColors.accentDeep),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '· ${task.assignee}',
                                  style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, color: NestlyColors.textSubtle, fontWeight: FontWeight.w500),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildSoundscapeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(
        color: NestlyColors.bgCard,
        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
        border: Border.all(color: NestlyColors.border),
        boxShadow: NestlyTheme.shadowXs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: NestlyTheme.transitionSmooth,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _isAudioPlaying
                      ? const LinearGradient(colors: [NestlyColors.accentSoft, Color(0xFFFAE8D2)])
                      : null,
                  color: _isAudioPlaying ? null : NestlyColors.bgBase,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: _isAudioPlaying ? NestlyColors.accent.withOpacity(0.28) : NestlyColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.music_note,
                  color: _isAudioPlaying ? NestlyColors.accentDeep : NestlyColors.textMuted,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ambient Soundscape',
                    style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12.5, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _activeTrack,
                      isDense: true,
                      style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11.0, color: NestlyColors.textMuted, fontWeight: FontWeight.w600),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 12, color: NestlyColors.textSubtle),
                      items: ['Cozy Rainfall', 'Evening Fireplace', 'Soft Forest Noise'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _activeTrack = val;
                          });
                        }
                      },
                    ),
                  )
                ],
              )
            ],
          ),
          Row(
            children: [
              if (_isAudioPlaying) ...[
                _buildMockSoundWave(),
                const SizedBox(width: 10),
              ],
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAudioPlaying = !_isAudioPlaying;
                    if (_isAudioPlaying) {
                      _soundWaveController.repeat();
                    } else {
                      _soundWaveController.stop();
                    }
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAudioPlaying ? NestlyColors.accent : NestlyColors.primary,
                    boxShadow: NestlyTheme.shadowSm,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMockSoundWave() {
    return AnimatedBuilder(
      animation: _soundWaveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            // Generates simple waving bars using basic sine wave shifts
            final value = 4.0 + 12.0 * (0.3 + 0.7 * (0.5 + 0.5 * (1.0 + (index * 0.2) + _soundWaveController.value * 2.0).hashCode.toDouble().sin()));
            final finalHeight = value.clamp(4.0, 16.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 2.0,
              height: finalHeight,
              color: NestlyColors.accentDeep,
            );
          }),
        );
      },
    );
  }

  Widget _buildWeeklyLoadSection() {
    final weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final currentDay = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: NestlyColors.bgCard,
        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
        border: Border.all(color: NestlyColors.border),
        boxShadow: NestlyTheme.shadowXs,
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: NestlyColors.primary, size: 14),
                  SizedBox(width: 7),
                  Text(
                    'Weekly Load',
                    style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13.0, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark),
                  ),
                ],
              ),
              Text(
                '5-DAY FORECAST',
                style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 9.0, fontWeight: FontWeight.w700, color: NestlyColors.textSubtle, letterSpacing: 0.04),
              )
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final day = currentDay.add(Duration(days: i));
              final dayName = weekdayNames[day.weekday % 7];
              final load = _getDayLoad(i);
              final active = i == 0;

              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? _getLoadBg(load) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? _getLoadColor(load).withOpacity(0.25) : Colors.transparent),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayName.toUpperCase(),
                        style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 9.0, fontWeight: FontWeight.bold, color: active ? NestlyColors.textMuted : NestlyColors.textSubtle, letterSpacing: 0.04),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 16, fontWeight: FontWeight.w800, color: active ? NestlyColors.primaryDark : NestlyColors.textMain),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getLoadColor(load),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        load.toUpperCase(),
                        style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 7, fontWeight: FontWeight.bold, color: NestlyColors.textSubtle, letterSpacing: 0.05),
                      )
                    ],
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildAiRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: NestlyGradients.accentWarm,
                borderRadius: BorderRadius.circular(NestlyTheme.radiusFull),
                border: Border.all(color: NestlyColors.accent.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: NestlyColors.accent, size: 10),
                  const SizedBox(width: 5),
                  Text('AI INSIGHTS', style: NestlyTheme.labelCaps(color: NestlyColors.accentDeep)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _aiTips.length,
            itemBuilder: (context, index) {
              final tip = _aiTips[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + index * 120),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(offset: Offset(20 * (1 - v), 0), child: child),
                ),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NestlyColors.bgCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: NestlyColors.accent.withOpacity(0.15)),
                    boxShadow: NestlyTheme.shadowCard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(tip['icon']!, style: const TextStyle(fontSize: 22)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _dismissTip(tip['id']),
                            child: const Icon(Icons.close, size: 13, color: NestlyColors.textSubtle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tip['title']!,
                        style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark),
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(
                          tip['description']!,
                          style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, color: NestlyColors.textMuted, height: 1.45),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: tip['action'],
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NestlyColors.primaryDark,
                          foregroundColor: NestlyColors.textOnDark,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          minimumSize: const Size(double.infinity, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10.5, fontWeight: FontWeight.w700),
                          elevation: 0,
                        ),
                        child: Text(tip['actionText']!),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildScheduleDinnerGrid() {
    final upcoming = _events.take(2).toList();
    final todayDinner = _meals[_getCurrentDay()]?.dinner ?? 'Slow Cooker Lentil Soup';

    return Row(
      children: [
        // Schedule card
        Expanded(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: NestlyColors.bgCard,
              borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
              border: Border.all(color: NestlyColors.border),
              boxShadow: NestlyTheme.shadowXs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 13, color: NestlyColors.textBody),
                        SizedBox(width: 5),
                        Text('Schedule', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12.5, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => widget.setActiveTab('plan'),
                      child: const Text('View', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10.5, color: NestlyColors.accentDeep, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: upcoming.isEmpty
                      ? const Center(child: Text('Enjoy a quiet day.', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, color: NestlyColors.textSubtle, fontStyle: FontStyle.italic)))
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: upcoming.length,
                          itemBuilder: (context, index) {
                            final ev = upcoming[index];
                            // Parse hex color safely
                            Color indicatorColor = NestlyColors.primary;
                            try {
                              indicatorColor = Color(int.parse(ev.color.replaceAll('#', '0xFF')));
                            } catch (_) {}

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6.0),
                              padding: const EdgeInsets.only(left: 6.0),
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: indicatorColor, width: 2.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ev.title,
                                    style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10.5, fontWeight: FontWeight.bold, color: NestlyColors.textMain),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${ev.time} · ${ev.member}',
                                    style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 9.5, color: NestlyColors.textSubtle),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 11),

        // Dinner card
        Expanded(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: NestlyColors.bgCard,
              borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
              border: Border.all(color: NestlyColors.border),
              boxShadow: NestlyTheme.shadowXs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restaurant_outlined, size: 13, color: NestlyColors.textBody),
                        SizedBox(width: 5),
                        Text('Dinner', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12.5, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => widget.setActiveTab('meals'),
                      child: const Text('Plan', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10.5, color: NestlyColors.accentDeep, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                Text(
                  todayDinner,
                  style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, fontWeight: FontWeight.bold, color: NestlyColors.textMain, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  '✓ Preference matched',
                  style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, color: NestlyColors.sageDark, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildFamilyFeedSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: NestlyColors.bgCard,
        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
        border: Border.all(color: NestlyColors.border),
        boxShadow: NestlyTheme.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sentiment_satisfied_alt_outlined, color: NestlyColors.sage, size: 14),
              SizedBox(width: 7),
              Text(
                'Family Feed',
                style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13.0, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (_timeline.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: Text(
                  'No activity yet — actions will appear here.',
                  style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12.5, color: NestlyColors.textSubtle, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timeline.length,
              itemBuilder: (context, index) {
                final act = _timeline[index];
                final isLast = index == _timeline.length - 1;

                List<Color> avatarGrad = [NestlyColors.primaryLight, NestlyColors.primary];
                if (act.user.toLowerCase().contains('mom')) {
                  avatarGrad = [NestlyColors.sage, NestlyColors.sageDark];
                } else if (act.user.toLowerCase().contains('dad')) {
                  avatarGrad = [NestlyColors.sky, NestlyColors.skyDark];
                } else if (act.user.toLowerCase().contains('nan') || act.user.toLowerCase().contains('grand')) {
                  avatarGrad = [NestlyColors.lavender, NestlyColors.lavender];
                }

                return Container(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 11.0),
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 11.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isLast ? Colors.transparent : NestlyColors.border,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: avatarGrad,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: NestlyTheme.shadowXs,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          act.user.isNotEmpty ? act.user[0].toUpperCase() : 'U',
                          style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12.0, color: NestlyColors.textBody, height: 1.45),
                            children: [
                              TextSpan(text: act.user, style: const TextStyle(fontWeight: FontWeight.bold, color: NestlyColors.textMain)),
                              const TextSpan(text: ' '),
                              TextSpan(text: act.action, style: const TextStyle(color: NestlyColors.textMuted)),
                              const TextSpan(text: ' '),
                              TextSpan(text: act.task, style: const TextStyle(fontWeight: FontWeight.w600, color: NestlyColors.primaryDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        act.time,
                        style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, color: NestlyColors.textSubtle, fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                );
              },
            )
        ],
      ),
    );
  }
}

// Extends double to calculate sine waves for sound waves animation
extension on double {
  double sin() => double.parse(toString()); // stub for math.sin
}
