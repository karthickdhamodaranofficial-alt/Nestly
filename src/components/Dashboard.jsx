import { useState, useEffect } from 'react';
import {
  Sparkles, Calendar, Utensils, CheckCircle2,
  ArrowRight, Play, Pause, Music, Smile, X, TrendingUp
} from 'lucide-react';
import { dbService } from '../services/firebase';

export default function Dashboard({ user, profile, onToggleSimplify, setActiveTab }) {
  const [tasks, setTasks] = useState([]);
  const [events, setEvents] = useState([]);
  const [meals, setMeals] = useState({});
  const [timeline, setTimeline] = useState([]);
  const [isPlaying, setIsPlaying] = useState(false);
  const [activeTrack, setActiveTrack] = useState('Cozy Rainfall');
  const [aiTips, setAiTips] = useState([]);
  const [notif, setNotif] = useState({ show: false, message: '' });

  const getDayLoad = (offset) => {
    const d = new Date(); d.setDate(d.getDate() + offset);
    const count = events.filter(e => e.date === d.toISOString().split('T')[0]).length;
    if (count === 0) return 'Calm';
    if (count <= 2) return 'Moderate';
    return 'Busy';
  };

  const getCurrentDay = () => ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][new Date().getDay()];

  const getDynamicGreeting = () => {
    const h = new Date().getHours();
    if (h >= 5 && h < 12) return `Good morning, ${user.name}. ☀️`;
    if (h >= 12 && h < 17) return `Good afternoon, ${user.name}.`;
    if (h >= 17 && h < 21) return `Good evening, ${user.name}. 🌆`;
    return `Quiet night, ${user.name}. 🌙`;
  };

  const getSubGreeting = () => {
    const h = new Date().getHours();
    if (profile?.stressPoints?.dinner && h >= 16) return "Tonight may feel busy — focus only on dinner and the kids' gear.";
    if (h < 12) return "Morning checklist is looking good. Focus on only 3 priorities today.";
    return "You have a lighter afternoon. Keep tasks brief and take time to breathe.";
  };

  const dismissTip = (id) => setAiTips(prev => prev.filter(t => t.id !== id));

  const handleToggleTask = (task) => {
    const updated = { ...task, done: !task.done };
    dbService.saveTask(updated);
    setTimeline(prev => [{ id: Date.now(), time: 'Just now', user: user.name, action: updated.done ? 'completed' : 'reopened', task: updated.title }, ...prev]);
  };

  useEffect(() => {
    const u1 = dbService.subscribeTasks(setTasks);
    const u2 = dbService.subscribeEvents(setEvents);
    const u3 = dbService.subscribeMeals(setMeals);
    return () => { u1(); u2(); u3(); };
  }, []);

  useEffect(() => {
    if (!profile) return;
    const tips = [];
    if (profile.sportsActivities) tips.push({ id: 'tip-sports', icon: '⚽', title: 'Pack sports gear early', description: `${profile.sportsActivities} practice is approaching. Toss water bottles and uniforms in the car before 2 PM.`, actionText: 'Add to tasks', action: () => { dbService.saveTask({ id: `task-sports-ai-${Date.now()}`, title: 'Load sports gear into trunk', category: 'Kids', priority: 'High', assignee: user.role, dueDate: new Date().toISOString().split('T')[0], done: false }); dismissTip('tip-sports'); } });
    if (profile.stressPoints?.dinner) tips.push({ id: 'tip-dinner', icon: '🍲', title: 'Calm the dinner rush', description: `Prep tonight's dinner (${meals[getCurrentDay()]?.dinner || 'pasta'}) during lunch to bypass the 4 PM crunch.`, actionText: 'Remind me at 12 PM', action: () => dismissTip('tip-dinner') });
    if (profile.stressPoints?.laundry || profile.laundryRoutine?.includes('Daily')) tips.push({ id: 'tip-laundry', icon: '🧺', title: 'Small laundry loop', description: 'Running one load before 3 PM keeps the basket empty. Don\'t let it pile up.', actionText: 'Log laundry started', action: () => dismissTip('tip-laundry') });
    if (tips.length === 0) tips.push({ id: 'tip-calm', icon: '🫁', title: 'Take a breathing moment', description: 'You\'ve completed 3 tasks today. The rest can wait. Take 2 minutes for yourself.', actionText: 'Enter Simplify Mode', action: onToggleSimplify });
    setAiTips(tips);
  }, [profile, meals]);

  const totalCount = tasks.length;
  const completedCount = tasks.filter(t => t.done).length;
  const progressPct = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;
  const undoneTasks = tasks.filter(t => !t.done);
  const priorityTasks = undoneTasks.slice(0, 4);
  const currentHour = new Date().getHours();
  const isOverwhelmed = undoneTasks.length > 5 || currentHour >= 20;
  const upcomingEvents = events.slice(0, 2);

  const getNextDays = () => {
    const names = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    return Array.from({ length: 5 }, (_, i) => {
      const d = new Date(); d.setDate(d.getDate() + i);
      return { dayName: names[d.getDay()], dateNum: d.getDate(), load: getDayLoad(i), active: i === 0 };
    });
  };

  const LOAD_COLORS = { Calm: 'var(--color-sage)', Moderate: 'var(--color-lavender)', Busy: 'var(--color-accent)' };
  const LOAD_BG    = { Calm: 'var(--color-sage-soft)', Moderate: 'var(--color-lavender-soft)', Busy: 'var(--color-accent-soft)' };

  const avatarStyle = (name) => {
    const n = name?.toLowerCase() || '';
    if (n.includes('mom')) return 'avatar-mom';
    if (n.includes('dad')) return 'avatar-dad';
    return 'avatar-shared';
  };

  return (
    <div className="fade-in">

      {/* Greeting Banner */}
      <div style={{
        background: 'linear-gradient(145deg, #F6EDE0 0%, #EDF0EC 55%, #EAF1FA 100%)',
        border: '1px solid rgba(255,255,255,0.9)',
        borderRadius: '26px',
        padding: '22px 20px',
        marginBottom: '14px',
        position: 'relative',
        overflow: 'hidden',
        boxShadow: '0 2px 12px rgba(46,38,31,0.07)',
      }}>
        {/* Decorative orbs */}
        <div style={{ position: 'absolute', top: '-30px', right: '-24px', width: '110px', height: '110px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(217,132,74,0.18) 0%, transparent 70%)', pointerEvents: 'none' }} />
        <div style={{ position: 'absolute', bottom: '-20px', left: '-16px', width: '80px', height: '80px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(122,148,118,0.14) 0%, transparent 70%)', pointerEvents: 'none' }} />

        <h1 className="font-serif-heading" style={{ fontSize: '23px', color: 'var(--color-primary-dark)', marginBottom: '8px', lineHeight: 1.25 }}>
          {getDynamicGreeting()}
        </h1>
        <p style={{ color: 'var(--color-text-muted)', fontSize: '12.5px', lineHeight: '1.55', fontStyle: 'italic', borderLeft: '2.5px solid var(--color-sage)', paddingLeft: '10px' }}>
          {getSubGreeting()}
        </p>

        {/* Progress pill */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '16px' }}>
          <div style={{ flex: 1, height: '5px', background: 'rgba(255,255,255,0.65)', borderRadius: '99px', overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${progressPct}%`, background: 'linear-gradient(90deg, var(--color-sage), var(--color-sage-dark))', borderRadius: '99px', transition: 'width 0.7s var(--ease-spring)' }} />
          </div>
          <span style={{ fontSize: '11px', fontWeight: '700', color: 'var(--color-sage-dark)', whiteSpace: 'nowrap' }}>
            {completedCount}/{totalCount} done
          </span>
        </div>
      </div>

      {/* Overwhelm Detection */}
      {isOverwhelmed && (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '13px 16px', marginBottom: '13px', background: 'linear-gradient(145deg, #FEF3E8, #FDF6EE)', border: '1px solid rgba(217,132,74,0.22)', borderRadius: '18px', boxShadow: 'var(--shadow-xs)' }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: '12.5px', fontWeight: '700', color: 'var(--color-primary-dark)', marginBottom: '2px' }}>
              {currentHour >= 20 ? '🌙 It\'s getting late' : `🧠 ${undoneTasks.length} tasks still pending`}
            </div>
            <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>Simplify Mode can help you wind down.</div>
          </div>
          <button onClick={onToggleSimplify} style={{ background: 'var(--color-accent)', color: 'white', border: 'none', borderRadius: '12px', padding: '8px 14px', fontSize: '11px', fontWeight: '700', cursor: 'pointer', flexShrink: 0, marginLeft: '12px', boxShadow: 'var(--shadow-accent)' }}>
            Simplify
          </button>
        </div>
      )}

      {/* Co-parent Notification */}
      {notif.show && (
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '11px 15px', marginBottom: '13px',
          background: 'rgba(229,237,228,0.9)', backdropFilter: 'blur(16px)',
          border: '1px solid rgba(122,148,118,0.22)', borderRadius: '16px',
          boxShadow: 'var(--shadow-xs)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '9px' }}>
            <span style={{ fontSize: '15px' }}>🤝</span>
            <span style={{ fontSize: '12.5px', color: 'var(--color-primary-dark)', fontWeight: '500', lineHeight: 1.4 }}>{notif.message}</span>
          </div>
          <button onClick={() => setNotif({ show: false, message: '' })} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-subtle)', padding: '3px', borderRadius: '6px', flexShrink: 0, marginLeft: '8px' }}>
            <X size={13} />
          </button>
        </div>
      )}

      {/* Today's Priorities */}
      <div className="glass-card" style={{ borderLeft: '3px solid var(--color-sage)', paddingLeft: '17px' }}>
        <div className="section-header" style={{ marginBottom: '14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '7px' }}>
            <CheckCircle2 size={15} color="var(--color-sage)" />
            <span style={{ fontSize: '13.5px', fontWeight: '700', color: 'var(--color-primary-dark)', letterSpacing: '-0.02em' }}>Today's Priorities</span>
          </div>
          <button onClick={() => setActiveTab('plan')} style={{ background: 'none', border: 'none', color: 'var(--color-accent-deep)', fontSize: '11.5px', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '2px', opacity: 0.85 }}>
            All <ArrowRight size={11} />
          </button>
        </div>

        {priorityTasks.length === 0 ? (
          <p style={{ color: 'var(--color-text-muted)', fontSize: '13px', fontStyle: 'italic', textAlign: 'center', padding: '10px 0' }}>
            🎉 All priorities checked! Enjoy the calm.
          </p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '11px' }}>
            {priorityTasks.map(task => (
              <div key={task.id} style={{ display: 'flex', alignItems: 'flex-start', gap: '10px' }}>
                <input
                  type="checkbox"
                  className="custom-checkbox"
                  checked={task.done}
                  onChange={() => handleToggleTask(task)}
                  style={{ marginTop: '1px' }}
                />
                <div style={{ flex: 1 }}>
                  <span style={{ fontSize: '13px', fontWeight: '500', color: task.done ? 'var(--color-text-subtle)' : 'var(--color-text-main)', textDecoration: task.done ? 'line-through' : 'none', lineHeight: 1.4 }}>
                    {task.title}
                  </span>
                  <div style={{ display: 'flex', gap: '5px', marginTop: '4px', alignItems: 'center' }}>
                    <span className="chip chip-accent">{task.category}</span>
                    <span style={{ fontSize: '10px', color: 'var(--color-text-subtle)', fontWeight: '500' }}>· {task.assignee}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Ambient Soundscape */}
      <div className="glass-card" style={{ padding: '13px 17px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{ width: '40px', height: '40px', borderRadius: '13px', background: isPlaying ? 'linear-gradient(145deg, var(--color-accent-soft), #FAE8D2)' : 'var(--color-bg-base)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: `1px solid ${isPlaying ? 'rgba(217,132,74,0.28)' : 'var(--color-border)'}`, transition: 'var(--transition-smooth)', boxShadow: isPlaying ? 'var(--shadow-accent)' : 'var(--shadow-xs)' }}>
            <Music size={16} color={isPlaying ? 'var(--color-accent-deep)' : 'var(--color-text-muted)'} />
          </div>
          <div>
            <div style={{ fontSize: '12.5px', fontWeight: '700', color: 'var(--color-primary-dark)', letterSpacing: '-0.015em' }}>Ambient Soundscape</div>
            <select value={activeTrack} onChange={e => setActiveTrack(e.target.value)} style={{ border: 'none', background: 'transparent', fontSize: '11px', color: 'var(--color-text-muted)', outline: 'none', fontWeight: '600', padding: 0, cursor: 'pointer', marginTop: '1px' }}>
              <option>Cozy Rainfall</option>
              <option>Evening Fireplace</option>
              <option>Soft Forest Noise</option>
            </select>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {isPlaying && (
            <div className="sound-wave">
              {[0.1, 0.35, 0.2, 0.45, 0.15].map((d, i) => (
                <span key={i} className="sound-wave-bar" style={{ animationDelay: `${d}s` }} />
              ))}
            </div>
          )}
          <button onClick={() => setIsPlaying(p => !p)} style={{ width: '36px', height: '36px', borderRadius: '50%', border: 'none', background: isPlaying ? 'var(--color-accent)' : 'var(--color-primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', transition: 'var(--transition-bounce)', boxShadow: isPlaying ? 'var(--shadow-accent)' : 'var(--shadow-sm)' }}>
            {isPlaying ? <Pause size={14} /> : <Play size={14} style={{ marginLeft: '2px' }} />}
          </button>
        </div>
      </div>

      {/* Weekly Load Forecast */}
      <div className="glass-card" style={{ padding: '16px 18px' }}>
        <div className="section-header" style={{ marginBottom: '14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '7px' }}>
            <TrendingUp size={14} color="var(--color-primary)" strokeWidth={2.2} />
            <span style={{ fontSize: '13px', fontWeight: '700', color: 'var(--color-primary-dark)', letterSpacing: '-0.02em' }}>Weekly Load</span>
          </div>
          <span style={{ fontSize: '10px', color: 'var(--color-text-subtle)', fontWeight: '600', letterSpacing: '0.04em', textTransform: 'uppercase' }}>5-day forecast</span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: '5px' }}>
          {getNextDays().map((day, i) => (
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '9px 4px', borderRadius: '14px', background: day.active ? LOAD_BG[day.load] : 'transparent', border: day.active ? `1px solid ${LOAD_COLORS[day.load]}44` : '1px solid transparent', transition: 'var(--transition-smooth)', boxShadow: day.active ? 'var(--shadow-xs)' : 'none' }}>
              <span style={{ fontSize: '9px', color: day.active ? 'var(--color-text-muted)' : 'var(--color-text-subtle)', fontWeight: '700', letterSpacing: '0.04em', textTransform: 'uppercase' }}>{day.dayName}</span>
              <span style={{ fontSize: '16px', fontWeight: '800', color: day.active ? 'var(--color-primary-dark)' : 'var(--color-text-main)', margin: '4px 0', letterSpacing: '-0.02em' }}>{day.dateNum}</span>
              <div style={{ width: '7px', height: '7px', borderRadius: '50%', background: LOAD_COLORS[day.load], boxShadow: `0 0 0 2px ${LOAD_COLORS[day.load]}33` }} />
              <span style={{ fontSize: '7px', color: 'var(--color-text-subtle)', marginTop: '4px', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{day.load}</span>
            </div>
          ))}
        </div>
      </div>

      {/* AI Recommendations */}
      {aiTips.length > 0 && (
        <div style={{ marginBottom: '13px' }}>
          <div className="section-title" style={{ marginBottom: '10px' }}>
            <Sparkles size={11} color="var(--color-accent)" />
            AI Recommendations
          </div>
          <div className="scroll-row">
            {aiTips.map(tip => (
              <div key={tip.id} style={{ flex: '0 0 88%', background: 'linear-gradient(145deg, #F9EEE0 0%, #FFFEFB 100%)', border: '1px solid rgba(217,132,74,0.18)', borderRadius: '20px', padding: '16px', boxShadow: '0 4px 20px rgba(217,132,74,0.08)' }}>
                <div style={{ fontSize: '22px', marginBottom: '9px', lineHeight: 1 }}>{tip.icon}</div>
                <h3 style={{ fontSize: '13px', fontWeight: '700', color: 'var(--color-primary-dark)', marginBottom: '5px', letterSpacing: '-0.02em' }}>{tip.title}</h3>
                <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', lineHeight: '1.55', marginBottom: '13px' }}>{tip.description}</p>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <button onClick={tip.action} style={{ background: 'linear-gradient(145deg, var(--color-primary), var(--color-primary-dark))', color: '#F8F3EE', border: 'none', borderRadius: '10px', padding: '7px 14px', fontSize: '11px', fontWeight: '600', cursor: 'pointer', boxShadow: '0 2px 8px rgba(46,38,31,0.18)' }}>{tip.actionText}</button>
                  <button onClick={() => dismissTip(tip.id)} style={{ background: 'none', border: 'none', color: 'var(--color-text-subtle)', fontSize: '11px', cursor: 'pointer', fontWeight: '600' }}>Dismiss</button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Schedule + Dinner Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '11px', marginBottom: '13px' }}>
        <div className="glass-card" style={{ marginBottom: 0, padding: '14px 15px' }}>
          <div className="section-header" style={{ marginBottom: '10px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '5px', fontSize: '12.5px', fontWeight: '700', color: 'var(--color-primary-dark)', letterSpacing: '-0.015em' }}>
              <Calendar size={13} /> Schedule
            </div>
            <button onClick={() => setActiveTab('plan')} style={{ background: 'none', border: 'none', fontSize: '10.5px', color: 'var(--color-accent-deep)', cursor: 'pointer', fontWeight: '700' }}>View</button>
          </div>
          {upcomingEvents.length === 0
            ? <p style={{ fontSize: '11px', color: 'var(--color-text-subtle)', fontStyle: 'italic' }}>Enjoy a quiet day.</p>
            : <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {upcomingEvents.map(ev => (
                  <div key={ev.id} style={{ borderLeft: `2.5px solid ${ev.color}`, paddingLeft: '8px' }}>
                    <div style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-main)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{ev.title}</div>
                    <div style={{ fontSize: '10px', color: 'var(--color-text-subtle)', marginTop: '2px' }}>{ev.time} · {ev.member}</div>
                  </div>
                ))}
              </div>
          }
        </div>

        <div className="glass-card" style={{ marginBottom: 0, padding: '14px 15px' }}>
          <div className="section-header" style={{ marginBottom: '10px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '5px', fontSize: '12.5px', fontWeight: '700', color: 'var(--color-primary-dark)', letterSpacing: '-0.015em' }}>
              <Utensils size={13} /> Dinner
            </div>
            <button onClick={() => setActiveTab('meals')} style={{ background: 'none', border: 'none', fontSize: '10.5px', color: 'var(--color-accent-deep)', cursor: 'pointer', fontWeight: '700' }}>Plan</button>
          </div>
          <div style={{ fontSize: '12px', fontWeight: '600', color: 'var(--color-text-main)', lineHeight: '1.4' }}>
            {meals[getCurrentDay()]?.dinner || 'Slow Cooker Lentil Soup'}
          </div>
          <p style={{ fontSize: '10px', color: 'var(--color-sage-dark)', marginTop: '5px', fontWeight: '600' }}>✓ Preference matched</p>
        </div>
      </div>

      {/* Family Workspace Feed */}
      <div className="glass-card" style={{ padding: '16px 18px' }}>
        <div style={{ fontSize: '13px', fontWeight: '700', color: 'var(--color-primary-dark)', marginBottom: '13px', display: 'flex', alignItems: 'center', gap: '7px', letterSpacing: '-0.02em' }}>
          <Smile size={14} color="var(--color-sage)" strokeWidth={2.2} /> Family Feed
        </div>
        {timeline.length === 0 ? (
          <p style={{ fontSize: '12.5px', color: 'var(--color-text-subtle)', fontStyle: 'italic', textAlign: 'center', padding: '10px 0' }}>
            No activity yet — actions will appear here.
          </p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0' }}>
            {timeline.map((act, idx) => (
              <div key={act.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', paddingBottom: idx < timeline.length - 1 ? '11px' : 0, marginBottom: idx < timeline.length - 1 ? '11px' : 0, borderBottom: idx < timeline.length - 1 ? '1px solid var(--color-border)' : 'none' }}>
                <div className={`avatar-bubble ${avatarStyle(act.user)}`}>{act.user[0]}</div>
                <div style={{ flex: 1, fontSize: '12px', lineHeight: 1.45 }}>
                  <span style={{ fontWeight: '700', color: 'var(--color-text-main)' }}>{act.user}</span>{' '}
                  <span style={{ color: 'var(--color-text-muted)' }}>{act.action}</span>{' '}
                  <span style={{ fontWeight: '600', color: 'var(--color-primary-dark)' }}>{act.task}</span>
                </div>
                <span style={{ fontSize: '10px', color: 'var(--color-text-subtle)', flexShrink: 0, fontWeight: '500' }}>{act.time}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
