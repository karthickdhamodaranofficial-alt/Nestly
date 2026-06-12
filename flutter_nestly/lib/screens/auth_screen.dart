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

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  String _setupStep = 'auth'; // 'auth' or 'family-setup'
  String? _familyAction; // 'create' or 'join'
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _familyCodeController = TextEditingController();
  
  String _familyRole = 'Mom';
  String _error = '';
  bool _loading = false;

  final List<Map<String, String>> _roles = [
    {'key': 'Mom', 'label': 'Mom', 'emoji': '👩‍🦰'},
    {'key': 'Dad', 'label': 'Dad', 'emoji': '👨‍🦱'},
    {'key': 'Co-parent', 'label': 'Co-parent', 'emoji': '🧑‍🤝‍🧑'},
    {'key': 'Nanny', 'label': 'Nanny', 'emoji': '👩‍⚕️'},
    {'key': 'Grandparent', 'label': 'Grandparent', 'emoji': '👵'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _familyNameController.dispose();
    _familyCodeController.dispose();
    super.dispose();
  }

  void _handleAuthSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isSignUp && name.isEmpty)) {
      setState(() {
        _error = 'Please fill in all fields.';
      });
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    // Simulate login server delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _loading = false;
          _setupStep = 'family-setup';
        });
      }
    });
  }

  void _handleThirdPartyLogin(String provider) {
    setState(() {
      _error = '';
      _loading = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _loading = false;
          _nameController.text = provider == 'Google' ? 'Sarah' : 'Sarah Apple';
          _emailController.text = '${provider.toLowerCase()}@nestly.com';
          _setupStep = 'family-setup';
        });
      }
    });
  }

  void _handleFamilySubmit() {
    final familyName = _familyNameController.text.trim();
    final familyCode = _familyCodeController.text.trim();

    if (_familyAction == 'create' && familyName.isEmpty) {
      setState(() {
        _error = 'Please name your household.';
      });
      return;
    }
    if (_familyAction == 'join' && familyCode.isEmpty) {
      setState(() {
        _error = 'Please enter an invite code.';
      });
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _loading = false;
        });

        final email = _emailController.text.trim();
        final name = _nameController.text.trim();
        final code = _familyAction == 'create'
            ? 'NEST-${1000 + Random().nextInt(9000)}'
            : familyCode.toUpperCase();

        final user = NestlyUser(
          name: name.isNotEmpty ? name : email.split('@')[0],
          email: email,
          role: _familyRole,
        );

        widget.onAuthComplete(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              if (_setupStep == 'auth') _buildAuthStep() else _buildFamilyStep(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo and Header
        Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NestlyColors.accentSoft, NestlyColors.sageSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(color: NestlyColors.accentSoft.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: NestlyColors.accent.withOpacity(0.2),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: const Text('🪹', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            Text('Nestly', style: NestlyTheme.serifHeading(fontSize: 30)),
            const SizedBox(height: 6),
            const Text(
              'Your proactive household COO',
              style: TextStyle(
                fontFamily: NestlyTheme.fontSans,
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                color: NestlyColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Auth Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          decoration: BoxDecoration(
            color: NestlyColors.bgCard.withOpacity(0.88),
            borderRadius: BorderRadius.circular(NestlyTheme.radiusLg),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: NestlyTheme.shadowMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: NestlyColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _isSignUp ? 'Create your family account' : 'Welcome back, parent',
                    style: const TextStyle(
                      fontFamily: NestlyTheme.fontSans,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: NestlyColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_error.isNotEmpty) _buildErrorBanner(),

              // Form fields
              if (_isSignUp) ...[
                Text('YOUR NAME', style: NestlyTheme.labelCaps()),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: NestlyTheme.sansBody(fontSize: 13.5),
                  decoration: _buildInputDecoration('e.g. Sarah Miller'),
                ),
                const SizedBox(height: 12),
              ],

              Text('EMAIL ADDRESS', style: NestlyTheme.labelCaps()),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: NestlyTheme.sansBody(fontSize: 13.5),
                decoration: _buildInputDecoration(
                  'name@household.com',
                  prefixIcon: Icons.mail_outline,
                ),
              ),
              const SizedBox(height: 12),

              Text('PASSWORD', style: NestlyTheme.labelCaps()),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: NestlyTheme.sansBody(fontSize: 13.5),
                decoration: _buildInputDecoration(
                  '••••••••',
                  prefixIcon: Icons.lock_outline,
                ),
              ),
              const SizedBox(height: 18),

              // Submit Button
              ElevatedButton(
                onPressed: _loading ? null : _handleAuthSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NestlyColors.primaryDark,
                  foregroundColor: const Color(0xFFF8F3EE),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
                  ),
                  elevation: 4,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login, size: 15),
                          const SizedBox(width: 8),
                          Text(_isSignUp ? 'Begin Journey' : 'Enter Nest'),
                        ],
                      ),
              ),

              const SizedBox(height: 18),
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: NestlyColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text('OR CONNECT SECURELY', style: NestlyTheme.labelCaps()),
                  ),
                  const Expanded(child: Divider(color: NestlyColors.border)),
                ],
              ),
              const SizedBox(height: 18),

              // OAuth Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => _handleThirdPartyLogin('Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: const BorderSide(color: NestlyColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.g_mobiledata, color: Color(0xFF4285F4), size: 22),
                          SizedBox(width: 4),
                          Text('Google', style: TextStyle(color: NestlyColors.textBody, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => _handleThirdPartyLogin('Apple'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: const BorderSide(color: NestlyColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, color: Colors.black, size: 16),
                          SizedBox(width: 6),
                          Text('Apple', style: TextStyle(color: NestlyColors.textBody, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Toggle sign up
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isSignUp ? 'Already have an account?' : "Don't have a household space?",
              style: const TextStyle(fontSize: 13, color: NestlyColors.textMuted),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                  _error = '';
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  _isSignUp ? 'Sign In' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 13,
                    color: NestlyColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildFamilyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Column(
          children: [
            const Text('🏡', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text('Set Up Your Nest', style: NestlyTheme.serifHeading(fontSize: 24)),
            const SizedBox(height: 6),
            const Text(
              'Sync with your partner or care providers in real-time.',
              style: TextStyle(
                fontFamily: NestlyTheme.fontSans,
                fontSize: 13,
                color: NestlyColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Card Content
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: NestlyColors.bgCard.withOpacity(0.88),
            borderRadius: BorderRadius.circular(NestlyTheme.radiusLg),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
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
                ElevatedButton(
                  onPressed: () => setState(() => _familyAction = 'create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NestlyColors.primaryDark,
                    foregroundColor: const Color(0xFFF8F3EE),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NestlyTheme.radiusMd)),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 15),
                      SizedBox(width: 8),
                      Text('Create New Household'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider(color: NestlyColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('— OR JOIN CO-PARENT —', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: NestlyColors.textSubtle, letterSpacing: 0.08)),
                    ),
                    Expanded(child: Divider(color: NestlyColors.border)),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _familyAction = 'join'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: NestlyColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NestlyTheme.radiusMd)),
                  ),
                  child: const Text('Join Partner\'s Household', style: TextStyle(color: NestlyColors.primary, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _familyAction = null;
                      _error = '';
                    }),
                    icon: const Icon(Icons.arrow_back, size: 14, color: NestlyColors.textMuted),
                    label: const Text('Back', style: TextStyle(color: NestlyColors.textMuted, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),

                // Role selection
                Text('YOUR ROLE', style: NestlyTheme.labelCaps()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roles.map((r) {
                    final isSelected = _familyRole == r['key'];
                    return InkWell(
                      onTap: () => setState(() => _familyRole = r['key']!),
                      borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            Text(r['emoji']!, style: const TextStyle(fontSize: 17)),
                            const SizedBox(width: 6),
                            Text(
                              r['label']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? NestlyColors.sageDark : NestlyColors.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Sub-action input
                if (_familyAction == 'create') ...[
                  Text('HOUSEHOLD NAME', style: NestlyTheme.labelCaps()),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _familyNameController,
                    style: NestlyTheme.sansBody(fontSize: 13.5),
                    decoration: _buildInputDecoration('e.g. Miller Family Nest'),
                  ),
                ] else ...[
                  Text('INVITE CODE', style: NestlyTheme.labelCaps()),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _familyCodeController,
                    style: NestlyTheme.sansBody(fontSize: 13.5),
                    decoration: _buildInputDecoration('e.g. NEST-5421'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ask your partner for the code in their Dashboard.',
                    style: TextStyle(fontSize: 11, color: NestlyColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : _handleFamilySubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NestlyColors.primaryDark,
                    foregroundColor: const Color(0xFFF8F3EE),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NestlyTheme.radiusMd)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward, size: 15),
                            SizedBox(width: 8),
                            Text('Confirm & Enter'),
                          ],
                        ),
                ),
              ]
            ],
          ),
        )
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: NestlyColors.dangerSoft,
        border: Border.all(color: NestlyColors.danger.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: NestlyColors.danger, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error,
              style: const TextStyle(
                fontFamily: NestlyTheme.fontSans,
                color: NestlyColors.danger,
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: NestlyColors.textSubtle, fontSize: 13.5),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: NestlyColors.textSubtle, size: 15) : null,
      filled: true,
      fillColor: NestlyColors.bgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
        borderSide: const BorderSide(color: NestlyColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
        borderSide: const BorderSide(color: NestlyColors.primary, width: 1.5),
      ),
    );
  }
}
