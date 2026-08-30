(async function () {
  const status = document.querySelector('#auth-status');
  const button = document.querySelector('#auth-button');
  const modal = document.querySelector('#auth-modal');
  const form = document.querySelector('#auth-form');
  const message = document.querySelector('#auth-message');
  let client;
  const open = () => { modal.classList.add('open'); document.querySelector('#auth-email').focus(); };
  const close = () => { modal.classList.remove('open'); message.textContent = ''; };
  function setUser(user) {
    if (user) { status.textContent = user.email.toUpperCase(); button.textContent = 'Sign out'; button.onclick = async () => { await client.auth.signOut(); location.reload(); }; }
    else { status.textContent = client ? 'CLOUD READY' : 'LOCAL MODE'; button.textContent = client ? 'Sign in' : 'Cloud setup'; button.onclick = open; }
  }
  async function store(decision) {
    const { data: { user } } = await client.auth.getUser(); if (!user) return;
    const payload = { user_id:user.id, title:decision.title, question:decision.question, status:decision.status === 'ARCHIVED' ? 'archived' : 'complete' };
    const { error } = await client.from('decisions').upsert({ ...payload, id: decision.id }, { onConflict: 'id' });
    if (error && error.code === '22P02') await client.from('decisions').insert(payload);
  }
  async function loadCloud() {
    const { data: { user } } = await client.auth.getUser(); if (!user) return;
    const { data, error } = await client.from('decisions').select('*').order('created_at', { ascending: false });
    if (error) return console.warn('War Room sync failed', error.message);
    if (data.length) window.setWarRoomDecisions(data.map(row => ({ id:row.id,title:row.title,question:row.question,date:new Date(row.created_at).toLocaleDateString('en-US',{month:'short',day:'numeric',year:'numeric'}).toUpperCase(),recommendation:'CONDITIONAL',score:72,confidence:75,status:row.status==='archived'?'ARCHIVED':'ACTIVE',weights:[20,20,15,20,15,10] })));
    else for (const decision of window.getWarRoomDecisions().filter(d => d.id !== 'northstar')) await store(decision);
  }
  try {
    const response = await fetch('/api/config'); const config = await response.json();
    if (!config.configured) { setUser(null); return; }
    client = window.supabase.createClient(config.url, config.anonKey); window.syncWarRoomDecisions = store;
    const { data: { session } } = await client.auth.getSession(); setUser(session?.user); if (session?.user) await loadCloud();
    client.auth.onAuthStateChange((_event, session) => setUser(session?.user));
  } catch { setUser(null); }
  button.onclick = open; document.querySelector('#close-auth').onclick = close; modal.onclick = e => { if (e.target === modal) close(); };
  form.onsubmit = async e => { e.preventDefault(); if (!client) { message.textContent = 'Cloud access is not configured yet.'; return; } message.textContent = 'Signing in…'; const { error } = await client.auth.signInWithPassword({ email:document.querySelector('#auth-email').value, password:document.querySelector('#auth-password').value }); message.textContent = error ? error.message : 'Signed in. Loading your command center…'; if (!error) setTimeout(() => location.reload(), 500); };
  document.querySelector('#sign-up').onclick = async () => { if (!client) { message.textContent = 'Cloud access is not configured yet.'; return; } const { error } = await client.auth.signUp({ email:document.querySelector('#auth-email').value, password:document.querySelector('#auth-password').value, options:{emailRedirectTo:location.origin} }); message.textContent = error ? error.message : 'Check your email to confirm the account, then sign in.'; };
})();
