/* Execute the delivered HTML's actual controller in a VM with storage/audio shims.
   This is NOT a browser rendering or native Flutter test. */
const vm=require('node:vm'),fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const script=fs.readFileSync(path.join(root,'Block_Crash_Line_Playable_Preview.html'),'utf8').match(/<script>([\s\S]*?)<\/script>/)[1];
const files=new Map(),elements=new Map();let elapsed=0,fail=false;
function el(id){if(!elements.has(id))elements.set(id,{innerHTML:'',textContent:'',style:{setProperty(){}},append(){},appendChild(){},remove(){},addEventListener(){},click(){}});return elements.get(id);}
class Audio {volume=1;loop=false;play(){return Promise.resolve();}pause(){}}
const document={hidden:false,documentElement:{lang:'tr'},body:el('body'),getElementById:el,querySelector:()=>null,querySelectorAll:()=>[],createElement:()=>el('toast'),addEventListener(){}};
const ctx=vm.createContext({document,Audio,localStorage:{getItem:k=>files.get(k)||null,setItem:(k,v)=>{if(fail)throw Error('full');files.set(k,v);}},performance:{now:()=>elapsed},navigator:{vibrate(){}},setTimeout(){},setInterval(){},console,Date,Math,JSON,Set,Image:class{},FileReader:class{}});
vm.runInContext(script,ctx);const run=s=>vm.runInContext(s,ctx);let checks=[];
function test(n,fn){fn();checks.push(n);console.log('PASS '+n);}
test('Login reward only once after reload',()=>{assert.equal(run('p.coins'),50);vm.runInContext(script.replace(/\bconst\b/g,'var').replace(/\blet\b/g,'var'),vm.createContext({...ctx}));assert.equal(JSON.parse(files.values().next().value).coins,50);});
test('Locked direct launch rejected',()=>{assert.equal(run("start('adventure',2)"),false);});
test('All 20 solutions through actual controller, unlocking and rewards',()=>{for(let i=1;i<=20;i++){run(`start('adventure',${i}); for(const a of LEVELS[${i-1}].solution)attempt(a.slot,a.row,a.col,!!a.bomb)`);assert.equal(run('g.outcome'),'won');assert.equal(run(`p.levelStars[${i}]`),3);}assert.equal(run("p.achievements.includes('master')"),true);});
test('Replay rewards only normal line coins',()=>{const balance=run('p.coins');run("start('adventure',1);attempt(0,0,6)");assert.equal(run('p.coins'),balance+10);});
test('Classic saved board and tray resume',()=>{run("start('classic');g.tray=['single','h2','v2'];attempt(0,0,0);home()");let saved=run('JSON.stringify(p.classic)');assert(saved);run("start('classic',null,true)");assert.equal(run('g.moves'),1);assert.equal(run('g.board[0]'),1);assert.equal(run('g.tray[0]'),null);});
test('Save failure keeps gameplay and coins unchanged',()=>{const state=run('JSON.stringify(g)'),balance=run('p.coins');fail=true;run('attempt(1,1,0)');fail=false;assert.equal(run('JSON.stringify(g)'),state);assert.equal(run('p.coins'),balance);});
test('Insufficient funds rejected and owned product not charged twice',()=>{run("{let x=copy(p);x.coins=499;save(x);buy('neon');}");assert.equal(run("p.owned.includes('neon')"),false);run("{let x=copy(p);x.coins=500;save(x);buy('neon');}");assert.equal(run('p.coins'),0);run("buy('neon')");assert.equal(run('p.coins'),0);});
test('Photo cancel leaves existing settings intact',()=>{const state=run('JSON.stringify(p)');run('photoChosen({files:[]})');assert.equal(run('JSON.stringify(p)'),state);});
test('Settings stored and language changes delivered markup',()=>{run("setting('language','en');setting('reducedMotion',true);nav('settings')");assert.equal(JSON.parse(files.values().next().value).language,'en');assert(elements.get('app').innerHTML.includes('Settings'));assert.equal(run('p.reducedMotion'),true);});
test('Paused time attack expires, future placements rejected',()=>{run("start('timeAttack');pause()");elapsed+=61000;run('updateTime();render()');assert.equal(run('g.outcome'),'lost');const score=run('g.score');run('attempt(0,0,0)');assert.equal(run('g.score'),score);});
fs.writeFileSync(path.join(root,'APP_LOGIC_VERIFICATION.json'),JSON.stringify({method:'Node VM executes delivered HTML controller with localStorage and audio shims; not DOM/browser rendering or Flutter',passed:checks.length,checks},null,2));console.log(`${checks.length} application logic checks passed`);
