import 'package:flutter/material.dart';
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
        ),
        useMaterial3: true,
      ),
      home: const NestlyAppContainer(),
    );
  }
}

class NestlyAppContainer extends StatefulWidget {
  const NestlyAppContainer({super.key});

  @override
  State<NestlyAppContainer> createState() => _NestlyAppContainerState();
}

class _NestlyAppContainerState extends State<NestlyAppContainer> {
  final DbService _db = DbService();
  String _activeTab = 'dashboard';
  bool _simplifyMode = false;
  String? _syncToastMessage;

  @override
  void initState() {
    super.initState();
    
    // Start listening to databases
    _db.userNotifier.addListener(_onStateChanged);
    _db.profileNotifier.addListener(_onStateChanged);

    // Initial check to start simulation
    _checkSimulation();
  }

  @override
  void dispose() {
    _db.userNotifier.removeListener(_onStateChanged);
    _db.profileNotifier.removeListener(_onStateChanged);
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
          setState(() {
            _syncToastMessage = message;
          });
          // Dismiss toast after 4 seconds
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted && _syncToastMessage == message) {
              setState(() {
                _syncToastMessage = null;
              });
            }
          });
        }
      });
    } else {
      CoparentSimulation.stop();
    }
  }

  void _handleTabSelect(String tabId) {
    setState(() {
      _activeTab = tabId;
    });
  }

  void _handleToggleSimplify() {
    setState(() {
      _simplifyMode = !_simplifyMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _db.userNotifier.value;
    final profile = _db.profileNotifier.value;

    // Outer backdrop: Elegant dark gradient matching body CSS
    return Scaffold(
      backgroundColor: const Color(0xFF16110D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.8),
            radius: 1.2,
            colors: [
              Color(0xFF2A1C14),
              Color(0xFF0D0A08),
              Color(0xFF111009),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Phone frame simulation constraints on wide screens
              final isWide = constraints.maxWidth > 480 && constraints.maxHeight > 500;
              final width = isWide ? 412.0 : constraints.maxWidth;
              final height = isWide ? 896.0 : constraints.maxHeight;

              Widget mainWidget;

              if (user == null) {
                mainWidget = AuthScreen(
                  onAuthComplete: (u) => _db.saveUser(u),
                );
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
                mainWidget = _buildTabScaffold(user, profile);
              }

              // Stack notification toasts on top of the screen content
              Widget screenWithToast = Stack(
                children: [
                  mainWidget,
                  if (_syncToastMessage != null) _buildSyncToast(_syncToastMessage!),
                ],
              );

              if (isWide) {
                // Return phone frame simulation wrapper
                return Container(
                  width: width,
                  height: height,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _simplifyMode ? NestlyColors.simplifyBgBase : NestlyColors.bgBase,
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(color: const Color(0xFF1A130E), width: 10.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 100,
                        spreadRadius: 0,
                        offset: Offset(0, 40),
                      ),
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 32,
                        spreadRadius: 0,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: screenWithToast,
                );
              } else {
                return SizedBox(
                  width: width,
                  height: height,
                  child: screenWithToast,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabScaffold(NestlyUser user, OnboardingProfile profile) {
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

    final isSimplify = _simplifyMode;
    final primaryColor = NestlyColors.getPrimary(isSimplify);
    final textMuted = NestlyColors.getTextMuted(isSimplify);
    final bgCard = NestlyColors.getBgCard(isSimplify);
    final border = NestlyColors.getBorder(isSimplify);

    return Scaffold(
      backgroundColor: NestlyColors.getBgBase(isSimplify),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: activeView,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgCard.withOpacity(0.95),
          border: Border(top: BorderSide(color: border, width: 1.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem('dashboard', Icons.home_outlined, Icons.home, 'Home', primaryColor, textMuted),
              _buildNavItem('plan', Icons.playlist_add_check, Icons.playlist_add_check, 'Plan', primaryColor, textMuted),
              _buildNavItem('meals', Icons.restaurant_outlined, Icons.restaurant, 'Meals', primaryColor, textMuted),
              _buildNavItem('chat', Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI', primaryColor, textMuted),
              _buildNavItem('logout', Icons.logout_outlined, Icons.logout, 'Reset', primaryColor, textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String tabId,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _activeTab == tabId;
    return GestureDetector(
      onTap: () {
        if (tabId == 'logout') {
          _showLogoutDialog();
        } else {
          _handleTabSelect(tabId);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: NestlyTheme.transitionFast,
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(
                fontFamily: NestlyTheme.fontSans,
                fontSize: 10.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.01,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NestlyTheme.radiusMd)),
          backgroundColor: NestlyColors.bgCard,
          title: Text('Reset App Data?', style: NestlyTheme.serifHeading(fontSize: 18)),
          content: Text(
            'This will clear your local household profile, task history, and log you out. Proceed?',
            style: NestlyTheme.sansBody(fontSize: 13, color: NestlyColors.textBody),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: NestlyColors.textMuted, fontFamily: NestlyTheme.fontSans, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _db.logout();
                setState(() {
                  _activeTab = 'dashboard';
                  _simplifyMode = false;
                });
              },
              child: const Text('Reset', style: TextStyle(color: NestlyColors.danger, fontFamily: NestlyTheme.fontSans, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncToast(String message) {
    return Positioned(
      top: 24,
      left: 14,
      right: 14,
      child: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * (1.0 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Material(
            elevation: 8,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3A2E26), Color(0xFF1E1812)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync, color: NestlyColors.accent, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFF8F3EE),
                      ),
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
