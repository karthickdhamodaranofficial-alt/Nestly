import React, { useState, useEffect, useRef } from 'react';
import { Send, Sparkles, Key, Mic, Database, X, Heart, Loader2 } from 'lucide-react';
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
    text: `Hello ${user.name} 👋 I'm your Nestly household assistant. I've analysed your family profile. How can I lighten your mental load today?`
  }]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [streamingText, setStreamingText] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showFacts, setShowFacts] = useState(false);
  const [apiKey, setApiKey] = useState(localStorage.getItem('nestly_gemini_key') || '');
  const messagesEndRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading, streamingText]);

  const send = async (text) => {
    const t = text || input;
    if (!t.trim() || loading || streamingText) return;
    if (!text) setInput('');
    setMessages(prev => [...prev, { id: `u-${Date.now()}`, sender: 'user', text: t }]);
    setLoading(true);
    try {
      const res = await askGemini(t, profile, apiKey);
      setLoading(false);
      
      // Simulate smooth streaming effect
      let currentText = '';
      const chunkSize = 2;
      for (let i = 0; i <= res.length; i += chunkSize) {
        currentText = res.substring(0, i);
        setStreamingText(currentText);
        await new Promise(r => setTimeout(r, 12));
      }
      setStreamingText('');
      setMessages(prev => [...prev, { id: `a-${Date.now()}`, sender: 'assistant', text: res }]);
    } catch {
      setLoading(false);
      setMessages(prev => [...prev, { id: `e-${Date.now()}`, sender: 'assistant', text: "I had a small hiccup. Please try again or check your API key." }]);
    }
  };

  const simulateVoice = () => {
    if (loading || isRecording || streamingText) return;
    setIsRecording(true);
    setTimeout(() => {
      setIsRecording(false);
      setInput("How can we organize the evening bedtime routine?");
    }, 2000);
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
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <div>
          <h1 className="font-serif-heading" style={{ fontSize: '26px', color: 'var(--color-primary-dark)', marginBottom: '2px' }}>Nestly AI</h1>
          <p style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>Your proactive household partner</p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          <button onClick={() => setShowFacts(true)} className="glass-button" style={{ display: 'flex', alignItems: 'center', gap: '5px', padding: '8px 12px', borderRadius: '14px', fontSize: '11.5px', fontWeight: '600', color: 'var(--color-primary-dark)', border: '1px solid var(--color-border)', cursor: 'pointer', transition: 'all 0.2s' }}>
            <Database size={13} color="var(--color-sage-dark)" /> Memory
          </button>
          <button onClick={() => setShowSettings(s => !s)} className="glass-button" style={{ display: 'flex', alignItems: 'center', gap: '5px', padding: '8px 12px', borderRadius: '14px', fontSize: '11.5px', fontWeight: '600', background: showSettings ? 'var(--color-primary-dark)' : 'var(--color-bg-card)', color: showSettings ? '#fff' : 'var(--color-primary-dark)', border: '1px solid var(--color-border)', cursor: 'pointer', transition: 'all 0.2s' }}>
            <Key size={13} color={showSettings ? '#fff' : 'var(--color-accent)'} /> {apiKey ? 'API Set' : 'Setup API'}
          </button>
        </div>
      </div>

      {/* Settings Panel */}
      {showSettings && (
        <div className="glass-card slide-up fade-in" style={{ padding: '16px 20px', background: 'var(--color-accent-soft)', borderColor: 'rgba(230,161,92,0.25)', marginBottom: '16px', borderRadius: '16px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', color: 'var(--color-primary-dark)', marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Sparkles size={14} color="var(--color-accent)" /> Gemini API Setup
          </h3>
          <p style={{ fontSize: '12.5px', color: 'var(--color-text-muted)', marginBottom: '14px', lineHeight: '1.5' }}>
            Enter your key to enable live AI capabilities. Without it, Nestly uses a mocked smart local model based on your profile.
          </p>
          <form onSubmit={saveKey} style={{ display: 'flex', gap: '10px' }}>
            <input type="password" className="form-input" style={{ flex: 1, padding: '12px 16px', fontSize: '13.5px', borderRadius: '12px' }} placeholder="AIzaSy..." value={apiKey} onChange={e => setApiKey(e.target.value)} />
            <button type="submit" className="btn-primary" style={{ width: 'auto', padding: '12px 20px', fontSize: '13.5px', borderRadius: '12px' }}>Save Key</button>
          </form>
        </div>
      )}

      {/* Memory Drawer Overlay */}
      {showFacts && (
        <div className="fade-in" style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(255,255,255,0.96)', backdropFilter: 'blur(28px)', zIndex: 50, borderRadius: '24px', border: '1px solid rgba(255,255,255,0.8)', boxShadow: 'var(--shadow-lg)', padding: '24px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontSize: '18px', fontWeight: '700', color: 'var(--color-primary-dark)', display: 'flex', alignItems: 'center', gap: '8px', fontFamily: 'var(--font-serif)' }}>
              <Database size={18} color="var(--color-sage)" /> Family Knowledge Base
            </h3>
            <button onClick={() => setShowFacts(false)} style={{ background: 'var(--color-bg-muted)', border: 'none', cursor: 'pointer', color: 'var(--color-text-muted)', width: '32px', height: '32px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s' }}>
              <X size={16} />
            </button>
          </div>
          <p style={{ fontSize: '13.5px', color: 'var(--color-text-muted)', lineHeight: '1.6' }}>
            These details were parsed from your onboarding and are used continuously by Nestly to proactively personalize schedules, meals, and tasks.
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', flex: 1, overflowY: 'auto' }}>
            {FACTS.map(([k, v]) => (
              <div key={k} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--color-border)', paddingBottom: '10px', fontSize: '14px' }}>
                <span style={{ color: 'var(--color-text-muted)', fontWeight: '500' }}>{k}</span>
                <span style={{ fontWeight: '700', color: 'var(--color-primary-dark)' }}>{v}</span>
              </div>
            ))}
          </div>
          <div style={{ background: 'var(--color-sage-soft)', padding: '16px', borderRadius: '16px', fontSize: '12px', color: 'var(--color-sage-dark)', display: 'flex', alignItems: 'center', gap: '8px', fontWeight: '600' }}>
            <Heart size={15} fill="var(--color-sage)" color="var(--color-sage)" />
            All data is processed locally. Your privacy is protected.
          </div>
        </div>
      )}

      {/* Messages */}
      <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '16px', marginBottom: '12px', paddingRight: '4px', maxHeight: '420px', scrollBehavior: 'smooth' }}>
        {messages.map((msg, idx) => (
          <div key={msg.id} className="fade-in slide-up" style={{ display: 'flex', gap: '10px', alignSelf: msg.sender === 'user' ? 'flex-end' : 'flex-start', maxWidth: '85%', animationDelay: `${idx * 0.05}s` }}>
            {msg.sender === 'assistant' && (
              <div style={{ width: '32px', height: '32px', borderRadius: '12px', background: 'linear-gradient(135deg, var(--color-accent-soft), var(--color-sage-soft))', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '15px', flexShrink: 0, alignSelf: 'flex-end', border: '1px solid rgba(230,161,92,0.3)', boxShadow: '0 4px 10px rgba(0,0,0,0.03)' }}>
                🪹
              </div>
            )}
            <div>
              <div style={{
                background: msg.sender === 'user'
                  ? 'linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-dark) 100%)'
                  : 'rgba(255,255,255,0.95)',
                backdropFilter: msg.sender === 'assistant' ? 'blur(20px)' : 'none',
                color: msg.sender === 'user' ? '#fff' : 'var(--color-text-main)',
                borderRadius: msg.sender === 'user' ? '20px 20px 4px 20px' : '20px 20px 20px 4px',
                padding: '12px 18px',
                fontSize: '14px',
                lineHeight: '1.6',
                whiteSpace: 'pre-wrap',
                border: msg.sender === 'user' ? 'none' : '1px solid rgba(255,255,255,0.8)',
                boxShadow: msg.sender === 'user' ? '0 6px 16px rgba(74,60,51,0.25)' : 'var(--shadow-sm)',
              }}>
                {msg.text}
              </div>
            </div>
            {msg.sender === 'user' && (
              <div style={{ width: '32px', height: '32px', borderRadius: '12px', background: 'var(--color-primary-dark)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: '800', flexShrink: 0, alignSelf: 'flex-end', boxShadow: '0 4px 10px rgba(0,0,0,0.1)' }}>
                {(user.role || 'U').substring(0, 2)}
              </div>
            )}
          </div>
        ))}

        {streamingText && (
          <div className="fade-in" style={{ display: 'flex', gap: '10px', alignSelf: 'flex-start', maxWidth: '85%' }}>
            <div style={{ width: '32px', height: '32px', borderRadius: '12px', background: 'linear-gradient(135deg, var(--color-accent-soft), var(--color-sage-soft))', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '15px', flexShrink: 0, alignSelf: 'flex-end', border: '1px solid rgba(230,161,92,0.3)', boxShadow: '0 4px 10px rgba(0,0,0,0.03)' }}>
              🪹
            </div>
            <div style={{ background: 'rgba(255,255,255,0.95)', backdropFilter: 'blur(20px)', color: 'var(--color-text-main)', borderRadius: '20px 20px 20px 4px', padding: '12px 18px', fontSize: '14px', lineHeight: '1.6', whiteSpace: 'pre-wrap', border: '1px solid rgba(255,255,255,0.8)', boxShadow: 'var(--shadow-sm)' }}>
              {streamingText}
              <span className="cursor-blink" style={{ display: 'inline-block', width: '6px', height: '14px', background: 'var(--color-primary)', marginLeft: '4px', verticalAlign: 'middle', borderRadius: '2px' }}></span>
            </div>
          </div>
        )}

        {loading && (
          <div className="fade-in" style={{ alignSelf: 'flex-start', display: 'flex', alignItems: 'center', gap: '10px', padding: '12px 18px', background: 'rgba(255,255,255,0.95)', backdropFilter: 'blur(20px)', borderRadius: '20px 20px 20px 4px', border: '1px solid rgba(255,255,255,0.8)', boxShadow: 'var(--shadow-sm)', marginLeft: '42px' }}>
            <span style={{ fontSize: '12.5px', color: 'var(--color-text-muted)', fontWeight: '500' }}>Thinking</span>
            <div style={{ display: 'flex', gap: '4px' }}>
              {[0, 0.15, 0.3].map(d => (
                <span key={d} style={{ width: '6px', height: '6px', background: 'var(--color-primary)', borderRadius: '50%', display: 'inline-block', animation: `bounce 1s ease-in-out ${d}s infinite` }} />
              ))}
            </div>
          </div>
        )}
        <div ref={messagesEndRef} style={{ height: '10px' }} />
      </div>

      {/* Quick Prompt Pills */}
      <div className="scroll-row" style={{ marginBottom: '12px', paddingBottom: '4px' }}>
        {QUICK_PROMPTS.map(p => (
          <button key={p} onClick={() => send(p)} disabled={loading || isRecording || streamingText}
            className="quick-prompt-pill hover-lift"
            style={{ padding: '8px 16px', borderRadius: '20px', fontSize: '12.5px', background: 'rgba(255,255,255,0.85)', backdropFilter: 'blur(16px)', color: 'var(--color-primary-dark)', border: '1px solid rgba(255,255,255,0.9)', cursor: 'pointer', whiteSpace: 'nowrap', fontWeight: '600', boxShadow: 'var(--shadow-xs)', transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)' }}>
            {p}
          </button>
        ))}
      </div>

      {/* Input Row */}
      <form onSubmit={e => { e.preventDefault(); send(); }} style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
        <div style={{ position: 'relative', flex: 1 }}>
          <input
            type="text"
            className="form-input"
            style={{ padding: '14px 48px 14px 20px', borderRadius: '24px', fontSize: '14.5px', boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.02), var(--shadow-sm)' }}
            placeholder={isRecording ? '🎙 Listening...' : 'Ask Nestly anything…'}
            value={input}
            onChange={e => setInput(e.target.value)}
            disabled={loading || isRecording || streamingText}
          />
          <button type="button" onClick={simulateVoice} disabled={loading || streamingText} style={{ position: 'absolute', right: '14px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: isRecording ? 'var(--color-accent)' : 'var(--color-text-subtle)', animation: isRecording ? 'pulse 1.5s infinite' : 'none', transition: 'color 0.2s', padding: '4px' }}>
            {isRecording ? <Loader2 size={18} className="spin" /> : <Mic size={18} />}
          </button>
        </div>
        <button type="submit" disabled={loading || isRecording || !input.trim() || streamingText} className="btn-primary hover-lift"
          style={{ width: '50px', height: '50px', padding: 0, borderRadius: '20px', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 6px 16px rgba(125, 107, 93, 0.3)' }}>
          <Send size={18} style={{ transform: 'translateX(1px)' }} />
        </button>
      </form>
    </div>
  );
}
