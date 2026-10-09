const {chromium}=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES?process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/playwright':'playwright');
const path=require('node:path'),fs=require('node:fs'),assert=require('node:assert/strict');
(async()=>{
 const root=path.resolve(__dirname,'..');const browser=await chromium.launch({headless:true,executablePath:process.env.BROWSER_EXECUTABLE,args:['--no-sandbox']});
 const page=await browser.newPage({viewport:{width:390,height:844}});const errors=[];
 page.on('pageerror',e=>errors.push(e.message));await page.goto('file://'+path.join(root,'Block_Crash_Line_Playable_Preview.html'));
 await page.screenshot({path:path.join(root,'preview/home.png')});
 await page.getByRole('button',{name:'Macera',exact:false}).click();
 assert.equal(await page.locator('.map button:disabled').count(),19);
 assert.equal(await page.evaluate(()=>start('adventure',2)),false);
 await page.locator('.map button').first().click();
 await page.locator('[data-slot="0"]').click();await page.locator('[data-cell="6"]').click();
 assert.equal(await page.evaluate(()=>g.outcome),'won');assert.equal(await page.evaluate(()=>p.levelStars[1]),3);
 const balance=await page.evaluate(()=>p.coins);
 await page.getByRole('button',{name:'Yeniden oyna'}).click();
 await page.locator('[data-slot="0"]').click();await page.locator('[data-cell="6"]').click();
 assert.equal(await page.evaluate(()=>p.coins),balance+10);
 await page.evaluate(()=>home());await page.evaluate(()=>start('classic'));
 await page.locator('[data-slot="0"]').click();
 const before=await page.evaluate(()=>({m:g.moves,slot:g.tray[0],cells:shapes[g.tray[0]].length}));
 await page.locator('[data-cell="0"]').click();assert.equal(await page.evaluate(()=>g.moves),before.m+1);
 assert.equal(await page.evaluate(()=>g.board.filter(Boolean).length),before.cells);
 await page.screenshot({path:path.join(root,'preview/game.png')});
 await page.evaluate(()=>home());const saved=await page.evaluate(()=>JSON.stringify(p.classic));
 await page.reload();assert.equal(await page.evaluate(()=>JSON.stringify(p.classic)),saved);
 await page.evaluate(()=>start('classic',null,true));assert.equal(await page.evaluate(()=>g.moves),1);
 await page.evaluate(()=>home());
 // Replay all fixed solutions through UI controller and reward transaction.
 for(let i=1;i<=20;i++){
   await page.evaluate(id=>{start('adventure',id);for(const a of LEVELS[id-1].solution)attempt(a.slot,a.row,a.col,!!a.bomb);},i);
   assert.equal(await page.evaluate(()=>g.outcome),'won');assert.equal(await page.evaluate(id=>p.levelStars[id]),3);
 }
 assert.equal(await page.evaluate(()=>p.achievements.includes('master')),true);
 await page.evaluate(()=>home());
 await page.evaluate(()=>{let x=copy(p);x.coins=499;save(x);buy('neon');});assert.equal(await page.evaluate(()=>p.owned.includes('neon')),false);
 await page.evaluate(()=>{let x=copy(p);x.coins=500;save(x);buy('neon');});assert.equal(await page.evaluate(()=>p.coins),0);
 await page.evaluate(()=>buy('neon'));assert.equal(await page.evaluate(()=>p.coins),0);
 await page.evaluate(()=>setting('language','en'));await page.reload();assert.equal(await page.evaluate(()=>p.language),'en');
 await page.evaluate(()=>start('timeAttack'));await page.evaluate(()=>{origin=performance.now()-60001;updateTime();render();});
 assert.equal(await page.evaluate(()=>g.outcome),'lost');const score=await page.evaluate(()=>g.score);
 await page.evaluate(()=>attempt(0,0,0));assert.equal(await page.evaluate(()=>g.score),score);
 await page.setViewportSize({width:320,height:568});await page.evaluate(()=>home());await page.evaluate(()=>start('classic'));
 const bounds=await page.locator('#board').boundingBox();assert(bounds.x>=0&&bounds.x+bounds.width<=320);
 assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=320),true);
 assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(root,'BROWSER_QA.json'),JSON.stringify({method:'Executed Chromium browser rehearsal; NOT Flutter device testing',passed:true,checks:['locked launch','tap placement','first-clear reward','replay no duplicate reward','Classic restore','20 solutions and unlocks','grand master reward','purchase balance','settings restore','time expiry','320px layout'],pageErrors:errors},null,2));
 console.log('PASS browser UI: 11 checks, 20 level replays, no page errors');await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1;});
