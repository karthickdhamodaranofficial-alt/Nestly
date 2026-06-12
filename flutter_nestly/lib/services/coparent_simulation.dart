import 'dart:async';
import 'dart:math';
import 'db_service.dart';
import '../models/models.dart';

class CoparentSimulation {
  static Timer? _timer;
  static final Random _random = Random();

  static void start(DbService db, Function(String) onSyncNotification) {
    _timer?.cancel();

    // Trigger simulation checks every 25 seconds (matching React app's 25000ms interval)
    _timer = Timer.periodic(const Duration(seconds: 25), (timer) {
      final user = db.userNotifier.value;
      final profile = db.profileNotifier.value;
      if (user == null || profile == null) return;

      // 30% chance of triggering a sync simulation
      if (_random.nextDouble() >= 0.3) return;

      final coParentRole = user.role == 'Dad'
          ? 'Mom'
          : (user.role == 'Mom' ? 'Dad' : (_random.nextBool() ? 'Mom' : 'Dad'));
      final coParentName = coParentRole == 'Dad' ? 'David' : 'Sarah';

      final actionIndex = _random.nextInt(3);

      switch (actionIndex) {
        case 0:
          // Simulate: Complete a task
          final tasks = List<HouseholdTask>.from(db.tasksNotifier.value);
          final undone = tasks.where((t) => !t.done).toList();
          if (undone.isNotEmpty) {
            final randomTask = undone[_random.nextInt(undone.length)];
            final updated = randomTask.copyWith(done: true);
            db.saveTask(updated);
            db.addTimelineItem(coParentName, 'completed', updated.title);
            onSyncNotification('$coParentName completed: "${updated.title}"');
          }
          break;

        case 1:
          // Simulate: Add a task
          final titles = [
            'Pick up milk & bananas',
            'Double-check soccer jerseys',
            'Sanitize kids lunchboxes',
            'Water the garden plants',
          ];
          final title = titles[_random.nextInt(titles.length)];
          final tasks = db.tasksNotifier.value;
          if (!tasks.any((t) => t.title.toLowerCase() == title.toLowerCase())) {
            final newTask = HouseholdTask(
              id: 'task-sim-${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              category: 'Household',
              priority: 'Medium',
              assignee: coParentRole,
              dueDate: DateTime.now().toIso8601String().split('T')[0],
              recurring: 'None',
              notes: 'Added automatically by co-parent.',
              done: false,
            );
            db.saveTask(newTask);
            db.addTimelineItem(coParentName, 'added task', title);
            onSyncNotification('$coParentName added task: "$title"');
          }
          break;

        case 2:
          // Simulate: Update dinner preference
          final meals = Map<String, MealPlan>.from(db.mealsNotifier.value);
          final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
          
          // Get today's day name
          final todayInt = DateTime.now().weekday; // 1 = Mon, 7 = Sun
          final today = days[todayInt - 1];
          
          final currentMeal = meals[today] ?? MealPlan();
          final foodOptions = [
            'Creamy Tomato Soup',
            'Vegetable Stir Fry',
            'Sheet Pan Chicken',
            'Taco Night!',
          ];
          final selectedFood = foodOptions[_random.nextInt(foodOptions.length)];

          if (currentMeal.dinner != selectedFood) {
            meals[today] = MealPlan(
              breakfast: currentMeal.breakfast,
              lunch: currentMeal.lunch,
              dinner: selectedFood,
            );
            db.saveMeals(meals);
            db.addTimelineItem(coParentName, 'updated tonight\'s dinner to', selectedFood);
            onSyncNotification('$coParentName updated tonight\'s dinner to: "$selectedFood"');
          }
          break;
      }
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
