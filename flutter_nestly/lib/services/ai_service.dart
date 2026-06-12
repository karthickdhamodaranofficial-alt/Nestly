import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AiService {
  static Future<String> askGemini(String prompt, OnboardingProfile profile, {String apiKey = '', String familyName = 'Family'}) async {
    if (apiKey.trim().isNotEmpty) {
      try {
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
        
        final kidsJson = jsonEncode(profile.kids.map((k) => k.toMap()).toList());
        final stressPointsJson = jsonEncode(profile.stressPoints.toMap());
        
        final systemInstruction = '''
You are Nestly, a calming, supportive, and proactive digital digital COO for a busy household.
Your tone is gentle, empathetic, organized, and emotionally intelligent.
Avoid robotic lists; speak like a supportive, wise friend.
Here is the household profile context:
- Family Name: $familyName
- Kids: $kidsJson
- School schedule: ${profile.schoolSchedule}
- Sports activities: ${profile.sportsActivities.isNotEmpty ? profile.sportsActivities : 'None'}
- Laundry routine: ${profile.laundryRoutine}
- Work schedules: ${profile.workSchedule}
- Main stress points: $stressPointsJson

Answer the user with this context in mind. Keep your response around 100-300 words.
''';

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': '$systemInstruction\nUser query: $prompt'}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 500,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            if (content != null) {
              final parts = content['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text'] as String?;
                if (text != null && text.trim().isNotEmpty) {
                  return text;
                }
              }
            }
          }
        }
      } catch (e) {
        // Fallback silently to local model
      }
    }

    // Graceful local fallback engine
    await Future.delayed(const Duration(seconds: 1));
    return _generateLocalResponse(prompt, profile, familyName);
  }

  static String _generateLocalResponse(String prompt, OnboardingProfile profile, String familyName) {
    final query = prompt.toLowerCase();
    final kidsNames = profile.kids.isNotEmpty
        ? profile.kids.map((k) => k.name).join(' and ')
        : 'the kids';

    // 1. WHAT CAN I PREP TONIGHT?
    if (query.contains('prep tonight') || 
        (query.contains('forgetting') && query.contains('tonight')) || 
        (query.contains('prep') && query.contains('evening'))) {
      String response = "Take a breath. Prepping tonight means a calmer tomorrow morning. Here is what you can prep in under 10 minutes:\n\n";

      if (profile.stressPoints.morning) {
        response += "• **Morning Rescue:** Prep the coffee maker now and set out breakfast bowls. Eliminating these small choices saves significant morning energy.\n";
      }

      if (profile.kids.isNotEmpty) {
        response += "• **Kid Gear:** Lay out outfits for $kidsNames. Have them pack their backpacks and place them by the front door tonight.\n";
      }

      if (profile.sportsActivities.trim().isNotEmpty) {
        response += "• **Activity Prep:** Pack the gear bags for ${profile.sportsActivities} and put them directly in the car trunk tonight.\n";
      }

      if (profile.laundryRoutine.toLowerCase().contains('daily')) {
        response += "• **Laundry Check:** Flip today's laundry load to the dryer now so you don't wake up to a damp pile.\n";
      }

      response += "\nGo ahead and do just one of these. The rest can wait. You're doing great.";
      return response;
    }

    // 2. WHAT AM I FORGETTING?
    if (query.contains('forgetting') || query.contains('forgot') || query.contains('reminder')) {
      String response = "Let's double-check. Based on your household rhythm, here is what might slip through the cracks:\n\n";

      if (profile.sportsActivities.trim().isNotEmpty) {
        response += "• **Sports Gear:** Check if uniforms for ${profile.sportsActivities} are clean and ready.\n";
      }

      if (profile.kids.isNotEmpty) {
        response += "• **School Folders:** Verify if there are permission slips or homework folders that need signing for $kidsNames.\n";
      }

      if (profile.stressPoints.dinner) {
        response += "• **Dinner Thaw:** If you are planning a meal tomorrow, check if any ingredients need to be moved from the freezer to the fridge tonight.\n";
      }

      response += "• **Self Care:** Have you taken 5 minutes just for yourself today? Don't forget that your well-being is the foundation of the household.";
      return response;
    }

    // 3. WHAT SHOULD I FOCUS ON TODAY?
    if (query.contains('focus') || query.contains('today') || query.contains('priorities')) {
      String response = "Good morning. Let's simplify your day. Today, try to let go of the non-essentials and focus on these critical flows:\n\n";

      if (profile.stressPoints.morning) {
        response += "1. **A Calm Departure:** Don't rush. Leaving 5 minutes later is better than leaving in chaos.\n";
      } else {
        response += "1. **Rhythm check:** Keep the morning transition steady.\n";
      }

      if (profile.sportsActivities.trim().isNotEmpty) {
        response += "2. **Activity Logistics:** Sports (${profile.sportsActivities}) are on the horizon. Coordinate who is driving and when.\n";
      } else if (profile.stressPoints.dinner) {
        response += "2. **Dinner Decision:** Decide what's for dinner before 4:00 PM. Knowing the plan prevents that late-afternoon panic.\n";
      } else {
        response += "2. **Household loop:** Close one small laundry or kitchen loop early.\n";
      }

      response += "3. **Parent connection:** Sync with your support system (partner or caretaker) for just 2 minutes around midday to align schedules.\n\nEverything else is bonus. Take it one step at a time.";
      return response;
    }

    // 4. HELP ME PLAN THIS WEEK
    if (query.contains('plan this week') || query.contains('week') || query.contains('upcoming')) {
      return """Let's map out the week ahead with minimal stress. Here is a calming layout:

• **Monday/Tuesday:** Focus on routine stability. Perfect days for standard school-run rhythms and getting your '${profile.laundryRoutine}' established.
• **Midweek (Wed):** Re-evaluate. Check grocery needs. If sports (${profile.sportsActivities.isNotEmpty ? profile.sportsActivities : 'extracurriculars'}) are active, make sure kids' water bottles and uniforms are aligned.
• **Thursday/Friday:** Wind down. Simplify meals. Make Friday dinner a "fun / easy night" (like leftover assembly or pizza) to reward yourself.
• **Weekend:** Rest over chores. Do a quick 10-minute household preview on Sunday evening so Monday doesn't catch you off guard.

How does that sound? We can adjust the pacing to match your work schedule (${profile.workSchedule}).""";
    }

    // 5. GENERIC CHAT FALLBACK
    return """I hear you, and I'm here to support. Running a household ($familyName) with kids ($kidsNames) while balancing work (${profile.workSchedule}) is a massive undertaking. 

Tell me, are you feeling overwhelmed right now? We can switch to **Simplify Mode** together, or I can help you break down a chore into micro-steps.""";
  }
}
