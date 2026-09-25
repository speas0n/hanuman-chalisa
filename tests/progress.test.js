import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, statSync } from 'node:fs';
import { verses } from '../dist/verses.js';
import { dateKey, reviewResult, dueIds, normalizeState } from '../dist/progress.js';
test('all 43 passages have two Roman lines and two original lines',()=>{
 assert.equal(verses.length,43);
 assert.equal(verses.filter(v=>v.title.startsWith('Verse ')).length,40);
 verses.forEach((v,i)=>{assert.equal(v.id,i);assert.equal(v.lines.length,2);assert.equal(v.hindi.length,2);v.lines.forEach(line=>{assert.ok(line.length>10);assert.match(line,/^[A-Za-z ,]+$/);});});
});
test('recall progresses 1, 3, 7, 14 days and does not inflate on same-day repetitions',()=>{
 let now=new Date(2026,8,25,12);
 let r=reviewResult({},true,now);assert.equal(r.due,'2026-09-26');assert.equal(r.stage,1);
 r=reviewResult(r,true,now);assert.equal(r.stage,1);
 now=new Date(2026,8,26,12);r=reviewResult(r,true,now);assert.equal(r.stage,2);assert.equal(r.due,'2026-09-29');
 now=new Date(2026,8,29,12);r=reviewResult(r,true,now);assert.equal(r.due,'2026-10-06');
 now=new Date(2026,9,6,12);r=reviewResult(r,true,now);assert.equal(r.due,'2026-10-20');
 r=reviewResult(r,false,now);assert.equal(r.due,'2026-10-06');assert.equal(r.stage,0);assert.equal(r.recalled,true);
});
test('review selects due passages and handles month/year boundaries',()=>{
 assert.equal(reviewResult({},true,new Date(2026,11,31,12)).due,'2027-01-01');
 assert.deepEqual(dueIds({0:{due:'2026-09-25'},1:{due:'2026-09-24'},2:{due:'2026-09-26'}},'2026-09-25'),[0,1]);
});
test('corrupt saved data cannot select a missing verse or unsupported speed',()=>{
 assert.deepEqual(normalizeState({current:99,speed:20,records:{99:{},bad:{},1:{stage:99,recalled:'yes'}}}),{current:0,speed:1,records:{1:{stage:4,due:dateKey(),lastSuccess:null,recalled:false,practised:false}}});
});
test('every line has a nonempty bundled audio clip',()=>{
 for(const v of verses)for(let n=0;n<2;n++){
 const path=new URL(`../dist/audio/${String(v.id).padStart(2,'0')}-${n}.mp3`,import.meta.url);assert.ok(existsSync(path));assert.ok(statSync(path).size>2000);
 }
});
