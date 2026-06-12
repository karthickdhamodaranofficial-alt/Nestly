import React, { useState } from 'react';
import { Sparkles, Smile, Trash2, Baby, CalendarDays, Briefcase, Shirt, Flame, GraduationCap, Heart, ChevronRight, ChevronLeft, Check } from 'lucide-react';

export default function Onboarding({ user, onOnboardingComplete }) {
  const [step, setStep] = useState(1);
  const TOTAL = 7;

  const [householdSize, setHouseholdSize] = useState(3);
  const [kids, setKids] = useState([{ name: '', age: '' }]);
  const [schoolSchedule, setSchoolSchedule] = useState('Elementary');
  const [sportsActivities, setSportsActivities] = useState('');
  const [laundryRoutine, setLaundryRoutine] = useState('Daily single load');
  const [mealPreferences, setMealPreferences] = useState('Quick 20-minute meals');
  const [workSchedule, setWorkSchedule] = useState('Hybrid 9-to-5');
  const [stressPoints, setStressPoints] = useState({ dinner:true, mornings:true, laundry:false, bedtime:false, schedules:true });
  const [loading, setLoading] = useState(false);
  const [loadingMsg, setLoadingMsg] = useState('');

  const nextStep = () => step < TOTAL ? setStep(s => s+1) : handleFinalize();
  const prevStep = () => setStep(s => Math.max(1, s-1));

  const handleFinalize = () => {
    setLoading(true);
    const msgs = ['Aligning co-parent priorities…', 'Building low-stress schedules…', 'Activating AI recommendations…'];
    let i = 0;
    setLoadingMsg(msgs[0]);
    const iv = setInterval(() => { i++; if (i < msgs.length) setLoadingMsg(msgs[i]); }, 1200);
    setTimeout(() => {
      clearInterval(iv);
      const profile = { householdSize, kids: kids.filter(k=>k.name), schoolSchedule, sportsActivities, laundryRoutine, mealPreferences, workSchedule, stressPoints, onboarded:true, familyName: `${user.name}'s Nest` };
      localStorage.setItem('nestly_profile', JSON.stringify(profile));
      setLoading(false);
      onOnboardingComplete(profile);
    }, 3800);
  };

  if (loading) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', height:'100%', gap:'20px', padding:'32px', textAlign:'center' }}>
      <div style={{ width:'88px', height:'88px', borderRadius:'28px', background:'linear-gradient(135deg, #F6EDE0, #E5EDE4)', display:'flex', alignItems:'center', justifyContent:'center', animation:'breathe 3s ease-in-out infinite', boxShadow:'0 12px 40px rgba(122,148,118,0.2)' }}>
        <span style={{ fontSize:'40px' }}>🪹</span>
      </div>
      <div>
        <h2 style={{ fontFamily:'var(--font-serif)', fontSize:'22px', color:'var(--color-primary-dark)', marginBottom:'8px' }}>Personalizing Nestly</h2>
        <p style={{ fontSize:'13.5px', color:'var(--color-text-muted)', fontStyle:'italic' }}>"{loadingMsg}"</p>
      </div>
      <div style={{ width:'200px', height:'4px', background:'var(--color-border)', borderRadius:'99px', overflow:'hidden' }}>
        <div style={{ height:'100%', background:'linear-gradient(90deg, var(--color-sage), var(--color-accent))', borderRadius:'99px', animation:'loading-bar 3.8s ease forwards' }}/>
      </div>
    </div>
  );

  const STEPS_META = [
    { emoji:'👨‍👩‍👧', label:'Household' },
    { emoji:'👶', label:'Kids' },
    { emoji:'🏫', label:'School' },
    { emoji:'⚽', label:'Activities' },
    { emoji:'🧺', label:'Laundry' },
    { emoji:'😤', label:'Stress' },
    { emoji:'✨', label:'Activate' },
  ];

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%', justifyContent:'space-between' }}>
      
      {/* ── Top progress area ── */}
      <div>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'10px' }}>
          <div style={{ display:'flex', alignItems:'center', gap:'6px' }}>
            <span style={{ fontSize:'18px' }}>🪹</span>
            <span style={{ fontSize:'12px', fontWeight:'800', color:'var(--color-primary-dark)', letterSpacing:'0.04em' }}>NESTLY</span>
          </div>
          <span style={{ fontSize:'11px', fontWeight:'600', color:'var(--color-text-muted)', background:'var(--color-bg-card)', padding:'4px 10px', borderRadius:'99px', border:'1px solid var(--color-border)' }}>
            {step}/{TOTAL}
          </span>
        </div>

        {/* Step dots */}
        <div style={{ display:'flex', gap:'4px', marginBottom:'16px' }}>
          {STEPS_META.map((s,i) => (
            <div key={i} style={{ flex:1, height:'3px', borderRadius:'99px', background: i<step ? 'var(--color-sage)' : i===step-1 ? 'var(--color-accent)' : 'var(--color-border)', transition:'var(--transition-smooth)' }}/>
          ))}
        </div>

        {/* Step label */}
        <div style={{ display:'flex', alignItems:'center', gap:'8px', marginBottom:'4px' }}>
          <span style={{ fontSize:'22px' }}>{STEPS_META[step-1].emoji}</span>
          <span style={{ fontSize:'11px', fontWeight:'700', color:'var(--color-text-muted)', letterSpacing:'0.06em', textTransform:'uppercase' }}>
            Step {step} — {STEPS_META[step-1].label}
          </span>
        </div>
      </div>

      {/* ── Step content ── */}
      <div style={{ flex:1, display:'flex', flexDirection:'column', justifyContent:'center', overflowY:'auto', paddingY:'8px' }}>

        {/* STEP 1 */}
        {step===1 && (
          <div>
            <h2 style={{ fontFamily:'var(--font-serif)', fontSize:'22px', color:'var(--color-primary-dark)', marginBottom:'6px' }}>How large is your household?</h2>
            <p style={{ color:'var(--color-text-muted)', fontSize:'13px', marginBottom:'24px', lineHeight:'1.5' }}>Includes parents, kids, and any live-in support.</p>
            <div style={{ display:'flex', justifyContent:'center', marginBottom:'20px' }}>
              <div style={{ width:'80px', height:'80px', borderRadius:'50%', background:'linear-gradient(135deg,var(--color-accent-soft),var(--color-sage-soft))', display:'flex', alignItems:'center', justifyContent:'center', fontSize:'36px', fontWeight:'800', color:'var(--color-primary-dark)', boxShadow:'var(--shadow-md)', border:'3px solid rgba(255,255,255,0.8)' }}>
                {householdSize}
              </div>
            </div>
            <div style={{ display:'flex', gap:'8px', flexWrap:'wrap', justifyContent:'center' }}>
              {[1,2,3,4,5,6,7,'8+'].map(n => {
                const val = n==='8+' ? 8 : n;
                const sel = n==='8+' ? householdSize>=8 : householdSize===n;
                return (
                  <button key={n} type="button" onClick={()=>setHouseholdSize(val)} style={{ width:'46px', height:'46px', borderRadius:'50%', border:`2px solid ${sel?'var(--color-sage)':'var(--color-border)'}`, background:sel?'var(--color-sage-soft)':'var(--color-bg-card)', color:sel?'var(--color-sage-dark)':'var(--color-text-main)', fontWeight:'800', fontSize:'15px', cursor:'pointer', transition:'var(--transition-bounce)', boxShadow:sel?'var(--shadow-sm)':'none' }}>
                    {n}
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* STEP 2 */}
        {step===2 && (
          <div>
            <h2 style={{ fontFamily:'var(--font-serif)', fontSize:'22px', color:'var(--color-primary-dark)', marginBottom:'6px' }}>Tell us about the kids</h2>
            <p style={{ color:'var(--color-text-muted)', fontSize:'13px', marginBottom:'16px' }}>Nestly customises routines based on their ages.</p>
            <div style={{ display:'flex', flexDirection:'column', gap:'10px', maxHeight:'220px', overflowY:'auto' }}>
              {kids.map((k,i) => (
                <div key={i} style={{ display:'flex', gap:'8px', alignItems:'center', background:'rgba(255,255,255,0.85)', backdropFilter:'blur(12px)', border:'1px solid var(--color-border)', padding:'10px 12px', borderRadius:'16px' }}>
                  <div style={{ width:'32px', height:'32px', borderRadius:'10px', background:'var(--color-accent-soft)', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}>
                    <Baby size={16} color="var(--color-accent-deep)"/>
                  </div>
                  <input type="text" className="form-input" style={{ flex:2, padding:'8px 12px', fontSize:'13px' }} placeholder="Name" value={k.name} onChange={e=>{ const u=[...kids]; u[i].name=e.target.value; setKids(u); }}/>
                  <input type="number" className="form-input" style={{ flex:1, padding:'8px 10px', fontSize:'13px' }} placeholder="Age" value={k.age} onChange={e=>{ const u=[...kids]; u[i].age=e.target.value; setKids(u); }}/>
                  {kids.length>1 && <button onClick={()=>setKids(kids.filter((_,j)=>j!==i))} style={{ background:'none', border:'none', color:'var(--color-danger)', cursor:'pointer', opacity:0.6, padding:'4px' }}><Trash2 size={14}/></button>}
                </div>
              ))}
            </div>
            <button onClick={()=>setKids([...kids,{name:'',age:''}])} className="btn-secondary" style={{ marginTop:'12px', padding:'10px', borderRadius:'12px', fontSize:'12.5px', width:'100%' }}>
              + Add another child
            </button>
          </div>
        )}

        {/* STEP 3 */}
        {step===3 && (
          <div>
            <h2 style={{ fontFamily:'var(--font-serif)', fontSize:'22px', color:'var(--color-primary-dark)', marginBottom:'6px' }}>School & Work</h2>
            <p style={{ color:'var(--color-text-muted)', fontSize:'13px', marginBottom:'16px' }}>Nestly builds routines around your schedule.</p>
            <div style={{ display:'flex', flexDirection:'column', gap:'14px' }}>
              <div>
                <label style={{ fontSize:'10.5px', fontWeight:'700', color:'var(--color-text-muted)', display:'block', marginBottom:'8px', letterSpacing:'0.06em', textTransform:'uppercase' }}>School Schedule</label>
                <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'8px' }}>
                  {[{l:'Elementary',d:'8 AM – 3 PM'},{l:'Middle/High',d:'7:30 AM – 2:30 PM'},{l:'Preschool',d:'Hybrid hours'},{l:'No school',d:'Toddlers / Baby'}].map(s => (
                    <button key={s.l} type="button" onClick={()=>setSchoolSchedule(s.l)} style={{ padding:'12px', borderRadius:'16px', border:`1.5px solid ${schoolSchedule===s.l?'var(--color-sage)':'var(--color-border)'}`, background:schoolSchedule===s.l?'var(--color-sage-soft)':'var(--color-bg-card)', cursor:'pointer', textAlign:'left', transition:'var(--transition-smooth)' }}>
                      <GraduationCap size={16} color={schoolSchedule===s.l?'var(--color-sage-dark)':'var(--color-secondary)'} style={{ marginBottom:'6px' }}/>
                      <div style={{ fontSize:'12px', fontWeight:'700', color:'var(--color-primary-dark)' }}>{s.l}</div>
                      <div style={{ fontSize:'10px', color:'var(--color-text-muted)' }}>{s.d}</div>
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <label style={{ fontSize:'10.5px', fontWeight:'700', color:'var(--color-text-muted)', display:'block', marginBottom:'8px', letterSpacing:'0.06em', textTransform:'uppercase' }}>Work Arrangement</label>
                <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'8px' }}>
                  {['Hybrid 9-to-5','Strictly Remote','Shift work','Homemaker'].map(w => (
                    <button key={w} type="button" onClick={()=>setWorkSchedule(w)} style={{ padding:'11px 12px', borderRadius:'14px', border:`1.5px solid ${workSchedule===w?'var(--color-lavender)':'var(--color-border)'}`, background:workSchedule===w?'var(--color-lavender-soft)':'var(--color-bg-card)', cursor:'pointer', display:'flex', alignItems:'center', gap:'7px', transition:'var(--transition-smooth)' }}>
                      <Briefcase size={14} color={workSchedule===w?'var(--color-lavender)':'var(--color-text-muted)'}/>
                      <span style={{ fontSize:'12px', fontWeight:'600', color:'var(--color-primary-dark)' }}>{w}</span>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* STEP 4 */}
        {step===4 && (
          <div>
            <h2 style={{ fontFamily:'var(--font-serif)', fontSize:'22px', color:'var(--color-primary-dark)', marginBottom:'6px' }}>Sports & activities</h2>
            <p style={{ color:'var(--color-text-muted)', fontSize:'13px', marginBottom:'16px' }}>Nestly reminds you to prep gear the day before.</p>
            <div style={{ position:'relative', marginBottom:'12px' }}>
              <CalendarDays size={16} style={{ position:'absolute', left:'14px', top:'50%', transform:'translateY(-50%)', color:'var(--color-text-subtle)' }}/>
              <input type="text" className="form-input" style={{ paddingLeft:'42px' }} placeholder="e.g. Soccer Tue/Thu, Swim Saturday" value={sportsActivities} onChange={e=>setSportsActivities(e.target.value)}/>
            </div>
            <div style={{ display:'flex', gap:'7px', flexWrap:'wrap', marginBottom:'14px' }}>
              {['Soccer ⚽','Swim 🏊','Piano 🎹','Dance 💃','Gymnastics 🤸','Basketball 🏀','Art class 🎨'].map(t => (
                <button key={t} type="button" onClick={()=>{ if(!sportsActivities.includes(t)) setSportsActivities(p=>p?(p+', '+t):t); }} style={{ padding:'6px 13px', borderRadius:'20px', fontSize:'11.5px', border:'1.5px solid var(--color-border)', background:sportsActivities.includes(t)?'var(--color-accent-soft)':'var(--color-bg-card)', color:sportsActivities.includes(t)?'var(--color-accent-deep)':'var(--color-text-muted)', cursor:'pointer', fontWeight:'500', transition:'var(--transition-smooth)' }}>
                  {t}
                </button>
              ))}
            </div>
            <div style={{ display:'flex', gap:'10px', background:'var(--color-sage-soft)', padding:'12px 14px', borderRadius:'14px', fontSize:'12.5px', color:'var(--color-sage-dark)', alignItems:'flex-start' }}>
              <span>💡</span><span>Skip this if no recurring activities yet — link external calendars later from the Calendar tab.</span>
            </div>
          </div>
        )}

        {/* STEP 5 */}
        {step===5 && (
          <div>
            <h2 style={{ fontFamily:'var(--font-serif)', fontSize:'22px', color:'var(--color-primary-dark)', marginBottom:'6px' }}>Laundry Operations</h2>
            <p style={{ color:'var(--color-text-muted)', fontSize:'13px', marginBottom:'16px' }}>Nestly creates smart reminders around your flow.</p>
            <div style={{ display:'flex', flexDirection:'column', gap:'9px' }}>
              {[{v:'Daily single load',t:'Daily Loop',d:'One load every morning — wash, dry, fold.',icon:'🔄'},{v:'Weekend marathon',t:'Weekend Block',d:'Let it pile, then tackle all on Sunday.',icon:'📅'},{v:'Outsourced / Service',t:'Outsourced',d:'Weekly pickup & wash-dry-fold service.',icon:'🚐'},{v:'Ad-hoc when needed',t:'As-Needed',d:'Only run when the hamper overflows.',icon:'🧺'}].map(item => (
                <button key={item.v} type="button" onClick={()=>setLaundryRoutine(item.v)} style={{ display:'flex', alignItems:'center', gap:'14px', padding:'14px 16px', borderRadius:'18px', border:`1.5px solid ${laundryRoutine===item.v?'var(--color-accent)':'var(--color-border)'}`, background:laundryRoutine===item.v?'var(--color-accent-soft)':'rgba(255,255,255,0.85)', cursor:'pointer', textAlign:'left', transition:'var(--transition-smooth)', boxShadow:laundryRoutine===item.v?'var(--shadow-sm)':'none' }}>
                  <span style={{ fontSize:'24px', flexShrink:0 }}>{item.icon}</span>
                  <div>
                    <div style={{ fontSize:'13.5px', fontWeight:'700', color:'var(--color-primary-dark)' }}>{item.t}</div>
                    <div style={{ fontSize:'11px', color:'var(--color-text-muted)', marginTop:'2px' }}>{item.d}</div>
                  </div>
                  {laundryRoutine===item.v && <div style={{ marginLeft:'auto', width:'22px', height:'22px', borderRadius:'50%', background:'var(--color-sage)', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Check size={12} color="white"/></div>}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* STEP 6 */}
        {step===6 && (
          <div>
            <h2 style={{ fontFamily:'var(--font-serif)', fontSize:'22px', color:'var(--color-primary-dark)', marginBottom:'6px' }}>Where is the friction?</h2>
            <p style={{ color:'var(--color-text-muted)', fontSize:'13px', marginBottom:'20px', lineHeight:'1.5' }}>
              Select your stress zones. Nestly builds calming recommendations specifically for these.
            </p>
            <div style={{ display:'flex', flexDirection:'column', gap:'9px' }}>
              {[{k:'mornings',e:'🌅',l:'Morning chaos',d:'Rushed school runs, missing items, chaotic starts'},{k:'dinner',e:'🍲',l:'Dinner planning panic',d:'Last-minute scrambles, picky eaters, time crunch'},{k:'laundry',e:'🧺',l:'Laundry pileup',d:'Overflowing baskets, lost uniforms, chaos'},{k:'bedtime',e:'🌙',l:'Long bedtime routines',d:'Stalling, multiple trips, exhausting evenings'},{k:'schedules',e:'📅',l:'School date tracking',d:'Missed permission slips, surprise events'}].map(pt => (
                <button key={pt.k} type="button" onClick={()=>setStressPoints(p=>({...p,[pt.k]:!p[pt.k]}))} style={{ display:'flex', alignItems:'center', gap:'12px', padding:'13px 16px', borderRadius:'16px', border:`1.5px solid ${stressPoints[pt.k]?'var(--color-accent)':'var(--color-border)'}`, background:stressPoints[pt.k]?'var(--color-accent-soft)':'rgba(255,255,255,0.85)', cursor:'pointer', textAlign:'left', transition:'var(--transition-smooth)', boxShadow:stressPoints[pt.k]?'var(--shadow-xs)':'none' }}>
                  <span style={{ fontSize:'22px', flexShrink:0 }}>{pt.e}</span>
                  <div style={{ flex:1 }}>
                    <div style={{ fontSize:'13px', fontWeight:'700', color:'var(--color-primary-dark)' }}>{pt.l}</div>
                    <div style={{ fontSize:'10.5px', color:'var(--color-text-muted)', marginTop:'1px' }}>{pt.d}</div>
                  </div>
                  <div style={{ width:'22px', height:'22px', borderRadius:'50%', border:`2px solid ${stressPoints[pt.k]?'var(--color-sage)':'var(--color-border)'}`, background:stressPoints[pt.k]?'var(--color-sage)':'transparent', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0, transition:'var(--transition-smooth)' }}>
                    {stressPoints[pt.k] && <Check size={12} color="white"/>}
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* STEP 7 */}
        {step===7 && (
          <div style={{ textAlign:'center' }}>
            <div style={{ width:'90px', height:'90px', borderRadius:'30px', background:'linear-gradient(135deg,var(--color-accent-soft),var(--color-sage-soft))', display:'flex', alignItems:'center', justifyContent:'center', margin:'0 auto 20px', boxShadow:'var(--shadow-lg)', animation:'breathe 4s ease-in-out infinite' }}>
              <span style={{ fontSize:'44px' }}>🪹</span>
            </div>
            <h2 style={{ fontFamily:'var(--font-serif)', fontSize:'24px', color:'var(--color-primary-dark)', marginBottom:'10px' }}>Your Nest is Ready</h2>
            <p style={{ color:'var(--color-text-muted)', fontSize:'13.5px', lineHeight:'1.7', marginBottom:'24px', maxWidth:'300px', margin:'0 auto 24px' }}>
              We've built a custom AI household profile with proactive tasks, colour-coded events, and personalised meal schedules — all designed to lower your family's cognitive load.
            </p>
            <div style={{ display:'flex', flexDirection:'column', gap:'8px' }}>
              {[`${householdSize} member household configured`,kids.filter(k=>k.name).length>0?`${kids.filter(k=>k.name).length} child profile(s) ready`:'No children added',`Laundry: ${laundryRoutine}`,`${Object.values(stressPoints).filter(Boolean).length} stress zones covered`].map((t,i) => (
                <div key={i} style={{ display:'flex', alignItems:'center', gap:'10px', padding:'10px 14px', background:'rgba(255,255,255,0.8)', backdropFilter:'blur(12px)', borderRadius:'14px', border:'1px solid var(--color-border)' }}>
                  <div style={{ width:'20px', height:'20px', borderRadius:'50%', background:'var(--color-sage)', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Check size={11} color="white"/></div>
                  <span style={{ fontSize:'12.5px', color:'var(--color-primary-dark)', fontWeight:'500' }}>{t}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* ── Navigation ── */}
      <div style={{ display:'flex', gap:'10px', paddingTop:'16px', borderTop:'1px solid var(--color-border)', marginTop:'12px' }}>
        {step>1 && (
          <button onClick={prevStep} className="btn-secondary" style={{ flex:1, padding:'13px', borderRadius:'16px', display:'flex', alignItems:'center', justifyContent:'center', gap:'6px' }}>
            <ChevronLeft size={15}/> Back
          </button>
        )}
        <button onClick={nextStep} className="btn-primary" style={{ flex:2, padding:'13px', borderRadius:'16px', display:'flex', alignItems:'center', justifyContent:'center', gap:'6px', fontSize:'14px' }}>
          {step===TOTAL ? '✨ Enter Nestly' : <>Continue <ChevronRight size={15}/></>}
        </button>
      </div>
    </div>
  );
}
