import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/nestly_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final NestlyUser user;
  final Function(OnboardingProfile) onOnboardingComplete;

  const OnboardingScreen({
    super.key,
    required this.user,
    required this.onOnboardingComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 1;
  final int _totalSteps = 7;

  int _householdSize = 3;
  List<KidProfile> _kids = [KidProfile(name: '', age: 0)];
  String _schoolSchedule = 'Elementary';
  String _sportsActivities = '';
  String _laundryRoutine = 'Daily single load';
  String _workSchedule = 'Hybrid 9-to-5';
  
  // Stress zones map
  bool _stressMorning = true;
  bool _stressDinner = true;
  bool _stressLaundry = false;
  bool _stressBedtime = false;
  bool _stressSchedules = true;

  bool _loading = false;
  String _loadingMsg = '';
  Timer? _loadingTimer;

  final _sportsController = TextEditingController();

  final List<Map<String, String>> _stepHeaders = [
    {'emoji': '👨‍👩‍👧', 'label': 'Household'},
    {'emoji': '👶', 'label': 'Kids'},
    {'emoji': '🏫', 'label': 'School'},
    {'emoji': '⚽', 'label': 'Activities'},
    {'emoji': '🧺', 'label': 'Laundry'},
    {'emoji': '😤', 'label': 'Stress'},
    {'emoji': '✨', 'label': 'Activate'},
  ];

  @override
  void dispose() {
    _sportsController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _nextStep() {
    if (_step < _totalSteps) {
      setState(() {
        _step++;
      });
    } else {
      _handleFinalize();
    }
  }

  void _prevStep() {
    if (_step > 1) {
      setState(() {
        _step--;
      });
    }
  }

  void _handleFinalize() {
    setState(() {
      _loading = true;
    });

    final messages = [
      'Aligning co-parent priorities…',
      'Building low-stress schedules…',
      'Activating AI recommendations…',
    ];
    
    int index = 0;
    setState(() {
      _loadingMsg = messages[0];
    });

    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      index++;
      if (index < messages.length) {
        if (mounted) {
          setState(() {
            _loadingMsg = messages[index];
          });
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 3800), () {
      _loadingTimer?.cancel();
      if (mounted) {
        setState(() {
          _loading = false;
        });
        
        final profile = OnboardingProfile(
          householdSize: _householdSize,
          kids: _kids.where((k) => k.name.trim().isNotEmpty).toList(),
          schoolSchedule: _schoolSchedule,
          laundryRoutine: _laundryRoutine,
          workSchedule: _workSchedule,
          sportsActivities: _sportsController.text.trim(),
          stressPoints: StressPoints(
            morning: _stressMorning,
            dinner: _stressDinner,
            bedtime: _stressBedtime,
            laundry: _stressLaundry,
            sports: _stressSchedules,
          ),
        );
        
        widget.onOnboardingComplete(profile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingScreen();

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgressHeader(),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: NestlyTheme.transitionSmooth,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_step),
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: 24),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NestlyColors.accentSoft, NestlyColors.sageSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: NestlyColors.sage.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: const Text('🪹', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 24),
            Text('Personalizing Nestly', style: NestlyTheme.serifHeading(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              '"$_loadingMsg"',
              style: const TextStyle(
                fontFamily: NestlyTheme.fontSans,
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                color: NestlyColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Loading progress bar bar
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: NestlyColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(NestlyColors.sage),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final activeHeader = _stepHeaders[_step - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text('🪹', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Text(
                  'NESTLY',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: NestlyColors.primaryDark,
                    letterSpacing: 0.04,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NestlyColors.bgCard,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: NestlyColors.border),
              ),
              child: Text(
                '$_step/$_totalSteps',
                style: const TextStyle(
                  fontFamily: NestlyTheme.fontSans,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: NestlyColors.textMuted,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 10),

        // Step dot indicators
        Row(
          children: List.generate(_totalSteps, (index) {
            final isCompleted = index < _step - 1;
            final isActive = index == _step - 1;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                height: 3.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: isCompleted
                      ? NestlyColors.sage
                      : (isActive ? NestlyColors.accent : NestlyColors.border),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Active Step Info
        Row(
          children: [
            Text(activeHeader['emoji']!, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'STEP $_step — ${activeHeader['label']!.toUpperCase()}',
              style: NestlyTheme.labelCaps(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      case 6:
        return _buildStep6();
      case 7:
        return _buildStep7();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How large is your household?', style: NestlyTheme.serifHeading(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Includes parents, kids, and any live-in support.',
          style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [NestlyColors.accentSoft, NestlyColors.sageSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.0),
              boxShadow: NestlyTheme.shadowMd,
            ),
            alignment: Alignment.center,
            child: Text(
              '$_householdSize',
              style: const TextStyle(
                fontFamily: NestlyTheme.fontSans,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: NestlyColors.primaryDark,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [1, 2, 3, 4, 5, 6, 7, 8].map((n) {
            final isSelected = n == 8 ? _householdSize >= 8 : _householdSize == n;
            final label = n == 8 ? '8+' : '$n';
            return InkWell(
              onTap: () {
                setState(() {
                  _householdSize = n;
                });
              },
              shape: const CircleBorder(),
              child: AnimatedContainer(
                duration: NestlyTheme.transitionFast,
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? NestlyColors.sage : NestlyColors.border,
                    width: 2.0,
                  ),
                  color: isSelected ? NestlyColors.sageSoft : NestlyColors.bgCard,
                  boxShadow: isSelected ? NestlyTheme.shadowXs : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: NestlyTheme.fontSans,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.0,
                    color: isSelected ? NestlyColors.sageDark : NestlyColors.textMain,
                  ),
                ),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tell us about the kids', style: NestlyTheme.serifHeading(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Nestly customises routines based on their ages.',
          style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _kids.length,
            itemBuilder: (context, index) {
              final kid = _kids[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  border: Border.all(color: NestlyColors.border),
                  borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: NestlyColors.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.child_care, color: NestlyColors.accentDeep, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        style: NestlyTheme.sansBody(fontSize: 13),
                        decoration: _buildMiniInputDecoration('Name'),
                        controller: TextEditingController(text: kid.name)
                          ..selection = TextSelection.fromPosition(TextPosition(offset: kid.name.length)),
                        onChanged: (val) {
                          _kids[index] = KidProfile(name: val, age: kid.age);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        style: NestlyTheme.sansBody(fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: _buildMiniInputDecoration('Age'),
                        controller: TextEditingController(text: kid.age > 0 ? '${kid.age}' : '')
                          ..selection = TextSelection.fromPosition(TextPosition(offset: kid.age > 0 ? '${kid.age}'.length : 0)),
                        onChanged: (val) {
                          final parsedAge = int.tryParse(val) ?? 0;
                          _kids[index] = KidProfile(name: kid.name, age: parsedAge);
                        },
                      ),
                    ),
                    if (_kids.length > 1) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _kids.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.delete, color: NestlyColors.danger, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _kids.add(KidProfile(name: '', age: 0));
            });
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: const BorderSide(color: NestlyColors.border, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('+ Add another child', style: TextStyle(color: NestlyColors.primary, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final schoolSchedules = ['None', 'Preschool', 'Elementary', 'Middle', 'High'];
    final workSchedules = [
      'Full-time in-office',
      'Remote 9-to-5',
      'Hybrid 9-to-5',
      'Flexible/Self-employed',
      'Shift work',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('School & Work', style: NestlyTheme.serifHeading(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Nestly builds routines around your schedule.',
          style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted),
        ),
        const SizedBox(height: 16),

        Text('SCHOOL SCHEDULE', style: NestlyTheme.labelCaps()),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: NestlyColors.bgCard,
            borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
            border: Border.all(color: NestlyColors.border, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _schoolSchedule,
              items: schoolSchedules.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s, style: NestlyTheme.sansBody(fontSize: 13.5)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _schoolSchedule = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        Text('WORK SCHEDULE', style: NestlyTheme.labelCaps()),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: NestlyColors.bgCard,
            borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
            border: Border.all(color: NestlyColors.border, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _workSchedule,
              items: workSchedules.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s, style: NestlyTheme.sansBody(fontSize: 13.5)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _workSchedule = val;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Extracurriculars', style: NestlyTheme.serifHeading(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Are there any sports clubs or practices? We will track them.',
          style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _sportsController,
          style: NestlyTheme.sansBody(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'e.g. Soccer, Swimming',
            hintStyle: const TextStyle(color: NestlyColors.textSubtle, fontSize: 13.5),
            filled: true,
            fillColor: NestlyColors.bgCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ],
    );
  }

  Widget _buildStep5() {
    final routines = [
      {'v': 'Daily single load', 't': 'Daily Loop', 'd': 'One load every morning — wash, dry, fold.', 'icon': '🔄'},
      {'v': 'Weekend marathon', 't': 'Weekend Block', 'd': 'Let it pile, then tackle all on Sunday.', 'icon': '📅'},
      {'v': 'Outsourced / Service', 't': 'Outsourced', 'd': 'Weekly pickup & wash-dry-fold service.', 'icon': '🚐'},
      {'v': 'Ad-hoc when needed', 't': 'As-Needed', 'd': 'Only run when the hamper overflows.', 'icon': '🧺'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Laundry Operations', style: NestlyTheme.serifHeading(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Nestly creates smart reminders around your flow.',
          style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted),
        ),
        const SizedBox(height: 16),
        ...routines.map((item) {
          final isSelected = _laundryRoutine == item['v'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 9.0),
            child: InkWell(
              onTap: () => setState(() => _laundryRoutine = item['v']!),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: NestlyTheme.transitionSmooth,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? NestlyColors.accent : NestlyColors.border,
                    width: 1.5,
                  ),
                  color: isSelected ? NestlyColors.accentSoft : Colors.white.withOpacity(0.85),
                  boxShadow: isSelected ? NestlyTheme.shadowSm : null,
                ),
                child: Row(
                  children: [
                    Text(item['icon']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['t']!,
                            style: const TextStyle(
                              fontFamily: NestlyTheme.fontSans,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: NestlyColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['d']!,
                            style: const TextStyle(
                              fontFamily: NestlyTheme.fontSans,
                              fontSize: 11,
                              color: NestlyColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: NestlyColors.sage,
                        ),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep6() {
    final stressPts = [
      {'k': 'morning', 'e': '🌅', 'l': 'Morning chaos', 'd': 'Rushed school runs, missing items, chaotic starts'},
      {'k': 'dinner', 'e': '🍲', 'l': 'Dinner planning panic', 'd': 'Last-minute scrambles, picky eaters, time crunch'},
      {'k': 'laundry', 'e': '🧺', 'l': 'Laundry pileup', 'd': 'Overflowing baskets, lost uniforms, chaos'},
      {'k': 'bedtime', 'e': '🌙', 'l': 'Long bedtime routines', 'd': 'Stalling, multiple trips, exhausting evenings'},
      {'k': 'schedules', 'e': '📅', 'l': 'School date tracking', 'd': 'Missed permission slips, surprise events'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Where is the friction?', style: NestlyTheme.serifHeading(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Select your stress zones. Nestly builds calming recommendations specifically for these.',
          style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted),
        ),
        const SizedBox(height: 20),
        ...stressPts.map((pt) {
          bool isActive = false;
          switch (pt['k']) {
            case 'morning':
              isActive = _stressMorning;
              break;
            case 'dinner':
              isActive = _stressDinner;
              break;
            case 'laundry':
              isActive = _stressLaundry;
              break;
            case 'bedtime':
              isActive = _stressBedtime;
              break;
            case 'schedules':
              isActive = _stressSchedules;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 9.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  switch (pt['k']) {
                    case 'morning':
                      _stressMorning = !_stressMorning;
                      break;
                    case 'dinner':
                      _stressDinner = !_stressDinner;
                      break;
                    case 'laundry':
                      _stressLaundry = !_stressLaundry;
                      break;
                    case 'bedtime':
                      _stressBedtime = !_stressBedtime;
                      break;
                    case 'schedules':
                      _stressSchedules = !_stressSchedules;
                      break;
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: NestlyTheme.transitionSmooth,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? NestlyColors.accent : NestlyColors.border,
                    width: 1.5,
                  ),
                  color: isActive ? NestlyColors.accentSoft : Colors.white.withOpacity(0.85),
                  boxShadow: isActive ? NestlyTheme.shadowXs : null,
                ),
                child: Row(
                  children: [
                    Text(pt['e']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pt['l']!,
                            style: const TextStyle(
                              fontFamily: NestlyTheme.fontSans,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: NestlyColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            pt['d']!,
                            style: const TextStyle(
                              fontFamily: NestlyTheme.fontSans,
                              fontSize: 10.5,
                              color: NestlyColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? NestlyColors.sage : Colors.transparent,
                        border: Border.all(
                          color: isActive ? NestlyColors.sage : NestlyColors.border,
                          width: 2.0,
                        ),
                      ),
                      child: isActive ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep7() {
    int activeStressCount = [
      _stressMorning,
      _stressDinner,
      _stressLaundry,
      _stressBedtime,
      _stressSchedules
    ].where((x) => x).length;

    final kidCount = _kids.where((k) => k.name.trim().isNotEmpty).length;

    final highlights = [
      '$_householdSize member household configured',
      kidCount > 0 ? '$kidCount child profile(s) ready' : 'No children added',
      'Laundry: $_laundryRoutine',
      '$activeStressCount stress zones covered',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [NestlyColors.accentSoft, NestlyColors.sageSoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: NestlyTheme.shadowLg,
                ),
                alignment: Alignment.center,
                child: const Text('🪹', style: TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 20),
              Text('Your Nest is Ready', style: NestlyTheme.serifHeading(fontSize: 24)),
              const SizedBox(height: 10),
              const Text(
                'We\'ve built a custom AI household profile with proactive tasks, colour-coded events, and personalised meal schedules — all designed to lower your family\'s cognitive load.',
                style: TextStyle(
                  fontFamily: NestlyTheme.fontSans,
                  fontSize: 13.5,
                  height: 1.7,
                  color: NestlyColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...highlights.map((t) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NestlyColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: NestlyColors.sage,
                    ),
                    child: const Icon(Icons.check, size: 11, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: NestlyColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NestlyColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 1) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: NestlyColors.border, width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_left, size: 15, color: NestlyColors.primary),
                    SizedBox(width: 4),
                    Text('Back', style: TextStyle(color: NestlyColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: NestlyColors.primary,
                foregroundColor: const Color(0xFFF8F3EE),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_step == _totalSteps ? '✨ Enter Nestly' : 'Continue'),
                  if (_step < _totalSteps) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 15),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildMiniInputDecoration(String label) {
    return InputDecoration(
      isDense: true,
      hintText: label,
      hintStyle: const TextStyle(color: NestlyColors.textSubtle, fontSize: 13.0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NestlyColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NestlyColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NestlyColors.primary),
      ),
    );
  }
}
