import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/nestly_theme.dart';
import '../services/db_service.dart';

class MealsScreen extends StatefulWidget {
  final NestlyUser user;
  final OnboardingProfile profile;

  const MealsScreen({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final DbService _db = DbService();
  String _activeSubTab = 'planner'; // 'planner' or 'shopping'

  // Weekly Menu state
  Map<String, MealPlan> _meals = {};
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final Map<String, String> _mealEmojis = {'breakfast': '🥐', 'lunch': '🥪', 'dinner': '🍲'};

  // Shopping List state
  List<ShoppingItem> _shoppingList = [];
  final _newItemController = TextEditingController();
  String _newCategory = 'Produce';

  // Collapsed state for aisles
  final Map<String, bool> _collapsedAisles = {};

  final List<String> _categories = [
    'Produce',
    'Dairy & Eggs',
    'Pantry',
    'Meat & Seafood',
    'Household'
  ];

  final Map<String, Map<String, dynamic>> _catMeta = {
    'Produce': {'color': Color(0xFF7A9476), 'bg': Color(0xFFE5EDE4), 'icon': '🥦'},
    'Dairy & Eggs': {'color': Color(0xFFA496BB), 'bg': Color(0xFFF0EDF6), 'icon': '🥛'},
    'Pantry': {'color': Color(0xFFD9844A), 'bg': Color(0xFFF6EDE0), 'icon': '🫙'},
    'Meat & Seafood': {'color': Color(0xFFB87070), 'bg': Color(0xFFFAF0F0), 'icon': '🥩'},
    'Household': {'color': Color(0xFF8AADD8), 'bg': Color(0xFFEAF1FA), 'icon': '🧹'},
  };

  final List<Map<String, String>> _quickAdds = [
    {'title': 'Milk', 'category': 'Dairy & Eggs', 'emoji': '🥛'},
    {'title': 'Eggs', 'category': 'Dairy & Eggs', 'emoji': '🥚'},
    {'title': 'Bread', 'category': 'Pantry', 'emoji': '🍞'},
    {'title': 'Bananas', 'category': 'Produce', 'emoji': '🍌'},
    {'title': 'Cheese', 'category': 'Dairy & Eggs', 'emoji': '🧀'},
    {'title': 'Tomatoes', 'category': 'Produce', 'emoji': '🍅'},
    {'title': 'Chicken', 'category': 'Meat & Seafood', 'emoji': '🍗'},
    {'title': 'Rice', 'category': 'Pantry', 'emoji': '🍚'},
    {'title': 'Butter', 'category': 'Dairy & Eggs', 'emoji': '🧈'},
    {'title': 'Apples', 'category': 'Produce', 'emoji': '🍎'},
  ];

  @override
  void initState() {
    super.initState();
    _db.mealsNotifier.addListener(_updateMeals);
    _db.shoppingNotifier.addListener(_updateShopping);

    _updateMeals();
    _updateShopping();
  }

  @override
  void dispose() {
    _db.mealsNotifier.removeListener(_updateMeals);
    _db.shoppingNotifier.removeListener(_updateShopping);
    _newItemController.dispose();
    super.dispose();
  }

  void _updateMeals() {
    if (mounted) setState(() => _meals = _db.mealsNotifier.value);
  }

  void _updateShopping() {
    if (mounted) setState(() => _shoppingList = _db.shoppingNotifier.value);
  }

  String _getTodayDay() {
    final d = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    return _days[d - 1];
  }

  // --- PLANNERS METHODS ---

  void _showEditDaySheet(String day) {
    final plan = _meals[day];
    final bController = TextEditingController(text: plan?.breakfast ?? '');
    final lController = TextEditingController(text: plan?.lunch ?? '');
    final dController = TextEditingController(text: plan?.dinner ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NestlyColors.bgBase,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
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
                    Text('Plan Menu: $day', style: NestlyTheme.serifHeading(fontSize: 19)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 14),
                    )
                  ],
                ),
                const SizedBox(height: 18),
                Text('🥐 BREAKFAST', style: NestlyTheme.labelCaps()),
                const SizedBox(height: 5),
                TextField(
                  controller: bController,
                  style: NestlyTheme.sansBody(fontSize: 13.5),
                  decoration: const InputDecoration(hintText: 'e.g. Scrambled eggs & fruit'),
                ),
                const SizedBox(height: 12),
                Text('🥪 LUNCH', style: NestlyTheme.labelCaps()),
                const SizedBox(height: 5),
                TextField(
                  controller: lController,
                  style: NestlyTheme.sansBody(fontSize: 13.5),
                  decoration: const InputDecoration(hintText: 'e.g. Avocado toast or wrap'),
                ),
                const SizedBox(height: 12),
                Text('🍲 DINNER', style: NestlyTheme.labelCaps()),
                const SizedBox(height: 5),
                TextField(
                  controller: dController,
                  style: NestlyTheme.sansBody(fontSize: 13.5),
                  decoration: const InputDecoration(hintText: 'e.g. Chicken curry & rice'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final updatedMap = Map<String, MealPlan>.from(_meals);
                    updatedMap[day] = MealPlan(
                      breakfast: bController.text.trim(),
                      lunch: lController.text.trim(),
                      dinner: dController.text.trim(),
                    );
                    _db.saveMeals(updatedMap);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NestlyColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Day Plan'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- SHOPPING METHODS ---

  void _addUnique(List<ShoppingItem> arr, String title, String category) {
    final titleLower = title.toLowerCase();
    if (!arr.any((item) => item.title.toLowerCase() == titleLower)) {
      arr.add(ShoppingItem(
        id: 'gro-${DateTime.now().millisecondsSinceEpoch}-${Random().nextDouble()}',
        title: title,
        category: category,
        done: false,
      ));
    }
  }

  void _autoGenerateGroceries() {
    final list = List<ShoppingItem>.from(_shoppingList);
    _meals.values.forEach((m) {
      final d = m.dinner.toLowerCase();
      if (d.contains('pasta') || d.contains('mac')) {
        _addUnique(list, 'Pasta', 'Pantry');
        _addUnique(list, 'Shredded cheddar', 'Dairy & Eggs');
      }
      if (d.contains('taco')) {
        _addUnique(list, 'Taco shells', 'Pantry');
        _addUnique(list, 'Avocados', 'Produce');
      }
      if (d.contains('chicken') || d.contains('beef')) {
        _addUnique(list, 'Free-range chicken breast', 'Meat & Seafood');
      }
      if (d.contains('curry') || d.contains('lentil')) {
        _addUnique(list, 'Coconut milk', 'Pantry');
        _addUnique(list, 'Red lentils', 'Pantry');
      }
      if (d.contains('pizza')) {
        _addUnique(list, 'Pizza dough', 'Pantry');
        _addUnique(list, 'Mozzarella', 'Dairy & Eggs');
      }
      if (d.contains('stir fry') || d.contains('stir-fry')) {
        _addUnique(list, 'Soy sauce', 'Pantry');
        _addUnique(list, 'Mixed vegetables', 'Produce');
      }
    });

    _db.saveShoppingList(list);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: NestlyColors.primaryDark,
        content: Text(
          'Auto-compiled ingredients based on meals.',
          style: NestlyTheme.sansBody(fontSize: 12.5, color: Colors.white),
        ),
      ),
    );
  }

  void _addManualItem() {
    final text = _newItemController.text.trim();
    if (text.isEmpty) return;

    final list = List<ShoppingItem>.from(_shoppingList);
    list.add(ShoppingItem(
      id: 'gro-${DateTime.now().millisecondsSinceEpoch}',
      title: text,
      category: _newCategory,
      done: false,
    ));

    _db.saveShoppingList(list);
    _newItemController.clear();
  }

  void _addQuickItem(Map<String, String> item) {
    final title = item['title']!;
    final category = item['category']!;

    final list = List<ShoppingItem>.from(_shoppingList);
    if (list.any((i) => i.title.toLowerCase() == title.toLowerCase())) return;

    list.add(ShoppingItem(
      id: 'gro-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      done: false,
    ));

    _db.saveShoppingList(list);
  }

  void _toggleGrocery(ShoppingItem item) {
    final list = _shoppingList.map((i) {
      if (i.id == item.id) {
        return i.copyWith(done: !i.done);
      }
      return i;
    }).toList();
    _db.saveShoppingList(list);
  }

  void _deleteGrocery(ShoppingItem item) {
    final list = _shoppingList.where((i) => i.id != item.id).toList();
    _db.saveShoppingList(list);
  }

  void _clearDone() {
    final list = _shoppingList.where((i) => !i.done).toList();
    _db.saveShoppingList(list);
  }

  // --- CORE BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final pendingCount = _shoppingList.where((i) => !i.done).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768; // Tablet breakpoint

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.only(right: 16),
                        decoration: const BoxDecoration(
                          border: Border(right: BorderSide(color: NestlyColors.border)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Menu',
                              style: NestlyTheme.serifHeading(fontSize: 18, color: NestlyColors.primaryDark),
                            ),
                            const SizedBox(height: 12),
                            Expanded(child: _buildPlannerTab()),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Grocery',
                                  style: NestlyTheme.serifHeading(fontSize: 18, color: NestlyColors.primaryDark),
                                ),
                                if (pendingCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(color: NestlyColors.accent, borderRadius: BorderRadius.circular(99)),
                                    child: Text(
                                      '$pendingCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ]
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(child: _buildShoppingTab()),
                          ],
                        ),
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
            _buildHeader(),
            const SizedBox(height: 12),
            _buildSubTabBar(pendingCount),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: NestlyTheme.transitionSmooth,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _activeSubTab == 'planner'
                    ? KeyedSubtree(key: const ValueKey('planner'), child: _buildPlannerTab())
                    : KeyedSubtree(key: const ValueKey('shopping'), child: _buildShoppingTab()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meal Operations', style: NestlyTheme.serifHeading(fontSize: 24)),
        const SizedBox(height: 3),
        const Text(
          'Nourishing your household with clarity',
          style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 13, color: NestlyColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildSubTabBar(int pendingCount) {
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
              onTap: () => setState(() => _activeSubTab = 'planner'),
              child: AnimatedContainer(
                duration: NestlyTheme.transitionFast,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeSubTab == 'planner' ? NestlyColors.primaryDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(NestlyTheme.radiusSm),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 13, color: _activeSubTab == 'planner' ? Colors.white : NestlyColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Weekly Menu',
                      style: TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _activeSubTab == 'planner' ? Colors.white : NestlyColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeSubTab = 'shopping'),
              child: AnimatedContainer(
                duration: NestlyTheme.transitionFast,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeSubTab == 'shopping' ? NestlyColors.primaryDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(NestlyTheme.radiusSm),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 13, color: _activeSubTab == 'shopping' ? Colors.white : NestlyColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Grocery',
                      style: TextStyle(
                        fontFamily: NestlyTheme.fontSans,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _activeSubTab == 'shopping' ? Colors.white : NestlyColors.textMuted,
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: NestlyColors.accent, borderRadius: BorderRadius.circular(99)),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PLANNER TAB VIEW ---
  Widget _buildPlannerTab() {
    final todayDay = _getTodayDay();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        final plan = _meals[day] ?? MealPlan(breakfast: '', lunch: '', dinner: '');
        final hasData = plan.breakfast.isNotEmpty || plan.lunch.isNotEmpty || plan.dinner.isNotEmpty;
        final isToday = day == todayDay;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: NestlyColors.bgCard,
            gradient: isToday
                ? const LinearGradient(
                    colors: [Color(0xFFFFFEFB), Color(0xFFFEF8F2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(18),
            border: Border(
              left: BorderSide(
                color: isToday ? NestlyColors.accent : Colors.transparent,
                width: 3.0,
              ),
              top: const BorderSide(color: NestlyColors.border),
              right: const BorderSide(color: NestlyColors.border),
              bottom: const BorderSide(color: NestlyColors.border),
            ),
            boxShadow: NestlyTheme.shadowXs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(day, style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 14, fontWeight: FontWeight.bold, color: NestlyColors.primaryDark)),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: NestlyColors.accentSoft, borderRadius: BorderRadius.circular(6)),
                          child: const Text('TODAY', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 9.0, fontWeight: FontWeight.bold, color: NestlyColors.accentDeep, letterSpacing: 0.04)),
                        )
                      ]
                    ],
                  ),
                  TextButton(
                    onPressed: () => _showEditDaySheet(day),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      hasData ? 'Edit' : '+ Plan',
                      style: const TextStyle(color: NestlyColors.primary, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              if (hasData) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan.breakfast.isNotEmpty)
                      Expanded(child: _buildMealColumn('breakfast', plan.breakfast)),
                    if (plan.lunch.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildMealColumn('lunch', plan.lunch)),
                    ],
                    if (plan.dinner.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildMealColumn('dinner', plan.dinner)),
                    ],
                  ],
                )
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealColumn(String key, String meal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_valueToEmoji(key)} $key'.toUpperCase(),
            style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 9.0, color: NestlyColors.textSubtle, fontWeight: FontWeight.bold, letterSpacing: 0.06),
          ),
          const SizedBox(height: 2),
          Text(
            meal,
            style: TextStyle(
              fontFamily: NestlyTheme.fontSans,
              fontSize: 11.5,
              fontWeight: key == 'dinner' ? FontWeight.bold : FontWeight.w500,
              color: key == 'dinner' ? NestlyColors.primaryDark : NestlyColors.textBody,
              height: 1.3,
            ),
          )
        ],
      ),
    );
  }

  String _valueToEmoji(String key) {
    return _mealEmojis[key] ?? '🍲';
  }

  // --- SHOPPING TAB VIEW ---
  Widget _buildShoppingTab() {
    final totalCount = _shoppingList.length;
    final doneCount = _shoppingList.where((i) => i.done).length;
    final progress = totalCount > 0 ? (doneCount / totalCount) : 0.0;
    final allDone = totalCount > 0 && doneCount == totalCount;

    // Group shopping items by category
    final Map<String, List<ShoppingItem>> grouped = {};
    for (var cat in _categories) {
      grouped[cat] = _shoppingList.where((i) => i.category == cat).toList();
    }

    // Filter quick adds to exclude already-added ones
    final addedTitles = _shoppingList.map((i) => i.title.toLowerCase()).toSet();

    return Column(
      children: [
        // Summary bar
        if (totalCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: allDone ? const LinearGradient(colors: [Color(0xFFE8F0E7), Color(0xFFD9E8D7)]) : null,
              color: allDone ? null : Colors.white.withOpacity(0.75),
              border: Border.all(color: allDone ? const Color(0x4D7A9476) : Colors.white.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.07), borderRadius: BorderRadius.circular(99)),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [NestlyColors.sage, NestlyColors.sageDark]),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  allDone ? '✓ All done!' : '$doneCount/$totalCount done',
                  style: TextStyle(
                    fontFamily: NestlyTheme.fontSans,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: allDone ? NestlyColors.sageDark : NestlyColors.textMuted,
                  ),
                ),
                if (doneCount > 0) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearDone,
                    child: const Text('Clear ✓', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 10.5, fontWeight: FontWeight.bold, color: NestlyColors.danger)),
                  )
                ]
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Auto compile button
        ElevatedButton.icon(
          onPressed: _autoGenerateGroceries,
          style: ElevatedButton.styleFrom(
            backgroundColor: NestlyColors.accentSoft,
            foregroundColor: NestlyColors.primaryDark,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: NestlyColors.accent.withOpacity(0.2)),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.auto_awesome, size: 13, color: NestlyColors.accentDeep),
          label: const Text('Auto-Compile from Menu', style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),

        // Input row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _newItemController,
                style: NestlyTheme.sansBody(fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Add milk, apples…',
                  hintStyle: TextStyle(color: NestlyColors.textSubtle, fontSize: 13.5),
                ),
                onSubmitted: (_) => _addManualItem(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: NestlyColors.bgCard,
                  borderRadius: BorderRadius.circular(NestlyTheme.radiusMd),
                  border: Border.all(color: NestlyColors.border, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _newCategory,
                    isDense: true,
                    style: NestlyTheme.sansBody(fontSize: 13.5),
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _newCategory = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addManualItem,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: NestlyColors.primary, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),

        // Quick add chips
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _quickAdds.length,
            itemBuilder: (context, index) {
              final item = _quickAdds[index];
              final already = addedTitles.contains(item['title']!.toLowerCase());
              return Padding(
                padding: const EdgeInsets.only(right: 7.0),
                child: GestureDetector(
                  onTap: () => already ? null : _addQuickItem(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: already ? NestlyColors.sageSoft : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: already ? NestlyColors.sage.withOpacity(0.35) : NestlyColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (already) ...[
                          const Icon(Icons.check, size: 10, color: NestlyColors.sageDark),
                          const SizedBox(width: 4),
                        ] else ...[
                          Text(item['emoji']!, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          item['title']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: already ? NestlyColors.sageDark : NestlyColors.textMuted,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Grouped Aisles
        Expanded(
          child: totalCount == 0
              ? _buildEmptyState('🛒', 'Your list is empty\nTap a quick-add chip or type above.')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final items = grouped[cat] ?? [];
                    if (items.isEmpty) return const SizedBox();

                    final meta = _catMeta[cat]!;
                    final color = meta['color'] as Color;
                    final bg = meta['bg'] as Color;
                    final icon = meta['icon'] as String;

                    final activeCount = items.where((i) => !i.done).length;
                    final collapsed = _collapsedAisles[cat] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        border: Border.all(color: Colors.white.withOpacity(0.55)),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: NestlyTheme.shadowXs,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _collapsedAisles[cat] = !collapsed;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: bg,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        collapsed ? Icons.chevron_right : Icons.keyboard_arrow_down,
                                        size: 13,
                                        color: color,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$icon ${cat.toUpperCase()}',
                                        style: TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.06),
                                      )
                                    ],
                                  ),
                                  activeCount > 0
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
                                          child: Text('$activeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      : Text('✓ Done', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          if (!collapsed)
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
                              child: Column(
                                children: items.map((item) {
                                  return Dismissible(
                                    key: Key(item.id),
                                    direction: DismissDirection.horizontal,
                                    background: Container(
                                      margin: const EdgeInsets.only(top: 6.0),
                                      decoration: BoxDecoration(
                                        color: NestlyColors.sage,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    ),
                                    secondaryBackground: Container(
                                      margin: const EdgeInsets.only(top: 6.0),
                                      decoration: BoxDecoration(
                                        color: NestlyColors.danger,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                    ),
                                    confirmDismiss: (dir) async {
                                      if (dir == DismissDirection.startToEnd) {
                                        _toggleGrocery(item);
                                        return false; // don't remove, just toggle
                                      } else {
                                        _deleteGrocery(item);
                                        return false;
                                      }
                                    },
                                    child: AnimatedOpacity(
                                      duration: NestlyTheme.transitionSmooth,
                                      opacity: item.done ? 0.6 : 1.0,
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 6.0),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: item.done ? NestlyColors.sage.withOpacity(0.06) : NestlyColors.bgCard,
                                          borderRadius: BorderRadius.circular(13),
                                          border: Border.all(color: item.done ? NestlyColors.sage.withOpacity(0.15) : NestlyColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _toggleGrocery(item),
                                              child: AnimatedSwitcher(
                                                duration: NestlyTheme.transitionFast,
                                                child: Icon(
                                                  item.done ? Icons.check_circle : Icons.circle_outlined,
                                                  key: ValueKey(item.done),
                                                  color: item.done ? NestlyColors.sage : NestlyColors.borderStrong,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontFamily: NestlyTheme.fontSans,
                                                  fontSize: 13,
                                                  color: NestlyColors.textMain,
                                                  decoration: item.done ? TextDecoration.lineThrough : null,
                                                  fontWeight: item.done ? FontWeight.normal : FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
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
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontFamily: NestlyTheme.fontSans, fontSize: 12, color: NestlyColors.textMuted, fontStyle: FontStyle.italic, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
