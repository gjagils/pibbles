// ---- UI ----
const $=id=>document.getElementById(id);
const pad=x=>String(x).padStart(2,'0');
const dayIdx=d=>Math.round(Date.UTC(d.getFullYear(),d.getMonth(),d.getDate())/864e5);
const keyOf=d=>d.getFullYear()+'-'+pad(d.getMonth()+1)+'-'+pad(d.getDate());
const now=new Date(), TODAY=dayIdx(now), LAUNCH=dayIdx(new Date(2026,10,22));
const WD=(now.getDay()+6)%7;                       // monday = 0
const dateOfWd=w=>new Date(now.getFullYear(),now.getMonth(),now.getDate()+w-WD);
const HINT_PENALTY=30000;
// mode: 'daily' counts for streak and leaderboard; 'preview' (another weekday) and 'practice' do not.
let mode='daily', viewWd=WD, practiceNo=0, P=null, placed=[], hints=0, startAt=0, endAt=0, tick=0, cell=48, drag=null;
// player state: streak fields + today's result + recently solved days
let S={streak:0,jokers:0,lastDay:null,best:0,day:null,ms:0,hints:0,score:0,solved:[]};
let db=null, user=null, uid=null, saveNote='';
try{const r=JSON.parse(localStorage.getItem('randsom-state')||'null'); if(r&&typeof r==='object') S=Object.assign(S,r)}catch(e){}
const saveLocal=()=>{try{localStorage.setItem('randsom-state',JSON.stringify(S))}catch(e){}};
const solvedToday=()=>S.lastDay===TODAY;

function pieceEl(i,size){
  const key=P.pieces[i], d=dims(key), el=document.createElement('div');
  el.className='piece'; el.style.width=d.w*size+'px'; el.style.height=d.h*size+'px'; el.style.setProperty('--pc','var(--p'+(i%8)+')');
  for(const[r,c]of SHAPES[key]){const b=document.createElement('b');b.style.cssText='left:'+c*size+'px;top:'+r*size+'px;width:'+size+'px;height:'+size+'px';el.appendChild(b)}
  el.dataset.i=i; return el;
}
function occupancy(skip){const n=P.n,g=new Int8Array(n*n).fill(-1);placed.forEach((p,i)=>{if(p<0||i===skip)return;for(const[r,c]of SHAPES[P.pieces[i]])g[p+r*n+c]=i});return g}
function fits(i,r0,c0,g){const n=P.n,d=dims(P.pieces[i]);if(r0<0||c0<0||r0+d.h>n||c0+d.w>n)return false;return SHAPES[P.pieces[i]].every(([r,c])=>g[(r0+r)*n+c0+c]<0)}
function sums(){const n=P.n,R=new Array(n).fill(0),C=new Array(n).fill(0),g=occupancy(-1);for(let r=0;r<n;r++)for(let c=0;c<n;c++)if(g[r*n+c]>=0){R[r]++;C[c]++}return{R,C}}
function solved(){if(placed.some(p=>p<0))return false;const s=sums();return s.R.every((x,i)=>x===P.rows[i])&&s.C.every((x,i)=>x===P.cols[i])}
function fmt(ms){const s=Math.floor(ms/1000);return Math.floor(s/60)+':'+pad(s%60)}
const hintTxt=h=>h?h+(h===1?' hint':' hints'):'zonder hints';

function sizeCell(){const w=Math.min($('board').parentElement.clientWidth,460);cell=Math.max(26,Math.min(56,Math.floor(w/(P.n+1))));document.documentElement.style.setProperty('--cellpx',cell+'px')}
function load(){
  clearInterval(tick); hints=0; startAt=0; endAt=0;
  const d=dateOfWd(viewWd);
  P = mode==='practice' ? generate(WEEK[WD],'oefen-'+Date.now()+'-'+practiceNo) : generate(WEEK[viewWd],keyOf(d));
  placed=P.pieces.map(()=>-1);
  if(mode==='daily' && solvedToday()){ placed=P.solution.slice(); hints=S.hints; endAt=Date.now(); startAt=endAt-S.ms; }
  $('timer').textContent=endAt?fmt(endAt-startAt):'0:00';
  $('sub').textContent = mode==='practice' ? 'Oefenpuzzel '+practiceNo
    : d.toLocaleDateString('nl-NL',{weekday:'long',day:'numeric',month:'long'})+(dayIdx(d)>=LAUNCH?' · nr. '+(dayIdx(d)-LAUNCH+1):'');
  $('mode').textContent = mode==='daily' ? '' : mode==='practice' ? 'Oefenpuzzel op het niveau van vandaag. Telt niet mee voor reeks of ranglijst.'
    : 'Voorproef van een andere dag. Telt niet mee voor reeks of ranglijst.';
  renderWeek(); renderChips(); render();
}
function renderChips(){
  const v=streakNow(S,TODAY), c=$('chips');
  c.innerHTML='<span>Reeks <b>'+v.streak+'</b></span><span>Jokers <b>'+v.jokers+'</b></span><span>Beste reeks <b>'+(S.best||0)+'</b></span>';
  const n=document.createElement('span');
  n.textContent = v.used ? (v.used===1?'1 joker ingezet voor een gemiste dag':v.used+' jokers ingezet voor gemiste dagen') : v.lost ? 'Reeks verbroken, begin vandaag opnieuw' : '';
  if(n.textContent)c.appendChild(n);
}
function renderWeek(){
  const w=$('week'); w.innerHTML='';
  WEEK.forEach((L,i)=>{const b=document.createElement('button'), di=dayIdx(dateOfWd(i)), ok=(S.solved||[]).includes(di);
    b.className=(i===WD?'today ':'')+(ok?'solved':''); b.setAttribute('aria-pressed',mode!=='practice'&&i===viewWd);
    b.setAttribute('aria-label',dateOfWd(i).toLocaleDateString('nl-NL',{weekday:'long'})+', '+L.n+' bij '+L.n+', '+L.pieces+' blokken'+(ok?', opgelost':''));
    b.innerHTML='<b>'+DAYS[i]+'</b><small>'+(ok?'✓':L.n+'×'+L.n)+'</small>';
    b.onclick=()=>{viewWd=i;mode=i===WD?'daily':'preview';load()}; w.appendChild(b)});
}
function render(){
  sizeCell(); const n=P.n, board=$('board'); board.style.setProperty('--n1',n+1); board.innerHTML=''; board.classList.remove('won');
  const s=sums();
  const clue=(v,cur,lab)=>{const d=document.createElement('div');d.className='clue'+(cur===v?' done':cur>v?' over':'');d.setAttribute('aria-label',lab+': '+cur+' van '+v);d.innerHTML='<span>'+v+'</span>';return d};
  board.appendChild(document.createElement('div'));
  for(let c=0;c<n;c++)board.appendChild(clue(P.cols[c],s.C[c],'Kolom '+(c+1)));
  for(let r=0;r<n;r++){board.appendChild(clue(P.rows[r],s.R[r],'Rij '+(r+1)));for(let c=0;c<n;c++){const d=document.createElement('div');d.className='cell';d.innerHTML='<i></i>';board.appendChild(d)}}
  const layer=document.createElement('div');layer.className='layer';layer.id='layer';board.appendChild(layer);
  placed.forEach((p,i)=>{if(p<0||(drag&&drag.i===i))return;const el=pieceEl(i,cell);el.style.left=(p%n)*cell+'px';el.style.top=Math.floor(p/n)*cell+'px';layer.appendChild(el)});
  const tray=$('tray');tray.innerHTML='';
  const done=solved(), allIn=placed.every(p=>p>=0);
  if(done){
    if(!endAt){endAt=Date.now();clearInterval(tick);if(!startAt)startAt=endAt;$('timer').textContent=fmt(endAt-startAt);board.classList.add('won');if(mode==='daily')recordSolve()}
    const what=mode==='practice'?'oefenpuzzel':mode==='preview'?'voorproef '+DAYS[viewWd]:'nr. '+(TODAY-LAUNCH+1);
    const txt='Randsom '+what+' · '+fmt(endAt-startAt)+' · '+hintTxt(hints)+(mode==='daily'?' · reeks '+S.streak:'');
    tray.innerHTML='<div class="msg"><strong>Opgelost!</strong><p class="share" id="sharetxt"></p><button class="btn primary" id="copy">Kopieer resultaat</button><p id="savenote"></p></div>';
    $('sharetxt').textContent=txt; $('savenote').textContent=mode==='daily'?saveNote:'';
    $('copy').onclick=()=>{const b=$('copy');const ok=()=>b.textContent='Gekopieerd';const sel=()=>{const r=document.createRange();r.selectNodeContents($('sharetxt'));const x=getSelection();x.removeAllRanges();x.addRange(r);b.textContent='Geselecteerd, kopieer zelf'};
      try{navigator.clipboard.writeText(txt).then(ok,sel)}catch(e){sel()}};
  } else if(allIn && !drag){
    tray.innerHTML='<div class="msg"><strong>Nog niet goed</strong><p>Alle blokken liggen, maar niet elk getal klopt. Pak een blok op en verschuif het.</p></div>';
  } else {
    P.pieces.forEach((k,i)=>{const slot=document.createElement('div');slot.className='slot'+((placed[i]>=0||(drag&&drag.i===i))?' empty':'');slot.appendChild(pieceEl(i,Math.round(cell*.56)));tray.appendChild(slot)});
  }
  $('hint').disabled=done; $('reset').disabled=done;
}

// ---- Streak, result and leaderboard ----
function recordSolve(){
  if(solvedToday())return;
  const ms=endAt-startAt;
  S=Object.assign({},S,streakAfterSolve(S,TODAY),{day:keyOf(now),ms,hints,score:ms+hints*HINT_PENALTY,solved:(S.solved||[]).filter(d=>d>TODAY-14).concat(TODAY)});
  saveLocal(); renderChips(); renderWeek(); pushScore(); if(!db)renderBoardList([]);
}
let writing=null;
function pushScore(){
  if(!db||!uid)return;
  writing=(writing||Promise.resolve()).then(()=>db.doc('scores/'+uid).set(JSON.parse(JSON.stringify(S))))
    .then(()=>{saveNote=''},()=>{saveNote='Je score kon niet op de ranglijst worden gezet. Je reeks is op dit apparaat bewaard.'})
    .then(()=>{const n=$('savenote');if(n&&mode==='daily')n.textContent=saveNote});
}
let lbRows=[], lbToken=0;
async function renderBoardList(rows){
  lbRows=rows; const my=++lbToken, list=rows.slice();
  if(solvedToday() && !list.some(r=>r.id===uid)) list.push({id:uid||'local',score:S.score,ms:S.ms,hints:S.hints,streak:S.streak,local:true});
  list.sort((a,b)=>a.score-b.score);
  let ps={}; if(user){try{ps=await user.profiles(list.map(r=>r.id).filter(x=>x&&x!=='local'))}catch(e){}} if(my!==lbToken)return;
  const ol=$('lb'); ol.innerHTML='';
  list.forEach((r,i)=>{const me=r.local||r.id===uid, li=document.createElement('li'); if(me)li.className='me';
    const rk=document.createElement('span');rk.className='rk';rk.textContent=i+1;
    const nm=document.createElement('span');nm.className='nm';nm.textContent=(ps[r.id]&&ps[r.id].name)||(me?'Jij':'Speler');
    const sm=document.createElement('small');sm.textContent=(me&&ps[r.id]&&ps[r.id].name?'jij · ':'')+hintTxt(r.hints||0)+' · reeks '+(r.streak||0);nm.appendChild(sm);
    const tm=document.createElement('span');tm.className='tm';tm.textContent=fmt(r.score);
    li.append(rk,nm,tm);ol.appendChild(li)});
  if(!list.length && db)$('lbnote').textContent='Nog niemand heeft de puzzel van vandaag opgelost. Wees de eerste.';
  else if(db)$('lbnote').textContent='';
}
async function connect(){
  const use=window.claude&&window.claude.use?n=>window.claude.use(n):()=>Promise.resolve(null);
  try{[db,user]=await Promise.all([use('db'),use('user')]); uid=user?await user.id():null}catch(e){db=null}
  if(!db||!uid){db=null;$('lbnote').textContent='De gedeelde ranglijst is hier niet beschikbaar. Je reeks wordt op dit apparaat bewaard.';renderBoardList([]);return}
  try{const snap=await db.doc('scores/'+uid).get();
    if(snap.exists){const r=snap.data(); if(S.lastDay==null||(r.lastDay||0)>=S.lastDay){const was=solvedToday();S=Object.assign({},S,r);saveLocal();renderChips();renderWeek();if(!was&&solvedToday()&&mode==='daily'&&!endAt)load()}else pushScore()}
    else if(S.lastDay!=null)pushScore();
  }catch(e){}
  const slow=setTimeout(()=>{$('lbnote').textContent='De ranglijst is nog niet bereikbaar.'},10000);
  db.collection('scores').where('day','==',keyOf(now)).limit(200).onSnapshot(
    q=>{if(!q.metadata.fromCache)clearTimeout(slow);renderBoardList(q.docs.map(d=>Object.assign({id:d.id},d.data())))},
    ()=>{clearTimeout(slow);$('lbnote').textContent='De ranglijst is nu niet bereikbaar.'});
}

function startTimer(){if(startAt)return;startAt=Date.now();tick=setInterval(()=>{$('timer').textContent=fmt(Date.now()-startAt)},500)}
function beginDrag(i,ev,fx,fy){
  startTimer(); const d=dims(P.pieces[i]); placed[i]=-1;
  const el=pieceEl(i,cell); el.classList.add('drag'); document.body.appendChild(el);
  drag={i,el,gx:fx*d.w*cell,gy:fy*d.h*cell,lift:ev.pointerType==='touch'?cell*1.3:0,shadow:null,target:null,g:occupancy(i)};
  render(); moveDrag(ev);
}
function moveDrag(ev){
  if(!drag)return; const x=ev.clientX-drag.gx, y=ev.clientY-drag.gy-drag.lift;
  drag.el.style.left=x+'px'; drag.el.style.top=y+'px';
  const layer=$('layer'), rc=layer.getBoundingClientRect(), n=P.n;
  const c0=Math.round((x-rc.left)/cell), r0=Math.round((y-rc.top)/cell);
  const ok=fits(drag.i,r0,c0,drag.g); const t=ok?r0*n+c0:null;
  if(t!==drag.target){drag.target=t; if(drag.shadow){drag.shadow.remove();drag.shadow=null}
    if(ok){const s=pieceEl(drag.i,cell);s.classList.add('shadow');s.style.left=c0*cell+'px';s.style.top=r0*cell+'px';layer.appendChild(s);drag.shadow=s}}
}
function endDrag(){ if(!drag)return; const d=drag; drag=null; d.el.remove(); if(d.target!==null)placed[d.i]=d.target; render() }
document.addEventListener('pointerdown',ev=>{
  if(drag||ev.button>0)return; const b=ev.target.closest('.piece b'); if(!b||solved())return;
  const el=b.parentElement, i=+el.dataset.i, rc=el.getBoundingClientRect();
  ev.preventDefault(); beginDrag(i,ev,(ev.clientX-rc.left)/rc.width,(ev.clientY-rc.top)/rc.height);
});
document.addEventListener('pointermove',ev=>{if(drag){ev.preventDefault();moveDrag(ev)}},{passive:false});
document.addEventListener('pointerup',endDrag); document.addEventListener('pointercancel',endDrag);
document.addEventListener('touchmove',ev=>{if(drag)ev.preventDefault()},{passive:false});

function hint(){
  if(solved())return; startTimer(); const n=P.n;
  const j=P.pieces.findIndex((k,idx)=>!P.pieces.some((k2,i2)=>k2===k&&placed[i2]===P.solution[idx])); if(j<0)return;
  const key=P.pieces[j], sol=new Set(P.pieces.map((k,idx)=>k+'@'+P.solution[idx]));
  let i=P.pieces.findIndex((k,idx)=>k===key&&placed[idx]<0); if(i<0)i=P.pieces.findIndex((k,idx)=>k===key&&!sol.has(k+'@'+placed[idx]));
  placed[i]=-1; const g=occupancy(-1), p=P.solution[j];
  for(const[r,c]of SHAPES[key]){const o=g[p+r*n+c]; if(o>=0)placed[o]=-1}
  placed[i]=p; hints++; render();
}
$('hint').onclick=hint;
$('reset').onclick=()=>{if(solved())return;placed=placed.map(()=>-1);render()};
$('practice').onclick=()=>{practiceNo++;mode='practice';load()};
window.addEventListener('resize',()=>{if(P&&!drag)render()});
load(); renderBoardList([]); connect();
