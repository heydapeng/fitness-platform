(function(){
  const path=location.pathname.split('/').pop()||'index.html';

  document.querySelectorAll('.nav a,.member-links a').forEach(a=>{
    if(a.getAttribute('href')===path)a.classList.add('active');
  });

  const menu=document.querySelector('[data-menu]');
  const nav=document.querySelector('.nav');
  if(menu&&nav) menu.addEventListener('click',()=>nav.classList.toggle('open'));

  window.openModal=id=>document.getElementById(id)?.classList.add('open');
  window.closeModal=id=>document.getElementById(id)?.classList.remove('open');
  document.querySelectorAll('.modal').forEach(m=>m.addEventListener('click',e=>{
    if(e.target===m)m.classList.remove('open');
  }));
  window.formatNum=n=>Number(n).toLocaleString('zh-CN');

  // --- Prototype authentication state ---
  const AUTH_KEY='fitnessPrototypeAuthV03';
  const getAuth=()=>{ const v=new URLSearchParams(location.search).get('view'); if(v==='member') return true; if(v==='guest') return false; return localStorage.getItem(AUTH_KEY)==='member'; };

  function renderAuthState(){
    const guest=document.getElementById('guestHome');
    const member=document.getElementById('memberHome');
    if(!guest&&!member){ document.body.classList.remove('auth-loading'); document.body.classList.add('auth-ready'); return; }
    const authed=getAuth();
    if(guest) guest.hidden=authed;
    if(member) member.hidden=!authed;
    document.body.classList.toggle('member-mode',authed);
    document.body.classList.toggle('guest-mode',!authed);
    document.body.classList.remove('auth-loading');
    document.body.classList.add('auth-ready');
    if(authed && typeof window.initMemberHome==='function') window.initMemberHome();
    if(!authed) initLandingReveal();
    window.scrollTo(0,0);
  }

  window.openAuth=function(mode){
    const title=document.getElementById('authTitle');
    const sub=document.getElementById('authSub');
    const submit=document.getElementById('authSubmit');
    if(mode==='register'){
      if(title) title.textContent='创建你的账号';
      if(sub) sub.textContent='先开始记录，目标和计划都可以以后再设置。';
      if(submit) submit.textContent='创建账号并进入';
    }else{
      if(title) title.textContent='登录你的账号';
      if(sub) sub.textContent='继续查看今天的饮食、训练和趋势。';
      if(submit) submit.textContent='登录';
    }
    openModal('authModal');
  };

  window.prototypeLogin=function(){
    localStorage.setItem(AUTH_KEY,'member');
    closeModal('authModal');
    renderAuthState();
  };

  window.prototypeLogout=function(){
    localStorage.removeItem(AUTH_KEY);
    document.getElementById('profileMenu')?.classList.remove('open');
    const guest=document.getElementById('guestHome'), member=document.getElementById('memberHome');
    if(!guest && !member){ location.href='index.html?view=guest'; return; }
    renderAuthState();
  };

  window.toggleProfileMenu=function(){
    document.getElementById('profileMenu')?.classList.toggle('open');
  };

  window.memberAskAi=function(){
    const input=document.getElementById('memberAiInput');
    const q=(input?.value||'').trim();
    if(q) localStorage.setItem('prototypePrompt',q);
    location.href='assistant.html';
  };

  function initLandingReveal(){
    const els=[...document.querySelectorAll('#guestHome .reveal')];
    if(!('IntersectionObserver' in window)) { els.forEach(el=>el.classList.add('visible')); return; }
    const io=new IntersectionObserver(entries=>entries.forEach(e=>{
      if(e.isIntersecting){e.target.classList.add('visible');io.unobserve(e.target)}
    }),{threshold:.13,rootMargin:'0px 0px -40px 0px'});
    els.forEach(el=>{if(!el.classList.contains('visible'))io.observe(el)});
  }

  window.switchTrend=function(btn,range){
    btn.parentElement?.querySelectorAll('button').forEach(b=>b.classList.remove('active'));
    btn.classList.add('active');
    const line=document.getElementById('memberLinePath');
    const area=document.getElementById('memberAreaPath');
    if(!line||!area)return;
    if(range==='30d'){
      line.setAttribute('d','M58 173 C145 122 212 150 286 103 S424 79 505 129 S645 164 718 115 S806 92 862 136');
      area.setAttribute('d','M58 173 C145 122 212 150 286 103 S424 79 505 129 S645 164 718 115 S806 92 862 136 L862 255 L58 255 Z');
    }else{
      line.setAttribute('d','M58 140 L192 110 L326 168 L460 72 L594 124 L728 153 L862 198');
      area.setAttribute('d','M58 140 L192 110 L326 168 L460 72 L594 124 L728 153 L862 198 L862 255 L58 255 Z');
    }
  };

  document.addEventListener('click',e=>{
    const pm=document.getElementById('profileMenu');
    if(pm && pm.classList.contains('open') && !e.target.closest('.member-actions')) pm.classList.remove('open');
  });

  document.addEventListener('DOMContentLoaded',renderAuthState);
})();
