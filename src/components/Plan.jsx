import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Plus, CheckCircle2, Circle, Trash2, Edit3, Search, Zap, RefreshCw, X, Calendar, Clock } from 'lucide-react';
import { dbService } from '../services/firebase';

/* ─── Centered modal via portal ─── */
function Modal({ onClose, onSubmit, title, children, submitLabel }) {
  const root = document.getElementById('nestly-modal-root');
  if (!root) return null;
  return createPortal(
    <div
      onClick={onClose}
      style={{
        position: 'absolute',
        inset: 0,
        background: 'rgba(30,24,18,0.6)',
        backdropFilter: 'blur(12px)',
        WebkitBackdropFilter: 'blur(12px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '24px',
        pointerEvents: 'all',
      }}
    >
      <div
        onClick={e => e.stopPropagation()}
        className="slide-up-drawer"
        style={{
          width: '100%',
          maxWidth: '380px',
          background: 'var(--color-bg-base)',
          borderRadius: '28px',
          padding: '24px',
          boxShadow: '0 28px 80px rgba(0,0,0,0.35)',
          maxHeight: '82%',
          overflowY: 'auto',
        }}
      >
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'18px' }}>
          <h2 className="font-serif-heading" style={{ fontSize:'19px', color:'var(--color-primary-dark)' }}>{title}</h2>
          <button onClick={onClose} type="button" style={{ background:'var(--color-bg-card)', border:'1px solid var(--color-border)', borderRadius:'50%', width:'30px', height:'30px', display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', color:'var(--color-text-muted)' }}>
            <X size={14}/>
          </button>
        </div>

        <form onSubmit={onSubmit}>
          {children}
          <button type="submit" className="btn-primary" style={{ marginTop:'16px' }}>{submitLabel}</button>
        </form>
      </div>
    </div>,
    root
  );
}

const PRIORITY_COLOR = { High:'#C9813A', Medium:'#B5A8C8', Low:'#8F9E8B' };
const PRIORITY_BG    = { High:'#FFF3E8', Medium:'#F4F1F8', Low:'#E8ECE7' };
const PRIORITY_TEXT  = { High:'#9A5A1A', Medium:'#6B5B8A', Low:'#4E6B4A' };
const MEMBER_COLOR   = { Kids:'#E6A15C', Mom:'#8F9E8B', Dad:'#7D6B5D', Shared:'#B5A8C8' };

const emptyTask = () => ({ title:'', category:'Home', priority:'Medium', assignee:'Shared', dueDate:new Date().toISOString().split('T')[0], recurring:'None', notes:'' });
const emptyEvent = () => ({ title:'', time:'09:00', date:new Date().toISOString().split('T')[0], member:'Kids', notes:'' });

export default function Plan() {
  const [tab, setTab] = useState('tasks');
  const [tasks, setTasks]   = useState([]);
  const [events, setEvents] = useState([]);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('All');
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [calFilter, setCalFilter] = useState('All');
  const [showAddTask, setShowAddTask]   = useState(false);
  const [showAddEvent, setShowAddEvent] = useState(false);
  const [editTask, setEditTask] = useState(null);
  const [taskForm, setTaskForm] = useState(emptyTask());
  const [editForm, setEditForm] = useState(emptyTask());
  const [eventForm, setEventForm] = useState(emptyEvent());
  const [sparkId, setSparkId] = useState(null);
  const [syncing, setSyncing] = useState(false);

  useEffect(() => {
    const u1 = dbService.subscribeTasks(t => setTasks(t||[]));
    const u2 = dbService.subscribeEvents(e => setEvents(e||[]));
    return () => { u1(); u2(); };
  }, []);

  /* ─── Tasks logic ─── */
  const setT = (k,v) => setTaskForm(f=>({...f,[k]:v}));
  const setE = (k,v) => setEditForm(f=>({...f,[k]:v}));
  const setEv = (k,v) => setEventForm(f=>({...f,[k]:v}));

  const detectPri = val => /urgent|tonight|asap/i.test(val)?'High':/weekly|maybe/i.test(val)?'Low':'Medium';

  const handleAddTask = e => {
    e.preventDefault();
    if (!taskForm.title.trim()) return;
    dbService.saveTask({ id:`task-${Date.now()}`, ...taskForm, done:false });
    setTaskForm(emptyTask()); setShowAddTask(false);
  };

  const handleSaveEdit = e => {
    e.preventDefault();
    if (!editTask||!editForm.title.trim()) return;
    dbService.saveTask({...editTask,...editForm});
    setEditTask(null);
  };

  const openEdit = task => { setEditTask(task); setEditForm({ title:task.title||'', category:task.category||'Home', priority:task.priority||'Medium', assignee:task.assignee||'Shared', dueDate:task.dueDate||new Date().toISOString().split('T')[0], recurring:task.recurring||'None', notes:task.notes||'' }); };

  const toggleTask = task => {
    const u = {...task, done:!task.done};
    dbService.saveTask(u);
    if (u.done) { setSparkId(task.id); setTimeout(()=>setSparkId(null),700); }
  };

  const filteredTasks = tasks.filter(t => {
    const catOk = filter==='All'||t.category===filter;
    const q = search.toLowerCase();
    return catOk && (!q||(t.title||'').toLowerCase().includes(q));
  });
  const done = filteredTasks.filter(t=>t.done).length;

  /* ─── Events logic ─── */
  const handleAddEvent = e => {
    e.preventDefault();
    if (!eventForm.title.trim()) return;
    dbService.saveEvent({ id:`ev-${Date.now()}`, ...eventForm, color: MEMBER_COLOR[eventForm.member]||'#7D6B5D' });
    setEventForm(emptyEvent()); setShowAddEvent(false);
  };

  const syncFeed = () => {
    setSyncing(true);
    setTimeout(() => setSyncing(false), 1500);
  };

  const dayStrip = Array.from({length:9},(_,i)=>{
    const d=new Date(); d.setDate(d.getDate()+i-2);
    return { str:d.toISOString().split('T')[0], name:d.toLocaleDateString([],{weekday:'short'}), num:d.getDate(), today:i===2 };
  });

  const dayEvents = events.filter(e=>e.date===selectedDate&&(calFilter==='All'||e.member===calFilter));

  /* ─── Form fields ─── */
  const TaskFields = ({form, onChange}) => (
    <div style={{display:'flex',flexDirection:'column',gap:'12px'}}>
      <div>
        <label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Task Name</label>
        <input type="text" className="form-input" placeholder="e.g. Clean school uniforms tonight" value={form.title} onChange={e=>{onChange('title',e.target.value);onChange('priority',detectPri(e.target.value));}} required autoFocus />
        {form.priority==='High'&&<span style={{fontSize:'10px',color:'var(--color-accent-deep)',fontWeight:'700',display:'flex',alignItems:'center',gap:'3px',marginTop:'4px'}}><Zap size={10}/>Auto: High Priority</span>}
      </div>
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:'10px'}}>
        <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Category</label>
          <select className="form-input" value={form.category} onChange={e=>onChange('category',e.target.value)}>
            {['Home','Kids','Meals','General'].map(c=><option key={c}>{c}</option>)}
          </select>
        </div>
        <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Priority</label>
          <select className="form-input" value={form.priority} onChange={e=>onChange('priority',e.target.value)}>
            <option value="Low">🌿 Low</option><option value="Medium">🔵 Medium</option><option value="High">🔥 High</option>
          </select>
        </div>
      </div>
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:'10px'}}>
        <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Assignee</label>
          <select className="form-input" value={form.assignee} onChange={e=>onChange('assignee',e.target.value)}>
            {['Shared','Mom','Dad'].map(a=><option key={a}>{a}</option>)}
          </select>
        </div>
        <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Due Date</label>
          <input type="date" className="form-input" value={form.dueDate} onChange={e=>onChange('dueDate',e.target.value)}/>
        </div>
      </div>
      <div>
        <label className="label-caps" style={{display:'block',marginBottom:'6px'}}>Recurring</label>
        <div style={{display:'flex',gap:'6px'}}>
          {['None','Daily','Weekly','Monthly'].map(r=>(
            <button key={r} type="button" onClick={()=>onChange('recurring',r)} style={{flex:1,padding:'7px 4px',borderRadius:'10px',border:`1.5px solid ${form.recurring===r?'var(--color-sage)':'var(--color-border)'}`,background:form.recurring===r?'var(--color-sage-soft)':'var(--color-bg-card)',fontSize:'10.5px',fontWeight:'600',cursor:'pointer',color:form.recurring===r?'var(--color-sage-dark)':'var(--color-text-muted)',transition:'var(--transition-smooth)'}}>{r}</button>
          ))}
        </div>
      </div>
      <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Notes</label>
        <textarea className="form-input" placeholder="Any helpful details…" style={{height:'64px',resize:'none'}} value={form.notes} onChange={e=>onChange('notes',e.target.value)}/>
      </div>
    </div>
  );

  return (
    <div className="fade-in" style={{position:'relative'}}>

      {/* Header */}
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:'16px'}}>
        <div>
          <h1 className="font-serif-heading" style={{fontSize:'24px',color:'var(--color-primary-dark)',marginBottom:'3px'}}>Family Plan</h1>
          <p style={{color:'var(--color-text-muted)',fontSize:'12.5px',letterSpacing:'-0.01em'}}>Tasks & schedule in one place</p>
        </div>
        <button
          onClick={()=>tab==='tasks'?setShowAddTask(true):setShowAddEvent(true)}
          style={{display:'flex',alignItems:'center',gap:'5px',padding:'9px 16px',borderRadius:'20px',background:'linear-gradient(145deg,var(--color-primary),var(--color-primary-dark))',color:'#F8F3EE',border:'none',cursor:'pointer',fontSize:'12px',fontWeight:'700',boxShadow:'0 4px 14px rgba(46,38,31,0.22)',flexShrink:0,letterSpacing:'-0.01em'}}>
          <Plus size={14}/> {tab==='tasks'?'Add Task':'Add Event'}
        </button>
      </div>

      {/* Internal Tab Switcher */}
      <div className="subtab-bar" style={{marginBottom:'16px'}}>
        <button className={`subtab-btn ${tab==='tasks'?'active':'inactive'}`} onClick={()=>setTab('tasks')}>
          <CheckCircle2 size={13}/> Tasks ({tasks.filter(t=>!t.done).length} left)
        </button>
        <button className={`subtab-btn ${tab==='calendar'?'active':'inactive'}`} onClick={()=>setTab('calendar')}>
          <Calendar size={13}/> Calendar ({events.length})
        </button>
      </div>

      {/* ═══════════════ TASKS TAB ═══════════════ */}
      {tab==='tasks'&&(
        <div className="fade-in">
          <div style={{position:'relative',marginBottom:'12px'}}>
            <Search size={14} style={{position:'absolute',left:'14px',top:'50%',transform:'translateY(-50%)',color:'var(--color-text-subtle)'}}/>
            <input type="text" className="form-input" style={{paddingLeft:'40px'}} placeholder="Search tasks…" value={search} onChange={e=>setSearch(e.target.value)}/>
          </div>

          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:'14px'}}>
            <div style={{display:'flex',gap:'5px',overflowX:'auto'}}>
              {['All','Home','Kids','Meals'].map(c=>(
                <button key={c} onClick={()=>setFilter(c)} style={{padding:'5px 13px',borderRadius:'20px',fontSize:'11px',fontWeight:'700',border:'none',background:filter===c?'var(--color-primary-dark)':'var(--color-bg-card)',color:filter===c?'#F8F3EE':'var(--color-text-muted)',cursor:'pointer',whiteSpace:'nowrap',transition:'var(--transition-smooth)',boxShadow:filter===c?'0 2px 8px rgba(46,38,31,0.18)':'var(--shadow-xs)',letterSpacing:'-0.01em'}}>{c}</button>
              ))}
            </div>
            {filteredTasks.length>0&&<span style={{fontSize:'11px',fontWeight:'700',color:'var(--color-sage-dark)',whiteSpace:'nowrap',marginLeft:'8px',background:'var(--color-sage-soft)',padding:'3px 9px',borderRadius:'99px'}}>{done}/{filteredTasks.length} ✓</span>}
          </div>

          <div style={{display:'flex',flexDirection:'column',gap:'9px'}}>
            {filteredTasks.length===0?(
              <div style={{textAlign:'center',padding:'36px',background:'rgba(255,255,255,0.7)',backdropFilter:'blur(16px)',borderRadius:'20px',border:'1px solid rgba(255,255,255,0.5)'}}>
                <div style={{fontSize:'30px',marginBottom:'8px'}}>✅</div>
                <p style={{fontSize:'13px',color:'var(--color-text-muted)',fontStyle:'italic'}}>{search?'No tasks match.':'Tap + Add Task to get started.'}</p>
              </div>
            ):filteredTasks.map(task=>{
              const pc=PRIORITY_COLOR[task.priority]||PRIORITY_COLOR.Medium;
              const pb=PRIORITY_BG[task.priority]||PRIORITY_BG.Medium;
              const pt=PRIORITY_TEXT[task.priority]||PRIORITY_TEXT.Medium;
              return (
                <div key={task.id} className={sparkId===task.id?'sparkle-pop':''} style={{background:'rgba(255,255,255,0.88)',backdropFilter:'blur(20px)',border:'1px solid rgba(255,255,255,0.65)',borderLeft:`3.5px solid ${pc}`,borderRadius:'18px',padding:'13px 12px 13px 14px',display:'flex',alignItems:'flex-start',gap:'11px',boxShadow:'0 2px 10px rgba(46,38,31,0.06)',opacity:task.done?0.5:1,transition:'var(--transition-smooth)'}}>
                  <button onClick={()=>toggleTask(task)} style={{background:'none',border:'none',cursor:'pointer',padding:0,marginTop:'1px',flexShrink:0}}>
                    {task.done?<CheckCircle2 size={20} color="var(--color-sage)"/>:<Circle size={20} color="var(--color-border-strong)"/>}
                  </button>
                  <div style={{flex:1,minWidth:0,cursor:'pointer'}} onClick={()=>openEdit(task)}>
                    <p style={{fontSize:'13.5px',fontWeight:task.priority==='High'?'700':'500',color:task.done?'var(--color-text-subtle)':'var(--color-text-main)',textDecoration:task.done?'line-through':'none',marginBottom:'5px',lineHeight:'1.4',wordBreak:'break-word',letterSpacing:'-0.01em'}}>{task.title}</p>
                    <div style={{display:'flex',gap:'5px',flexWrap:'wrap',alignItems:'center'}}>
                      <span style={{fontSize:'10px',fontWeight:'700',padding:'2px 8px',borderRadius:'99px',background:pb,color:pt,letterSpacing:'0.01em'}}>{task.priority}</span>
                      <span style={{fontSize:'10px',padding:'2px 8px',borderRadius:'99px',background:'var(--color-bg-base)',color:'var(--color-text-muted)',fontWeight:'600',border:'1px solid var(--color-border)'}}>{task.category}</span>
                      <span style={{fontSize:'10px',color:'var(--color-text-subtle)',fontWeight:'500'}}>· {task.assignee}</span>
                      {task.recurring&&task.recurring!=='None'&&<span style={{fontSize:'10px',color:'var(--color-sage-dark)',fontWeight:'700'}}>↻ {task.recurring}</span>}
                    </div>
                    {task.notes&&<p style={{fontSize:'11px',color:'var(--color-text-subtle)',marginTop:'5px',fontStyle:'italic',lineHeight:1.4}}>{task.notes}</p>}
                  </div>
                  <div style={{display:'flex',flexDirection:'column',gap:'1px',flexShrink:0}}>
                    <button onClick={()=>openEdit(task)} style={{background:'none',border:'none',color:'var(--color-text-subtle)',cursor:'pointer',padding:'5px',borderRadius:'7px',transition:'var(--transition-fast)'}}><Edit3 size={13}/></button>
                    <button onClick={()=>dbService.deleteTask(task.id)} style={{background:'none',border:'none',color:'var(--color-danger)',opacity:0.55,cursor:'pointer',padding:'5px',borderRadius:'7px',transition:'var(--transition-fast)'}}><Trash2 size={13}/></button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* ═══════════════ CALENDAR TAB ═══════════════ */}
      {tab==='calendar'&&(
        <div className="fade-in">
          {/* Sync button */}
          <button onClick={syncFeed} disabled={syncing} style={{display:'flex',alignItems:'center',gap:'8px',width:'100%',padding:'11px 16px',borderRadius:'14px',background:'var(--color-accent-soft)',border:'1px solid rgba(217,132,74,0.18)',cursor:'pointer',marginBottom:'14px',fontFamily:'var(--font-sans)',fontWeight:'600',fontSize:'12.5px',color:'var(--color-primary-dark)',boxShadow:'var(--shadow-xs)',letterSpacing:'-0.01em'}}>
            <RefreshCw size={14} className={syncing?'spinning':''} color="var(--color-accent-deep)"/>
            {syncing?'Syncing school feed…':'Sync Lincoln Elementary & Soccer League'}
          </button>

          {/* Day strip */}
          <div className="scroll-row" style={{marginBottom:'16px'}}>
            {dayStrip.map(d=>(
              <button key={d.str} onClick={()=>setSelectedDate(d.str)} style={{flexShrink:0,display:'flex',flexDirection:'column',alignItems:'center',padding:'10px 13px',borderRadius:'16px',border:`1.5px solid ${selectedDate===d.str?'var(--color-accent)':'var(--color-border)'}`,background:selectedDate===d.str?'linear-gradient(145deg,var(--color-accent-soft),#FAE8D2)':'var(--color-bg-card)',cursor:'pointer',minWidth:'52px',transition:'var(--transition-smooth)',boxShadow:selectedDate===d.str?'0 3px 12px rgba(217,132,74,0.18)':'var(--shadow-xs)'}}>
                <span style={{fontSize:'9.5px',color:selectedDate===d.str?'var(--color-accent-deep)':'var(--color-text-subtle)',fontWeight:'700',letterSpacing:'0.05em',textTransform:'uppercase'}}>{d.name}</span>
                <span style={{fontSize:'17px',fontWeight:'800',color:selectedDate===d.str?'var(--color-primary-dark)':'var(--color-text-main)',margin:'3px 0',letterSpacing:'-0.02em'}}>{d.num}</span>
                {d.today&&<span style={{width:'5px',height:'5px',borderRadius:'50%',background:selectedDate===d.str?'var(--color-accent-deep)':'var(--color-sage)',boxShadow:`0 0 0 2px ${selectedDate===d.str?'rgba(217,132,74,0.25)':'rgba(122,148,118,0.2)'}`}}/>}
              </button>
            ))}
          </div>

          {/* Member filter */}
          <div style={{display:'flex',gap:'5px',marginBottom:'14px',overflowX:'auto'}}>
            {['All','Kids','Mom','Dad','Shared'].map(m=>(
              <button key={m} onClick={()=>setCalFilter(m)} style={{padding:'5px 13px',borderRadius:'20px',fontSize:'11px',fontWeight:'700',border:'none',background:calFilter===m?'var(--color-primary-dark)':'var(--color-bg-card)',color:calFilter===m?'#F8F3EE':'var(--color-text-muted)',cursor:'pointer',whiteSpace:'nowrap',transition:'var(--transition-smooth)',boxShadow:calFilter===m?'0 2px 8px rgba(46,38,31,0.18)':'var(--shadow-xs)',letterSpacing:'-0.01em'}}>{m}</button>
            ))}
          </div>

          {/* Events list */}
          {dayEvents.length===0?(
            <div style={{textAlign:'center',padding:'36px 24px',background:'rgba(255,255,255,0.75)',backdropFilter:'blur(20px)',borderRadius:'22px',border:'1px solid rgba(255,255,255,0.6)',boxShadow:'var(--shadow-sm)'}}>
              <div style={{fontSize:'30px',marginBottom:'10px'}}>📅</div>
              <p style={{fontSize:'13px',color:'var(--color-text-muted)',fontStyle:'italic'}}>No events for this day.</p>
              <p style={{fontSize:'11.5px',color:'var(--color-text-subtle)',marginTop:'4px'}}>Tap + Add Event to get started.</p>
            </div>
          ):(
            <div style={{display:'flex',flexDirection:'column',gap:'9px'}}>
              {dayEvents.map(ev=>(
                <div key={ev.id} style={{display:'flex',gap:'12px',background:'rgba(255,255,255,0.88)',backdropFilter:'blur(20px)',border:'1px solid rgba(255,255,255,0.65)',borderLeft:`3.5px solid ${ev.color||'var(--color-primary)'}`,borderRadius:'18px',padding:'13px 13px 13px 15px',boxShadow:'0 2px 10px rgba(46,38,31,0.06)'}}>
                  <div style={{flex:1}}>
                    <p style={{fontSize:'13.5px',fontWeight:'600',color:'var(--color-text-main)',marginBottom:'5px',letterSpacing:'-0.01em'}}>{ev.title}</p>
                    <div style={{display:'flex',gap:'8px',alignItems:'center'}}>
                      <span style={{fontSize:'11px',color:'var(--color-text-muted)',display:'flex',alignItems:'center',gap:'3px',fontWeight:'500'}}><Clock size={11}/>{ev.time}</span>
                      <span style={{fontSize:'10px',padding:'2px 9px',borderRadius:'99px',fontWeight:'700',background:`${ev.color}22`,color:ev.color}}>{ev.member}</span>
                    </div>
                    {ev.notes&&<p style={{fontSize:'11px',color:'var(--color-text-subtle)',marginTop:'5px',fontStyle:'italic',lineHeight:1.4}}>{ev.notes}</p>}
                  </div>
                  <button onClick={()=>dbService.deleteEvent(ev.id)} style={{background:'none',border:'none',color:'var(--color-danger)',opacity:0.5,cursor:'pointer',padding:'5px',flexShrink:0,alignSelf:'flex-start',borderRadius:'7px',transition:'var(--transition-fast)'}}><Trash2 size={14}/></button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ═══ CENTERED MODAL — Add Task ═══ */}
      {showAddTask&&(
        <Modal title="Add New Task" onClose={()=>setShowAddTask(false)} onSubmit={handleAddTask} submitLabel="✓ Create Task">
          <TaskFields form={taskForm} onChange={setT}/>
        </Modal>
      )}

      {/* ═══ CENTERED MODAL — Edit Task ═══ */}
      {editTask&&(
        <Modal title="Edit Task" onClose={()=>setEditTask(null)} onSubmit={handleSaveEdit} submitLabel="✓ Save Changes">
          <TaskFields form={editForm} onChange={setE}/>
        </Modal>
      )}

      {/* ═══ CENTERED MODAL — Add Event ═══ */}
      {showAddEvent&&(
        <Modal title="Add Event" onClose={()=>setShowAddEvent(false)} onSubmit={handleAddEvent} submitLabel="✓ Add to Calendar">
          <div style={{display:'flex',flexDirection:'column',gap:'12px'}}>
            <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Event Title</label>
              <input type="text" className="form-input" placeholder="e.g. Soccer practice" value={eventForm.title} onChange={e=>setEv('title',e.target.value)} required autoFocus/>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:'10px'}}>
              <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Date</label>
                <input type="date" className="form-input" value={eventForm.date} onChange={e=>setEv('date',e.target.value)}/>
              </div>
              <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Time</label>
                <input type="time" className="form-input" value={eventForm.time} onChange={e=>setEv('time',e.target.value)}/>
              </div>
            </div>
            <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Member</label>
              <div style={{display:'flex',gap:'6px'}}>
                {['Kids','Mom','Dad','Shared'].map(m=>(
                  <button key={m} type="button" onClick={()=>setEv('member',m)} style={{flex:1,padding:'8px 4px',borderRadius:'10px',border:`1.5px solid ${eventForm.member===m?MEMBER_COLOR[m]:'var(--color-border)'}`,background:eventForm.member===m?`${MEMBER_COLOR[m]}22`:'var(--color-bg-card)',fontSize:'11px',fontWeight:'600',cursor:'pointer',color:eventForm.member===m?MEMBER_COLOR[m]:'var(--color-text-muted)',transition:'var(--transition-smooth)'}}>{m}</button>
                ))}
              </div>
            </div>
            <div><label className="label-caps" style={{display:'block',marginBottom:'5px'}}>Notes</label>
              <textarea className="form-input" placeholder="Optional notes…" style={{height:'60px',resize:'none'}} value={eventForm.notes} onChange={e=>setEv('notes',e.target.value)}/>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}
