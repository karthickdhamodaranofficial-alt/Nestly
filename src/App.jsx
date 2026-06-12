import React, { useState, useEffect } from 'react';
import { Home, ClipboardList, Utensils, MessageSquare, Heart, LogOut } from 'lucide-react';

import Auth from './components/Auth';
import Onboarding from './components/Onboarding';
import Dashboard from './components/Dashboard';
import SimplifyScreen from './components/SimplifyScreen';
import Plan from './components/Plan';
import Meals from './components/Meals';
import AIChat from './components/AIChat';
import { dbService } from './services/firebase';

export default function App() {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [simplifyMode, setSimplifyMode] = useState(false);
  const [syncToast, setSyncToast] = useState(null);

  useEffect(() => {
    if (!localStorage.getItem('nestly_v2')) {
      ['nestly_tasks','nestly_meals','nestly_events','nestly_shopping'].forEach(k => localStorage.removeItem(k));
      localStorage.setItem('nestly_v2', '1');
    }
    const u = localStorage.getItem('nestly_user');
    const p = localStorage.getItem('nestly_profile');
    if (u) setUser(JSON.parse(u));
    if (p) setProfile(JSON.parse(p));
  }, []);

  useEffect(() => {
    if (!user || !profile) return;

    // Periodically simulate co-parent activity to demonstrate live-sync and co-parent features
    const interval = setInterval(() => {
      const coParentRole = user.role === 'Dad' ? 'Mom' : (user.role === 'Mom' ? 'Dad' : (Math.random() > 0.5 ? 'Mom' : 'Dad'));
      const coParentName = coParentRole === 'Dad' ? 'David' : 'Sarah';

      const simulations = [
        () => {
          // Complete a task
          const tasks = JSON.parse(localStorage.getItem('nestly_tasks') || '[]');
          const undone = tasks.filter(t => !t.done);
          if (undone.length > 0) {
            const randomTask = undone[Math.floor(Math.random() * undone.length)];
            const updated = { ...randomTask, done: true };
            dbService.saveTask(updated);
            setSyncToast(`${coParentName} completed: "${updated.title}"`);
            setTimeout(() => setSyncToast(null), 4000);
          }
        },
        () => {
          // Add a task
          const titles = [
            'Pick up milk & bananas',
            'Double-check soccer jerseys',
            'Sanitize kids lunchboxes',
            'Water the garden plants'
          ];
          const title = titles[Math.floor(Math.random() * titles.length)];
          const tasks = JSON.parse(localStorage.getItem('nestly_tasks') || '[]');
          if (!tasks.some(t => t.title === title)) {
            const newTask = {
              id: `task-sim-${Date.now()}`,
              title,
              category: 'Household',
              priority: 'Medium',
              assignee: coParentRole,
              dueDate: new Date().toISOString().split('T')[0],
              done: false
            };
            dbService.saveTask(newTask);
            setSyncToast(`${coParentName} added task: "${title}"`);
            setTimeout(() => setSyncToast(null), 4000);
          }
        },
        () => {
          // Update dinner preference
          const meals = JSON.parse(localStorage.getItem('nestly_meals') || '{}');
          const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
          const today = days[new Date().getDay()];
          const currentMeal = meals[today] || {};
          const foodOptions = ['Creamy Tomato Soup', 'Vegetable Stir Fry', 'Sheet Pan Chicken', 'Taco Night!'];
          const selectedFood = foodOptions[Math.floor(Math.random() * foodOptions.length)];
          
          if (currentMeal.dinner !== selectedFood) {
            meals[today] = { ...currentMeal, dinner: selectedFood };
            dbService.saveMeals(meals);
            setSyncToast(`${coParentName} updated tonight's dinner to: "${selectedFood}"`);
            setTimeout(() => setSyncToast(null), 4000);
          }
        }
      ];

      // 30% chance of triggering a sync simulation every 25 seconds
      if (Math.random() < 0.3) {
        const randomSim = simulations[Math.floor(Math.random() * simulations.length)];
        randomSim();
      }
    }, 25000);

    return () => clearInterval(interval);
  }, [user, profile]);

  const handleLogout = () => {
    ['nestly_user','nestly_profile','nestly_tasks','nestly_meals','nestly_events','nestly_shopping'].forEach(k=>localStorage.removeItem(k));
    setUser(null); setProfile(null); setSimplifyMode(false); setActiveTab('dashboard');
  };

  const renderScreen = () => {
    switch(activeTab) {
      case 'dashboard': return <Dashboard user={user} profile={profile} onToggleSimplify={()=>setSimplifyMode(s=>!s)} setActiveTab={setActiveTab}/>;
      case 'plan':      return <Plan user={user} profile={profile}/>;
      case 'meals':     return <Meals user={user} profile={profile}/>;
      case 'chat':      return <AIChat user={user} profile={profile}/>;
      default:          return <Dashboard user={user} profile={profile} onToggleSimplify={()=>setSimplifyMode(s=>!s)} setActiveTab={setActiveTab}/>;
    }
  };

  if (!user) return (
    <div className="nestly-app-container" style={{padding:'28px 24px',justifyContent:'center'}}>
      <Auth onAuthComplete={u=>{setUser(u);}} />
    </div>
  );

  if (!profile?.onboarded) return (
    <div className="nestly-app-container" style={{padding:'24px 20px'}}>
      <Onboarding user={user} onOnboardingComplete={p=>{setProfile(p);setActiveTab('dashboard');}} />
    </div>
  );

  if (simplifyMode) return (
    <div className="nestly-app-container simplify-active">
      <SimplifyScreen user={user} profile={profile} onExit={()=>setSimplifyMode(false)}/>
    </div>
  );

  const NAV = [
    { id:'dashboard', label:'Home',     Icon:Home },
    { id:'plan',      label:'Plan',     Icon:ClipboardList },
    { id:'meals',     label:'Meals',    Icon:Utensils },
    { id:'chat',      label:'AI',       Icon:MessageSquare },
  ];

  return (
    <div className="nestly-app-container">

      {/* Live co-parent toast */}
      {syncToast && (
        <div style={{ position:'absolute', top:'72px', left:'12px', right:'12px', zIndex:500, background:'rgba(30,24,18,0.9)', backdropFilter:'blur(16px)', color:'#F6EDE0', borderRadius:'16px', padding:'10px 16px', fontSize:'11.5px', fontWeight:'600', display:'flex', alignItems:'center', gap:'8px', boxShadow:'0 8px 32px rgba(0,0,0,0.3)', border:'1px solid rgba(255,255,255,0.08)', animation:'toast-in 0.3s var(--ease-bounce)' }}>
          <span style={{ width:'7px', height:'7px', borderRadius:'50%', background:'var(--color-accent)', flexShrink:0, boxShadow:'0 0 8px var(--color-accent)' }}/>
          {syncToast}
        </div>
      )}

      {/* Top Header */}
      <div className="app-header">
        <div style={{display:'flex',alignItems:'center',gap:'10px'}}>
          <div style={{width:'38px',height:'38px',borderRadius:'14px',background:'linear-gradient(145deg,#F6EDE0,#E5EDE4)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:'19px',boxShadow:'var(--shadow-sm)',border:'1px solid rgba(255,255,255,0.8)'}}>🪹</div>
          <div>
            <div style={{fontSize:'13.5px',fontWeight:'700',color:'var(--color-primary-dark)',lineHeight:1.2,letterSpacing:'-0.02em'}}>{profile.familyName||'Family Nest'}</div>
            <div style={{fontSize:'10px',color:'var(--color-text-muted)',display:'flex',alignItems:'center',gap:'4px',marginTop:'1px'}}>
              <span style={{width:'6px',height:'6px',background:'var(--color-sage)',borderRadius:'50%',display:'inline-block',boxShadow:'0 0 0 2px rgba(122,148,118,0.2)'}}/>
              {user.role} · Live
            </div>
          </div>
        </div>
        <div style={{display:'flex',alignItems:'center',gap:'7px'}}>
          <button onClick={()=>setSimplifyMode(s=>!s)} className="breathe-indicator" style={{border:'1px solid rgba(217,132,74,0.22)',background:'linear-gradient(145deg,#F6EDE0,#EDF0EC)',padding:'6px 14px',borderRadius:'20px',fontSize:'11.5px',fontWeight:'600',color:'var(--color-primary-dark)',cursor:'pointer',display:'flex',alignItems:'center',gap:'5px',boxShadow:'var(--shadow-xs)',letterSpacing:'-0.01em'}}>
            <Heart size={11} color="var(--color-accent)" fill="var(--color-accent)"/> Simplify
          </button>
          <button onClick={handleLogout} style={{background:'none',border:'none',color:'var(--color-text-subtle)',cursor:'pointer',padding:'6px',borderRadius:'8px',transition:'var(--transition-fast)'}} title="Sign Out">
            <LogOut size={16}/>
          </button>
        </div>
      </div>

      {/* Screen */}
      <div className="screen-content">{renderScreen()}</div>

      {/* Modal portal root — sits above screen-content, inside the clipping container */}
      <div id="nestly-modal-root" style={{position:'absolute',inset:0,zIndex:9999,pointerEvents:'none'}} />

      {/* Bottom Nav */}
      <div className="bottom-nav">
        {NAV.map(({id,label,Icon})=>{
          const active=activeTab===id;
          return (
            <button key={id} onClick={()=>setActiveTab(id)} className={`nav-item${active?' active':''}`}>
              <div className="nav-item-pill">
                <Icon size={18} strokeWidth={active?2.2:1.8}/>
              </div>
              <span className="nav-item-label">{label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
