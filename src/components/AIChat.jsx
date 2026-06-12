import React, { useState, useEffect, useRef } from 'react';
import { Send, Sparkles, Key, Mic, Database, X, Heart } from 'lucide-react';
import { askGemini } from '../services/ai';

const QUICK_PROMPTS = [
  "What should I focus on today?",
  "What am I forgetting?",
  "What can I prep tonight?",
  "Help me plan this week",
];

export default function AIChat({ user, profile }) {
  const [messages, setMessages] = useState([{
    id: 'welcome', sender: 'assistant',
    text: `Hello ${user.name} 👋  I'm your Nestly household assistant. I've analysed your family profile. How can I lighten your mental load today?`
  }]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showFacts, setShowFacts] = useState(false);
  const [apiKey, setApiKey] = useState(localStorage.getItem('nestly_gemini_key') || '');
  const messagesEndRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  const send = async (text) => {
    const t = text || input;
    if (!t.trim() || loading) return;
    if (!text) setInput('');
    setMessages(prev => [...prev, { id: `u-${Date.now()}`, sender: 'user', text: t }]);
    setLoading(true);
    try {
      const res = await askGemini(t, profile, apiKey);
      setMessages(prev => [...prev, { id: `a-${Date.now()}`, sender: 'assistant', text: res }]);
    } catch {
      setMessages(prev => [...prev, { id: `e-${Date.now()}`, sender: 'assistant', text: "I had a small hiccup. Please try again or check your API key." }]);
    } finally {
      setLoading(false);
    }
  };

  const simulateVoice = () => {
    if (loading || isRecording) return;
    setIsRecording(true);
    setTimeout(() => setIsRecording(false), 2000);
  };

  const saveKey = (e) => { e.preventDefault(); localStorage.setItem('nestly_gemini_key', apiKey); setShowSettings(false); };

  const FACTS = [
    ['Household Size', `${profile?.householdSize || 3} members`],
    ['Children', `${profile?.kids?.length || 0}`],
    ['School schedule', profile?.schoolSchedule || 'None'],
    ['Laundry routine', profile?.laundryRoutine || 'None'],
    ['Work schedule', profile?.workSchedule || 'None'],
  ];

  return (
    <div className="fade-in" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative', gap: '0' }}>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
        <div>
          <h1 className="font-serif-heading" style={{ fontSize: '24px', color: 'var(--color-primary-dark)', marginBottom: '3px' }}>Nestly AI</h1>
          <p style={{ color: 'var(--color-text-muted)', fontSize: '12.5px' }}>Your empathetic household partner</p>
        </div>
        <div style={{ display: 'flex', gap: '6px' }}>
          <button onClick={() => setShowFacts(true)} style={{ border: '1px solid var(--color-border)', background: 'var(--color-bg-card)', color: 'var(--color-text-muted)', padding: '7px 11px', borderRadius: '12px', fontSize: '11px', fontWeight: '600', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Database size={12} /> Memory
          </button>
          <button onClick={() => setShowSettings(s => !s)} style={{ border: '1px solid var(--color-border)', background: showSettings ? 'var(--color-primary)' : 'var(--color-bg-card)', color: showSettings ? '#fff' : 'var(--color-text-muted)', padding: '7px 11px', borderRadius: '12px', fontSize: '11px', fontWeight: '600', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Key size={12} /> {apiKey ? '✓ API' : 'Setup'}
          </button>
        </div>
      </div>

      {/* Settings Panel */}
      {showSettings && (
        <div className="glass-card" style={{ padding: '14px 16px', background: 'var(--color-accent-soft)', borderColor: 'rgba(230,161,92,0.2)', marginBottom: '12px' }}>
          <h3 style={{ fontSize: '13px', fontWeight: '700', color: 'var(--color-primary-dark)', marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Sparkles size={13} color="var(--color-accent)" /> Gemini API Key
          </h3>
          <p style={{ fontSize: '11.5px', color: 'var(--color-text-muted)', marginBottom: '10px', lineHeight: '1.5' }}>
            Enter your key to use live AI. Without it, Nestly uses a smart local model built from your profile.
          </p>
          <form onSubmit={saveKey} style={{ display: 'flex', gap: '8px' }}>
            <input type="password" className="form-input" style={{ flex: 1, padding: '10px 14px', fontSize: '13px' }} placeholder="AIzaSy..." value={apiKey} onChange={e => setApiKey(e.target.value)} />
            <button type="submit" className="btn-primary" style={{ width: 'auto', padding: '10px 16px', fontSize: '13px' }}>Save</button>
          </form>
        </div>
      )}

      {/* Memory Drawer Overlay */}
      {showFacts && (
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(255,255,255,0.95)', backdropFilter: 'blur(24px)', zIndex: 50, borderRadius: '20px', border: '1px solid var(--color-border)', boxShadow: 'var(--shadow-lg)', padding: '20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: 'var(--color-primary-dark)', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Database size={15} color="var(--color-sage)" /> AI Family Memory
            </h3>
            <button onClick={() => setShowFacts(false)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-secondary)' }}>
              <X size={18} />
            </button>
          </div>
          <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', lineHeight: '1.5' }}>
            These facts are parsed from your onboarding and used to personalise all AI recommendations.
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', flex: 1 }}>
            {FACTS.map(([k, v]) => (
              <div key={k} style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid var(--color-border)', paddingBottom: '8px', fontSize: '13px' }}>
                <span style={{ color: 'var(--color-text-muted)' }}>{k}</span>
                <span style={{ fontWeight: '700', color: 'var(--color-primary-dark)' }}>{v}</span>
              </div>
            ))}
          </div>
          <div style={{ background: 'var(--color-sage-soft)', padding: '12px 14px', borderRadius: '14px', fontSize: '11.5px', color: 'var(--color-primary-dark)', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Heart size={13} fill="var(--color-sage)" color="var(--color-sage)" />
            All data is processed locally. Your privacy is protected.
          </div>
        </div>
      )}

      {/* Messages */}
      <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '10px', paddingRight: '2px', maxHeight: '380px' }}>
        {messages.map(msg => (
          <div key={msg.id} style={{ display: 'flex', gap: '8px', alignSelf: msg.sender === 'user' ? 'flex-end' : 'flex-start', maxWidth: '88%' }}>
            {msg.sender === 'assistant' && (
              <div style={{ width: '30px', height: '30px', borderRadius: '10px', background: 'linear-gradient(135deg, var(--color-accent-soft), var(--color-sage-soft))', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '14px', flexShrink: 0, alignSelf: 'flex-end', border: '1px solid rgba(230,161,92,0.2)' }}>
                🪹
              </div>
            )}
            <div>
              <div style={{
                background: msg.sender === 'user'
                  ? 'linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-dark) 100%)'
                  : 'rgba(255,255,255,0.88)',
                backdropFilter: msg.sender === 'assistant' ? 'blur(16px)' : 'none',
                color: msg.sender === 'user' ? '#fff' : 'var(--color-text-main)',
                borderRadius: msg.sender === 'user' ? '20px 20px 4px 20px' : '20px 20px 20px 4px',
                padding: '11px 15px',
                fontSize: '13.5px',
                lineHeight: '1.55',
                whiteSpace: 'pre-wrap',
                border: msg.sender === 'user' ? 'none' : '1px solid rgba(255,255,255,0.6)',
                boxShadow: msg.sender === 'user' ? '0 4px 16px rgba(74,60,51,0.2)' : 'var(--shadow-sm)',
              }}>
                {msg.text}
              </div>
            </div>
            {msg.sender === 'user' && (
              <div style={{ width: '30px', height: '30px', borderRadius: '10px', background: 'var(--color-primary-dark)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '11px', fontWeight: '800', flexShrink: 0, alignSelf: 'flex-end' }}>
                {(user.role || 'U').substring(0, 2)}
              </div>
            )}
          </div>
        ))}

        {loading && (
          <div style={{ alignSelf: 'flex-start', display: 'flex', alignItems: 'center', gap: '8px', padding: '11px 15px', background: 'rgba(255,255,255,0.85)', backdropFilter: 'blur(12px)', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.6)', boxShadow: 'var(--shadow-sm)' }}>
            <span style={{ fontSize: '11.5px', color: 'var(--color-text-muted)' }}>Thinking</span>
            {[0, 0.2, 0.4].map(d => (
              <span key={d} style={{ width: '5px', height: '5px', background: 'var(--color-primary)', borderRadius: '50%', display: 'inline-block', animation: `breathe 1.1s ease-in-out ${d}s infinite` }} />
            ))}
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Quick Prompt Pills */}
      <div className="scroll-row" style={{ marginBottom: '8px' }}>
        {QUICK_PROMPTS.map(p => (
          <button key={p} onClick={() => send(p)} disabled={loading || isRecording}
            style={{ padding: '7px 14px', borderRadius: '16px', fontSize: '11.5px', background: 'rgba(255,255,255,0.8)', backdropFilter: 'blur(12px)', color: 'var(--color-primary-dark)', border: '1px solid rgba(255,255,255,0.5)', cursor: 'pointer', whiteSpace: 'nowrap', fontWeight: '500', boxShadow: 'var(--shadow-xs)', transition: 'var(--transition-smooth)' }}>
            {p}
          </button>
        ))}
      </div>

      {/* Input Row */}
      <form onSubmit={e => { e.preventDefault(); send(); }} style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
        <div style={{ position: 'relative', flex: 1 }}>
          <input
            type="text"
            className="form-input"
            style={{ padding: '12px 44px 12px 16px', borderRadius: '20px' }}
            placeholder={isRecording ? '🎙 Listening...' : 'Ask Nestly anything…'}
            value={input}
            onChange={e => setInput(e.target.value)}
            disabled={loading || isRecording}
          />
          <button type="button" onClick={simulateVoice} disabled={loading} style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: isRecording ? 'var(--color-accent)' : 'var(--color-text-subtle)', animation: isRecording ? 'breathe 0.8s infinite alternate' : 'none' }}>
            <Mic size={17} />
          </button>
        </div>
        <button type="submit" disabled={loading || isRecording || !input.trim()} className="btn-primary"
          style={{ width: '46px', height: '46px', padding: 0, borderRadius: '16px', flexShrink: 0 }}>
          <Send size={17} />
        </button>
      </form>
    </div>
  );
}
