import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class DbService extends ChangeNotifier {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // Reactive state containers (ValueNotifiers/ChangeNotifiers)
  final ValueNotifier<NestlyUser?> userNotifier = ValueNotifier<NestlyUser?>(null);
  final ValueNotifier<OnboardingProfile?> profileNotifier = ValueNotifier<OnboardingProfile?>(null);
  final ValueNotifier<List<HouseholdTask>> tasksNotifier = ValueNotifier<List<HouseholdTask>>([]);
  final ValueNotifier<List<CalendarEvent>> eventsNotifier = ValueNotifier<List<CalendarEvent>>([]);
  final ValueNotifier<Map<String, MealPlan>> mealsNotifier = ValueNotifier<Map<String, MealPlan>>({});
  final ValueNotifier<List<ShoppingItem>> shoppingNotifier = ValueNotifier<List<ShoppingItem>>([]);
  final ValueNotifier<List<FamilyFeedItem>> timelineNotifier = ValueNotifier<List<FamilyFeedItem>>([]);

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    // Check version migration matching React's nestly_v2 check
    if (_prefs!.getBool('nestly_v2') != true) {
      await _prefs!.remove('nestly_user');
      await _prefs!.remove('nestly_profile');
      await _prefs!.remove('nestly_tasks');
      await _prefs!.remove('nestly_events');
      await _prefs!.remove('nestly_meals');
      await _prefs!.remove('nestly_shopping');
      await _prefs!.remove('nestly_timeline');
      await _prefs!.setBool('nestly_v2', true);
    }

    _loadUser();
    _loadProfile();
    _loadTasks();
    _loadEvents();
    _loadMeals();
    _loadShoppingList();
    _loadTimeline();

    _initialized = true;
  }

  // --- PERSISTENCE LOADERS ---
  void _loadUser() {
    final raw = _prefs?.getString('nestly_user');
    if (raw != null) {
      userNotifier.value = NestlyUser.fromMap(jsonDecode(raw));
    }
  }

  void _loadProfile() {
    final raw = _prefs?.getString('nestly_profile');
    if (raw != null) {
      profileNotifier.value = OnboardingProfile.fromMap(jsonDecode(raw));
    }
  }

  void _loadTasks() {
    final raw = _prefs?.getString('nestly_tasks');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      tasksNotifier.value = decoded.map((item) => HouseholdTask.fromMap(item)).toList();
    } else {
      // Seed default tasks
      _seedDefaultTasks();
    }
  }

  void _loadEvents() {
    final raw = _prefs?.getString('nestly_events');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      eventsNotifier.value = decoded.map((item) => CalendarEvent.fromMap(item)).toList();
    } else {
      _seedDefaultEvents();
    }
  }

  void _loadMeals() {
    final raw = _prefs?.getString('nestly_meals');
    if (raw != null) {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      mealsNotifier.value = decoded.map(
        (key, value) => MapEntry(key, MealPlan.fromMap(value)),
      );
    } else {
      _seedDefaultMeals();
    }
  }

  void _loadShoppingList() {
    final raw = _prefs?.getString('nestly_shopping');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      shoppingNotifier.value = decoded.map((item) => ShoppingItem.fromMap(item)).toList();
    } else {
      _seedDefaultShoppingList();
    }
  }

  void _loadTimeline() {
    final raw = _prefs?.getString('nestly_timeline');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      timelineNotifier.value = decoded.map((item) => FamilyFeedItem.fromMap(item)).toList();
    } else {
      _seedDefaultTimeline();
    }
  }

  // --- SEEDERS ---
  void _seedDefaultTasks() {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
    final list = [
      HouseholdTask(
        id: 'task-1',
        title: 'Prep kids backpacks & outfit layouts',
        category: 'Kids',
        priority: 'High',
        assignee: 'Mom',
        dueDate: todayStr,
        recurring: 'Daily',
        notes: 'Include permission slips and spare socks.',
        done: false,
      ),
      HouseholdTask(
        id: 'task-2',
        title: 'Restock milk and fresh berries',
        category: 'Meals',
        priority: 'Medium',
        assignee: 'Shared',
        dueDate: todayStr,
        recurring: 'None',
        notes: 'Need organic whole milk for toddler.',
        done: false,
      ),
      HouseholdTask(
        id: 'task-3',
        title: 'Fold clean laundry laundry mountain',
        category: 'Home',
        priority: 'Low',
        assignee: 'Dad',
        dueDate: todayStr,
        recurring: 'Weekly',
        notes: 'Get kids to help sort their socks.',
        done: false,
      ),
      HouseholdTask(
        id: 'task-4',
        title: 'Schedule pediatric dentist checkups',
        category: 'Kids',
        priority: 'Medium',
        assignee: 'Shared',
        dueDate: tomorrowStr,
        recurring: 'None',
        notes: 'Dr. Smile office.',
        done: false,
      ),
    ];
    saveTasks(list);
  }

  void _seedDefaultEvents() {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
    final list = [
      CalendarEvent(
        id: 'event-1',
        title: 'Kids Soccer Practice',
        time: '16:30',
        date: todayStr,
        member: 'Kids',
        notes: 'Wear green jerseys. Bring orange slices.',
        color: '#E6A15C',
      ),
      CalendarEvent(
        id: 'event-2',
        title: 'Mom Work Presentation',
        time: '10:00',
        date: todayStr,
        member: 'Mom',
        notes: 'Quarterly review. Block calendar.',
        color: '#8F9E8B',
      ),
      CalendarEvent(
        id: 'event-3',
        title: 'Family Swim Lessons',
        time: '11:00',
        date: tomorrowStr,
        member: 'Kids',
        notes: 'Rec center. Pack towels.',
        color: '#E6A15C',
      ),
    ];
    saveEvents(list);
  }

  void _seedDefaultMeals() {
    final map = {
      'Monday': MealPlan(breakfast: 'Berry smoothies & toast', lunch: 'Turkey wraps & cucumbers', dinner: 'Creamy Tomato Pasta'),
      'Tuesday': MealPlan(breakfast: 'Scrambled eggs & avocado', lunch: 'Leftover pasta', dinner: 'Taco Night!'),
      'Wednesday': MealPlan(breakfast: 'Oatmeal with honey', lunch: 'Hummus & pita plates', dinner: 'Slow Cooker Lentil Soup'),
      'Thursday': MealPlan(breakfast: 'Yogurt parfaits', lunch: 'Egg salad sandwiches', dinner: 'Sheet Pan Chicken & Veggies'),
      'Friday': MealPlan(breakfast: 'Pancake morning!', lunch: 'School lunch / leftovers', dinner: 'Homemade Pizza Night'),
      'Saturday': MealPlan(breakfast: 'French toast & bacon', lunch: 'Picnic at the park', dinner: 'BBQ Burgers & Salad'),
      'Sunday': MealPlan(breakfast: 'Bagels & cream cheese', lunch: 'Snack board / grazing', dinner: 'Slow Cooker Pot Roast'),
    };
    saveMeals(map);
  }

  void _seedDefaultShoppingList() {
    final list = [
      ShoppingItem(id: 'shop-1', title: 'Organic whole milk', category: 'Dairy & Eggs', done: false),
      ShoppingItem(id: 'shop-2', title: 'Avocados', category: 'Produce', done: false),
      ShoppingItem(id: 'shop-3', title: 'Sourdough bread', category: 'Pantry', done: false),
      ShoppingItem(id: 'shop-4', title: 'Toilet paper', category: 'Household', done: false),
    ];
    saveShoppingList(list);
  }

  void _seedDefaultTimeline() {
    final list = [
      FamilyFeedItem(id: 'feed-1', time: '2 hours ago', user: 'Mom', action: 'completed', task: 'Schedule pediatric dentist checkups'),
      FamilyFeedItem(id: 'feed-2', time: '4 hours ago', user: 'Dad', action: 'added task', task: 'Restock milk and fresh berries'),
    ];
    saveTimeline(list);
  }

  // --- SERVICES WRITE APIS ---

  Future<void> saveUser(NestlyUser? user) async {
    userNotifier.value = user;
    if (user != null) {
      await _prefs?.setString('nestly_user', jsonEncode(user.toMap()));
    } else {
      await _prefs?.remove('nestly_user');
    }
  }

  Future<void> saveProfile(OnboardingProfile? profile) async {
    profileNotifier.value = profile;
    if (profile != null) {
      await _prefs?.setString('nestly_profile', jsonEncode(profile.toMap()));
    } else {
      await _prefs?.remove('nestly_profile');
    }
  }

  Future<void> saveTasks(List<HouseholdTask> list) async {
    tasksNotifier.value = list;
    await _prefs?.setString('nestly_tasks', jsonEncode(list.map((item) => item.toMap()).toList()));
  }

  Future<void> saveTask(HouseholdTask task) async {
    final current = List<HouseholdTask>.from(tasksNotifier.value);
    final idx = current.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      current[idx] = task;
    } else {
      current.insert(0, task); // Prepend new task to top
    }
    await saveTasks(current);
  }

  Future<void> deleteTask(String id) async {
    final current = List<HouseholdTask>.from(tasksNotifier.value);
    current.removeWhere((t) => t.id == id);
    await saveTasks(current);
  }

  Future<void> saveEvents(List<CalendarEvent> list) async {
    eventsNotifier.value = list;
    await _prefs?.setString('nestly_events', jsonEncode(list.map((item) => item.toMap()).toList()));
  }

  Future<void> saveEvent(CalendarEvent event) async {
    final current = List<CalendarEvent>.from(eventsNotifier.value);
    final idx = current.indexWhere((e) => e.id == event.id);
    if (idx != -1) {
      current[idx] = event;
    } else {
      current.insert(0, event);
    }
    await saveEvents(current);
  }

  Future<void> deleteEvent(String id) async {
    final current = List<CalendarEvent>.from(eventsNotifier.value);
    current.removeWhere((e) => e.id == id);
    await saveEvents(current);
  }

  Future<void> saveMeals(Map<String, MealPlan> meals) async {
    mealsNotifier.value = meals;
    final map = meals.map((k, v) => MapEntry(k, v.toMap()));
    await _prefs?.setString('nestly_meals', jsonEncode(map));
  }

  Future<void> saveShoppingList(List<ShoppingItem> list) async {
    shoppingNotifier.value = list;
    await _prefs?.setString('nestly_shopping', jsonEncode(list.map((item) => item.toMap()).toList()));
  }

  Future<void> saveTimeline(List<FamilyFeedItem> list) async {
    timelineNotifier.value = list;
    await _prefs?.setString('nestly_timeline', jsonEncode(list.map((item) => item.toMap()).toList()));
  }

  Future<void> addTimelineItem(String user, String action, String task) async {
    final current = List<FamilyFeedItem>.from(timelineNotifier.value);
    final newItem = FamilyFeedItem(
      id: 'feed-${DateTime.now().millisecondsSinceEpoch}',
      time: 'Just now',
      user: user,
      action: action,
      task: task,
    );
    current.insert(0, newItem);
    await saveTimeline(current);
  }

  Future<void> logout() async {
    userNotifier.value = null;
    profileNotifier.value = null;
    tasksNotifier.value = [];
    eventsNotifier.value = [];
    mealsNotifier.value = {};
    shoppingNotifier.value = [];
    timelineNotifier.value = [];

    await _prefs?.remove('nestly_user');
    await _prefs?.remove('nestly_profile');
    await _prefs?.remove('nestly_tasks');
    await _prefs?.remove('nestly_events');
    await _prefs?.remove('nestly_meals');
    await _prefs?.remove('nestly_shopping');
    await _prefs?.remove('nestly_timeline');
  }
}
