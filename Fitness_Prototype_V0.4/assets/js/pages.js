const D=window.FitnessData;
function pct(v,g){return Math.min(100,Math.round(v/g*100));}
function initDashboard(){
 const root=document.getElementById('metricCards'); if(!root)return;
 const defs=[
  ['热量','calories','kcal','🔥','cal'],
  ['蛋白质','protein','g','🍗','protein'],
  ['碳水','carbs','g','🍚','carbs'],
  ['脂肪','fat','g','🥑','fat']
 ];
 root.innerHTML=defs.map(([label,k,u,icon,cls])=>{let x=D.nutrition[k],p=pct(x.value,x.goal);return `<div class="macro-card"><div class="macro-icon ${cls}">${icon}</div><div class="macro-body"><div class="macro-top"><span class="macro-label">${label}</span><span class="pill ${p>=100?'orange':'green'}">${p}%</span></div><div class="macro-value">${x.value} <small>/ ${x.goal} ${u}</small></div><div class="macro-sub">还差 ${Math.max(0,x.goal-x.value)} ${u}</div><div class="progress ${p>=100?'warn':''}"><span style="width:${p}%"></span></div></div></div>`}).join('');
 const tl=document.getElementById('mealTimeline'); if(tl){const icons={'早餐':'🥣','午餐':'🍱','晚餐':'🍽️','加餐':'🍌'};tl.innerHTML=D.meals.map(m=>`<div class="meal-row"><div class="meal-time">${m.time}</div><div class="meal-emoji">${icons[m.type]||'🥗'}</div><div><div class="meal-title">${m.title}</div><div class="meal-sub">${m.type} · P${m.p} / C${m.c} / F${m.f}</div></div><div class="meal-kcal">${m.kcal} kcal</div></div>`).join('');}
}
function goAssistant(){let q=document.getElementById('homeAiInput')?.value||'';localStorage.setItem('prototypePrompt',q);location.href='assistant.html';}
function fakeSaveFood(){alert('原型：已模拟保存记录。正式产品会通过 Food Record Service 计算并持久化。');closeModal('foodModal');}

let selectedFood=null;
function renderFoods(){
 const el=document.getElementById('foodResults'); if(!el)return; const q=(document.getElementById('foodSearch')?.value||'').trim().toLowerCase();
 const list=D.foods.filter(f=>!q||f.name.toLowerCase().includes(q)||f.brand.toLowerCase().includes(q));
 el.innerHTML=list.length?list.map(f=>`<div class="food-result"><div><div class="food-name">${f.name}</div><div class="source">${f.brand} · ${f.source==='API'?'更多食品来源':'平台食品'}</div></div><div class="macro"><strong>${f.cal}</strong><br><span class="source">kcal/${f.unit}</span></div><div class="macro"><strong>P ${f.p}</strong><br><span class="source">g</span></div><div class="macro"><strong>C ${f.c}</strong><br><span class="source">g</span></div><div class="macro"><strong>F ${f.f}</strong><br><span class="source">g</span></div><button class="btn small primary" onclick="chooseFood(${f.id})">选择</button></div>`).join(''):`<div class="empty">暂时没有找到合适的食品。你可以换个关键词，或使用更多食品来源继续搜索。</div>`;
}
function chooseFood(id){selectedFood=D.foods.find(f=>f.id===id);document.getElementById('recordPreview').innerHTML=`<div class="notice"><strong>${selectedFood.name}</strong><br>${selectedFood.cal} kcal / ${selectedFood.unit} · P ${selectedFood.p} · C ${selectedFood.c} · F ${selectedFood.f}<br><span class="meta">来源：${selectedFood.brand}</span></div>`;openModal('recordModal');}
function confirmFoodRecord(){alert(`已模拟确认：${selectedFood?.name||'食品'}。\n正式流程：Confirm → Service Execute → Idempotency → Result`);closeModal('recordModal');}
function initNutrition(){renderFoods();const t=document.getElementById('nutritionHistory');if(!t)return;t.innerHTML=D.meals.map(m=>`<tr><td>${m.time}</td><td>${m.type}</td><td>${m.title}</td><td>${m.kcal}</td><td>${m.p}g</td><td>${m.c}g</td><td>${m.f}g</td><td><button class="btn small ghost">编辑</button></td></tr>`).join('');}

function drawChart(){const c=document.getElementById('nutritionChart');if(!c)return;const ratio=window.devicePixelRatio||1,w=c.clientWidth,h=c.clientHeight;c.width=w*ratio;c.height=h*ratio;const x=c.getContext('2d');x.scale(ratio,ratio);x.clearRect(0,0,w,h);const pad={l:42,r:18,t:22,b:32},cw=w-pad.l-pad.r,ch=h-pad.t-pad.b,min=1700,max=2500;x.strokeStyle='#e5e7eb';x.lineWidth=1;x.font='11px Arial';x.fillStyle='#7a8290';for(let i=0;i<5;i++){let y=pad.t+ch*i/4;x.beginPath();x.moveTo(pad.l,y);x.lineTo(w-pad.r,y);x.stroke();let v=Math.round(max-(max-min)*i/4);x.fillText(v,pad.l-38,y+4)}let goalY=pad.t+(max-2300)/(max-min)*ch;x.setLineDash([5,5]);x.strokeStyle='#12a36d';x.beginPath();x.moveTo(pad.l,goalY);x.lineTo(w-pad.r,goalY);x.stroke();x.setLineDash([]);x.strokeStyle='#315fff';x.lineWidth=3;x.beginPath();D.analytics.forEach((d,i)=>{let px=pad.l+cw*i/(D.analytics.length-1),py=pad.t+(max-d.cal)/(max-min)*ch;i?x.lineTo(px,py):x.moveTo(px,py)});x.stroke();D.analytics.forEach((d,i)=>{let px=pad.l+cw*i/(D.analytics.length-1),py=pad.t+(max-d.cal)/(max-min)*ch;x.fillStyle='#315fff';x.beginPath();x.arc(px,py,4,0,Math.PI*2);x.fill();x.fillStyle='#7a8290';x.fillText(d.d,px-14,h-10)});}
function initAnalytics(){const t=document.getElementById('analyticsRows');if(!t)return;t.innerHTML=D.analytics.map(d=>`<tr><td>${d.d}</td><td>${d.cal}</td><td>${d.p}g</td><td>${d.c}g</td><td>${d.f}g</td><td><span class="pill ${d.p>=160?'green':'orange'}">${d.p>=160?'达标':'未达标'}</span></td></tr>`).join('');drawChart();window.addEventListener('resize',drawChart);}
function refreshAnalytics(){document.querySelector('.notice').innerHTML='<strong>当前视图已更新：</strong>图表、每日数据和导出会一起使用你刚刚选择的条件。';drawChart();}
function exportCSV(){let rows=['date,calories,protein,carbs,fat',...D.analytics.map(d=>`${d.d},${d.cal},${d.p},${d.c},${d.f}`)];let blob=new Blob([rows.join('\n')],{type:'text/csv;charset=utf-8'}),a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='nutrition_analytics_demo.csv';a.click();URL.revokeObjectURL(a.href);}

function addMsg(role,html){const box=document.getElementById('messages');if(!box)return;let d=document.createElement('div');d.className='msg '+role;d.innerHTML=html;box.appendChild(d);box.scrollTop=box.scrollHeight;}
function setState(intent,state,trace){
 const intentMap={QUERY_NUTRITION:'查询个人数据',RECORD_FOOD:'准备饮食记录',KNOWLEDGE_QUESTION:'查找健身知识',CLASSIFYING:'理解你的问题'};
 const stateMap={RESOLVING:'正在处理',READY_FOR_CONFIRMATION:'等待你确认',EXECUTING:'正在保存',SUCCEEDED:'已完成'};
 let s=document.getElementById('agentState');
 if(s)s.innerHTML=`<div class="ai-status-chip"><span>正在做什么</span><strong>${intentMap[intent]||intent}</strong></div><div class="ai-status-chip"><span>当前状态</span><strong>${stateMap[state]||state}</strong></div>`;
 let t=document.getElementById('trace');if(t)t.innerHTML=trace;
}
function sendPreset(q){document.getElementById('chatText').value=q;sendChat();}
function sendChat(){let el=document.getElementById('chatText'),q=(el?.value||'').trim();if(!q)return;addMsg('user',q);el.value='';setState('CLASSIFYING','RESOLVING','1. Input received<br>2. Intent classification<br>3. Resolving required data...');setTimeout(()=>respond(q),350);}
function respond(q){
 if(/记录|吃了|喝了/.test(q)){
  setState('RECORD_FOOD','READY_FOR_CONFIRMATION','1. Structured Output created<br>2. Food search Tool<br>3. Entity resolve<br>4. Preview generated<br>5. Waiting for confirmation');
  addMsg('ai',`我解析到一条饮食记录请求。写操作不会直接执行。<div class="mini-card"><strong>准备记录</strong><br><br>熟鸡胸肉 · 200g<br>白米饭（熟）· 150g<br><hr style="border:0;border-top:1px solid #eee">预计约 525 kcal · P 66g · C 42g · F 8g<div style="display:flex;gap:8px;margin-top:12px"><button class="btn small ghost" onclick="addMsg('ai','已进入编辑状态（原型）。')">编辑</button><button class="btn small accent" onclick="confirmAgentDraft()">确认记录</button></div></div>`);
 } else if(/RIR|卧推|蛋白质.*作用|为什么/.test(q)){
  setState('KNOWLEDGE_QUESTION','SUCCEEDED','1. Query rewrite<br>2. Vector retrieval<br>3. Rerank<br>4. Source filtered<br>5. Answer generated');
  addMsg('ai',`RIR 是“还可以完成多少次重复”的主观估计。比如 RIR 2 通常表示这一组结束时，你认为在保持动作质量的前提下大约还能再做 2 次。<div class="mini-card"><strong>来源</strong><br><span class="meta">训练强度基础知识 · 已审核</span></div>`);
 } else {
  setState('QUERY_NUTRITION','SUCCEEDED','1. QuerySpec built<br>2. Nutrition Tool called<br>3. Real data returned<br>4. Response generated');
  addMsg('ai',`根据你最近 7 天的记录，平均蛋白质约 <strong>156g/天</strong>。你可以继续问某一天、某一餐，或者换成 30 天范围查看。`);
 }
}
function confirmAgentDraft(){setState('RECORD_FOOD','EXECUTING','1. User confirmed<br>2. requestId generated<br>3. Food Record Tool executing...');setTimeout(()=>{setState('RECORD_FOOD','SUCCEEDED','1. User confirmed<br>2. requestId idempotency check<br>3. Food Record Service executed<br>4. New totals queried<br>5. Completed');addMsg('ai','已记录。今天的营养汇总也已经更新，你可以继续问我还差多少热量或蛋白质。');},350)}
function voiceMock(){document.getElementById('chatText').value='早餐吃了两个鸡蛋和一杯牛奶';alert('已模拟完成语音转文字，你可以先检查和修改，再发送。')}
function initAssistant(){let q=localStorage.getItem('prototypePrompt');if(q){localStorage.removeItem('prototypePrompt');document.getElementById('chatText').value=q;setTimeout(sendChat,200)}}

function filterKnowledge(){let q=(document.getElementById('knowledgeSearch').value||'').toLowerCase();document.querySelectorAll('.knowledge-card').forEach(c=>c.style.display=!q||c.dataset.k.toLowerCase().includes(q)||c.innerText.toLowerCase().includes(q)?'block':'none');}
function initTraining(){let r=document.getElementById('planCards');if(!r)return;r.innerHTML=D.plans.map((p,idx)=>`<div class="plan-card"><div class="plan-head"><div><span class="pill ${idx===0?'green':idx===1?'blue':'purple'}">${p.category}</span><h3>${p.name}</h3></div><span class="pill">${p.status}</span></div><div class="cycle">${p.cycle.map((d,i)=>`<div class="day ${d==='Rest'?'rest':''} ${i===0?'active':''}"><strong>Day ${i+1}</strong><br>${d}</div>`).join('')}</div><div class="meta">今日：${p.today}</div></div>`).join('')}
function startFreeWorkout(){alert('已模拟创建 Free Workout Session。它不依赖任何训练计划。')}

function initCalendar(){let r=document.getElementById('calendarGrid');if(!r)return;let heads=['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];r.innerHTML=heads.map(h=>`<div class="cal-head">${h}</div>`).join('');let events={1:['food:4 meals'],2:['cardio:Easy Run'],3:['strength:Pull'],5:['strength:Legs'],8:['strength:Push'],9:['cardio:Easy Run'],12:['strength:Pull'],13:['strength:Legs'],17:['strength:Push'],18:['cardio:Easy Run'],20:['strength:Pull'],21:['strength:Legs'],22:['food:4 meals','strength:Push','cardio:Mobility'],24:['strength:Pull'],25:['cardio:Easy Run'],26:['strength:Legs'],30:['strength:Push']};let startOffset=1;for(let i=0;i<35;i++){let day=i-startOffset+1;let valid=day>=1&&day<=30;let html=`<div class="cal-day ${valid?'':'muted'}"><div class="cal-num">${valid?day:(day<1?31:day-30)}</div>`;if(valid&&(events[day]||[]).length)html+=(events[day]||[]).map(e=>{let [type,name]=e.split(':');return `<div class="event ${type}">${name}</div>`}).join('');r.innerHTML+=html+'</div>'}}

document.addEventListener('DOMContentLoaded',()=>{initDashboard();initNutrition();initAnalytics();initAssistant();initTraining();initCalendar();});

window.initMemberHome=function(){
  const root=document.getElementById('memberMealList');
  if(root && !root.dataset.ready){
    const icons={'早餐':'◐','午餐':'◒','晚餐':'◑','加餐':'◇'};
    root.innerHTML=D.meals.map(m=>`<div class="member-meal-row"><div class="member-meal-icon">${icons[m.type]||'○'}</div><div><div class="member-meal-title">${m.title}</div><div class="member-meal-sub">${m.time} · ${m.type} · P${m.p} / C${m.c} / F${m.f}</div></div><div class="member-meal-kcal">${m.kcal} kcal</div></div>`).join('');
    root.dataset.ready='1';
  }
};
