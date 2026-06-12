import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/nestly_theme.dart';

class AuthScreen extends StatefulWidget {
  final Function(NestlyUser) onAuthComplete;
  const AuthScreen({super.key, required this.onAuthComplete});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  // Tab: 0 = Sign In, 1 = Sign Up
  int _authTabIndex = 0;
  String _setupStep = 'auth';
  String? _familyAction;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _familyNameCtrl = TextEditingController();
  final _familyCodeCtrl = TextEditingController();

  String _familyRole = 'Mom';
  String _error = '';
  bool _loading = false;
  bool _showPassword = false;

  late AnimationController _logoAnim;
  late AnimationController _cardAnim;
  late Animation<double> _logoScale;
  late Animation<double> _cardSlide;

  final List<Map<String, String>> _roles = [
    {'key': 'Mom', 'label': 'Mom', 'emoji': '👩'},
    {'key': 'Dad', 'label': 'Dad', 'emoji': '👨'},
    {'key': 'Co-parent', 'label': 'Co-parent', 'emoji': '🤝'},
    {'key': 'Nanny', 'label': 'Nanny', 'emoji': '💼'},
    {'key': 'Grandparent', 'label': 'Grandparent', 'emoji': '👴'},
  ];

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _cardAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnim, curve: Curves.elasticOut),
    );
    _cardSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _logoAnim.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnim.forward();
    });
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    _cardAnim.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _familyNameCtrl.dispose();
    _familyCodeCtrl.dispose();
    super.dispose();
  }

  void _handleAuthSubmit() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty || (_authTabIndex == 1 && name.isEmpty)) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() { _error = ''; _loading = true; });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() { _loading = false; _setupStep = 'family-setup'; });
    });
  }

  void _handleSocialLogin(String provider) {
    setState(() { _error = ''; _loading = true; });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _loading = false;
          _nameCtrl.text = provider == 'Google' ? 'Sarah Miller' : 'Sarah Apple';
          _emailCtrl.text = '${provider.toLowerCase()}@nestly.com';
          _setupStep = 'family-setup';
        });
      }
    });
  }

  void _handleFamilySubmit() {
    final familyName = _familyNameCtrl.text.trim();
    final familyCode = _familyCodeCtrl.text.trim();

    if (_familyAction == 'create' && familyName.isEmpty) {
      setState(() => _error = 'Please name your household.');
      return;
    }
    if (_familyAction == 'join' && familyCode.isEmpty) {
      setState(() => _error = 'Please enter the invite code from your partner.');
      return;
    }

    setState(() { _error = ''; _loading = true; });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _loading = false);
        final email = _emailCtrl.text.trim();
        final name = _nameCtrl.text.trim();
        widget.onAuthComplete(NestlyUser(
          name: name.isNotEmpty ? name : email.split('@')[0],
          email: email,
          role: _familyRole,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestlyColors.bgBase,
      body: Stack(
        children: [
          // Decorative background blobs
          _buildBackground(),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_setupStep),
                        child: _setupStep == 'auth' ? _buildAuthStep() : _buildFamilyStep(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(children: [
      Positioned(
        top: -80, right: -60,
        child: Container(
          width: 280, height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              NestlyColors.accentSoft.withOpacity(0.7),
              Colors.transparent,
            ]),
          ),
        ),
      ),
      Positioned(
        bottom: -100, left: -80,
        child: Container(
          width: 320, height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              NestlyColors.sageSoft.withOpacity(0.8),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildAuthStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        // Animated logo
        Center(
          child: ScaleTransition(
            scale: _logoScale,
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: NestlyGradients.warmSunrise,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: NestlyColors.accent.withOpacity(0.22),
                        blurRadius: 32, offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('🪹', style: TextStyle(fontSize: 40)),
                ),
                const SizedBox(height: 16),
                Text('Nestly', style: NestlyTheme.serifHeading(fontSize: 32)),
                const SizedBox(height: 5),
                Text(
                  'Your proactive household COO',
                  style: NestlyTheme.caption(color: NestlyColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Animated card
        AnimatedBuilder(
          animation: _cardAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _cardSlide.value),
            child: Opacity(opacity: _cardAnim.value.clamp(0.0, 1.0), child: child),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NestlyColors.bgCard,
              borderRadius: BorderRadius.circular(NestlyTheme.radiusLg),
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
              boxShadow: NestlyTheme.shadowMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tab switcher
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: NestlyColors.bgMuted,
                    borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
                    border: Border.all(color: NestlyColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildAuthTab(0, 'Sign In'),
                      _buildAuthTab(1, 'Create Account'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_error.isNotEmpty) ...[
                  _buildErrorBanner(),
                  const SizedBox(height: 14),
                ],

                // Name field (sign up only)
                if (_authTabIndex == 1) ...[
                  Text('YOUR NAME', style: NestlyTheme.labelCaps()),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    style: NestlyTheme.sansBody(fontSize: 14),
                    decoration: NestlyTheme.inputDecoration(
                      hint: 'e.g. Sarah Miller',
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Text('EMAIL ADDRESS', style: NestlyTheme.labelCaps()),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: NestlyTheme.sansBody(fontSize: 14),
                  decoration: NestlyTheme.inputDecoration(
                    hint: 'name@household.com',
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                Text('PASSWORD', style: NestlyTheme.labelCaps()),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  style: NestlyTheme.sansBody(fontSize: 14),
                  decoration: NestlyTheme.inputDecoration(
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _showPassword = !_showPassword),
                      child: Icon(
                        _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 17,
                        color: NestlyColors.textSubtle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Primary CTA
                ElevatedButton(
                  onPressed: _loading ? null : _handleAuthSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NestlyColors.primaryDark,
                    foregroundColor: NestlyColors.textOnDark,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd)),
                    elevation: 4,
                    shadowColor: NestlyColors.primaryDark.withOpacity(0.3),
                  ),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ))
                      : Text(
                          _authTabIndex == 0 ? 'Enter Your Nest →' : 'Begin the Journey →',
                          style: const TextStyle(
                            fontFamily: NestlyTheme.fontSans,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                ),
                const SizedBox(height: 18),

                // Divider
                Row(children: [
                  const Expanded(child: Divider(color: NestlyColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR', style: NestlyTheme.labelCaps()),
                  ),
                  const Expanded(child: Divider(color: NestlyColors.border)),
                ]),
                const SizedBox(height: 16),

                // Social logins
                Row(
                  children: [
                    Expanded(child: _buildSocialButton(
                      label: 'Google',
                      color: const Color(0xFF4285F4),
                      icon: Icons.g_mobiledata,
                      onTap: () => _handleSocialLogin('Google'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSocialButton(
                      label: 'Apple',
                      color: Colors.black87,
                      icon: Icons.apple,
                      onTap: () => _handleSocialLogin('Apple'),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        // Privacy note
        Center(
          child: Text(
            '🔒  Your data stays private & local',
            style: NestlyTheme.caption(color: NestlyColors.textSubtle, fontSize: 11),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAuthTab(int index, String label) {
    final isSelected = _authTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _authTabIndex = index; _error = ''; }),
        child: AnimatedContainer(
          duration: NestlyTheme.transitionSmooth,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? NestlyColors.bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(NestlyTheme.radiusSm),
            boxShadow: isSelected ? NestlyTheme.shadowXs : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: NestlyTheme.fontSans,
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? NestlyColors.primaryDark : NestlyColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: _loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: NestlyColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NestlyTheme.radiusMd)),
        backgroundColor: NestlyColors.bgCard,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(label,
            style: const TextStyle(
              color: NestlyColors.textBody,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: NestlyTheme.fontSans,
            )),
        ],
      ),
    );
  }

  Widget _buildFamilyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              const Text('🏡', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text('Set Up Your Nest', style: NestlyTheme.serifHeading(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                'Connect with your partner and care team in real-time.',
                style: NestlyTheme.caption(color: NestlyColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NestlyColors.bgCard,
            borderRadius: BorderRadius.circular(NestlyTheme.radiusLg),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
            boxShadow: NestlyTheme.shadowMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error.isNotEmpty) ...[
                _buildErrorBanner(),
                const SizedBox(height: 14),
              ],
              if (_familyAction == null) ...[
                // Choose action
                _buildFamilyActionCard(
                  icon: '✨',
                  title: 'Create New Household',
                  subtitle: 'Start fresh and invite your partner',
                  onTap: () => setState(() => _familyAction = 'create'),
                  isPrimary: true,
                ),
                const SizedBox(height: 12),
                _buildFamilyActionCard(
                  icon: '🔗',
                  title: "Join Partner's Household",
                  subtitle: 'Enter the invite code you received',
                  onTap: () => setState(() => _familyAction = 'join'),
                  isPrimary: false,
                ),
              ] else ...[
                // Back
                TextButton.icon(
                  onPressed: () => setState(() { _familyAction = null; _error = ''; }),
                  icon: const Icon(Icons.arrow_back, size: 14, color: NestlyColors.textMuted),
                  label: const Text('Back', style: TextStyle(color: NestlyColors.textMuted, fontSize: 13)),
                ),
                const SizedBox(height: 12),

                // Role picker
                Text('YOUR ROLE IN THE FAMILY', style: NestlyTheme.labelCaps()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _roles.map((r) {
                    final isSelected = _familyRole == r['key'];
                    return GestureDetector(
                      onTap: () => setState(() => _familyRole = r['key']!),
                      child: AnimatedContainer(
                        duration: NestlyTheme.transitionFast,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? NestlyColors.sageSoft : NestlyColors.bgCard,
                          borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
                          border: Border.all(
                            color: isSelected ? NestlyColors.sage : NestlyColors.border,
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? NestlyTheme.shadowXs : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(r['emoji']!, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(r['label']!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? NestlyColors.sageDark : NestlyColors.textBody,
                              )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                if (_familyAction == 'create') ...[
                  Text('HOUSEHOLD NAME', style: NestlyTheme.labelCaps()),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _familyNameCtrl,
                    style: NestlyTheme.sansBody(fontSize: 14),
                    decoration: NestlyTheme.inputDecoration(
                      hint: 'e.g. The Miller Family Nest',
                      prefixIcon: Icons.home_outlined,
                    ),
                  ),
                ] else ...[
                  Text('INVITE CODE', style: NestlyTheme.labelCaps()),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _familyCodeCtrl,
                    style: NestlyTheme.sansBody(fontSize: 14),
                    decoration: NestlyTheme.inputDecoration(
                      hint: 'e.g. NEST-5421',
                      prefixIcon: Icons.vpn_key_outlined,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ask your partner for the code visible on their Dashboard.',
                    style: NestlyTheme.caption(color: NestlyColors.textSubtle, fontSize: 11.5),
                  ),
                ],
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : _handleFamilySubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NestlyColors.primaryDark,
                    foregroundColor: NestlyColors.textOnDark,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd)),
                    elevation: 4,
                  ),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Confirm & Enter Nest →',
                          style: TextStyle(fontFamily: NestlyTheme.fontSans, fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFamilyActionCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? NestlyColors.primaryDark : NestlyColors.bgCard,
          borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
          border: Border.all(
            color: isPrimary ? Colors.transparent : NestlyColors.border,
            width: 1.5,
          ),
          boxShadow: isPrimary ? NestlyTheme.shadowMd : NestlyTheme.shadowXs,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: TextStyle(
                      fontFamily: NestlyTheme.fontSans,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? Colors.white : NestlyColors.primaryDark,
                    )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: TextStyle(
                      fontFamily: NestlyTheme.fontSans,
                      fontSize: 11.5,
                      color: isPrimary ? Colors.white60 : NestlyColors.textMuted,
                    )),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
              size: 16,
              color: isPrimary ? Colors.white60 : NestlyColors.textSubtle),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: NestlyColors.dangerSoft,
        border: Border.all(color: NestlyColors.danger.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: NestlyColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error,
              style: const TextStyle(
                fontFamily: NestlyTheme.fontSans,
                color: NestlyColors.danger,
                fontSize: 13,
              )),
          ),
        ],
      ),
    );
  }
}
