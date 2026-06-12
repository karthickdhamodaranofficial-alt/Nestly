import React, { useState, useEffect } from 'react';
import { Plus, Trash2, RefreshCw, Clock, X, ChevronLeft, ChevronRight } from 'lucide-react';
import { dbService } from '../services/firebase';

const MEMBER_COLORS = { Kids:'#E6A15C', Mom:'#8F9E8B', Dad:'#7D6B5D', Shared:'#A496BB' };
const MEMBER_BG     = { Kids:'#FDF3E8', Mom:'#E8EDE7', Dad:'#EDE9E7', Shared:'#F4F1F8' };

export default function Calendar({ user, profile }) {
  const [events, setEvents] = useState([]);
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [memberFilter, setMemberFilter] = useState('All');
  const [showAdd, setShowAdd] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [syncMsg, setSyncMsg] = useState('');
  const [weekOffset, setWeekOffset] = useState(0);

  const [title, setTitle] = useState('');
  const [time, setTime] = useState('09:00');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [member, setMember] = useState('Kids');
  const [notes, setNotes] = useState('');

  useEffect(() => {
    const unsub = dbService.subscribeEvents(setEvents);
    return () => unsub();
  }, []);

  const handleAdd = (e) => {
    e.preventDefault();
    if (!title.trim()) return;
    dbService.saveEvent({ id:`ev-${Date.now()}`, title, time, date, member, color: MEMBER_COLORS[member]||'#7D6B5D', notes });
    setTitle(''); setTime('09:00'); setNotes(''); setDate(selectedDate); setShowAdd(false);
  };

  const syncFeed = (src) => {
    setSyncing(true); setSyncMsg(src);
    setTimeout(() => {
      const d = new Date(); d.setDate(d.getDate()+1);
      const ds = d.toISOString().split('T')[0];
      const ev = src.includes('School')
        ? { id:`ev-sync-${Date.now()}`, title:'School Field Trip: Nature Center', date:ds, time:'09:00', member:'Kids', color:'#E6A15C', notes:'Pack brown bag lunch.' }
        : { id:`ev-sync-${Date.now()}`, title:'Soccer Tournament Finals', date:ds, time:'14:30', member:'Kids', color:'#E6A15C', notes:'Jersey color: Blue.' };
      dbService.saveEvent(ev);
      setSyncing(false); setSyncMsg('');
    }, 1600);
  };

  // Build 7-day strip based on weekOffset
  const getDayStrip = () => {
    const strip = [];
    const base = new Date();
    base.setDate(base.getDate() + weekOffset * 7 - 3);
    for (let i=0; i<7; i++) {
      const d = new Date(base); d.setDate(base.getDate()+i);
      strip.push({ str: d.toISOString().split('T')[0], name: d.toLocaleDateString([],{weekday:'short'}), num: d.getDate(), month: d.toLocaleDateString([],{month:'short'}), isToday: d.toDateString()===new Date().toDateString() });
    }
    return strip;
  };

  const dayStrip = getDayStrip();
  const filteredEvents = events.filter(e => e.date===selectedDate && (memberFilter==='All'||e.member===memberFilter));
  const selectedDateLabel = new Date(selectedDate+'T00:00:00').toLocaleDateString([],{ weekday:'long', month:'long', day:'numeric' });

  const eventCountForDay = (ds) => events.filter(e=>e.date===ds).length;

  return (
    <div className="fade-in" style={{ position:'relative' }}>

      {/* Header */}
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:'16px' }}>
        <div>
          <h1 style={{ fontFamily:'var(--font-serif)', fontSize:'24px', color:'var(--color-primary-dark)', marginBottom:'3px' }}>Family Calendar</h1>
          <p style={{ color:'var(--color-text-muted)', fontSize:'12.5px' }}>Shared schedule at a glance</p>
        </div>
        <button onClick={()=>{ setDate(selectedDate); setShowAdd(true); }} style={{ display:'flex', alignItems:'center', gap:'5px', padding:'9px 16px', borderRadius:'20px', background:'linear-gradient(135deg,var(--color-primary),var(--color-primary-dark))', color:'#fff', border:'none', cursor:'pointer', fontSize:'12px', fontWeight:'600', boxShadow:'var(--shadow-sm)', flexShrink:0 }}>
          <Plus size={14}/> Add Event
        </button>
      </div>

      {/* Sync cards */}
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'8px', marginBottom:'16px' }}>
        {[{label:'Lincoln Elementary',sub:'School calendar',src:'School Feed'},{label:'Soccer Youth League',sub:'Match schedule',src:'Sports League'}].map(s => (
          <button key={s.src} onClick={()=>syncFeed(s.src)} disabled={syncing} style={{ display:'flex', alignItems:'center', gap:'10px', padding:'12px 14px', borderRadius:'16px', background:'rgba(255,255,255,0.85)', backdropFilter:'blur(12px)', border:'1px solid var(--color-border)', cursor:'pointer', textAlign:'left', boxShadow:'var(--shadow-xs)', transition:'var(--transition-smooth)' }}>
            <div style={{ width:'32px', height:'32px', borderRadius:'10px', background:'var(--color-accent-soft)', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}>
              <RefreshCw size={14} color="var(--color-accent-deep)" className={syncing&&syncMsg===s.src?'spinning':''}/>
            </div>
            <div>
              <div style={{ fontSize:'11.5px', fontWeight:'700', color:'var(--color-primary-dark)', lineHeight:1.2 }}>{s.label}</div>
              <div style={{ fontSize:'10px', color:'var(--color-text-muted)', marginTop:'2px' }}>{syncing&&syncMsg===s.src?'Syncing…':s.sub}</div>
            </div>
          </button>
        ))}
      </div>

      {/* Day strip with week navigation */}
      <div style={{ background:'rgba(255,255,255,0.85)', backdropFilter:'blur(16px)', border:'1px solid rgba(255,255,255,0.6)', borderRadius:'22px', padding:'12px 8px', marginBottom:'14px', boxShadow:'var(--shadow-xs)' }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:'10px', paddingX:'4px' }}>
          <button onClick={()=>setWeekOffset(w=>w-1)} style={{ background:'none', border:'none', cursor:'pointer', color:'var(--color-text-muted)', padding:'4px 8px' }}><ChevronLeft size={16}/></button>
          <span style={{ fontSize:'11px', fontWeight:'700', color:'var(--color-text-muted)', letterSpacing:'0.04em' }}>
            {dayStrip[0]?.name} {dayStrip[0]?.num} — {dayStrip[6]?.name} {dayStrip[6]?.num} {dayStrip[0]?.month}
          </span>
          <button onClick={()=>setWeekOffset(w=>w+1)} style={{ background:'none', border:'none', cursor:'pointer', color:'var(--color-text-muted)', padding:'4px 8px' }}><ChevronRight size={16}/></button>
        </div>
        <div style={{ display:'flex', justifyContent:'space-between', gap:'4px' }}>
          {dayStrip.map(d => {
            const sel = selectedDate===d.str;
            const cnt = eventCountForDay(d.str);
            return (
              <button key={d.str} onClick={()=>setSelectedDate(d.str)} style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', padding:'8px 4px', borderRadius:'16px', border:`1.5px solid ${sel?'var(--color-accent)':'transparent'}`, background:sel?'var(--color-accent-soft)':d.isToday?'var(--color-sage-soft)':'transparent', cursor:'pointer', transition:'var(--transition-smooth)', minWidth:0 }}>
                <span style={{ fontSize:'9px', fontWeight:'700', color:sel?'var(--color-accent-deep)':d.isToday?'var(--color-sage-dark)':'var(--color-text-muted)', letterSpacing:'0.04em' }}>{d.name.toUpperCase()}</span>
                <span style={{ fontSize:'17px', fontWeight:'800', color:sel?'var(--color-primary-dark)':'var(--color-text-main)', margin:'3px 0' }}>{d.num}</span>
                {cnt>0 ? (
                  <div style={{ display:'flex', gap:'2px', justifyContent:'center' }}>
                    {events.filter(e=>e.date===d.str).slice(0,3).map((ev,i)=>(
                      <span key={i} style={{ width:'4px', height:'4px', borderRadius:'50%', background:sel?'var(--color-accent)':ev.color }}/>
                    ))}
                  </div>
                ) : <span style={{ width:'4px', height:'4px' }}/>}
              </button>
            );
          })}
        </div>
      </div>

      {/* Member filter */}
      <div style={{ display:'flex', gap:'6px', marginBottom:'16px', overflowX:'auto' }}>
        {['All','Kids','Mom','Dad','Shared'].map(m => {
          const sel = memberFilter===m;
          const col = MEMBER_COLORS[m];
          return (
            <button key={m} onClick={()=>setMemberFilter(m)} style={{ display:'flex', alignItems:'center', gap:'5px', padding:'6px 13px', borderRadius:'20px', border:'none', background:sel?(col||'var(--color-primary-dark)'):'var(--color-bg-card)', color:sel?'#fff':'var(--color-text-muted)', fontSize:'11.5px', fontWeight:'700', cursor:'pointer', whiteSpace:'nowrap', transition:'var(--transition-smooth)', boxShadow:sel?'var(--shadow-sm)':'none' }}>
              {m!=='All'&&<span style={{ width:'6px', height:'6px', borderRadius:'50%', background:sel?'rgba(255,255,255,0.7)':col }}/>}
              {m}
            </button>
          );
        })}
      </div>

      {/* Timeline */}
      <div style={{ background:'rgba(255,255,255,0.82)', backdropFilter:'blur(16px)', border:'1px solid rgba(255,255,255,0.55)', borderRadius:'22px', padding:'18px', boxShadow:'var(--shadow-xs)' }}>
        <h3 style={{ fontSize:'12px', fontWeight:'700', color:'var(--color-text-muted)', marginBottom:'16px', textTransform:'uppercase', letterSpacing:'0.06em', display:'flex', alignItems:'center', gap:'6px' }}>
          <Clock size={13}/> {selectedDateLabel}
        </h3>

        {filteredEvents.length===0 ? (
          <div style={{ textAlign:'center', padding:'28px 0' }}>
            <div style={{ fontSize:'36px', marginBottom:'10px' }}>📅</div>
            <p style={{ fontSize:'13px', color:'var(--color-text-muted)', fontStyle:'italic' }}>No events. Tap + Add Event.</p>
          </div>
        ) : (
          <div style={{ position:'relative', paddingLeft:'22px', borderLeft:'2px solid var(--color-border)', display:'flex', flexDirection:'column', gap:'18px' }}>
            {filteredEvents.sort((a,b)=>a.time.localeCompare(b.time)).map(ev => (
              <div key={ev.id} style={{ position:'relative' }}>
                {/* Timeline node */}
                <div style={{ position:'absolute', left:'-29px', top:'6px', width:'14px', height:'14px', borderRadius:'50%', background:ev.color, border:'3px solid var(--color-bg-base)', boxShadow:`0 0 0 2px ${ev.color}44` }}/>

                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', background:`${ev.color}0D`, border:`1px solid ${ev.color}33`, borderRadius:'16px', padding:'12px 14px' }}>
                  <div style={{ flex:1 }}>
                    <div style={{ display:'flex', alignItems:'center', gap:'7px', marginBottom:'4px' }}>
                      <span style={{ fontSize:'12px', fontWeight:'800', color:'var(--color-primary-dark)' }}>{ev.time}</span>
                      <span style={{ fontSize:'10px', fontWeight:'700', padding:'2px 8px', borderRadius:'99px', background:MEMBER_BG[ev.member]||'#F5F5F5', color:MEMBER_COLORS[ev.member]||'#666' }}>{ev.member}</span>
                    </div>
                    <h4 style={{ fontSize:'14px', fontWeight:'600', color:'var(--color-text-main)', margin:'0 0 2px 0' }}>{ev.title}</h4>
                    {ev.notes && <p style={{ fontSize:'11px', color:'var(--color-text-muted)', margin:0, fontStyle:'italic' }}>{ev.notes}</p>}
                  </div>
                  <button onClick={()=>dbService.deleteEvent(ev.id)} style={{ background:'none', border:'none', color:'var(--color-danger)', opacity:0.4, cursor:'pointer', padding:'4px', flexShrink:0, marginLeft:'8px' }}>
                    <Trash2 size={14}/>
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add Event Modal */}
      {showAdd && (
        <div onClick={()=>setShowAdd(false)} style={{ position:'fixed', inset:0, background:'rgba(30,24,18,0.6)', backdropFilter:'blur(12px)', zIndex:9999, display:'flex', alignItems:'center', justifyContent:'center', padding:'24px' }}>
          <form onClick={e=>e.stopPropagation()} onSubmit={handleAdd} style={{ width:'100%', maxWidth:'380px', background:'var(--color-bg-base)', borderRadius:'28px', padding:'24px', boxShadow:'0 28px 80px rgba(0,0,0,0.3)', maxHeight:'85vh', overflowY:'auto' }}>
            <div style={{ width:'32px', height:'3px', background:'var(--color-border-strong)', borderRadius:'99px', margin:'0 auto 18px' }}/>
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'20px' }}>
              <h2 style={{ fontFamily:'var(--font-serif)', fontSize:'20px', color:'var(--color-primary-dark)' }}>Add Calendar Event</h2>
              <button type="button" onClick={()=>setShowAdd(false)} style={{ background:'var(--color-bg-card)', border:'1px solid var(--color-border)', borderRadius:'50%', width:'30px', height:'30px', display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', color:'var(--color-text-muted)' }}><X size={14}/></button>
            </div>

            <div style={{ display:'flex', flexDirection:'column', gap:'14px' }}>
              <div>
                <label style={{ fontSize:'10.5px', fontWeight:'700', color:'var(--color-text-muted)', display:'block', marginBottom:'6px', letterSpacing:'0.06em', textTransform:'uppercase' }}>Event Title</label>
                <input type="text" className="form-input" placeholder="e.g. Swim lessons" value={title} onChange={e=>setTitle(e.target.value)} required autoFocus/>
              </div>

              <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'12px' }}>
                <div>
                  <label style={{ fontSize:'10.5px', fontWeight:'700', color:'var(--color-text-muted)', display:'block', marginBottom:'6px', letterSpacing:'0.06em', textTransform:'uppercase' }}>Date</label>
                  <input type="date" className="form-input" value={date} onChange={e=>setDate(e.target.value)}/>
                </div>
                <div>
                  <label style={{ fontSize:'10.5px', fontWeight:'700', color:'var(--color-text-muted)', display:'block', marginBottom:'6px', letterSpacing:'0.06em', textTransform:'uppercase' }}>Time</label>
                  <input type="time" className="form-input" value={time} onChange={e=>setTime(e.target.value)}/>
                </div>
              </div>

              <div>
                <label style={{ fontSize:'10.5px', fontWeight:'700', color:'var(--color-text-muted)', display:'block', marginBottom:'8px', letterSpacing:'0.06em', textTransform:'uppercase' }}>Family Member</label>
                <div style={{ display:'flex', gap:'7px' }}>
                  {['Kids','Mom','Dad','Shared'].map(m => (
                    <button key={m} type="button" onClick={()=>setMember(m)} style={{ flex:1, padding:'9px 4px', borderRadius:'12px', border:`1.5px solid ${member===m?MEMBER_COLORS[m]:'var(--color-border)'}`, background:member===m?MEMBER_BG[m]:'var(--color-bg-card)', fontSize:'11px', fontWeight:'700', cursor:'pointer', color:member===m?MEMBER_COLORS[m]:'var(--color-text-muted)', transition:'var(--transition-smooth)' }}>
                      {m}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label style={{ fontSize:'10.5px', fontWeight:'700', color:'var(--color-text-muted)', display:'block', marginBottom:'6px', letterSpacing:'0.06em', textTransform:'uppercase' }}>Notes</label>
                <textarea className="form-input" placeholder="Location, reminders…" style={{ height:'64px', resize:'none' }} value={notes} onChange={e=>setNotes(e.target.value)}/>
              </div>

              <button type="submit" className="btn-primary" style={{ marginTop:'4px' }}>✓ Create Event</button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
