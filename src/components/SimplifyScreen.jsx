import { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Star, ShieldCheck, RefreshCw, ChevronRight } from 'lucide-react';
import { dbService } from '../services/firebase';

const OVERWHELM_MESSAGES = [
  "You don't have to do everything. Just the next one thing.",
  "Progress, not perfection. One task at a time.",
  "The list feels long, but your capacity is real. Start small.",
  "You've handled harder days than this. Breathe first, then begin.",
  "Permission granted: ignore everything below these three.",
];

const LOW_ENERGY_MESSAGES = [
  "Low energy is real. These two things are enough for today.",
  "Conserve. Delegate. Rest. You're doing the right thing.",
  "A small win still counts. Pick one and let the day be enough.",
  "Your body is asking for gentleness. Honor that today.",
  "Slow is still moving forward. You've got this.",
];

const BREATHING_MESSAGES = [
  "Your nervous system is resetting. This is the work.",
  "Three slow breaths change your brain chemistry. Stay here.",
  "Stillness is productive. The pause is part of the plan.",
  "You can't pour from an empty cup. Fill it here.",
  "Let your shoulders drop. Let your jaw unclench. Breathe.",
];

const GENERAL_QUOTES = [
  "Do one thing at a time. The rest can wait.",
  "Breathe in calm, breathe out chaos.",
  "Your presence matters more than your productivity.",
  "In this moment, there is enough time.",
  "The house is safe. Everything else can wait.",
  "You have done enough today.",
  "Simplicity is the ultimate sophistication.",
  "Not everything that can be done needs to happen today.",
  "Rest is not a reward — it's a requirement.",
  "The most important thing is to be where you are.",
  "You are doing better than you think.",
  "A calm home starts with a calm parent.",
];

const SIMPLE_DINNERS = [
  'Scrambled eggs & toast',
  'Pasta with jar sauce',
  'Bean tacos with shredded cheese',
  'Grilled cheese & tomato soup',
  'Frozen pizza night 🍕',
  'Takeout — you earned it',
  'Pancakes for dinner',
];

const PHASE_TIPS = {
  inhale:    'Let your belly expand fully as you breathe in',
  'hold-in': 'Hold gently — keep your shoulders relaxed',
  exhale:    'Let go slowly, releasing all tension with the breath',
  'hold-out':'Rest in the stillness. Nothing to do here.',
};

const PHASE_LABELS  = { inhale: 'Inhale', 'hold-in': 'Hold', exhale: 'Exhale', 'hold-out': 'Rest' };
const PHASE_COLORS  = { inhale: 'var(--color-sage)', 'hold-in': 'var(--color-sage-dark)', exhale: 'var(--color-accent)', 'hold-out': 'var(--color-primary)' };

const BREATH_PATTERNS = {
  box: {
    label: 'Box',
    phases: ['inhale', 'hold-in', 'exhale', 'hold-out'],
    durations: { inhale: 4, 'hold-in': 4, exhale: 4, 'hold-out': 4 },
    desc: '4-4-4-4',
  },
  '478': {
    label: '4-7-8',
    phases: ['inhale', 'hold-in', 'exhale'],
    durations: { inhale: 4, 'hold-in': 7, exhale: 8 },
    desc: '4-7-8',
  },
  deep: {
    label: 'Deep',
    phases: ['inhale', 'exhale'],
    durations: { inhale: 5, exhale: 7 },
    desc: '5-7',
  },
};

const PARTICLE_COLORS = [
  'rgba(122,148,118,0.45)',
  'rgba(164,150,187,0.32)',
  'rgba(217,132,74,0.2)',
  'rgba(138,173,216,0.32)',
  'rgba(122,148,118,0.22)',
  'rgba(204,142,142,0.22)',
];

const MODES = [
  { id: 'overwhelm',  label: 'Overwhelm Recovery', icon: '🧠', color: '#D9844A' },
  { id: 'low-energy', label: 'Low Energy Mode',    icon: '🌙', color: '#A496BB' },
  { id: 'breathe',    label: 'Breathing Focus',    icon: '🫁', color: '#7A9476' },
];

const MODE_GRADIENTS = {
  overwhelm:   'linear-gradient(160deg, #FDF0E5 0%, #F5E8DA 55%, #ECE0D2 100%)',
  'low-energy':'linear-gradient(160deg, #EEF0F8 0%, #E7EAF5 55%, #E2E5EF 100%)',
  breathe:     'linear-gradient(160deg, #E7EFE6 0%, #DFE9DE 55%, #D8E2D7 100%)',
};
const DEFAULT_GRADIENT = 'linear-gradient(160deg, #F2EDE7 0%, #E8EBE5 55%, #E4E8E5 100%)';

function scoreTask(t) {
  let s = 0;
  if (t.priority === 'High') s += 10;
  if (t.priority === 'Medium') s += 5;
  const cat = (t.category || '').toLowerCase();
  if (cat.includes('kids') || cat.includes('health')) s += 3;
  if (t.dueDate === new Date().toISOString().split('T')[0]) s += 8;
  if (t.recurring) s += 2;
  return s;
}

function getGreeting(name, h) {
  const first = name?.split(' ')[0] || '';
  const suffix = first ? `, ${first}` : '';
  if (h < 6)  return `Still awake${suffix}?`;
  if (h < 12) return `Good morning${suffix}.`;
  if (h < 17) return `Good afternoon${suffix}.`;
  if (h < 21) return `Good evening${suffix}.`;
  return `Quiet night${suffix}.`;
}

function getContextLine(h, profile) {
  if (h >= 21) return "The day is winding down. Let yourself release the rest of it.";
  if (h >= 17 && profile?.stressPoints?.dinner) return "Dinner hour is often the hardest. Keep it simple tonight.";
  if (h >= 17) return "The hard part of the day is nearly over. Breathe into the evening.";
  if (h < 9) return "Morning is the best time to reset your intentions for the day.";
  return "Take two minutes here. The household can hold on.";
}

export default function SimplifyScreen({ user, profile, onExit }) {
  const [tasks, setTasks] = useState([]);
  const [activeMode, setActiveMode] = useState(null);

  // Breathing state
  const [breathPhase, setBreathPhase]       = useState('inhale');
  const [breathCountdown, setBreathCountdown] = useState(4);
  const [breathCount, setBreathCount]       = useState(0);
  const [breathPattern, setBreathPattern]   = useState('box');

  // UI state
  const [time, setTime]             = useState(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
  const [sessionSeconds, setSessionSecs] = useState(0);
  const [quoteIndex, setQuoteIndex] = useState(() => Math.floor(Math.random() * GENERAL_QUOTES.length));
  const [lastChecked, setLastChecked] = useState(null);

  // Rest timer
  const [restActive, setRestActive]     = useState(false);
  const [restRemaining, setRestRemaining] = useState(20 * 60);

  const sessionStart = useRef(Date.now());
  const initialTopIds = useRef([]);

  const [modeMessages] = useState({
    overwhelm:    OVERWHELM_MESSAGES [Math.floor(Math.random() * OVERWHELM_MESSAGES.length)],
    'low-energy': LOW_ENERGY_MESSAGES[Math.floor(Math.random() * LOW_ENERGY_MESSAGES.length)],
    breathe:      BREATHING_MESSAGES [Math.floor(Math.random() * BREATHING_MESSAGES.length)],
  });

  const [particles] = useState(() =>
    Array.from({ length: 22 }, (_, i) => ({
      id: i,
      left: `${3 + Math.random() * 94}%`,
      delay: `${Math.random() * 20}s`,
      duration: `${11 + Math.random() * 13}s`,
      size: 2.5 + Math.random() * 6,
      color: PARTICLE_COLORS[i % PARTICLE_COLORS.length],
    }))
  );

  // Clock + session ticker
  useEffect(() => {
    const clock   = setInterval(() => setTime(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })), 10000);
    const session = setInterval(() => setSessionSecs(Math.floor((Date.now() - sessionStart.current) / 1000)), 1000);
    const unsub   = dbService.subscribeTasks(setTasks);
    return () => { clearInterval(clock); clearInterval(session); unsub(); };
  }, []);

  // Breathing engine — 1-second interval drives both countdown and phase advance
  useEffect(() => {
    if (activeMode !== 'breathe') return;
    const { phases, durations } = BREATH_PATTERNS[breathPattern];
    let phaseIdx = 0, secInPhase = 0;
    setBreathPhase(phases[0]);
    setBreathCountdown(durations[phases[0]]);
    setBreathCount(0);

    const tick = setInterval(() => {
      secInPhase++;
      const cur = phases[phaseIdx];
      const remaining = durations[cur] - secInPhase;
      setBreathCountdown(remaining > 0 ? remaining : 0);
      if (secInPhase >= durations[cur]) {
        phaseIdx = (phaseIdx + 1) % phases.length;
        secInPhase = 0;
        setBreathPhase(phases[phaseIdx]);
        setBreathCountdown(durations[phases[phaseIdx]]);
        if (phaseIdx === 0) setBreathCount(c => c + 1);
      }
    }, 1000);
    return () => clearInterval(tick);
  }, [activeMode, breathPattern]);

  // Rest timer
  useEffect(() => {
    if (!restActive) return;
    const tick = setInterval(() => {
      setRestRemaining(r => {
        if (r <= 1) { setRestActive(false); return 20 * 60; }
        return r - 1;
      });
    }, 1000);
    return () => clearInterval(tick);
  }, [restActive]);

  // Lock in initial top task IDs when entering Overwhelm
  useEffect(() => {
    if (activeMode === 'overwhelm' && tasks.length > 0 && initialTopIds.current.length === 0) {
      const undone = tasks.filter(t => !t.done);
      initialTopIds.current = [...undone].sort((a, b) => scoreTask(b) - scoreTask(a)).slice(0, 3).map(t => t.id);
    }
    if (activeMode !== 'overwhelm') initialTopIds.current = [];
  }, [tasks, activeMode]);

  const handleToggleTask = (task) => {
    dbService.saveTask({ ...task, done: !task.done });
    if (!task.done) { setLastChecked(task.id); setTimeout(() => setLastChecked(null), 1800); }
  };

  // ── Derived data ──
  const hour        = new Date().getHours();
  const undoneTasks = tasks.filter(t => !t.done);
  const easyTasks   = [...undoneTasks].sort((a, b) => scoreTask(a) - scoreTask(b)).slice(0, 2);
  const todayDinner = SIMPLE_DINNERS[new Date().getDay()];

  const displayTop = initialTopIds.current.length
    ? initialTopIds.current.map(id => tasks.find(t => t.id === id)).filter(Boolean)
    : [...undoneTasks].sort((a, b) => scoreTask(b) - scoreTask(a)).slice(0, 3);

  const doneTopCount = displayTop.filter(t => t.done).length;
  const allTopDone   = displayTop.length > 0 && displayTop.every(t => t.done);

  const pattern      = BREATH_PATTERNS[breathPattern];
  const phaseDur     = pattern.durations[breathPhase] || 4;
  const phaseProgress = (phaseDur - breathCountdown) / phaseDur;
  const breathDone   = breathCount >= 4;
  const ARC_R = 100;
  const ARC_CIRC = 2 * Math.PI * ARC_R;

  const fmtSession = s => s < 60 ? `${s}s` : `${Math.floor(s / 60)}m${s % 60 ? ` ${s % 60}s` : ''}`;
  const fmtRest    = s => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;

  const bgGrad = activeMode ? (MODE_GRADIENTS[activeMode] || DEFAULT_GRADIENT) : DEFAULT_GRADIENT;

  return (
    <div className="fade-in" style={{
      display: 'flex', flexDirection: 'column',
      padding: '24px 22px 20px',
      color: 'var(--color-text-main)',
      zIndex: 10, overflow: 'hidden',
      width: '100%', height: '100%', minHeight: '100%',
      position: 'relative',
      background: bgGrad,
      transition: 'background 1.4s ease',
    }}>

      {/* Ambient particles */}
      {particles.map(p => (
        <div key={p.id} className="ambient-particle" style={{
          left: p.left, width: p.size + 'px', height: p.size + 'px',
          animationDelay: p.delay, animationDuration: p.duration, background: p.color,
        }} />
      ))}

      {/* ── TOP BAR ── */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', zIndex: 2, marginBottom: '16px' }}>
        {activeMode ? (
          <button onClick={() => setActiveMode(null)} className="simplify-back-btn">
            <ArrowLeft size={13} /> Back
          </button>
        ) : (
          <div style={{ display: 'flex', alignItems: 'center', gap: '7px' }}>
            <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: 'var(--color-sage)', boxShadow: '0 0 0 3px rgba(122,148,118,0.22)', animation: 'breathe 4.5s ease-in-out infinite' }} />
            <span style={{ fontSize: '10.5px', fontWeight: '700', color: 'var(--color-text-muted)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>Simplify Mode</span>
          </div>
        )}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          {sessionSeconds >= 15 && (
            <div style={{ background: 'rgba(255,255,255,0.58)', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.5)', borderRadius: '20px', padding: '4px 10px', fontSize: '10px', fontWeight: '700', color: 'var(--color-text-muted)' }}>
              {fmtSession(sessionSeconds)}
            </div>
          )}
          <button onClick={onExit} style={{ background: 'none', border: 'none', fontSize: '11px', fontWeight: '600', color: 'var(--color-text-subtle)', cursor: 'pointer', padding: '6px 10px', borderRadius: '10px' }}>
            Exit ✕
          </button>
        </div>
      </div>

      {/* ══════════════════════════════════════
          MODE SELECTION LANDING
      ══════════════════════════════════════ */}
      {!activeMode && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', zIndex: 2, overflowY: 'auto' }}>

          {/* Clock */}
          <div style={{ textAlign: 'center', marginBottom: '6px' }}>
            <div style={{ fontSize: '54px', fontWeight: '200', letterSpacing: '-0.05em', color: 'var(--color-primary-dark)', lineHeight: 1, fontFamily: 'var(--font-sans)' }}>{time}</div>
          </div>

          {/* Greeting */}
          <div style={{ textAlign: 'center', marginBottom: '16px' }}>
            <div style={{ fontSize: '15px', fontWeight: '600', color: 'var(--color-primary-dark)', marginBottom: '4px' }}>{getGreeting(user?.name, hour)}</div>
            <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontStyle: 'italic', lineHeight: 1.6, margin: 0 }}>{getContextLine(hour, profile)}</p>
          </div>

          {/* Quote with refresh */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: 'rgba(255,255,255,0.52)', backdropFilter: 'blur(10px)', border: '1px solid rgba(255,255,255,0.6)', borderRadius: '18px', padding: '11px 14px', marginBottom: '20px' }}>
            <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontStyle: 'italic', flex: 1, lineHeight: 1.55, margin: 0 }}>
              "{GENERAL_QUOTES[quoteIndex]}"
            </p>
            <button onClick={() => setQuoteIndex(i => (i + 1) % GENERAL_QUOTES.length)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-subtle)', padding: '3px', flexShrink: 0, opacity: 0.7, transition: 'opacity 0.2s' }}>
              <RefreshCw size={12} />
            </button>
          </div>

          <p style={{ fontSize: '10px', fontWeight: '700', color: 'var(--color-text-subtle)', textTransform: 'uppercase', letterSpacing: '0.09em', textAlign: 'center', marginBottom: '10px' }}>
            How are you feeling right now?
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {MODES.map((mode, i) => {
              const preview =
                mode.id === 'overwhelm'  ? `${undoneTasks.length} task${undoneTasks.length !== 1 ? 's' : ''} to sort through` :
                mode.id === 'low-energy' ? `${Math.min(easyTasks.length, 2)} gentle item${easyTasks.length !== 1 ? 's' : ''} + easy dinner` :
                'Resets your nervous system in ~2 min';
              return (
                <button key={mode.id} onClick={() => setActiveMode(mode.id)} className="simplify-mode-card" style={{ animationDelay: `${i * 0.08}s` }}>
                  <span style={{ fontSize: '28px', lineHeight: 1, flexShrink: 0 }}>{mode.icon}</span>
                  <div style={{ flex: 1, textAlign: 'left' }}>
                    <div style={{ fontSize: '13.5px', fontWeight: '700', color: 'var(--color-primary-dark)', marginBottom: '2px' }}>{mode.label}</div>
                    <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', lineHeight: 1.4 }}>{preview}</div>
                  </div>
                  <ChevronRight size={14} color="var(--color-text-subtle)" style={{ flexShrink: 0 }} />
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* ══════════════════════════════════════
          OVERWHELM RECOVERY
      ══════════════════════════════════════ */}
      {activeMode === 'overwhelm' && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '13px', zIndex: 2, overflowY: 'auto' }}>

          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '30px', marginBottom: '6px' }}>🧠</div>
            <h2 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--color-primary-dark)', marginBottom: '5px', fontFamily: 'var(--font-serif)' }}>Overwhelm Recovery</h2>
            <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontStyle: 'italic', lineHeight: 1.55 }}>{modeMessages.overwhelm}</p>
          </div>

          {allTopDone ? (
            <div className="simplify-success-card">
              <div style={{ fontSize: '44px', marginBottom: '10px' }}>🎉</div>
              <h3 style={{ fontSize: '18px', fontWeight: '700', color: 'var(--color-sage-dark)', marginBottom: '8px', fontFamily: 'var(--font-serif)' }}>All done. Well done.</h3>
              <p style={{ fontSize: '13px', color: 'var(--color-text-muted)', lineHeight: 1.65 }}>You worked through what mattered most. The rest can wait — or not happen at all today.</p>
              <div style={{ marginTop: '14px', padding: '12px 16px', background: 'rgba(255,255,255,0.6)', borderRadius: '14px', fontSize: '12px', fontStyle: 'italic', color: 'var(--color-sage-dark)', backdropFilter: 'blur(8px)' }}>
                "You've done enough. You are enough."
              </div>
            </div>
          ) : (
            <div style={{ background: 'rgba(255,255,255,0.84)', backdropFilter: 'blur(20px)', borderRadius: '24px', padding: '18px', border: '1px solid rgba(255,255,255,0.65)', boxShadow: 'var(--shadow-md)' }}>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                <div style={{ fontSize: '10px', fontWeight: '700', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.08em', display: 'flex', alignItems: 'center', gap: '5px' }}>
                  <Star size={10} fill="var(--color-accent)" color="var(--color-accent)" /> AI Focus
                </div>
                <span style={{ fontSize: '11px', fontWeight: '700', color: 'var(--color-sage-dark)' }}>
                  {doneTopCount}/{displayTop.length} done
                </span>
              </div>

              {/* Progress bar */}
              <div style={{ height: '4px', background: 'var(--color-border)', borderRadius: '2px', marginBottom: '14px', overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${displayTop.length ? (doneTopCount / displayTop.length) * 100 : 0}%`, background: 'linear-gradient(90deg, var(--color-sage), var(--color-sage-dark))', borderRadius: '2px', transition: 'width 0.7s ease' }} />
              </div>

              {displayTop.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '14px 0' }}>
                  <ShieldCheck size={30} color="var(--color-sage)" style={{ margin: '0 auto 8px' }} />
                  <p style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Your plate is clear. Take a real rest.</p>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  {displayTop.map((task, i) => (
                    <div key={task.id} className="simplify-task-card" style={{
                      opacity: task.done ? 0.5 : 1,
                      transform: lastChecked === task.id ? 'scale(1.03)' : 'scale(1)',
                      transition: 'all 0.32s var(--ease-bounce)',
                    }}>
                      <span className="deferred-badge">#{i + 1}</span>
                      <input type="checkbox" className="custom-checkbox" checked={task.done} onChange={() => handleToggleTask(task)} />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: '13px', fontWeight: '600', color: 'var(--color-primary-dark)', textDecoration: task.done ? 'line-through' : 'none', lineHeight: 1.35, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {task.title}
                        </div>
                        {(task.category || task.priority === 'High') && (
                          <div style={{ display: 'flex', gap: '5px', marginTop: '3px', alignItems: 'center' }}>
                            {task.category && <span className="chip chip-accent" style={{ fontSize: '9px' }}>{task.category}</span>}
                            {task.priority === 'High' && <span style={{ fontSize: '9px', color: 'var(--color-accent-deep)', fontWeight: '700' }}>⚡ High</span>}
                          </div>
                        )}
                      </div>
                      {lastChecked === task.id && <span style={{ fontSize: '16px', flexShrink: 0 }}>✓</span>}
                    </div>
                  ))}
                </div>
              )}

              <p style={{ fontSize: '10.5px', color: 'var(--color-text-subtle)', fontStyle: 'italic', textAlign: 'center', marginTop: '14px', borderTop: '1px solid var(--color-border)', paddingTop: '10px' }}>
                Everything else is deferred. You have permission to ignore it.
              </p>
            </div>
          )}
        </div>
      )}

      {/* ══════════════════════════════════════
          LOW ENERGY MODE
      ══════════════════════════════════════ */}
      {activeMode === 'low-energy' && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '12px', zIndex: 2, overflowY: 'auto' }}>

          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '30px', marginBottom: '6px' }}>🌙</div>
            <h2 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--color-primary-dark)', marginBottom: '5px', fontFamily: 'var(--font-serif)' }}>Low Energy Mode</h2>
            <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontStyle: 'italic', lineHeight: 1.55 }}>{modeMessages['low-energy']}</p>
          </div>

          {/* Two easy tasks */}
          <div style={{ background: 'rgba(255,255,255,0.84)', backdropFilter: 'blur(20px)', borderRadius: '24px', padding: '18px', border: '1px solid rgba(255,255,255,0.65)', boxShadow: 'var(--shadow-md)' }}>
            <div style={{ fontSize: '10px', fontWeight: '700', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: '12px' }}>
              Only these two matter today
            </div>
            {easyTasks.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '14px 0' }}>
                <ShieldCheck size={30} color="var(--color-sage)" style={{ margin: '0 auto 8px' }} />
                <p style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Nothing pending. You're clear to rest.</p>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {easyTasks.map(task => (
                  <div key={task.id} className="simplify-task-card" style={{ opacity: task.done ? 0.5 : 1, transition: 'opacity 0.3s ease' }}>
                    <input type="checkbox" className="custom-checkbox" checked={task.done} onChange={() => handleToggleTask(task)} />
                    <span style={{ fontSize: '13px', fontWeight: '500', color: 'var(--color-primary-dark)', flex: 1, textDecoration: task.done ? 'line-through' : 'none' }}>
                      {task.title}
                    </span>
                    {lastChecked === task.id && <span style={{ fontSize: '15px' }}>✓</span>}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Easy dinner */}
          <div style={{ background: 'rgba(255,255,255,0.7)', backdropFilter: 'blur(14px)', borderRadius: '20px', padding: '14px 18px', border: '1px solid rgba(255,255,255,0.55)', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <span style={{ fontSize: '24px', flexShrink: 0 }}>🍽️</span>
            <div>
              <div style={{ fontSize: '10px', fontWeight: '700', color: 'var(--color-text-subtle)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: '3px' }}>Easy dinner tonight</div>
              <div style={{ fontSize: '13.5px', fontWeight: '600', color: 'var(--color-primary-dark)' }}>{todayDinner}</div>
              <div style={{ fontSize: '10.5px', color: 'var(--color-text-subtle)', marginTop: '2px' }}>No prep required — that's the point.</div>
            </div>
          </div>

          {/* 20-min rest timer */}
          <div style={{ background: 'rgba(230,228,245,0.75)', backdropFilter: 'blur(14px)', borderRadius: '20px', padding: '16px 18px', border: '1px solid rgba(164,150,187,0.25)' }}>
            <div style={{ fontSize: '10px', fontWeight: '700', color: '#8A7AAA', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: '10px' }}>
              🛋️ 20-Minute Rest
            </div>
            {restActive ? (
              <>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
                  <div style={{ fontSize: '36px', fontWeight: '200', letterSpacing: '-0.04em', color: '#6A5A8A', fontFamily: 'var(--font-sans)' }}>{fmtRest(restRemaining)}</div>
                  <button onClick={() => { setRestActive(false); setRestRemaining(20 * 60); }} style={{ background: 'rgba(255,255,255,0.6)', border: '1px solid rgba(164,150,187,0.3)', borderRadius: '10px', padding: '6px 12px', fontSize: '11px', fontWeight: '600', color: '#8A7AAA', cursor: 'pointer' }}>
                    Stop
                  </button>
                </div>
                <div style={{ height: '4px', background: 'rgba(164,150,187,0.2)', borderRadius: '2px', overflow: 'hidden' }}>
                  <div style={{ height: '100%', width: `${((20 * 60 - restRemaining) / (20 * 60)) * 100}%`, background: 'linear-gradient(90deg, #A496BB, #7A6A8A)', borderRadius: '2px', transition: 'width 1s linear' }} />
                </div>
              </>
            ) : (
              <button onClick={() => setRestActive(true)} style={{ width: '100%', padding: '12px', background: 'rgba(255,255,255,0.6)', border: '1.5px solid rgba(164,150,187,0.4)', borderRadius: '14px', fontSize: '13px', fontWeight: '700', color: '#6A5A8A', cursor: 'pointer', backdropFilter: 'blur(8px)' }}>
                Start 20-min rest →
              </button>
            )}
          </div>
        </div>
      )}

      {/* ══════════════════════════════════════
          BREATHING FOCUS
      ══════════════════════════════════════ */}
      {activeMode === 'breathe' && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '12px', zIndex: 2 }}>

          <div style={{ textAlign: 'center' }}>
            <h2 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--color-primary-dark)', marginBottom: '4px', fontFamily: 'var(--font-serif)' }}>
              {breathDone ? 'Session Complete ✓' : (BREATH_PATTERNS[breathPattern].label + ' Breathing')}
            </h2>
            <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontStyle: 'italic', lineHeight: 1.5 }}>{modeMessages.breathe}</p>
          </div>

          {/* Pattern selector */}
          <div style={{ display: 'flex', gap: '6px' }}>
            {Object.entries(BREATH_PATTERNS).map(([key, p]) => (
              <button key={key} onClick={() => setBreathPattern(key)} style={{
                padding: '6px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: '700', cursor: 'pointer',
                border: breathPattern === key ? '1.5px solid var(--color-sage-dark)' : '1px solid var(--color-border)',
                background: breathPattern === key ? 'var(--color-sage-soft)' : 'rgba(255,255,255,0.6)',
                color: breathPattern === key ? 'var(--color-sage-dark)' : 'var(--color-text-muted)',
                backdropFilter: 'blur(8px)', transition: 'all 0.2s ease',
              }}>
                {p.label} <span style={{ opacity: 0.65, fontSize: '10px' }}>{p.desc}</span>
              </button>
            ))}
          </div>

          {/* Breathing ring with SVG progress arc */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '14px' }}>
            <div style={{ position: 'relative', width: '224px', height: '224px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>

              {/* SVG progress arc */}
              <svg style={{ position: 'absolute', width: '224px', height: '224px', transform: 'rotate(-90deg)' }} viewBox="0 0 224 224">
                <circle cx="112" cy="112" r={ARC_R} fill="none" stroke="rgba(122,148,118,0.12)" strokeWidth="5" />
                <circle cx="112" cy="112" r={ARC_R} fill="none"
                  stroke={PHASE_COLORS[breathPhase]}
                  strokeWidth="5" strokeLinecap="round"
                  strokeDasharray={ARC_CIRC}
                  strokeDashoffset={ARC_CIRC * (1 - phaseProgress)}
                  style={{ transition: 'stroke-dashoffset 1s linear, stroke 0.5s ease', opacity: 0.65 }}
                />
              </svg>

              {/* Breathing sphere */}
              <div className={`breath-phase-ring phase-${breathPhase}`} style={{ width: '190px', height: '190px' }}>
                <div className="breath-phase-inner" style={{ width: '122px', height: '122px' }}>
                  <span style={{ fontSize: '46px', fontWeight: '200', color: 'white', letterSpacing: '-0.04em', lineHeight: 1, fontFamily: 'var(--font-sans)' }}>
                    {breathCountdown}
                  </span>
                  <span style={{ fontSize: '10.5px', fontWeight: '700', color: 'rgba(255,255,255,0.85)', letterSpacing: '0.06em', textTransform: 'uppercase', marginTop: '3px' }}>
                    {PHASE_LABELS[breathPhase]}
                  </span>
                </div>
              </div>
            </div>

            {/* Tip text */}
            <p style={{ fontSize: '11.5px', color: 'var(--color-text-muted)', fontStyle: 'italic', textAlign: 'center', maxWidth: '230px', lineHeight: 1.6, transition: 'all 0.6s ease' }}>
              {PHASE_TIPS[breathPhase]}
            </p>

            {/* Cycle count / completion */}
            {breathDone ? (
              <div style={{ background: 'linear-gradient(145deg, #E6F0E5, #D7E9D5)', border: '1px solid rgba(122,148,118,0.3)', borderRadius: '20px', padding: '13px 20px', textAlign: 'center' }}>
                <div style={{ fontSize: '20px', marginBottom: '5px' }}>🌿</div>
                <div style={{ fontSize: '13px', fontWeight: '700', color: 'var(--color-sage-dark)', marginBottom: '3px' }}>Full session complete</div>
                <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>4 cycles · your nervous system has reset.</div>
              </div>
            ) : breathCount > 0 ? (
              <div style={{ background: 'rgba(255,255,255,0.62)', borderRadius: '20px', padding: '7px 16px', fontSize: '11px', fontWeight: '700', color: 'var(--color-sage-dark)', backdropFilter: 'blur(8px)' }}>
                {breathCount} {breathCount === 1 ? 'cycle' : 'cycles'} complete ✓
              </div>
            ) : null}
          </div>

          {/* Phase step indicators — width proportional to duration */}
          <div style={{ display: 'flex', gap: '7px', alignItems: 'center' }}>
            {pattern.phases.map(ph => (
              <div key={ph} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '4px', opacity: breathPhase === ph ? 1 : 0.3, transition: 'opacity 0.5s ease' }}>
                <div style={{ width: `${Math.max(24, pattern.durations[ph] * 5)}px`, height: '4px', borderRadius: '2px', background: breathPhase === ph ? PHASE_COLORS[ph] : 'var(--color-border)', transition: 'background 0.5s ease' }} />
                <span style={{ fontSize: '8px', fontWeight: '700', color: 'var(--color-text-subtle)', textTransform: 'uppercase', letterSpacing: '0.03em' }}>{PHASE_LABELS[ph]}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── RETURN BUTTON ── */}
      <div style={{ zIndex: 2, marginTop: '14px' }}>
        <button onClick={onExit} style={{
          width: '100%', padding: '14px', fontSize: '13px', fontWeight: '700', letterSpacing: '-0.01em',
          background: 'rgba(62,48,40,0.85)', backdropFilter: 'blur(12px)',
          borderRadius: '18px', border: 'none', color: 'white', cursor: 'pointer',
          boxShadow: '0 4px 20px rgba(46,38,31,0.18)',
        }}>
          Return to Nestly
        </button>
      </div>
    </div>
  );
}
