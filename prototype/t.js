const {generate,WEEK,streakAfterSolve,streakNow}=require('./logic.js');
WEEK.forEach((L,w)=>{let tot=0,max=0,f=0;for(let d=0;d<40;d++){const t=Date.now();const p=generate(L,'d'+d);const e=Date.now()-t;tot+=e;max=Math.max(max,e);if(!p)f++}console.log(w,L.n,L.pieces,'avg',(tot/40).toFixed(1),'max',max,'fails',f)});
let s={};for(const d of [1,2,3,4,5]) s=streakAfterSolve(s,d);console.log('5 days',s);
console.log('skip1 now',streakNow(s,7)); s=streakAfterSolve(s,7);console.log('after joker',s);
console.log('skip2 now',streakNow(s,10)); s=streakAfterSolve(s,10);console.log('reset',s);
