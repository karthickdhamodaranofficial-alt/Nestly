import 'dart:convert';

class NestlyUser {
  final String email;
  final String name;
  final String role;

  NestlyUser({required this.email, required this.name, required this.role});

  Map<String, dynamic> toMap() => {'email': email, 'name': name, 'role': role};
  factory NestlyUser.fromMap(Map<String, dynamic> map) {
    return NestlyUser(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
    );
  }
}

class KidProfile {
  final String name;
  final int age;
  KidProfile({required this.name, required this.age});
  Map<String, dynamic> toMap() => {'name': name, 'age': age};
  factory KidProfile.fromMap(Map<String, dynamic> map) {
    return KidProfile(
      name: map['name'] ?? '',
      age: map['age'] is int ? map['age'] : int.tryParse(map['age'].toString()) ?? 0,
    );
  }
}

class StressPoints {
  final bool morning;
  final bool dinner;
  final bool bedtime;
  final bool laundry;
  final bool sports;

  StressPoints({
    this.morning = false,
    this.dinner = false,
    this.bedtime = false,
    this.laundry = false,
    this.sports = false,
  });

  Map<String, dynamic> toMap() => {
    'morning': morning,
    'dinner': dinner,
    'bedtime': bedtime,
    'laundry': laundry,
    'sports': sports,
  };

  factory StressPoints.fromMap(Map<String, dynamic> map) {
    return StressPoints(
      morning: map['morning'] == true,
      dinner: map['dinner'] == true,
      bedtime: map['bedtime'] == true,
      laundry: map['laundry'] == true,
      sports: map['sports'] == true,
    );
  }
}

class OnboardingProfile {
  final int householdSize;
  final List<KidProfile> kids;
  final String schoolSchedule;
  final String laundryRoutine;
  final String workSchedule;
  final String sportsActivities;
  final StressPoints stressPoints;

  OnboardingProfile({
    required this.householdSize,
    required this.kids,
    required this.schoolSchedule,
    required this.laundryRoutine,
    required this.workSchedule,
    required this.sportsActivities,
    required this.stressPoints,
  });

  Map<String, dynamic> toMap() => {
    'householdSize': householdSize,
    'kids': kids.map((k) => k.toMap()).toList(),
    'schoolSchedule': schoolSchedule,
    'laundryRoutine': laundryRoutine,
    'workSchedule': workSchedule,
    'sportsActivities': sportsActivities,
    'stressPoints': stressPoints.toMap(),
  };

  factory OnboardingProfile.fromMap(Map<String, dynamic> map) {
    var kidsList = map['kids'] as List? ?? [];
    return OnboardingProfile(
      householdSize: map['householdSize'] is int ? map['householdSize'] : int.tryParse(map['householdSize'].toString()) ?? 3,
      kids: kidsList.map((k) => KidProfile.fromMap(Map<String, dynamic>.from(k))).toList(),
      schoolSchedule: map['schoolSchedule'] ?? '',
      laundryRoutine: map['laundryRoutine'] ?? '',
      workSchedule: map['workSchedule'] ?? '',
      sportsActivities: map['sportsActivities'] ?? '',
      stressPoints: map['stressPoints'] != null
          ? StressPoints.fromMap(Map<String, dynamic>.from(map['stressPoints']))
          : StressPoints(),
    );
  }
}

class HouseholdTask {
  final String id;
  final String title;
  final String category;
  final String priority;
  final String assignee;
  final String dueDate;
  final String recurring;
  final String notes;
  final bool done;

  HouseholdTask({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.assignee,
    required this.dueDate,
    required this.recurring,
    required this.notes,
    required this.done,
  });

  HouseholdTask copyWith({
    String? id,
    String? title,
    String? category,
    String? priority,
    String? assignee,
    String? dueDate,
    String? recurring,
    String? notes,
    bool? done,
  }) {
    return HouseholdTask(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      recurring: recurring ?? this.recurring,
      notes: notes ?? this.notes,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'priority': priority,
    'assignee': assignee,
    'dueDate': dueDate,
    'recurring': recurring,
    'notes': notes,
    'done': done,
  };

  factory HouseholdTask.fromMap(Map<String, dynamic> map) {
    return HouseholdTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'Home',
      priority: map['priority'] ?? 'Medium',
      assignee: map['assignee'] ?? 'Shared',
      dueDate: map['dueDate'] ?? '',
      recurring: map['recurring'] ?? 'None',
      notes: map['notes'] ?? '',
      done: map['done'] == true,
    );
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String time;
  final String date;
  final String member;
  final String notes;
  final String color;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.time,
    required this.date,
    required this.member,
    required this.notes,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'time': time,
    'date': date,
    'member': member,
    'notes': notes,
    'color': color,
  };

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      time: map['time'] ?? '',
      date: map['date'] ?? '',
      member: map['member'] ?? 'Kids',
      notes: map['notes'] ?? '',
      color: map['color'] ?? '#7D6B5D',
    );
  }
}

class MealPlan {
  final String breakfast;
  final String lunch;
  final String dinner;

  MealPlan({
    this.breakfast = '',
    this.lunch = '',
    this.dinner = '',
  });

  Map<String, dynamic> toMap() => {
    'breakfast': breakfast,
    'lunch': lunch,
    'dinner': dinner,
  };

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      breakfast: map['breakfast'] ?? '',
      lunch: map['lunch'] ?? '',
      dinner: map['dinner'] ?? '',
    );
  }
}

class FamilyFeedItem {
  final String id;
  final String time;
  final String user;
  final String action;
  final String task;

  FamilyFeedItem({
    required this.id,
    required this.time,
    required this.user,
    required this.action,
    required this.task,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'time': time,
    'user': user,
    'action': action,
    'task': task,
  };

  factory FamilyFeedItem.fromMap(Map<String, dynamic> map) {
    return FamilyFeedItem(
      id: map['id'] ?? '',
      time: map['time'] ?? '',
      user: map['user'] ?? '',
      action: map['action'] ?? '',
      task: map['task'] ?? '',
    );
  }
}

class ShoppingItem {
  final String id;
  final String title;
  final String category;
  final bool done;

  ShoppingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.done,
  });

  ShoppingItem copyWith({
    String? id,
    String? title,
    String? category,
    bool? done,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'done': done,
  };

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'Produce',
      done: map['done'] == true,
    );
  }
}
