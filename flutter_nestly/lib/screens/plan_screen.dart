import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/nestly_theme.dart';
import '../services/db_service.dart';

class PlanScreen extends StatefulWidget {
  final NestlyUser user;
  final OnboardingProfile profile;

  const PlanScreen({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final DbService _db = DbService();
  String _activeTab = 'tasks'; // 'tasks' or 'calendar'

  // Task state
  List<HouseholdTask> _tasks = [];
  String _taskSearchQuery = '';
  String _taskCategoryFilter = 'All';

  // Calendar state
  List<CalendarEvent> _events = [];
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];
  String _calendarMemberFilter = 'All';
  bool _syncingSchoolFeed = false;

  final Map<String, Color> _priorityColors = {
    'High': const Color(0xFFC9813A),
    'Medium': const Color(0xFFB5A8C8),
    'Low': const Color(0xFF8F9E8B),
  };

  final Map<String, Color> _priorityBgs = {
    'High': const Color(0xFFFFF3E8),
    'Medium': const Color(0xFFF4F1F8),
    'Low': const Color(0xFFE8ECE7),
  };

  final Map<String, Color> _priorityTexts = {
    'High': const Color(0xFF9A5A1A),
    'Medium': const Color(0xFF6B5B8A),
    'Low': const Color(0xFF4E6B4A),
  };

  final Map<String, Color> _memberColors = {
    'Kids': const Color(0xFFE6A15C),
    'Mom': const Color(0xFF8F9E8B),
    'Dad': const Color(0xFF7D6B5D),
    'Shared': const Color(0xFFB5A8C8),
  };

  @override
  void initState() {
    super.initState();
    _db.tasksNotifier.addListener(_updateTasks);
    _db.eventsNotifier.addListener(_updateEvents);

    _updateTasks();
    _updateEvents();
  }

  @override
  void dispose() {
    _db.tasksNotifier.removeListener(_updateTasks);
    _db.eventsNotifier.removeListener(_updateEvents);
    super.dispose();
  }

  void _updateTasks() {
    if (mounted) setState(() => _tasks = _db.tasksNotifier.value);
  }

  void _updateEvents() {
    if (mounted) setState(() => _events = _db.eventsNotifier.value);
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

  void _simulateSyncSchoolFeed() {
    setState(() {
      _syncingSchoolFeed = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _syncingSchoolFeed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: NestlyColors.primaryDark,
            content: Text(
              'Synced successfully with Lincoln Elementary & Soccer League.',
              style: NestlyTheme.sansBody(fontSize: 12.5, color: Colors.white),
            ),
          ),
        );
      }
    });
  }

  // --- BUILD METHS ---

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768; // Tablet breakpoint

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isWide: true),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.only(right: 12),
                        decoration: const BoxDecoration(
                          border: Border(right: BorderSide(color: NestlyColors.border)),
                        ),
                        child: _buildTasksTab(),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.only(left: 12),
                        child: _buildCalendarTab(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Mobile Layout
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isWide: false),
            const SizedBox(height: 12),
            _buildTabSwitcher(),
            const SizedBox(height: 12),
            Expanded(
              child: _activeTab == 'tasks' ? _buildTasksTab() : _buildCalendarTab(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader({required bool isWide}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Family Plan', style: NestlyTheme.serifHeading(fontSize: 24)),
            const SizedBox(height: 3),
            const Text(
              'Tasks & schedule in one place',
              style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12.5, color: NestlyColors.textMuted),
            ),
          ],
        ),
        if (isWide)
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showTaskFormSheet(null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NestlyColors.bgCard,
                  foregroundColor: NestlyColors.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: NestlyColors.border),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Task', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showEventFormSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NestlyColors.primary,
                  foregroundColor: const Color(0xFFF8F3EE),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Event', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: () {
              if (_activeTab == 'tasks') {
                _showTaskFormSheet(null);
              } else {
                _showEventFormSheet();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NestlyColors.primary,
              foregroundColor: const Color(0xFFF8F3EE),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 2,
            ),
            icon: const Icon(Icons.add, size: 14),
            label: Text(_activeTab == 'tasks' ? 'Add Task' : 'Add Event', style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, fontWeight: FontWeight.bold)),
          )
      ],
    );
  }



  Widget _buildTabSwitcher() {
    final leftCount = _tasks.where((t) => !t.done).length;
    return Container(
      decoration: BoxDecoration(
        color: NestlyColors.bgCard,
        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
        border: Border.all(color: NestlyColors.border),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'tasks'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 'tasks' ? NestlyColors.primaryDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(NestlyTheme.radiusSm),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 13, color: _activeTab == 'tasks' ? Colors.white : NestlyColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Tasks ($leftCount left)',
                      style: TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 'tasks' ? Colors.white : NestlyColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'calendar'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 'calendar' ? NestlyColors.primaryDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(NestlyTheme.radiusSm),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 13, color: _activeTab == 'calendar' ? Colors.white : NestlyColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Calendar (${_events.length})',
                      style: TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 'calendar' ? Colors.white : NestlyColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TASKS TAB VIEW ---
  Widget _buildTasksTab() {
    final filtered = _tasks.where((t) {
      final matchesCat = _taskCategoryFilter == 'All' || t.category == _taskCategoryFilter;
      final matchesSearch = _taskSearchQuery.isEmpty || t.title.toLowerCase().contains(_taskSearchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    final doneCount = filtered.where((t) => t.done).length;

    return Column(
      children: [
        // Search bar
        TextField(
          style: NestlyTheme.sansBody(fontSize: 13.5),
          onChanged: (val) => setState(() => _taskSearchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search tasks…',
            hintStyle: const TextStyle(color: NestlyColors.textSubtle, fontSize: 13.5),
            prefixIcon: const Icon(Icons.search, color: NestlyColors.textSubtle, size: 15),
            filled: true,
            fillColor: NestlyColors.bgCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
              borderSide: const BorderSide(color: NestlyColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
              borderSide: const BorderSide(color: NestlyColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Categories filters row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Home', 'Kids', 'Meals'].map((c) {
                    final isSelected = _taskCategoryFilter == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _taskCategoryFilter = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? NestlyColors.primaryDark : NestlyColors.bgCard,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected ? NestlyTheme.shadowXs : null,
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontFamily: NestlyTheme.fontSans,
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : NestlyColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (filtered.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: NestlyColors.sageSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$doneCount/${filtered.length} ✓',
                  style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, fontWeight: FontWeight.bold, color: NestlyColors.sageDark),
                ),
              )
          ],
        ),
        const SizedBox(height: 14),

        // List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('✅', _taskSearchQuery.isNotEmpty ? 'No tasks match.' : 'Tap + Add Task to get started.')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    final pc = _priorityColors[task.priority] ?? _priorityColors['Medium']!;
                    final pb = _priorityBgs[task.priority] ?? _priorityBgs['Medium']!;
                    final pt = _priorityTexts[task.priority] ?? _priorityTexts['Medium']!;

                    return Opacity(
                      opacity: task.done ? 0.55 : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 9.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          color: NestlyColors.bgCard.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(18),
                          border: Border(
                            left: BorderSide(color: pc, width: 3.5),
                            top: const BorderSide(color: NestlyColors.border),
                            right: const BorderSide(color: NestlyColors.border),
                            bottom: const BorderSide(color: NestlyColors.border),
                          ),
                          boxShadow: NestlyTheme.shadowXs,
                        ),
                        child: Row(
                          alignment: Alignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _handleToggleTask(task),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0),
                                child: Icon(
                                  task.done ? Icons.check_circle : Icons.circle_outlined,
                                  color: task.done ? NestlyColors.sage : NestlyColors.borderStrong,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showTaskFormSheet(task),
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontFamily: NestlyTheme.fontSans,
                                        fontSize: 13.5,
                                        fontWeight: task.priority == 'High' ? FontWeight.bold : FontWeight.w500,
                                        color: task.done ? NestlyColors.textSubtle : NestlyColors.textMain,
                                        decoration: task.done ? TextDecoration.lineThrough : null,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Wrap(
                                      spacing: 5,
                                      runSpacing: 5,
                                      alignment: WrapAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: pb,
                                            borderRadius: BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            task.priority,
                                            style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.bold, color: pt),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: NestlyColors.bgBase,
                                            borderRadius: BorderRadius.circular(99),
                                            border: Border.all(color: NestlyColors.border),
                                          ),
                                          child: Text(
                                            task.category,
                                            style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.bold, color: NestlyColors.textMuted),
                                          ),
                                        ),
                                        Text(
                                          '· ${task.assignee}',
                                          style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, color: NestlyColors.textSubtle, fontWeight: FontWeight.w500),
                                        ),
                                        if (task.recurring.isNotEmpty && task.recurring != 'None')
                                          Text(
                                            '↻ ${task.recurring}',
                                            style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, color: NestlyColors.sageDark, fontWeight: FontWeight.bold),
                                          )
                                      ],
                                    ),
                                    if (task.notes.isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        task.notes,
                                        style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, color: NestlyColors.textSubtle, fontStyle: FontStyle.italic, height: 1.4),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 13, color: NestlyColors.textSubtle),
                                  onPressed: () => _showTaskFormSheet(task),
                                  padding: const EdgeInsets.all(5),
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(height: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 13, color: NestlyColors.danger),
                                  onPressed: () => _db.deleteTask(task.id),
                                  padding: const EdgeInsets.all(5),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            )
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

  // --- CALENDAR TAB VIEW ---
  Widget _buildCalendarTab() {
    final List<Map<String, dynamic>> dayStrip = List.generate(9, (i) {
      final d = DateTime.now().add(Duration(days: i - 2));
      final weekdayStr = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.weekday % 7];
      return {
        'str': d.toIso8601String().split('T')[0],
        'name': weekdayStr,
        'num': d.day,
        'today': i == 2,
      };
    });

    final dayEvents = _events.where((e) {
      final matchesDate = e.date == _selectedDate;
      final matchesMember = _calendarMemberFilter == 'All' || e.member == _calendarMemberFilter;
      return matchesDate && matchesMember;
    }).toList();

    return Column(
      children: [
        // Sync button
        ElevatedButton(
          onPressed: _syncingSchoolFeed ? null : _simulateSyncSchoolFeed,
          style: ElevatedButton.styleFrom(
            backgroundColor: NestlyColors.accentSoft,
            foregroundColor: NestlyColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: NestlyColors.accent.withOpacity(0.18)),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _syncingSchoolFeed
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(NestlyColors.accentDeep)),
                    )
                  : const Icon(Icons.refresh, size: 14, color: NestlyColors.accentDeep),
              const SizedBox(width: 8),
              Text(
                _syncingSchoolFeed ? 'Syncing school feed…' : 'Sync Lincoln Elementary & Soccer League',
                style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12.5, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Day horizontal strip
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: dayStrip.length,
            itemBuilder: (context, index) {
              final d = dayStrip[index];
              final isSelected = _selectedDate == d['str'];
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = d['str']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [NestlyColors.accentSoft, Color(0xFFFAE8D2)])
                          : null,
                      color: isSelected ? null : NestlyColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? NestlyColors.accent : NestlyColors.border, width: 1.5),
                      boxShadow: isSelected ? const [BoxShadow(color: Color(0x1AD9844A), blurRadius: 12, offset: Offset(0, 3))] : NestlyTheme.shadowXs,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          d['name']!.toUpperCase(),
                          style: TextStyle(fontSize: 9.5, color: isSelected ? NestlyColors.accentDeep : NestlyColors.textSubtle, fontWeight: FontWeight.bold, letterSpacing: 0.05),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${d['num']}',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.extrabold, color: isSelected ? NestlyColors.primaryDark : NestlyColors.textMain, letterSpacing: -0.02),
                        ),
                        if (d['today'] == true) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? NestlyColors.accentDeep : NestlyColors.sage,
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Member filter row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Kids', 'Mom', 'Dad', 'Shared'].map((m) {
              final isSelected = _calendarMemberFilter == m;
              return Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: GestureDetector(
                  onTap: () => setState(() => _calendarMemberFilter = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? NestlyColors.primaryDark : NestlyColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? NestlyTheme.shadowXs : null,
                    ),
                    child: Text(
                      m,
                      style: TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : NestlyColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Events list
        Expanded(
          child: dayEvents.isEmpty
              ? _buildEmptyState('📅', 'No events for this day.\nTap + Add Event to get started.')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    final ev = dayEvents[index];
                    Color indicatorColor = NestlyColors.primary;
                    try {
                      indicatorColor = Color(int.parse(ev.color.replaceAll('#', '0xFF')));
                    } catch (_) {}

                    return Container(
                      margin: const EdgeInsets.only(bottom: 9.0),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: NestlyColors.bgCard.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(18),
                        border: Border(
                          left: BorderSide(color: indicatorColor, width: 3.5),
                          top: const BorderSide(color: NestlyColors.border),
                          right: const BorderSide(color: NestlyColors.border),
                          bottom: const BorderSide(color: NestlyColors.border),
                        ),
                        boxShadow: NestlyTheme.shadowXs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.title,
                                  style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13.5, fontWeight: FontWeight.bold, color: NestlyColors.textMain, letterSpacing: -0.01),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 11, color: NestlyColors.textMuted),
                                    const SizedBox(width: 3),
                                    Text(
                                      ev.time,
                                      style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, color: NestlyColors.textMuted, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: indicatorColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        ev.member,
                                        style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10, fontWeight: FontWeight.bold, color: indicatorColor),
                                      ),
                                    )
                                  ],
                                ),
                                if (ev.notes.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    ev.notes,
                                    style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, color: NestlyColors.textSubtle, fontStyle: FontStyle.italic, height: 1.4),
                                  )
                                ]
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 14, color: NestlyColors.danger),
                            onPressed: () => _db.deleteEvent(ev.id),
                          )
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildEmptyState(String emoji, String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24.0),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted, fontStyle: FontStyle.italic, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- SHEET FORMS (MODAL REPLICAS) ---

  void _showTaskFormSheet(HouseholdTask? existingTask) {
    final titleController = TextEditingController(text: existingTask?.title ?? '');
    final notesController = TextEditingController(text: existingTask?.notes ?? '');
    final dateController = TextEditingController(text: existingTask?.dueDate ?? DateTime.now().toIso8601String().split('T')[0]);

    String category = existingTask?.category ?? 'Home';
    String priority = existingTask?.priority ?? 'Medium';
    String assignee = existingTask?.assignee ?? 'Shared';
    String recurring = existingTask?.recurring ?? 'None';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NestlyColors.bgBase,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingTask == null ? 'Add New Task' : 'Edit Task',
                          style: NestlyTheme.serifHeading(fontSize: 19),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 14),
                        )
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text('TASK NAME', style: NestlyTheme.labelCaps()),
                    const SizedBox(height: 5),
                    TextField(
                      controller: titleController,
                      style: NestlyTheme.sansBody(fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Clean school uniforms tonight',
                        hintStyle: TextStyle(color: NestlyColors.textSubtle, fontSize: 13.5),
                      ),
                      onChanged: (val) {
                        // Priority prediction
                        if (/urgent|tonight|asap/i.test(val)) {
                          setSheetState(() => priority = 'High');
                        } else if (/weekly|maybe/i.test(val)) {
                          setSheetState(() => priority = 'Low');
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Category & Priority
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CATEGORY', style: NestlyTheme.labelCaps()),
                              const SizedBox(height: 5),
                              DropdownButtonFormField<String>(
                                value: category,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                items: ['Home', 'Kids', 'Meals', 'General'].map((c) {
                                  return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13.5)));
                                }).toList(),
                                onChanged: (val) => setSheetState(() => category = val!),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PRIORITY', style: NestlyTheme.labelCaps()),
                              const SizedBox(height: 5),
                              DropdownButtonFormField<String>(
                                value: priority,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                items: [
                                  {'v': 'Low', 'l': '🌿 Low'},
                                  {'v': 'Medium', 'l': '🔵 Medium'},
                                  {'v': 'High', 'l': '🔥 High'},
                                ].map((p) {
                                  return DropdownMenuItem(value: p['v'], child: Text(p['l']!, style: const TextStyle(fontSize: 13.5)));
                                }).toList(),
                                onChanged: (val) => setSheetState(() => priority = val!),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Assignee & Due Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ASSIGNEE', style: NestlyTheme.labelCaps()),
                              const SizedBox(height: 5),
                              DropdownButtonFormField<String>(
                                value: assignee,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                items: ['Shared', 'Mom', 'Dad'].map((a) {
                                  return DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13.5)));
                                }).toList(),
                                onChanged: (val) => setSheetState(() => assignee = val!),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DUE DATE', style: NestlyTheme.labelCaps()),
                              const SizedBox(height: 5),
                              TextField(
                                controller: dateController,
                                readOnly: true,
                                style: const TextStyle(fontSize: 13.5),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  prefixIcon: Icon(Icons.calendar_month, size: 14),
                                ),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null) {
                                    setSheetState(() {
                                      dateController.text = d.toIso8601String().split('T')[0];
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Recurring row
                    Text('RECURRING', style: NestlyTheme.labelCaps()),
                    const SizedBox(height: 6),
                    Row(
                      children: ['None', 'Daily', 'Weekly', 'Monthly'].map((r) {
                        final isSel = recurring == r;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: OutlinedButton(
                              onPressed: () => setSheetState(() => recurring = r),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                minimumSize: Size.zero,
                                side: BorderSide(
                                  color: isSel ? NestlyColors.sage : NestlyColors.border,
                                  width: 1.5,
                                ),
                                backgroundColor: isSel ? NestlyColors.sageSoft : NestlyColors.bgCard,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                r,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? NestlyColors.sageDark : NestlyColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    Text('NOTES', style: NestlyTheme.labelCaps()),
                    const SizedBox(height: 5),
                    TextField(
                      controller: notesController,
                      style: NestlyTheme.sansBody(fontSize: 13.5),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Any helpful details…',
                        hintStyle: TextStyle(color: NestlyColors.textSubtle, fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;
                        final task = HouseholdTask(
                          id: existingTask?.id ?? 'task-${DateTime.now().millisecondsSinceEpoch}',
                          title: titleController.text.trim(),
                          category: category,
                          priority: priority,
                          assignee: assignee,
                          dueDate: dateController.text,
                          recurring: recurring,
                          notes: notesController.text.trim(),
                          done: existingTask?.done ?? false,
                        );
                        _db.saveTask(task);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NestlyColors.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(existingTask == null ? '✓ Create Task' : '✓ Save Changes'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEventFormSheet() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final timeController = TextEditingController(text: '09:00');

    String member = 'Kids';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NestlyColors.bgBase,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add Event', style: NestlyTheme.serifHeading(fontSize: 19)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 14),
                        )
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text('EVENT TITLE', style: NestlyTheme.labelCaps()),
                    const SizedBox(height: 5),
                    TextField(
                      controller: titleController,
                      style: NestlyTheme.sansBody(fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Soccer practice',
                        hintStyle: TextStyle(color: NestlyColors.textSubtle, fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DATE', style: NestlyTheme.labelCaps()),
                              const SizedBox(height: 5),
                              TextField(
                                controller: dateController,
                                readOnly: true,
                                style: const TextStyle(fontSize: 13.5),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  prefixIcon: Icon(Icons.calendar_month, size: 14),
                                ),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null) {
                                    setSheetState(() {
                                      dateController.text = d.toIso8601String().split('T')[0];
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TIME', style: NestlyTheme.labelCaps()),
                              const SizedBox(height: 5),
                              TextField(
                                controller: timeController,
                                readOnly: true,
                                style: const TextStyle(fontSize: 13.5),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  prefixIcon: Icon(Icons.access_time, size: 14),
                                ),
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                                  );
                                  if (t != null) {
                                    setSheetState(() {
                                      final hour = t.hour.toString().padLeft(2, '0');
                                      final minute = t.minute.toString().padLeft(2, '0');
                                      timeController.text = '$hour:$minute';
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Member Row
                    Text('MEMBER', style: NestlyTheme.labelCaps()),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Kids', 'Mom', 'Dad', 'Shared'].map((m) {
                        final isSel = member == m;
                        final color = _memberColors[m]!;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: OutlinedButton(
                              onPressed: () => setSheetState(() => member = m),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                minimumSize: Size.zero,
                                side: BorderSide(
                                  color: isSel ? color : NestlyColors.border,
                                  width: 1.5,
                                ),
                                backgroundColor: isSel ? color.withOpacity(0.12) : NestlyColors.bgCard,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? color : NestlyColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    Text('NOTES', style: NestlyTheme.labelCaps()),
                    const SizedBox(height: 5),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: NestlyTheme.sansBody(fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Optional notes…',
                        hintStyle: TextStyle(color: NestlyColors.textSubtle, fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;
                        final hexColor = '#${_memberColors[member]!.value.toRadixString(16).substring(2).toUpperCase()}';
                        final event = CalendarEvent(
                          id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
                          title: titleController.text.trim(),
                          time: timeController.text,
                          date: dateController.text,
                          member: member,
                          notes: notesController.text.trim(),
                          color: hexColor,
                        );
                        _db.saveEvent(event);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NestlyColors.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('✓ Add to Calendar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
