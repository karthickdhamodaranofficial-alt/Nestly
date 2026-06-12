/**
 * Nestly AI Assistant Service
 * Connects to Gemini API or falls back to a highly personalized, context-aware local intelligence engine.
 */

export async function askGemini(prompt, profile, apiKey = '') {
  // If an API key is provided, we can fetch from Gemini API
  if (apiKey && apiKey.trim() !== '') {
    try {
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          contents: [
            {
              role: 'user',
              parts: [{ text: `You are Nestly, a calming, supportive, and proactive digital COO for a busy household. 
Your tone is gentle, empathetic, organized, and emotionally intelligent. 
Avoid robotic lists; speak like a supportive, wise friend.
Here is the household profile context:
- Kids: ${JSON.stringify(profile.kids)}
- School schedule: ${profile.schoolSchedule}
- Sports activities: ${profile.sportsActivities || 'None'}
- Laundry routine: ${profile.laundryRoutine}
- Meal preferences: ${profile.mealPreferences}
- Work schedules: ${profile.workSchedule}
- Main stress points: ${JSON.stringify(profile.stressPoints)}

User query: ${prompt}` }]
            }
          ],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 500
          }
        })
      });

      const data = await response.json();
      if (data.candidates && data.candidates[0].content.parts[0].text) {
        return data.candidates[0].content.parts[0].text;
      }
    } catch (e) {
      console.warn('Gemini API Error, falling back to local model:', e);
    }
  }

  // Graceful Local Fallback Engine - tailored to onboarding answers
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(generateLocalResponse(prompt, profile));
    }, 1000);
  });
}

function generateLocalResponse(prompt, profile) {
  const query = prompt.toLowerCase();
  const kidsNames = profile.kids && profile.kids.length > 0
    ? profile.kids.map(k => k.name).join(' and ')
    : 'the kids';

  // 1. WHAT CAN I PREP TONIGHT?
  if (query.includes('prep tonight') || query.includes('forgetting') && query.includes('tonight') || query.includes('prep') && query.includes('evening')) {
    let response = `Take a breath. Prepping tonight means a calmer tomorrow morning. Here is what you can prep in under 10 minutes:\n\n`;
    
    if (profile.stressPoints?.mornings) {
      response += `• **Morning Rescue:** Prep the coffee maker now and set out breakfast bowls. Eliminating these small choices saves significant morning energy.\n`;
    }
    
    if (profile.kids?.length > 0) {
      response += `• **Kid Gear:** Lay out outfits for ${kidsNames}. Have them pack their backpacks and place them by the front door tonight.\n`;
    }
    
    if (profile.sportsActivities) {
      response += `• **Activity Prep:** Pack the gear bags for ${profile.sportsActivities} and put them directly in the car trunk tonight.\n`;
    }

    if (profile.laundryRoutine?.toLowerCase().includes('daily')) {
      response += `• **Laundry Check:** Flip today's laundry load to the dryer now so you don't wake up to a damp pile.\n`;
    }

    response += `\nGo ahead and do just one of these. The rest can wait. You're doing great.`;
    return response;
  }

  // 2. WHAT AM I FORGETTING?
  if (query.includes('forgetting') || query.includes('forgot') || query.includes('reminder')) {
    let response = `Let's double-check. Based on your household rhythm, here is what might slip through the cracks:\n\n`;

    if (profile.sportsActivities) {
      response += `• **Sports Gear:** Check if uniforms for ${profile.sportsActivities} are clean and ready.\n`;
    }

    if (profile.kids?.length > 0) {
      response += `• **School Folders:** Verify if there are permission slips or homework folders that need signing for ${kidsNames}.\n`;
    }

    if (profile.stressPoints?.dinner) {
      response += `• **Dinner Thaw:** If you are planning a meal tomorrow, check if any ingredients need to be moved from the freezer to the fridge tonight.\n`;
    }

    response += `• **Self Care:** Have you taken 5 minutes just for yourself today? Don't forget that your well-being is the foundation of the household.`;
    return response;
  }

  // 3. WHAT SHOULD I FOCUS ON TODAY?
  if (query.includes('focus') || query.includes('today') || query.includes('priorities')) {
    let response = `Good morning. Let's simplify your day. Today, try to let go of the non-essentials and focus on these critical flows:\n\n`;

    if (profile.stressPoints?.mornings) {
      response += `1. **A Calm Departure:** Don't rush. Leaving 5 minutes later is better than leaving in chaos.\n`;
    } else {
      response += `1. **Rhythm check:** Keep the morning transition steady.\n`;
    }

    if (profile.sportsActivities) {
      response += `2. **Activity Logistics:** Sports (${profile.sportsActivities}) are on the horizon. Coordinate who is driving and when.\n`;
    } else if (profile.stressPoints?.dinner) {
      response += `2. **Dinner Decision:** Decide what's for dinner before 4:00 PM. Knowing the plan prevents that late-afternoon panic.\n`;
    } else {
      response += `2. **Household loop:** Close one small laundry or kitchen loop early.\n`;
    }

    response += `3. **Parent connection:** Sync with your support system (partner or caretaker) for just 2 minutes around midday to align schedules.\n\nEverything else is bonus. Take it one step at a time.`;
    return response;
  }

  // 4. HELP ME PLAN THIS WEEK
  if (query.includes('plan this week') || query.includes('week') || query.includes('upcoming')) {
    return `Let's map out the week ahead with minimal stress. Here is a calming layout:

• **Monday/Tuesday:** Focus on routine stability. Perfect days for standard school-run rhythms and getting your 'Daily single load' of laundry established.
• **Midweek (Wed):** Re-evaluate. Check grocery needs. If sports (${profile.sportsActivities || 'extracurriculars'}) are active, make sure kids' water bottles and uniforms are aligned.
• **Thursday/Friday:** Wind down. Simplify meals. Make Friday dinner a "fun / easy night" (like leftover assembly or pizza) to reward yourself.
• **Weekend:** Rest over chores. Do a quick 10-minute household preview on Sunday evening so Monday doesn't catch you off guard.

How does that sound? We can adjust the pacing to match your work schedule (${profile.workSchedule}).`;
  }

  // 5. GENERIC CHAT FALLBACK
  return `I hear you, and I'm here to support. Running a household (${profile.familyName || 'the family'}) with kids (${kidsNames}) while balancing work (${profile.workSchedule}) is a massive undertaking. 

Tell me, are you feeling overwhelmed right now? We can switch to **Simplify Mode** together, or I can help you break down a chore into micro-steps.`;
}
