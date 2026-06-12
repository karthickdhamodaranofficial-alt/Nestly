import { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { Sparkles, ShoppingBag, Utensils, Plus, Trash2, ChevronRight, ChevronDown, Check } from 'lucide-react';
import { dbService } from '../services/firebase';

const DAYS = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
const MEAL_EMOJIS = { breakfast: '🥐', lunch: '🥪', dinner: '🍲' };
const CATEGORIES = ['Produce','Dairy & Eggs','Pantry','Meat & Seafood','Household'];

const CAT_META = {
  'Produce':       { color: '#7A9476', bg: '#E5EDE4', icon: '🥦' },
  'Dairy & Eggs':  { color: '#A496BB', bg: '#F0EDF6', icon: '🥛' },
  'Pantry':        { color: '#D9844A', bg: '#F6EDE0', icon: '🫙' },
  'Meat & Seafood':{ color: '#B87070', bg: '#FAF0F0', icon: '🥩' },
  'Household':     { color: '#8AADD8', bg: '#EAF1FA', icon: '🧹' },
};

const QUICK_ADDS = [
  { title: 'Milk',     category: 'Dairy & Eggs', emoji: '🥛' },
  { title: 'Eggs',     category: 'Dairy & Eggs', emoji: '🥚' },
  { title: 'Bread',    category: 'Pantry',        emoji: '🍞' },
  { title: 'Bananas',  category: 'Produce',       emoji: '🍌' },
  { title: 'Cheese',   category: 'Dairy & Eggs',  emoji: '🧀' },
  { title: 'Tomatoes', category: 'Produce',       emoji: '🍅' },
  { title: 'Chicken',  category: 'Meat & Seafood',emoji: '🍗' },
  { title: 'Rice',     category: 'Pantry',        emoji: '🍚' },
  { title: 'Butter',   category: 'Dairy & Eggs',  emoji: '🧈' },
  { title: 'Apples',   category: 'Produce',       emoji: '🍎' },
];

const TODAY_DAY = (() => {
  const d = new Date().getDay();
  return DAYS[d === 0 ? 6 : d - 1];
})();

export default function Meals({ profile }) {
  const [meals, setMeals]             = useState({});
  const [shoppingList, setShoppingList] = useState([]);
  const [newItem, setNewItem]           = useState('');
  const [newCategory, setNewCategory]   = useState('Produce');
  const [activeSubTab, setActiveSubTab] = useState('planner');
  const [collapsedAisles, setCollapsedAisles] = useState({});
  const [editingDay, setEditingDay]     = useState(null);
  const [editB, setEditB]               = useState('');
  const [editL, setEditL]               = useState('');
  const [editD, setEditD]               = useState('');
  const inputRef = useRef(null);

  useEffect(() => {
    const unsub = dbService.subscribeMeals(setMeals);
    const local = JSON.parse(localStorage.getItem('nestly_shopping') || '[]');
    setShoppingList(local);
    return () => unsub();
  }, []);

  const handleEditDay = (day) => {
    setEditingDay(day);
    setEditB(meals[day]?.breakfast || '');
    setEditL(meals[day]?.lunch || '');
    setEditD(meals[day]?.dinner || '');
  };

  const handleSaveDay = () => {
    dbService.saveMeals({ ...meals, [editingDay]: { breakfast: editB, lunch: editL, dinner: editD } });
    setEditingDay(null);
  };

  const addUnique = (arr, title, category) => {
    if (!arr.some(i => i.title.toLowerCase() === title.toLowerCase()))
      arr.push({ id: `gro-${Date.now()}-${Math.random()}`, title, category, done: false });
  };

  const autoGenerate = () => {
    const list = [...shoppingList];
    Object.values(meals).forEach(m => {
      const d = (m?.dinner || '').toLowerCase();
      if (d.includes('pasta') || d.includes('mac')) { addUnique(list, 'Pasta', 'Pantry'); addUnique(list, 'Shredded cheddar', 'Dairy & Eggs'); }
      if (d.includes('taco')) { addUnique(list, 'Taco shells', 'Pantry'); addUnique(list, 'Avocados', 'Produce'); }
      if (d.includes('chicken') || d.includes('beef')) addUnique(list, 'Free-range chicken breast', 'Meat & Seafood');
      if (d.includes('curry') || d.includes('lentil')) { addUnique(list, 'Coconut milk', 'Pantry'); addUnique(list, 'Red lentils', 'Pantry'); }
      if (d.includes('pizza')) { addUnique(list, 'Pizza dough', 'Pantry'); addUnique(list, 'Mozzarella', 'Dairy & Eggs'); }
      if (d.includes('stir fry') || d.includes('stir-fry')) { addUnique(list, 'Soy sauce', 'Pantry'); addUnique(list, 'Mixed vegetables', 'Produce'); }
    });
    saveGrocery(list);
  };

  const addGrocery = () => {
    const trimmed = newItem.trim();
    if (!trimmed) { inputRef.current?.focus(); return; }
    saveGrocery([...shoppingList, { id: `gro-${Date.now()}`, title: trimmed, category: newCategory, done: false }]);
    setNewItem('');
    inputRef.current?.focus();
  };

  const addQuick = (item) => {
    if (shoppingList.some(i => i.title.toLowerCase() === item.title.toLowerCase())) return;
    saveGrocery([...shoppingList, { id: `gro-${Date.now()}`, title: item.title, category: item.category, done: false }]);
  };

  const toggleGrocery = (id) => saveGrocery(shoppingList.map(i => i.id === id ? { ...i, done: !i.done } : i));
  const deleteGrocery = (id) => saveGrocery(shoppingList.filter(i => i.id !== id));
  const clearDone = () => saveGrocery(shoppingList.filter(i => !i.done));
  const saveGrocery = (list) => { setShoppingList(list); localStorage.setItem('nestly_shopping', JSON.stringify(list)); };

  const grouped = shoppingList.reduce((g, i) => { (g[i.category] = g[i.category] || []).push(i); return g; }, {});
  const totalCount = shoppingList.length;
  const doneCount  = shoppingList.filter(i => i.done).length;
  const pendingCount = totalCount - doneCount;
  const allDone    = totalCount > 0 && doneCount === totalCount;

  const addedTitles = new Set(shoppingList.map(i => i.title.toLowerCase()));

  return (
    <div className="fade-in">

      {/* Header */}
      <div style={{ marginBottom: '16px' }}>
        <h1 className="font-serif-heading" style={{ fontSize: '24px', color: 'var(--color-primary-dark)', marginBottom: '3px' }}>Meal Operations</h1>
        <p style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>Nourishing your household with clarity</p>
      </div>

      {/* Sub-tab bar */}
      <div className="subtab-bar">
        <button className={`subtab-btn ${activeSubTab === 'planner' ? 'active' : 'inactive'}`} onClick={() => setActiveSubTab('planner')}>
          <Utensils size={13} /> Weekly Menu
        </button>
        <button className={`subtab-btn ${activeSubTab === 'shopping' ? 'active' : 'inactive'}`} onClick={() => setActiveSubTab('shopping')}>
          <ShoppingBag size={13} />
          Grocery{pendingCount > 0 ? <span style={{ background: 'var(--color-accent)', color: '#fff', borderRadius: '99px', fontSize: '9px', fontWeight: '800', padding: '1px 6px', marginLeft: '4px' }}>{pendingCount}</span> : ''}
        </button>
      </div>

      {/* ── PLANNER TAB ── */}
      {activeSubTab === 'planner' && (
        <div className="fade-in">
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {DAYS.map(day => {
              const plan = meals[day] || {};
              const hasData = plan.breakfast || plan.lunch || plan.dinner;
              const isToday = day === TODAY_DAY;
              return (
                <div key={day} className="nestly-card" style={{
                  padding: '14px 18px',
                  borderLeft: isToday ? '3px solid var(--color-accent)' : '3px solid transparent',
                  background: isToday ? 'linear-gradient(135deg, #FFFEFB 0%, #FEF8F2 100%)' : undefined,
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: hasData ? '10px' : '0' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <h3 style={{ fontSize: '14px', fontWeight: '700', color: 'var(--color-primary-dark)' }}>{day}</h3>
                      {isToday && <span style={{ fontSize: '9px', fontWeight: '800', color: 'var(--color-accent-deep)', background: 'var(--color-accent-soft)', borderRadius: '6px', padding: '2px 7px', letterSpacing: '0.04em', textTransform: 'uppercase' }}>Today</span>}
                    </div>
                    <button onClick={() => handleEditDay(day)} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', fontSize: '11.5px', fontWeight: '600', cursor: 'pointer', padding: '4px 8px', borderRadius: '8px' }}>
                      {hasData ? 'Edit' : '+ Plan'}
                    </button>
                  </div>
                  {hasData && (
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1.2fr', gap: '8px' }}>
                      {['breakfast','lunch','dinner'].map(key => (
                        plan[key] ? (
                          <div key={key} style={{ background: 'rgba(255,255,255,0.7)', borderRadius: '10px', padding: '7px 9px' }}>
                            <span style={{ color: 'var(--color-text-subtle)', fontSize: '9px', fontWeight: '700', display: 'block', marginBottom: '2px', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                              {MEAL_EMOJIS[key]} {key}
                            </span>
                            <span style={{ fontSize: '11.5px', fontWeight: key === 'dinner' ? '700' : '500', color: key === 'dinner' ? 'var(--color-primary-dark)' : 'var(--color-text-body)', lineHeight: 1.3, display: 'block' }}>
                              {plan[key]}
                            </span>
                          </div>
                        ) : null
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Edit Modal */}
          {editingDay && createPortal(
            <div onClick={() => setEditingDay(null)} style={{ position:'absolute', inset:0, background:'rgba(30,24,18,0.6)', backdropFilter:'blur(12px)', WebkitBackdropFilter:'blur(12px)', display:'flex', justifyContent:'center', alignItems:'center', padding:'24px', pointerEvents:'all' }}>
              <div onClick={e => e.stopPropagation()} className="slide-up-drawer" style={{ width:'100%', maxWidth:'380px', background:'var(--color-bg-base)', borderRadius:'28px', padding:'24px', boxShadow:'0 28px 80px rgba(0,0,0,0.35)', maxHeight:'82%', overflowY:'auto' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                  <h2 className="font-serif-heading" style={{ fontSize: '19px', color: 'var(--color-primary-dark)' }}>Plan Menu: {editingDay}</h2>
                  <button onClick={() => setEditingDay(null)} style={{ background:'var(--color-bg-card)', border:'1px solid var(--color-border)', borderRadius:'50%', width:'30px', height:'30px', display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', color:'var(--color-text-muted)' }}>✕</button>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  {[
                    ['🥐 BREAKFAST', editB, setEditB, 'e.g. Scrambled eggs & fruit'],
                    ['🥪 LUNCH',     editL, setEditL, 'e.g. Avocado toast or wrap'],
                    ['🍲 DINNER',    editD, setEditD, 'e.g. Chicken curry & rice'],
                  ].map(([label, val, setter, ph]) => (
                    <div key={label}>
                      <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>{label}</label>
                      <input type="text" className="form-input" value={val} onChange={e => setter(e.target.value)} placeholder={ph} />
                    </div>
                  ))}
                  <button onClick={handleSaveDay} className="btn-primary" style={{ marginTop: '6px' }}>Save Day Plan</button>
                </div>
              </div>
            </div>,
            document.getElementById('nestly-modal-root')
          )}
        </div>
      )}

      {/* ── SHOPPING TAB ── */}
      {activeSubTab === 'shopping' && (
        <div className="fade-in">

          {/* Summary bar */}
          {totalCount > 0 && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', background: allDone ? 'linear-gradient(135deg,#E8F0E7,#D9E8D7)' : 'rgba(255,255,255,0.75)', backdropFilter: 'blur(12px)', borderRadius: '18px', padding: '11px 16px', marginBottom: '12px', border: `1px solid ${allDone ? 'rgba(122,148,118,0.3)' : 'rgba(255,255,255,0.5)'}` }}>
              <div style={{ flex: 1 }}>
                <div style={{ height: '5px', background: 'rgba(0,0,0,0.07)', borderRadius: '99px', overflow: 'hidden' }}>
                  <div style={{ height: '100%', width: `${(doneCount / totalCount) * 100}%`, background: 'linear-gradient(90deg, var(--color-sage), var(--color-sage-dark))', borderRadius: '99px', transition: 'width 0.5s ease' }} />
                </div>
              </div>
              <span style={{ fontSize: '11.5px', fontWeight: '700', color: allDone ? 'var(--color-sage-dark)' : 'var(--color-text-muted)', whiteSpace: 'nowrap' }}>
                {allDone ? '✓ All done!' : `${doneCount}/${totalCount} done`}
              </span>
              {doneCount > 0 && (
                <button onClick={clearDone} style={{ background: 'none', border: 'none', fontSize: '10.5px', fontWeight: '700', color: 'var(--color-danger)', cursor: 'pointer', padding: '2px 6px', borderRadius: '8px', flexShrink: 0 }}>
                  Clear ✓
                </button>
              )}
            </div>
          )}

          {/* Action buttons row */}
          <div style={{ display: 'flex', gap: '8px', marginBottom: '12px' }}>
            <button onClick={autoGenerate} className="btn-secondary" style={{ padding: '10px 14px', fontSize: '12px', display: 'flex', gap: '6px', alignItems: 'center', background: 'var(--color-accent-soft)', borderColor: 'rgba(230,161,92,0.2)', flex: 1 }}>
              <Sparkles size={13} color="var(--color-accent)" /> Auto-Compile from Menu
            </button>
          </div>

          {/* Add item input */}
          <div style={{ display: 'flex', gap: '8px', marginBottom: '10px' }}>
            <input
              ref={inputRef}
              type="text"
              className="form-input"
              style={{ flex: 2 }}
              placeholder="Add milk, apples…"
              value={newItem}
              onChange={e => setNewItem(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && addGrocery()}
            />
            <select
              className="form-input"
              style={{ flex: 1, padding: '12px 8px' }}
              value={newCategory}
              onChange={e => setNewCategory(e.target.value)}
            >
              {CATEGORIES.map(c => <option key={c}>{c}</option>)}
            </select>
            <button
              type="button"
              onClick={addGrocery}
              className="btn-primary"
              style={{ width: '46px', height: '46px', padding: 0, borderRadius: '14px', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
            >
              <Plus size={18} />
            </button>
          </div>

          {/* Quick-add chips */}
          <div style={{ display: 'flex', gap: '7px', overflowX: 'auto', paddingBottom: '4px', marginBottom: '14px', scrollbarWidth: 'none' }}>
            {QUICK_ADDS.map(item => {
              const already = addedTitles.has(item.title.toLowerCase());
              return (
                <button
                  key={item.title}
                  type="button"
                  onClick={() => !already && addQuick(item)}
                  style={{
                    display: 'flex', alignItems: 'center', gap: '5px', flexShrink: 0,
                    padding: '6px 11px', borderRadius: '20px', fontSize: '12px', fontWeight: '600', cursor: already ? 'default' : 'pointer',
                    background: already ? 'var(--color-sage-soft)' : 'rgba(255,255,255,0.8)',
                    border: already ? '1px solid rgba(122,148,118,0.35)' : '1px solid var(--color-border)',
                    color: already ? 'var(--color-sage-dark)' : 'var(--color-text-muted)',
                    backdropFilter: 'blur(8px)', transition: 'all 0.2s ease',
                    opacity: already ? 0.7 : 1,
                  }}
                >
                  {already ? <Check size={10} color="var(--color-sage-dark)" /> : <span>{item.emoji}</span>}
                  {item.title}
                </button>
              );
            })}
          </div>

          {/* Grocery list */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {shoppingList.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '36px 20px', background: 'rgba(255,255,255,0.65)', backdropFilter: 'blur(12px)', border: '1px solid rgba(255,255,255,0.5)', borderRadius: '24px' }}>
                <div style={{ fontSize: '36px', marginBottom: '10px' }}>🛒</div>
                <p style={{ fontSize: '13.5px', fontWeight: '600', color: 'var(--color-primary-dark)', marginBottom: '5px' }}>Your list is empty</p>
                <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontStyle: 'italic' }}>Tap a quick-add chip or type above.</p>
              </div>
            ) : (
              Object.keys(grouped).map(cat => {
                const items = grouped[cat];
                const meta  = CAT_META[cat] || { color: 'var(--color-primary)', bg: 'var(--color-accent-soft)', icon: '🛒' };
                const activeCount = items.filter(i => !i.done).length;
                const collapsed   = collapsedAisles[cat];
                return (
                  <div key={cat} style={{ background: 'rgba(255,255,255,0.78)', backdropFilter: 'blur(16px)', border: '1px solid rgba(255,255,255,0.55)', borderRadius: '22px', overflow: 'hidden', boxShadow: 'var(--shadow-xs)' }}>

                    <button
                      type="button"
                      onClick={() => setCollapsedAisles(p => ({ ...p, [cat]: !p[cat] }))}
                      style={{ width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '13px 16px', border: 'none', cursor: 'pointer', background: meta.bg, fontFamily: 'var(--font-sans)' }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        {collapsed ? <ChevronRight size={13} color={meta.color} /> : <ChevronDown size={13} color={meta.color} />}
                        <span style={{ fontSize: '11px', fontWeight: '800', color: meta.color, letterSpacing: '0.06em', textTransform: 'uppercase' }}>
                          {meta.icon} {cat}
                        </span>
                      </div>
                      {activeCount > 0
                        ? <span style={{ background: meta.color, color: '#fff', padding: '2px 9px', borderRadius: '99px', fontSize: '10px', fontWeight: '800' }}>{activeCount}</span>
                        : <span style={{ color: meta.color, fontSize: '11px', fontWeight: '700' }}>✓ Done</span>
                      }
                    </button>

                    {!collapsed && (
                      <div style={{ padding: '8px 12px 12px' }}>
                        {items.map(item => (
                          <div key={item.id} style={{
                            display: 'flex', alignItems: 'center', gap: '10px',
                            background: item.done ? 'rgba(122,148,118,0.06)' : 'var(--color-bg-card)',
                            padding: '10px 12px', borderRadius: '13px', marginTop: '6px',
                            opacity: item.done ? 0.65 : 1,
                            transition: 'all 0.25s ease',
                            border: `1px solid ${item.done ? 'rgba(122,148,118,0.15)' : 'var(--color-border)'}`,
                          }}>
                            <input type="checkbox" className="custom-checkbox" checked={item.done} onChange={() => toggleGrocery(item.id)} />
                            <span style={{ flex: 1, fontSize: '13px', color: 'var(--color-text-main)', textDecoration: item.done ? 'line-through' : 'none', fontWeight: item.done ? '400' : '500' }}>
                              {item.title}
                            </span>
                            <button
                              type="button"
                              onClick={() => deleteGrocery(item.id)}
                              style={{ background: 'none', border: 'none', color: 'var(--color-danger)', opacity: 0.45, cursor: 'pointer', padding: '4px', borderRadius: '6px', display: 'flex', transition: 'opacity 0.2s' }}
                              onMouseEnter={e => e.currentTarget.style.opacity = '1'}
                              onMouseLeave={e => e.currentTarget.style.opacity = '0.45'}
                            >
                              <Trash2 size={13} />
                            </button>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
}
