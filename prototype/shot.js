const {chromium}=require('playwright');const fs=require('fs');
(async()=>{const b=await chromium.launch();
const html='<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{margin:0}</style></head><body>'+fs.readFileSync('randsom.html','utf8')+'</body></html>';
fs.writeFileSync('wrapped.html',html);
const ctx=await b.newContext({viewport:{width:400,height:1150}});const p=await ctx.newPage();
p.on('console',m=>{if(m.type()==='error')console.log('ERR',m.text())});p.on('pageerror',e=>console.log('PAGEERR',e.message));
// fake db + user to exercise the leaderboard path
await p.addInitScript(()=>{const store={'u_other':{day:new Date().getFullYear()+'-'+String(new Date().getMonth()+1).padStart(2,'0')+'-'+String(new Date().getDate()).padStart(2,'0'),score:95000,ms:65000,hints:1,streak:4}};let cb=null;
 const fire=()=>cb&&cb({metadata:{fromCache:false},docs:Object.keys(store).map(id=>({id,data:()=>store[id]}))});
 const dbx={doc:path=>({get:async()=>({exists:!!store[path.split('/')[1]],data:()=>store[path.split('/')[1]]}),set:async d=>{store[path.split('/')[1]]=d;window.__written=d;fire()}}),
  collection:()=>({where(){return this},limit(){return this},onSnapshot(n){cb=n;setTimeout(fire,50);return()=>{}}})};
 const ux={id:async()=>'u_me',profiles:async ids=>Object.fromEntries(ids.map(i=>[i,{id:i,name:i==='u_other'?'Sanne':''}]))};
 window.claude={use:async n=>n==='db'?dbx:n==='user'?ux:null}});
await p.goto('file://'+process.cwd()+'/wrapped.html');await p.waitForTimeout(600);
const pc=await p.locator('#tray .piece b').first().boundingBox();const ly=await p.locator('#layer').boundingBox();
await p.mouse.move(pc.x+5,pc.y+5);await p.mouse.down();await p.mouse.move(ly.x+60,ly.y+60,{steps:5});await p.mouse.up();
for(let i=0;i<10;i++)await p.click('#hint',{force:true}).catch(()=>{});
await p.waitForTimeout(400);
console.log('written',JSON.stringify(await p.evaluate(()=>window.__written)));
console.log('lb',await p.evaluate(()=>document.getElementById('lb').innerText.replace(/\n+/g,' | ')));
console.log('chips',await p.evaluate(()=>document.getElementById('chips').innerText.replace(/\n+/g,' ')),'overflow',await p.evaluate(()=>document.documentElement.scrollWidth>innerWidth));
await p.screenshot({path:'won.png',fullPage:true});
await p.reload();await p.waitForTimeout(600);
console.log('after reload solved',await p.evaluate(()=>solved()),await p.evaluate(()=>document.getElementById('timer').textContent));
await p.click('#week button:nth-child(1)');console.log('preview',await p.evaluate(()=>document.getElementById('mode').textContent),await p.evaluate(()=>P.n));
await b.close()})();
