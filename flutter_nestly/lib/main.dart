import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/nestly_theme.dart';
import 'models/models.dart';
import 'services/db_service.dart';
import 'services/coparent_simulation.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/meals_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/simplify_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait + landscape (allow all orientations)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFFAF8F4),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final db = DbService();
  await db.init();

  runApp(const NestlyApp());
}

class NestlyApp extends StatelessWidget {
  const NestlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nestly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: NestlyTheme.fontSans,
        scaffoldBackgroundColor: NestlyColors.bgBase,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NestlyColors.primary,
          primary: NestlyColors.primary,
          secondary: NestlyColors.secondary,
          surface: NestlyColors.bgCard,
          background: NestlyColors.bgBase,
        ),
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.transparent,
        dividerColor: NestlyColors.border,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: NestlyColors.primary,
          selectionColor: Color(0x337D6B5D),
          selectionHandleColor: NestlyColors.primary,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return NestlyColors.sage;
            return Colors.transparent;
          }),
          side: const BorderSide(color: NestlyColors.borderStrong, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
      home: const NestlyAppContainer(),
    );
  }
}

// ─── Tab definition ───────────────────────────────────────────────────────────
class _TabDef {
  final String id;
  final IconData icon;
  final IconData iconFilled;
  final String label;
  const _TabDef(this.id, this.icon, this.iconFilled, this.label);
}

const _tabs = [
  _TabDef('dashboard', Icons.home_outlined, Icons.home_rounded, 'Home'),
  _TabDef('plan', Icons.checklist_outlined, Icons.checklist_rtl_rounded, 'Plan'),
  _TabDef('meals', Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Meals'),
  _TabDef('chat', Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI'),
];

// ─── App Container ────────────────────────────────────────────────────────────
class NestlyAppContainer extends StatefulWidget {
  const NestlyAppContainer({super.key});

  @override
  State<NestlyAppContainer> createState() => _NestlyAppContainerState();
}

class _NestlyAppContainerState extends State<NestlyAppContainer>
    with SingleTickerProviderStateMixin {
  final DbService _db = DbService();
  String _activeTab = 'dashboard';
  bool _simplifyMode = false;
  String? _syncToastMessage;

  late AnimationController _tabAnimController;

  @override
  void initState() {
    super.initState();

    _tabAnimController = AnimationController(
      vsync: this,
      duration: NestlyTheme.transitionSmooth,
    );

    _db.userNotifier.addListener(_onStateChanged);
    _db.profileNotifier.addListener(_onStateChanged);
    _checkSimulation();
  }

  @override
  void dispose() {
    _db.userNotifier.removeListener(_onStateChanged);
    _db.profileNotifier.removeListener(_onStateChanged);
    _tabAnimController.dispose();
    CoparentSimulation.stop();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
      _checkSimulation();
    }
  }

  void _checkSimulation() {
    final user = _db.userNotifier.value;
    final profile = _db.profileNotifier.value;

    if (user != null && profile != null && profile.onboarded) {
      CoparentSimulation.start(_db, (message) {
        if (mounted) {
          setState(() => _syncToastMessage = message);
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _syncToastMessage == message) {
              setState(() => _syncToastMessage = null);
            }
          });
        }
      });
    } else {
      CoparentSimulation.stop();
    }
  }

  void _handleTabSelect(String tabId) {
    if (tabId == _activeTab) return;
    HapticFeedback.selectionClick();
    setState(() => _activeTab = tabId);
    _tabAnimController.forward(from: 0);
  }

  void _handleToggleSimplify() {
    HapticFeedback.mediumImpact();
    setState(() => _simplifyMode = !_simplifyMode);
  }

  @override
  Widget build(BuildContext context) {
    final user = _db.userNotifier.value;
    final profile = _db.profileNotifier.value;

    return Scaffold(
      backgroundColor: NestlyColors.bgBase,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;

          Widget mainWidget;

          if (user == null) {
            mainWidget = AuthScreen(onAuthComplete: (u) => _db.saveUser(u));
          } else if (profile == null || !profile.onboarded) {
            mainWidget = OnboardingScreen(
              user: user,
              onOnboardingComplete: (p) => _db.saveProfile(p),
            );
          } else if (_simplifyMode) {
            mainWidget = SimplifyScreen(
              user: user,
              profile: profile,
              onExit: () => setState(() => _simplifyMode = false),
            );
          } else {
            mainWidget = _buildResponsiveScaffold(user, profile, isWide);
          }

          return Stack(
            children: [
              // Animated page switcher
              AnimatedSwitcher(
                duration: NestlyTheme.transitionSmooth,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.02, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_simplifyMode
                      ? 'simplify'
                      : user == null
                          ? 'auth'
                          : profile == null || !profile.onboarded
                              ? 'onboarding'
                              : _activeTab),
                  child: mainWidget,
                ),
              ),
              // Sync toast overlay
              if (_syncToastMessage != null) _buildSyncToast(_syncToastMessage!),
            ],
          );
        },
      ),
    );
  }

  // ─── Responsive Shell ───────────────────────────────────────────────────────
  Widget _buildResponsiveScaffold(
      NestlyUser user, OnboardingProfile profile, bool isWide) {
    Widget activeView;
    switch (_activeTab) {
      case 'dashboard':
        activeView = DashboardScreen(
          user: user,
          profile: profile,
          onToggleSimplify: _handleToggleSimplify,
          setActiveTab: _handleTabSelect,
        );
        break;
      case 'plan':
        activeView = PlanScreen(user: user, profile: profile);
        break;
      case 'meals':
        activeView = MealsScreen(user: user, profile: profile);
        break;
      case 'chat':
        activeView = AiChatScreen(user: user, profile: profile);
        break;
      default:
        activeView = DashboardScreen(
          user: user,
          profile: profile,
          onToggleSimplify: _handleToggleSimplify,
          setActiveTab: _handleTabSelect,
        );
    }

    if (isWide) {
      return _buildWideLayout(user, profile, activeView);
    } else {
      return _buildMobileLayout(profile, activeView);
    }
  }

  // ─── Wide (Tablet/Desktop) Layout ──────────────────────────────────────────
  Widget _buildWideLayout(
      NestlyUser user, OnboardingProfile profile, Widget activeView) {
    return Scaffold(
      backgroundColor: NestlyColors.bgBase,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(user, profile),
          // Main content
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28.0, vertical: 28.0),
                child: activeView,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(NestlyUser user, OnboardingProfile profile) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: NestlyColors.bgCard,
        border: Border(
          right: BorderSide(color: NestlyColors.border, width: 1.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: NestlyGradients.warmSunrise,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: NestlyColors.accentSoft.withOpacity(0.5)),
                      boxShadow: NestlyTheme.shadowXs,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🪹', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nestly',
                          style: NestlyTheme.serifHeading(fontSize: 18)),
                      Text(
                        'Household COO',
                        style: NestlyTheme.caption(
                            color: NestlyColors.textSubtle, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NestlyColors.bgMuted,
                  borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
                  border: Border.all(color: NestlyColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: NestlyGradients.sageGlow,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: NestlyColors.sageMid, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontFamily: NestlyTheme.fontSans,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: NestlyColors.sageDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontFamily: NestlyTheme.fontSans,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: NestlyColors.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.role,
                            style: NestlyTheme.caption(fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: NestlyColors.border, height: 1),
            ),
            const SizedBox(height: 12),

            // Nav items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('NAVIGATION',
                        style: NestlyTheme.labelCaps(fontSize: 9)),
                    const SizedBox(height: 8),
                    ..._tabs.map((tab) => _buildSidebarItem(tab)),
                  ],
                ),
              ),
            ),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Simplify mode toggle
                  GestureDetector(
                    onTap: _handleToggleSimplify,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: NestlyGradients.sageGlow,
                        borderRadius:
                            BorderRadius.circular(NestlyTheme.radiusMd),
                        border: Border.all(
                            color: NestlyColors.sage.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.spa,
                              size: 14, color: NestlyColors.sageDark),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Simplify Mode',
                              style: TextStyle(
                                fontFamily: NestlyTheme.fontSans,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: NestlyColors.sageDark,
                              ),
                            ),
                          ),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: NestlyColors.sage,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Reset button
                  GestureDetector(
                    onTap: _showLogoutDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: NestlyColors.bgMuted,
                        borderRadius:
                            BorderRadius.circular(NestlyTheme.radiusMd),
                        border: Border.all(color: NestlyColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout,
                              size: 14,
                              color: NestlyColors.textMuted.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Text(
                            'Reset App Data',
                            style: NestlyTheme.caption(
                                fontSize: 11.5,
                                color: NestlyColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(_TabDef tab) {
    final isSelected = _activeTab == tab.id;
    return GestureDetector(
      onTap: () => _handleTabSelect(tab.id),
      child: AnimatedContainer(
        duration: NestlyTheme.transitionSmooth,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? NestlyColors.primaryDark
              : Colors.transparent,
          borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
          boxShadow: isSelected ? NestlyTheme.shadowXs : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? tab.iconFilled : tab.icon,
              size: 18,
              color: isSelected ? Colors.white : NestlyColors.textMuted,
            ),
            const SizedBox(width: 10),
            Text(
              tab.label,
              style: TextStyle(
                fontFamily: NestlyTheme.fontSans,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : NestlyColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mobile Layout ─────────────────────────────────────────────────────────
  Widget _buildMobileLayout(OnboardingProfile profile, Widget activeView) {
    return Scaffold(
      backgroundColor: NestlyColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: activeView,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: NestlyColors.bgCard,
        border: Border(top: BorderSide(color: NestlyColors.border, width: 1)),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _tabs.map((tab) => _buildNavItem(tab)).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(_TabDef tab) {
    final isSelected = _activeTab == tab.id;
    return GestureDetector(
      onTap: () => _handleTabSelect(tab.id),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: NestlyTheme.transitionSmooth,
              curve: NestlyTheme.curveSmooth,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? NestlyColors.primaryDark.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(NestlyTheme.radiusFull),
              ),
              child: AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: NestlyTheme.transitionFast,
                child: Icon(
                  isSelected ? tab.iconFilled : tab.icon,
                  color: isSelected
                      ? NestlyColors.primaryDark
                      : NestlyColors.textSubtle,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: NestlyTheme.transitionFast,
              style: TextStyle(
                fontFamily: NestlyTheme.fontSans,
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? NestlyColors.primaryDark
                    : NestlyColors.textSubtle,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Logout Dialog ─────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NestlyTheme.radiusLg)),
        backgroundColor: NestlyColors.bgCard,
        elevation: 0,
        title: Column(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text('Reset App Data?',
                style: NestlyTheme.serifHeading(fontSize: 18),
                textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'This will clear your local household profile, task history, and log you out. This action cannot be undone.',
          style: NestlyTheme.sansBody(fontSize: 13, color: NestlyColors.textBody),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: NestlyColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NestlyTheme.radiusMd)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel',
                style: TextStyle(
                    color: NestlyColors.textMuted,
                    fontFamily: NestlyTheme.fontSans,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _db.logout();
              setState(() {
                _activeTab = 'dashboard';
                _simplifyMode = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NestlyColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NestlyTheme.radiusMd)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Reset Everything',
                style: TextStyle(
                    fontFamily: NestlyTheme.fontSans,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Sync Toast ─────────────────────────────────────────────────────────────
  Widget _buildSyncToast(String message) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: NestlyTheme.curveBounce,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -28 * (1.0 - value)),
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Material(
            elevation: 12,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                gradient: NestlyGradients.darkRich,
                borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  // Pulsing indicator
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (_, v, __) => Transform.scale(
                      scale: v,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: NestlyColors.sage,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.sync_rounded,
                      color: NestlyColors.accent, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFF8F3EE),
                        height: 1.4,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _syncToastMessage = null),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.close,
                          size: 13, color: Color(0x80F8F3EE)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
