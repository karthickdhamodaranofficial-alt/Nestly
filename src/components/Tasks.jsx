import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Plus, CheckCircle2, Circle, Trash2, Search, Zap, Edit3, X } from 'lucide-react';
import { dbService } from '../services/firebase';

const CATEGORIES = ['Home', 'Kids', 'Meals', 'General'];
const ASSIGNEES   = ['Shared', 'Mom', 'Dad'];
const RECURRINGS  = ['None', 'Daily', 'Weekly', 'Monthly'];

const PRIORITY_COLORS = {
  High:   { border: '#C9813A', chip: '#FFF3E8', text: '#9A5A1A' },
  Medium: { border: '#B5A8C8', chip: '#F4F1F8', text: '#6B5B8A' },
  Low:    { border: '#8F9E8B', chip: '#E8ECE7', text: '#4E6B4A' },
};

const ASSIGNEE_STYLE = {
  Mom:    { bg: '#F4F1F8', color: '#6B5B8A', initials: 'M' },
  Dad:    { bg: '#EEF3FA', color: '#4A6FA5', initials: 'D' },
  Shared: { bg: '#E8ECE7', color: '#4E6B4A', initials: 'S' },
};


const emptyForm = () => ({
  title: '', category: 'Home', priority: 'Medium',
  assignee: 'Shared', dueDate: new Date().toISOString().split('T')[0],
  recurring: 'None', notes: '',
});

function detectPriority(val) {
  const l = val.toLowerCase();
  if (/urgent|immediately|tonight|asap/.test(l)) return 'High';
  if (/weekly|maybe|someday/.test(l)) return 'Low';
  return 'Medium';
}

/* ── Shared drawer shell ── */
function Drawer({ title, onClose, onSubmit, submitLabel, children }) {
  const root = document.getElementById('nestly-modal-root');
  if (!root) return null;
  return createPortal(
    <div
      onClick={onClose}
      style={{ position: 'absolute', inset: 0, background: 'rgba(30,24,18,0.6)', backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '24px', pointerEvents: 'all' }}
    >
      <form
        onSubmit={onSubmit}
        onClick={e => e.stopPropagation()}
        className="slide-up-drawer"
        style={{ width: '100%', maxWidth: '380px', background: 'var(--color-bg-base)', borderRadius: '28px', padding: '24px', boxShadow: '0 28px 80px rgba(0,0,0,0.35)', maxHeight: '82%', overflowY: 'auto' }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h2 className="font-serif-heading" style={{ fontSize: '19px', color: 'var(--color-primary-dark)' }}>{title}</h2>
          <button type="button" onClick={onClose} style={{ background: 'var(--color-bg-card)', border: '1px solid var(--color-border)', borderRadius: '50%', width: '30px', height: '30px', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: 'var(--color-text-muted)' }}>
            <X size={14} />
          </button>
        </div>

        {children}

        <button type="submit" className="btn-primary" style={{ marginTop: '16px' }}>{submitLabel}</button>
      </form>
    </div>,
    root
  );
}

/* ── Form fields shared between add & edit ── */
function TaskFormFields({ form, setForm }) {
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const handleTitle = (v) => setForm(f => ({ ...f, title: v, priority: detectPriority(v) }));

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
      {/* Task Name */}
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
          <label className="label-caps">Task Name</label>
          {form.priority === 'High' && (
            <span style={{ fontSize: '10px', color: 'var(--color-accent-deep)', fontWeight: '700', display: 'flex', alignItems: 'center', gap: '3px' }}>
              <Zap size={10} fill="var(--color-accent)" /> Auto: High Priority
            </span>
          )}
        </div>
        <input
          type="text"
          className="form-input"
          placeholder="e.g. Clean school uniforms tonight"
          value={form.title}
          onChange={e => handleTitle(e.target.value)}
          required
          autoFocus
        />
      </div>

      {/* Category + Priority */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
        <div>
          <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Category</label>
          <select className="form-input" value={form.category} onChange={e => set('category', e.target.value)}>
            {CATEGORIES.map(c => <option key={c}>{c}</option>)}
          </select>
        </div>
        <div>
          <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Priority</label>
          <select className="form-input" value={form.priority} onChange={e => set('priority', e.target.value)}>
            <option value="Low">🌿 Low</option>
            <option value="Medium">🔵 Medium</option>
            <option value="High">🔥 High</option>
          </select>
        </div>
      </div>

      {/* Assignee + Due Date */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
        <div>
          <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Assignee</label>
          <select className="form-input" value={form.assignee} onChange={e => set('assignee', e.target.value)}>
            {ASSIGNEES.map(a => <option key={a}>{a}</option>)}
          </select>
        </div>
        <div>
          <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Due Date</label>
          <input type="date" className="form-input" value={form.dueDate} onChange={e => set('dueDate', e.target.value)} />
        </div>
      </div>

      {/* Recurring */}
      <div>
        <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Recurring</label>
        <div style={{ display: 'flex', gap: '8px' }}>
          {RECURRINGS.map(r => (
            <button key={r} type="button" onClick={() => set('recurring', r)}
              style={{ flex: 1, padding: '8px 4px', borderRadius: '10px', border: `1.5px solid ${form.recurring === r ? 'var(--color-sage)' : 'var(--color-border)'}`, background: form.recurring === r ? 'var(--color-sage-soft)' : 'var(--color-bg-card)', fontSize: '11px', fontWeight: '600', cursor: 'pointer', color: form.recurring === r ? 'var(--color-sage-dark)' : 'var(--color-text-muted)', transition: 'var(--transition-smooth)' }}>
              {r}
            </button>
          ))}
        </div>
      </div>

      {/* Notes */}
      <div>
        <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Notes</label>
        <textarea
          className="form-input"
          placeholder="Any helpful details…"
          style={{ height: '72px', resize: 'none', lineHeight: '1.5' }}
          value={form.notes}
          onChange={e => set('notes', e.target.value)}
        />
      </div>
    </div>
  );
}

/* ── Main Component ── */
export default function Tasks({ user, profile }) {
  const [tasks, setTasks] = useState([]);
  const [filter, setFilter] = useState('All');
  const [search, setSearch] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [editingTask, setEditingTask] = useState(null);
  const [addForm, setAddForm] = useState(emptyForm());
  const [editForm, setEditForm] = useState(emptyForm());
  const [sparkId, setSparkId] = useState(null);

  useEffect(() => {
    const unsub = dbService.subscribeTasks(t => setTasks(t || []));
    return () => unsub();
  }, []);

  const handleToggle = (task) => {
    const updated = { ...task, done: !task.done };
    dbService.saveTask(updated);
    if (updated.done) { setSparkId(task.id); setTimeout(() => setSparkId(null), 700); }
  };

  const handleAdd = (e) => {
    e.preventDefault();
    if (!addForm.title.trim()) return;
    dbService.saveTask({ id: `task-${Date.now()}`, ...addForm, done: false });
    setAddForm(emptyForm());
    setShowAdd(false);
  };

  const openEdit = (task) => { setEditingTask(task); setEditForm({ title: task.title || '', category: task.category || 'Home', priority: task.priority || 'Medium', assignee: task.assignee || 'Shared', dueDate: task.dueDate || new Date().toISOString().split('T')[0], recurring: task.recurring || 'None', notes: task.notes || '' }); };

  const handleSaveEdit = (e) => {
    e.preventDefault();
    if (!editingTask || !editForm.title.trim()) return;
    dbService.saveTask({ ...editingTask, ...editForm });
    setEditingTask(null);
  };


  const filtered = tasks.filter(t => {
    if (!t) return false;
    const catOk = filter === 'All' || t.category === filter;
    const q = search.toLowerCase();
    const textOk = !q || (t.title || '').toLowerCase().includes(q) || (t.notes || '').toLowerCase().includes(q);
    return catOk && textOk;
  });

  const doneCount  = filtered.filter(t => t.done).length;
  const totalCount = filtered.length;

  const AssigneeBadge = ({ name }) => {
    const s = ASSIGNEE_STYLE[name] || ASSIGNEE_STYLE.Shared;
    return (
      <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', fontSize: '10.5px', fontWeight: '600', color: s.color }}>
        <span style={{ width: '16px', height: '16px', borderRadius: '50%', background: s.bg, color: s.color, fontSize: '8px', fontWeight: '800', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>{s.initials}</span>
        {name}
      </span>
    );
  };

  return (
    <div className="fade-in" style={{ position: 'relative' }}>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
        <div>
          <h1 className="font-serif-heading" style={{ fontSize: '24px', color: 'var(--color-primary-dark)', marginBottom: '3px' }}>Family Tasks</h1>
          <p style={{ color: 'var(--color-text-muted)', fontSize: '12.5px' }}>Proactive checklists for your household</p>
        </div>
        <button
          onClick={() => { setShowAdd(true); setAddForm(emptyForm()); }}
          style={{ display: 'flex', alignItems: 'center', gap: '5px', padding: '9px 16px', borderRadius: '20px', background: 'linear-gradient(145deg, var(--color-primary), var(--color-primary-dark))', color: '#F8F3EE', border: 'none', cursor: 'pointer', fontSize: '12px', fontWeight: '700', boxShadow: '0 4px 14px rgba(46,38,31,0.22)', transition: 'var(--transition-bounce)', flexShrink: 0, letterSpacing: '-0.01em' }}
        >
          <Plus size={14} /> Add Task
        </button>
      </div>

      {/* Search */}
      <div style={{ position: 'relative', marginBottom: '14px' }}>
        <Search size={15} style={{ position: 'absolute', left: '15px', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-subtle)' }} />
        <input type="text" className="form-input" style={{ paddingLeft: '42px' }} placeholder="Search tasks…" value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {/* Filter Chips + Count */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <div style={{ display: 'flex', gap: '5px', overflowX: 'auto' }}>
          {['All', ...CATEGORIES.filter(c => c !== 'General')].map(cat => (
            <button key={cat} onClick={() => setFilter(cat)}
              style={{ padding: '5px 13px', borderRadius: '20px', fontSize: '11px', fontWeight: '700', border: 'none', background: filter === cat ? 'var(--color-primary-dark)' : 'var(--color-bg-card)', color: filter === cat ? '#F8F3EE' : 'var(--color-text-muted)', cursor: 'pointer', whiteSpace: 'nowrap', boxShadow: filter === cat ? '0 2px 8px rgba(46,38,31,0.18)' : 'var(--shadow-xs)', transition: 'var(--transition-smooth)', letterSpacing: '-0.01em' }}>
              {cat}
            </button>
          ))}
        </div>
        {totalCount > 0 && (
          <span style={{ fontSize: '11px', fontWeight: '700', color: 'var(--color-sage-dark)', whiteSpace: 'nowrap', marginLeft: '8px', background: 'var(--color-sage-soft)', padding: '3px 9px', borderRadius: '99px' }}>
            {doneCount}/{totalCount} ✓
          </span>
        )}
      </div>

      {/* Task Cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', minHeight: '120px' }}>
        {filtered.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px 20px', background: 'rgba(255,255,255,0.7)', backdropFilter: 'blur(16px)', borderRadius: '20px', border: '1px solid rgba(255,255,255,0.5)' }}>
            <div style={{ fontSize: '32px', marginBottom: '10px' }}>✅</div>
            <p style={{ fontSize: '13px', color: 'var(--color-text-muted)', fontStyle: 'italic' }}>
              {search ? 'No tasks match your search.' : 'All clear! Tap + Add Task to get started.'}
            </p>
          </div>
        ) : (
          filtered.map(task => {
            const pc = PRIORITY_COLORS[task.priority] || PRIORITY_COLORS.Medium;
            const isSpark = sparkId === task.id;
            return (
              <div key={task.id} className={isSpark ? 'sparkle-pop' : ''} style={{ background: 'rgba(255,255,255,0.88)', backdropFilter: 'blur(20px)', border: '1px solid rgba(255,255,255,0.65)', borderLeft: `3.5px solid ${pc.border}`, borderRadius: '18px', padding: '13px 12px 13px 14px', display: 'flex', alignItems: 'flex-start', gap: '11px', boxShadow: '0 2px 10px rgba(46,38,31,0.06)', opacity: task.done ? 0.5 : 1, transition: 'var(--transition-smooth)' }}>

                {/* Checkbox */}
                <button onClick={() => handleToggle(task)} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, marginTop: '1px', flexShrink: 0 }}>
                  {task.done
                    ? <CheckCircle2 size={20} color="var(--color-sage)" />
                    : <Circle size={20} color="var(--color-border-strong)" />
                  }
                </button>

                {/* Content */}
                <div style={{ flex: 1, minWidth: 0, cursor: 'pointer' }} onClick={() => openEdit(task)}>
                  <p style={{ fontSize: '13.5px', fontWeight: task.priority === 'High' ? '700' : '500', color: task.done ? 'var(--color-text-subtle)' : 'var(--color-text-main)', textDecoration: task.done ? 'line-through' : 'none', marginBottom: '5px', lineHeight: '1.4', wordBreak: 'break-word', letterSpacing: '-0.01em' }}>
                    {task.title}
                  </p>
                  <div style={{ display: 'flex', gap: '5px', flexWrap: 'wrap', alignItems: 'center' }}>
                    <span style={{ fontSize: '10px', fontWeight: '700', padding: '2px 8px', borderRadius: '99px', background: pc.chip, color: pc.text, letterSpacing: '0.01em' }}>{task.priority}</span>
                    <span style={{ fontSize: '10px', padding: '2px 8px', borderRadius: '99px', background: 'var(--color-bg-base)', color: 'var(--color-text-muted)', fontWeight: '600', border: '1px solid var(--color-border)' }}>{task.category}</span>
                    <AssigneeBadge name={task.assignee || 'Shared'} />
                    {task.recurring && task.recurring !== 'None' && (
                      <span style={{ fontSize: '10px', color: 'var(--color-sage-dark)', fontWeight: '700' }}>↻ {task.recurring}</span>
                    )}
                  </div>
                  {task.notes && (
                    <p style={{ fontSize: '11px', color: 'var(--color-text-subtle)', marginTop: '5px', fontStyle: 'italic', lineHeight: '1.4' }}>{task.notes}</p>
                  )}
                </div>

                {/* Actions */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1px', flexShrink: 0 }}>
                  <button onClick={() => openEdit(task)} style={{ background: 'none', border: 'none', color: 'var(--color-text-subtle)', cursor: 'pointer', padding: '5px', borderRadius: '7px', transition: 'var(--transition-fast)' }}>
                    <Edit3 size={13} />
                  </button>
                  <button onClick={() => dbService.deleteTask(task.id)} style={{ background: 'none', border: 'none', color: 'var(--color-danger)', opacity: 0.55, cursor: 'pointer', padding: '5px', borderRadius: '7px', transition: 'var(--transition-fast)' }}>
                    <Trash2 size={13} />
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* ── ADD TASK DRAWER ── */}
      {showAdd && (
        <Drawer title="Add New Task" onClose={() => setShowAdd(false)} onSubmit={handleAdd} submitLabel="✓ Create Task">
          <TaskFormFields form={addForm} setForm={setAddForm} />
        </Drawer>
      )}

      {/* ── EDIT TASK DRAWER ── */}
      {editingTask && (
        <Drawer title="Edit Task" onClose={() => setEditingTask(null)} onSubmit={handleSaveEdit} submitLabel="✓ Save Changes">
          <TaskFormFields form={editForm} setForm={setEditForm} />
        </Drawer>
      )}
    </div>
  );
}
