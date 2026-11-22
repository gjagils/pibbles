// ---- Puzzle logic (pure, no DOM) ----
const SHAPES = {
  I2:[[0,0],[0,1]], I2v:[[0,0],[1,0]],
  I3:[[0,0],[0,1],[0,2]], I3v:[[0,0],[1,0],[2,0]],
  L3a:[[0,0],[1,0],[1,1]], L3b:[[0,0],[0,1],[1,0]], L3c:[[0,0],[0,1],[1,1]], L3d:[[0,1],[1,0],[1,1]],
  O4:[[0,0],[0,1],[1,0],[1,1]],
  I4:[[0,0],[0,1],[0,2],[0,3]], I4v:[[0,0],[1,0],[2,0],[3,0]],
  L4a:[[0,0],[1,0],[2,0],[2,1]], L4b:[[0,0],[0,1],[0,2],[1,0]], L4c:[[0,0],[0,1],[1,1],[2,1]], L4d:[[0,2],[1,0],[1,1],[1,2]],
  J4a:[[0,1],[1,1],[2,0],[2,1]], J4b:[[0,0],[1,0],[1,1],[1,2]], J4c:[[0,0],[0,1],[1,0],[2,0]], J4d:[[0,0],[0,1],[0,2],[1,2]],
  T4a:[[0,0],[0,1],[0,2],[1,1]], T4b:[[0,1],[1,0],[1,1],[2,1]], T4c:[[0,1],[1,0],[1,1],[1,2]], T4d:[[0,0],[1,0],[1,1],[2,0]],
  S4a:[[0,1],[0,2],[1,0],[1,1]], S4b:[[0,0],[1,0],[1,1],[2,1]],
  Z4a:[[0,0],[0,1],[1,1],[1,2]], Z4b:[[0,1],[1,0],[1,1],[2,0]],
};
const SHAPE_KEYS = Object.keys(SHAPES);
// Weekritme: maandag makkelijk, zondag het moeilijkst.
const WEEK = [
  { n:5, pieces:4 }, { n:5, pieces:5 }, { n:6, pieces:5 }, { n:6, pieces:6 },
  { n:6, pieces:7 }, { n:7, pieces:7 }, { n:7, pieces:8 },
];
const DAYS = ['ma','di','wo','do','vr','za','zo'];
// ---- Streak rules (pure) ----
const JOKER_EVERY = 5, JOKER_MAX = 3;
function streakAfterSolve(s, day){
  if(s.lastDay===day) return s;
  let streak=s.streak||0, jokers=s.jokers||0;
  if(s.lastDay==null) streak=0;
  else { const gap=day-s.lastDay-1; if(gap>0){ if(gap<=jokers) jokers-=gap; else streak=0; } }
  streak++; if(streak%JOKER_EVERY===0 && jokers<JOKER_MAX) jokers++;
  return {streak, jokers, lastDay:day, best:Math.max(s.best||0,streak)};
}
function streakNow(s, day){
  const jokers=s.jokers||0;
  if(s.lastDay==null) return {streak:0, jokers, used:0, lost:false};
  const gap=Math.max(0,day-s.lastDay-1);
  if(gap===0) return {streak:s.streak, jokers, used:0, lost:false};
  if(gap<=jokers) return {streak:s.streak, jokers:jokers-gap, used:gap, lost:false};
  return {streak:0, jokers, used:0, lost:(s.streak||0)>0};
}
function mulberry32(a){return function(){a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
function hashStr(s){let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)}return h>>>0}
function dims(key){const c=SHAPES[key];let h=0,w=0;for(const[r,q]of c){if(r+1>h)h=r+1;if(q+1>w)w=q+1}return{h,w}}

// Count solutions (up to `limit`). Identical shapes are interchangeable.
function countSolutions(n, shapeKeys, rows, cols, limit, budget){
  const order = shapeKeys.map((k,i)=>({k,i})).sort((a,b)=>SHAPES[b.k].length-SHAPES[a.k].length || (a.k<b.k?-1:a.k>b.k?1:0));
  const grid = new Uint8Array(n*n), R = rows.slice(), C = cols.slice();
  let count = 0, nodes = 0, first = null; const pos = new Array(order.length);
  function rec(d){
    if(count>=limit || nodes>budget) return;
    if(d===order.length){ if(R.every(x=>x===0)&&C.every(x=>x===0)){count++; if(!first){first=new Array(order.length); order.forEach((o,j)=>first[o.i]=pos[j]);}} return; }
    const key=order[d].k, cells=SHAPES[key], {h,w}=dims(key);
    const start = (d>0 && order[d-1].k===key) ? pos[d-1]+1 : 0;
    for(let p=start;p<n*n;p++){
      const r0=(p/n)|0, c0=p%n; if(r0+h>n||c0+w>n) continue;
      let ok=true;
      for(const[dr,dc]of cells){ if(grid[(r0+dr)*n+c0+dc]){ok=false;break} }
      if(!ok) continue;
      for(const[dr,dc]of cells){ R[r0+dr]--; C[c0+dc]--; }
      for(let i=0;i<n;i++) if(R[i]<0||C[i]<0){ok=false;break}
      if(ok){ nodes++; for(const[dr,dc]of cells) grid[(r0+dr)*n+c0+dc]=1; pos[d]=p; rec(d+1); for(const[dr,dc]of cells) grid[(r0+dr)*n+c0+dc]=0; }
      for(const[dr,dc]of cells){ R[r0+dr]++; C[c0+dc]++; }
      if(count>=limit || nodes>budget) return;
    }
  }
  rec(0);
  return {count, nodes, exhausted: nodes>budget, first};
}

function generate(L, seedStr){
  const n=L.n, rnd = mulberry32(hashStr(n+'x'+L.pieces+'|'+seedStr));
  for(let attempt=0; attempt<20000; attempt++){
    const grid=new Uint8Array(n*n), keys=[], at=[]; let fail=false;
    for(let i=0;i<L.pieces && !fail;i++){
      let placed=false;
      for(let t=0;t<40 && !placed;t++){
        const key=SHAPE_KEYS[(rnd()*SHAPE_KEYS.length)|0];
        if(SHAPES[key].length<3 && rnd()<0.6) continue;
        const {h,w}=dims(key), r0=(rnd()*(n-h+1))|0, c0=(rnd()*(n-w+1))|0;
        if(SHAPES[key].some(([dr,dc])=>grid[(r0+dr)*n+c0+dc])) continue;
        SHAPES[key].forEach(([dr,dc])=>grid[(r0+dr)*n+c0+dc]=1); keys.push(key); at.push(r0*n+c0); placed=true;
      }
      if(!placed) fail=true;
    }
    if(fail) continue;
    const cnt={}; let dup=false; for(const k of keys){cnt[k]=(cnt[k]||0)+1; if(cnt[k]>2) dup=true}
    if(dup) continue;
    const rows=new Array(n).fill(0), cols=new Array(n).fill(0);
    for(let r=0;r<n;r++)for(let c=0;c<n;c++) if(grid[r*n+c]){rows[r]++;cols[c]++}
    if(rows.concat(cols).filter(x=>x===0).length>(L.pieces<5?1:0)) continue;
    const res=countSolutions(n,keys,rows,cols,2,60000);
    if(res.count===1 && !res.exhausted) return {n,pieces:keys,rows,cols,solution:at,attempts:attempt+1,nodes:res.nodes};
  }
  return null;
}
if(typeof module!=='undefined') module.exports={SHAPES,WEEK,generate,countSolutions,dims,streakAfterSolve,streakNow};
