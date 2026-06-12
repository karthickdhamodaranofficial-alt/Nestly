import React, { useState } from 'react';
import { Mail, Lock, LogIn, Heart, ShieldAlert, Sparkles, ArrowRight } from 'lucide-react';

export default function Auth({ onAuthComplete }) {
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [setupStep, setSetupStep] = useState('auth');
  const [familyAction, setFamilyAction] = useState(null);
  const [familyName, setFamilyName] = useState('');
  const [familyCode, setFamilyCode] = useState('');
  const [familyRole, setFamilyRole] = useState('Mom');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleAuthSubmit = (e) => {
    e.preventDefault();
    if (!email || !password || (isSignUp && !name)) { setError('Please fill in all fields.'); return; }
    setError(''); setLoading(true);
    setTimeout(() => { setLoading(false); setSetupStep('family-setup'); }, 1200);
  };

  const handleThirdPartyLogin = (provider) => {
    setLoading(true); setError('');
    setTimeout(() => {
      setLoading(false);
      setName(provider === 'Google' ? 'Sarah' : 'Sarah Apple');
      setEmail(`${provider.toLowerCase()}@nestly.com`);
      setSetupStep('family-setup');
    }, 1200);
  };

  const handleFamilySubmit = (e) => {
    e.preventDefault();
    if (familyAction === 'create' && !familyName) { setError('Please name your household.'); return; }
    if (familyAction === 'join' && !familyCode) { setError('Please enter an invite code.'); return; }
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      const user = {
        name: name || email.split('@')[0],
        email,
        role: familyRole,
        familyName: familyAction === 'create' ? familyName : 'The Miller Household',
        familyCode: familyAction === 'create' ? `NEST-${Math.floor(1000 + Math.random() * 9000)}` : familyCode.toUpperCase()
      };
      localStorage.setItem('nestly_user', JSON.stringify(user));
      onAuthComplete(user);
    }, 1500);
  };

  const roles = [
    { key: 'Mom', label: 'Mom', emoji: '👩‍🦰' },
    { key: 'Dad', label: 'Dad', emoji: '👨‍🦱' },
    { key: 'Co-parent', label: 'Co-parent', emoji: '🧑‍🤝‍🧑' },
    { key: 'Nanny', label: 'Nanny', emoji: '👩‍⚕️' },
    { key: 'Grandparent', label: 'Grandparent', emoji: '👵' },
  ];

  return (
    <div className="fade-in" style={{ display: 'flex', flexDirection: 'column', height: '100%', justifyContent: 'center', position: 'relative', overflow: 'hidden' }}>

      {/* Ambient background orbs */}
      <div style={{ position: 'absolute', top: '-60px', right: '-60px', width: '200px', height: '200px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(230,161,92,0.12) 0%, transparent 70%)', pointerEvents: 'none' }} />
      <div style={{ position: 'absolute', bottom: '-40px', left: '-40px', width: '160px', height: '160px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(143,158,139,0.12) 0%, transparent 70%)', pointerEvents: 'none' }} />

      {/* AUTH SCREEN */}
      {setupStep === 'auth' && (
        <div style={{ padding: '4px', zIndex: 1 }}>
          {/* Logo */}
          <div style={{ textAlign: 'center', marginBottom: '28px' }}>
            <div className="breathe-indicator" style={{
              width: '72px', height: '72px', borderRadius: '28px',
              background: 'linear-gradient(135deg, var(--color-accent-soft) 0%, var(--color-sage-soft) 100%)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              margin: '0 auto 16px',
              boxShadow: '0 8px 28px rgba(230,161,92,0.2)',
              border: '1px solid rgba(230,161,92,0.15)',
            }}>
              <span style={{ fontSize: '36px' }}>🪹</span>
            </div>
            <h1 className="font-serif-heading" style={{ fontSize: '30px', color: 'var(--color-primary-dark)', marginBottom: '6px' }}>
              Nestly
            </h1>
            <p style={{ color: 'var(--color-text-muted)', fontSize: '13.5px', fontStyle: 'italic' }}>
              Your proactive household COO
            </p>
          </div>

          {/* Card */}
          <div style={{
            background: 'rgba(255,255,255,0.88)',
            backdropFilter: 'blur(24px)',
            border: '1px solid rgba(255,255,255,0.7)',
            borderRadius: '28px',
            padding: '28px 24px',
            boxShadow: 'var(--shadow-md)',
          }}>
            <h2 style={{ fontSize: '16px', fontWeight: '700', marginBottom: '20px', color: 'var(--color-primary-dark)', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Heart size={16} color="var(--color-accent)" fill="var(--color-accent-soft)" />
              {isSignUp ? 'Create your family account' : 'Welcome back, parent'}
            </h2>

            {error && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '11px 14px', background: 'var(--color-danger-soft)', border: '1px solid rgba(196,123,123,0.2)', borderRadius: '12px', color: 'var(--color-danger)', fontSize: '13px', marginBottom: '16px' }}>
                <ShieldAlert size={15} /><span>{error}</span>
              </div>
            )}

            <form onSubmit={handleAuthSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {isSignUp && (
                <div>
                  <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Your Name</label>
                  <input type="text" className="form-input" placeholder="e.g. Sarah Miller" value={name} onChange={e => setName(e.target.value)} />
                </div>
              )}
              <div>
                <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Email Address</label>
                <div style={{ position: 'relative' }}>
                  <Mail size={15} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-subtle)' }} />
                  <input type="email" className="form-input" style={{ paddingLeft: '44px' }} placeholder="name@household.com" value={email} onChange={e => setEmail(e.target.value)} />
                </div>
              </div>
              <div>
                <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Password</label>
                <div style={{ position: 'relative' }}>
                  <Lock size={15} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-subtle)' }} />
                  <input type="password" className="form-input" style={{ paddingLeft: '44px' }} placeholder="••••••••" value={password} onChange={e => setPassword(e.target.value)} />
                </div>
              </div>
              <button type="submit" className="btn-primary" disabled={loading} style={{ marginTop: '6px' }}>
                {loading
                  ? <span className="spinning" style={{ width: '16px', height: '16px', border: '2px solid rgba(255,255,255,0.35)', borderTopColor: '#fff', borderRadius: '50%' }} />
                  : <><LogIn size={15} /> {isSignUp ? 'Begin Journey' : 'Enter Nest'}</>
                }
              </button>
            </form>

            <div style={{ display: 'flex', alignItems: 'center', margin: '18px 0', gap: '10px' }}>
              <hr style={{ flex: 1, border: 'none', borderTop: '1px solid var(--color-border)' }} />
              <span className="label-caps">Or connect securely</span>
              <hr style={{ flex: 1, border: 'none', borderTop: '1px solid var(--color-border)' }} />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
              {/* Google */}
              <button onClick={() => handleThirdPartyLogin('Google')} className="btn-secondary" style={{ padding: '11px', fontSize: '13px', gap: '7px', borderRadius: '14px' }}>
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none">
                  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" fill="#FBBC05"/>
                  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" fill="#EA4335"/>
                </svg>
                Google
              </button>
              {/* Apple */}
              <button onClick={() => handleThirdPartyLogin('Apple')} className="btn-secondary" style={{ padding: '11px', fontSize: '13px', gap: '7px', borderRadius: '14px' }}>
                <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 4.17c.66-.81 1.11-1.93.99-3.06-1 .04-2.22.67-2.94 1.51-.62.72-1.16 1.87-1.01 2.98 1.12.09 2.27-.61 2.96-1.43z"/>
                </svg>
                Apple
              </button>
            </div>
          </div>

          <p style={{ textAlign: 'center', marginTop: '16px', fontSize: '13px', color: 'var(--color-text-muted)' }}>
            {isSignUp ? 'Already have an account?' : "Don't have a household space?"}
            <button onClick={() => setIsSignUp(s => !s)} style={{ background: 'none', border: 'none', color: 'var(--color-primary-dark)', fontWeight: '700', cursor: 'pointer', marginLeft: '6px', textDecoration: 'underline', fontSize: '13px' }}>
              {isSignUp ? 'Sign In' : 'Create Account'}
            </button>
          </p>
        </div>
      )}

      {/* HOUSEHOLD SETUP */}
      {setupStep === 'family-setup' && (
        <div style={{ padding: '4px', zIndex: 1 }}>
          <div style={{ textAlign: 'center', marginBottom: '22px' }}>
            <div style={{ fontSize: '32px', marginBottom: '10px' }}>🏡</div>
            <h1 className="font-serif-heading" style={{ fontSize: '24px', color: 'var(--color-primary-dark)', marginBottom: '6px' }}>Set Up Your Nest</h1>
            <p style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>Sync with your partner or care providers in real-time.</p>
          </div>

          <div style={{ background: 'rgba(255,255,255,0.88)', backdropFilter: 'blur(24px)', border: '1px solid rgba(255,255,255,0.7)', borderRadius: '28px', padding: '24px', boxShadow: 'var(--shadow-md)' }}>
            {error && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '11px 14px', background: 'var(--color-danger-soft)', border: '1px solid rgba(196,123,123,0.2)', borderRadius: '12px', color: 'var(--color-danger)', fontSize: '13px', marginBottom: '14px' }}>
                <ShieldAlert size={15} /><span>{error}</span>
              </div>
            )}

            {!familyAction ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <button onClick={() => setFamilyAction('create')} className="btn-primary" style={{ padding: '14px' }}>
                  <Sparkles size={15} /> Create New Household
                </button>
                <div style={{ textAlign: 'center', fontSize: '11px', color: 'var(--color-text-subtle)', fontWeight: '700', letterSpacing: '0.08em' }}>— OR JOIN CO-PARENT —</div>
                <button onClick={() => setFamilyAction('join')} className="btn-secondary" style={{ padding: '13px' }}>
                  Join Partner's Household
                </button>
              </div>
            ) : (
              <form onSubmit={handleFamilySubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <button type="button" onClick={() => setFamilyAction(null)} style={{ alignSelf: 'flex-start', background: 'none', border: 'none', fontSize: '13px', color: 'var(--color-text-muted)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  ← Back
                </button>

                <div>
                  <label className="label-caps" style={{ display: 'block', marginBottom: '8px' }}>Your Role</label>
                  <div className="card-selector-grid" style={{ gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                    {roles.map(r => (
                      <button key={r.key} type="button" onClick={() => setFamilyRole(r.key)}
                        className={`card-selector-item ${familyRole === r.key ? 'selected' : ''}`}
                        style={{ padding: '11px 10px', gap: '8px', fontSize: '13px' }}>
                        <span style={{ fontSize: '17px' }}>{r.emoji}</span>
                        <span style={{ fontWeight: '600' }}>{r.label}</span>
                      </button>
                    ))}
                  </div>
                </div>

                {familyAction === 'create' ? (
                  <div>
                    <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Household Name</label>
                    <input type="text" className="form-input" placeholder="e.g. Miller Family Nest" value={familyName} onChange={e => setFamilyName(e.target.value)} />
                  </div>
                ) : (
                  <div>
                    <label className="label-caps" style={{ display: 'block', marginBottom: '6px' }}>Invite Code</label>
                    <input type="text" className="form-input" placeholder="e.g. NEST-5421" value={familyCode} onChange={e => setFamilyCode(e.target.value)} />
                    <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '6px', display: 'block', fontStyle: 'italic' }}>Ask your partner for the code in their Dashboard.</span>
                  </div>
                )}

                <button type="submit" className="btn-primary" disabled={loading} style={{ marginTop: '4px' }}>
                  {loading
                    ? <span className="spinning" style={{ width: '16px', height: '16px', border: '2px solid rgba(255,255,255,0.35)', borderTopColor: '#fff', borderRadius: '50%' }} />
                    : <><ArrowRight size={15} /> Confirm & Enter</>
                  }
                </button>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
