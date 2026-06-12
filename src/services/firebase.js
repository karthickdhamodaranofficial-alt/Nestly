/**
 * Nestly Firebase Service Wrapper
 * Includes standard Firebase configuration scaffolding and an active mock adapter
 * that uses LocalStorage to run in a standalone browser environment.
 */

// -------------------------------------------------------------
// Boilerplate for future production Firebase integration:
// -------------------------------------------------------------
/*
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore, doc, setDoc, onSnapshot } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "nestly-app.firebaseapp.com",
  projectId: "nestly-app",
  storageBucket: "nestly-app.appspot.com",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
*/

// -------------------------------------------------------------
// Active local-storage mock adapter for realtime simulation:
// -------------------------------------------------------------

// Helper to trigger callback updates simulating real-time listeners
const listeners = {
  tasks: [],
  profile: [],
  meals: [],
  events: []
};

function trigger(channel, data) {
  if (listeners[channel]) {
    listeners[channel].forEach(callback => callback(data));
  }
}

export const dbService = {
  // --- TASKS ---
  subscribeTasks(callback) {
    listeners.tasks.push(callback);
    // Send initial load
    const tasks = JSON.parse(localStorage.getItem('nestly_tasks') || '[]');
    callback(tasks);
    
    // Return unsubscribe function
    return () => {
      listeners.tasks = listeners.tasks.filter(cb => cb !== callback);
    };
  },

  saveTask(task) {
    const tasks = JSON.parse(localStorage.getItem('nestly_tasks') || '[]');
    const existingIdx = tasks.findIndex(t => t.id === task.id);
    
    if (existingIdx > -1) {
      tasks[existingIdx] = task;
    } else {
      tasks.push(task);
    }
    
    localStorage.setItem('nestly_tasks', JSON.stringify(tasks));
    trigger('tasks', tasks);
    return Promise.resolve(task);
  },

  deleteTask(taskId) {
    let tasks = JSON.parse(localStorage.getItem('nestly_tasks') || '[]');
    tasks = tasks.filter(t => t.id !== taskId);
    localStorage.setItem('nestly_tasks', JSON.stringify(tasks));
    trigger('tasks', tasks);
    return Promise.resolve(true);
  },

  // --- FAMILY PROFILE ---
  subscribeProfile(callback) {
    listeners.profile.push(callback);
    const profile = JSON.parse(localStorage.getItem('nestly_profile') || 'null');
    callback(profile);
    return () => {
      listeners.profile = listeners.profile.filter(cb => cb !== callback);
    };
  },

  saveProfile(profile) {
    localStorage.setItem('nestly_profile', JSON.stringify(profile));
    trigger('profile', profile);
    return Promise.resolve(profile);
  },

  // --- MEAL PLAN ---
  subscribeMeals(callback) {
    listeners.meals.push(callback);
    
    const meals = JSON.parse(localStorage.getItem('nestly_meals')) || {};
    callback(meals);
    return () => {
      listeners.meals = listeners.meals.filter(cb => cb !== callback);
    };
  },

  saveMeals(meals) {
    localStorage.setItem('nestly_meals', JSON.stringify(meals));
    trigger('meals', meals);
    return Promise.resolve(meals);
  },

  // --- CALENDAR EVENTS ---
  subscribeEvents(callback) {
    listeners.events.push(callback);
    
    const events = JSON.parse(localStorage.getItem('nestly_events')) || [];
    callback(events);
    return () => {
      listeners.events = listeners.events.filter(cb => cb !== callback);
    };
  },

  saveEvent(event) {
    const events = JSON.parse(localStorage.getItem('nestly_events') || '[]');
    const existingIdx = events.findIndex(e => e.id === event.id);
    
    if (existingIdx > -1) {
      events[existingIdx] = event;
    } else {
      events.push(event);
    }
    
    localStorage.setItem('nestly_events', JSON.stringify(events));
    trigger('events', events);
    return Promise.resolve(event);
  },

  deleteEvent(eventId) {
    let events = JSON.parse(localStorage.getItem('nestly_events') || '[]');
    events = events.filter(e => e.id !== eventId);
    localStorage.setItem('nestly_events', JSON.stringify(events));
    trigger('events', events);
    return Promise.resolve(true);
  }
};
