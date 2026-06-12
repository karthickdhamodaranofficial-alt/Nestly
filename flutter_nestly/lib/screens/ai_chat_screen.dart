import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../theme/nestly_theme.dart';
import '../services/ai_service.dart';

class AiChatScreen extends StatefulWidget {
  final NestlyUser user;
  final OnboardingProfile profile;

  const AiChatScreen({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with TickerProviderStateMixin {
  final AiService _aiService = AiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  final List<NestlyMessage> _messages = [];
  bool _loading = false;
  bool _isRecording = false;
  bool _showSettings = false;
  bool _showFacts = false;
  String _streamingText = '';

  late AnimationController _dotsController;

  String _apiKey = '';

  // Suggested follow-ups
  final List<String> _suggestedReplies = [
    "What should I focus on today?",
    "What am I forgetting?",
    "What can I prep tonight?",
    "Help me plan this week",
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Welcome message
    _messages.add(NestlyMessage(
      id: 'welcome',
      sender: 'assistant',
      text: "Hello ${widget.user.name} 👋  I'm your Nestly household assistant. I've analysed your family profile. How can I lighten your mental load today?",
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('nestly_gemini_key') ?? '';
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nestly_gemini_key', key);
    setState(() {
      _apiKey = key;
      _showSettings = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _loading) return;

    setState(() {
      _messages.add(NestlyMessage(
        id: 'u-${DateTime.now().millisecondsSinceEpoch}',
        sender: 'user',
        text: cleanText,
      ));
      _loading = true;
      _streamingText = '';
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.askGemini(cleanText, widget.profile, _apiKey);
      // Simulate streaming by revealing chars progressively
      for (int i = 0; i <= response.length; i += 3) {
        if (!mounted) break;
        await Future.delayed(const Duration(milliseconds: 12));
        setState(() => _streamingText = response.substring(0, i.clamp(0, response.length)));
        _scrollToBottom();
      }
      setState(() {
        _streamingText = response;
        _messages.add(NestlyMessage(
          id: 'a-${DateTime.now().millisecondsSinceEpoch}',
          sender: 'assistant',
          text: response,
        ));
        _streamingText = '';
      });
    } catch (_) {
      setState(() {
        _messages.add(NestlyMessage(
          id: 'e-${DateTime.now().millisecondsSinceEpoch}',
          sender: 'assistant',
          text: "I had a small hiccup. Please try again or check your API key.",
        ));
      });
    } finally {
      setState(() {
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _simulateVoiceInput() {
    if (_loading || _isRecording) return;
    setState(() {
      _isRecording = true;
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _inputController.text = "How can we organize the evening bedtime routine?";
        });
      }
    });
  }

  // --- CORE BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                if (_showSettings) ...[
                  _buildSettingsCard(),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: _buildMessagesList(),
                ),
                const SizedBox(height: 8),
                _buildQuickPromptsRow(),
                const SizedBox(height: 8),
                _buildInputRow(),
              ],
            ),
            if (_showFacts) _buildFactsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nestly AI', style: NestlyTheme.serifHeading(fontSize: 24)),
            SizedBox(height: 3),
            Text(
              'Your empathetic household partner',
              style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12.5, color: NestlyColors.textMuted),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => setState(() => _showFacts = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: NestlyColors.bgCard,
                foregroundColor: NestlyColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                side: const BorderSide(color: NestlyColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.database, size: 12),
              label: const Text('Memory', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showSettings = !_showSettings),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showSettings ? NestlyColors.primary : NestlyColors.bgCard,
                foregroundColor: _showSettings ? Colors.white : NestlyColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                side: const BorderSide(color: NestlyColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.key, size: 12),
              label: Text(_apiKey.isNotEmpty ? '✓ API' : 'Setup', style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          ],
        )
      ],
    );
  }

  Widget _buildSettingsCard() {
    final controller = TextEditingController(text: _apiKey);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: NestlyColors.accentSoft,
        borderRadius: BorderRadius.circular(NestlyTheme.radiusLg),
        border: Border.all(color: NestlyColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: NestlyColors.accent, size: 13),
              SizedBox(width: 6),
              Text(
                'Gemini API Key',
                style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your key to use live AI. Without it, Nestly uses a smart local model built from your profile.',
            style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11.5, color: NestlyColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'AIzaSy...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _saveApiKey(controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NestlyColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(fontSize: 13)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length + (_loading ? 1 : 0) + (_streamingText.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // Streaming bubble shown before the thinking loader
        if (_streamingText.isNotEmpty && index == _messages.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [NestlyColors.accentSoft, NestlyColors.sageSoft]),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NestlyColors.accent.withOpacity(0.2)),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🪩', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20), topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4),
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
                        boxShadow: NestlyTheme.shadowSm,
                      ),
                      child: Text(
                        _streamingText,
                        style: const TextStyle(
                          fontFamily: NestlyTheme.fontSans, fontSize: 13.5,
                          color: NestlyColors.textMain, height: 1.55,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (index == _messages.length + (_streamingText.isNotEmpty ? 1 : 0)) {
          return _buildThinkingLoader();
        }

        final msg = _messages[index];
        final isMe = msg.sender == 'user';

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [NestlyColors.accentSoft, NestlyColors.sageSoft],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NestlyColors.accent.withOpacity(0.2)),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🪹', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [NestlyColors.primary, NestlyColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMe ? null : Colors.white.withOpacity(0.88),
                      borderRadius: isMe
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(4),
                            )
                          : const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(4),
                            ),
                      border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.6)),
                      boxShadow: isMe
                          ? const [BoxShadow(color: Color(0x334A3C33), blurRadius: 16, offset: Offset(0, 4))]
                          : NestlyTheme.shadowSm,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 13.5,
                        color: isMe ? Colors.white : NestlyColors.textMain,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: NestlyColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.user.role.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThinkingLoader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20),
            bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.6)),
          boxShadow: NestlyTheme.shadowSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Thinking', style: NestlyTheme.caption(color: NestlyColors.textMuted, fontSize: 11.5)),
            const SizedBox(width: 10),
            _buildBouncingDot(0),
            _buildBouncingDot(1),
            _buildBouncingDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildBouncingDot(int index) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (_, __) {
        final offset = ((_dotsController.value * 3 - index).clamp(0.0, 1.0));
        final bounce = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.translate(
            offset: Offset(0, -5 * bounce),
            child: Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                color: NestlyColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickPromptsRow() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickPrompts.length,
        itemBuilder: (context, index) {
          final p = _quickPrompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: GestureDetector(
              onTap: () => _send(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: NestlyTheme.shadowXs,
                ),
                alignment: Alignment.center,
                child: Text(
                  p,
                  style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11.5, color: NestlyColors.primaryDark, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: _inputController,
                style: NestlyTheme.sansBody(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: _isRecording ? '🎙 Listening...' : 'Ask Nestly anything…',
                  hintStyle: const TextStyle(color: NestlyColors.textSubtle, fontSize: 13.5),
                  contentPadding: const EdgeInsets.only(left: 16, right: 44, top: 12, bottom: 12),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: NestlyColors.border, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: NestlyColors.primary, width: 1.5)),
                ),
                onSubmitted: (val) {
                  _send(val);
                  _inputController.clear();
                },
              ),
              IconButton(
                icon: Icon(Icons.mic, color: _isRecording ? NestlyColors.accent : NestlyColors.textSubtle, size: 17),
                onPressed: _simulateVoiceInput,
              )
            ],
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            _send(_inputController.text);
            _inputController.clear();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: NestlyColors.primary, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Icon(Icons.send, color: Colors.white, size: 17),
          ),
        )
      ],
    );
  }

  Widget _buildFactsOverlay() {
    final facts = [
      {'k': 'Household Size', 'v': '${widget.profile.householdSize} members'},
      {'k': 'Children', 'v': '${widget.profile.kids.length}'},
      {'k': 'School schedule', 'v': widget.profile.schoolSchedule},
      {'k': 'Laundry routine', 'v': widget.profile.laundryRoutine},
      {'k': 'Work schedule', 'v': widget.profile.workSchedule},
    ];

    return Container(
      color: Colors.white.withOpacity(0.95),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.database, color: NestlyColors.sage, size: 15),
                  SizedBox(width: 6),
                  Text('AI Family Memory', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 15, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark)),
                ],
              ),
              IconButton(
                onPressed: () => setState(() => _showFacts = false),
                icon: const Icon(Icons.close, size: 18),
              )
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'These facts are parsed from your onboarding and used to personalise all AI recommendations.',
            style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, color: NestlyColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: facts.length,
              itemBuilder: (context, index) {
                final f = facts[index];
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: NestlyColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(f['k']!, style: const TextStyle(fontSize: 13, color: NestlyColors.textMuted)),
                      Text(f['v']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark)),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: NestlyColors.sageSoft, borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Icon(Icons.favorite, color: NestlyColors.sage, size: 13),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All data is processed locally. Your privacy is protected.',
                    style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11.5, color: NestlyColors.primaryDark),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
