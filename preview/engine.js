/* Browser rehearsal engine; the Flutter implementation is lib/engine/game.dart. */
const shapes={single:[[0,0]],h2:[[0,0],[0,1]],v2:[[0,0],[1,0]],h3:[[0,0],[0,1],[0,2]],v3:[[0,0],[1,0],[2,0]],square:[[0,0],[0,1],[1,0],[1,1]],L:[[0,0],[1,0],[2,0],[2,1]],T:[[0,0],[0,1],[0,2],[1,1]],Z:[[0,0],[0,1],[1,1],[1,2]],h4:[[0,0],[0,1],[0,2],[0,3]],v4:[[0,0],[1,0],[2,0],[3,0]]};
const mult=n=>n<=0?0:[1,2,4,8][Math.min(n,4)-1];
function tray(score){let pool=Object.keys(shapes),out=[];for(let n=0;n<3;n++){let w=pool.map(s=>10+(shapes[s].length>=4?Math.min(Math.floor(score/500),25):0));let p=Math.random()*w.reduce((a,b)=>a+b,0),i=0;while(p>=w[i])p-=w[i++];out.push(pool.splice(i,1)[0]);}return out;}
function newGame(mode,level){return{mode,level:level?.id||null,board:level?level.board.join('').split('').map(x=>x==='#'?1:0):Array(64).fill(0),tray:level?[...level.trays[0]]:tray(0),score:0,streak:0,lines:0,moves:0,placements:0,bombs:level?.bombs||0,ti:0,elapsed:0,budget:60000,outcome:'playing',last:{points:0,combo:0,sm:0,coins:0,cleared:[]}};}
function fits(g,s,r,c){return !!shapes[s]&&shapes[s].every(([dr,dc])=>r+dr>=0&&r+dr<8&&c+dc>=0&&c+dc<8&&!g.board[(r+dr)*8+c+dc]);}
function possible(g,s){for(let r=0;r<8;r++)for(let c=0;c<8;c++)if(fits(g,s,r,c))return true;return false;}
function stars(g,levels){if(g.outcome!=='won')return 0;if(g.mode==='rush')return g.placements<=20?3:g.placements<=30?2:1;const l=levels[g.level-1];return Math.max(0,...l.stars.filter(s=>s.maximum==null||({moves:g.moves,placements:g.placements,elapsedMs:g.elapsed}[s.metric]<=s.maximum)).map(s=>s.stars));}
function move(g,slot,r,c,levels,bomb=false){
 if(g.outcome!=='playing'||g.paused||(g.mode==='timeAttack'&&g.elapsed>=g.budget)||r<0||r>=8||c<0||c>=8)return null;
 let cleared=new Set(),points=0,count=0,combo=0,sm=0,coins=0;
 if(bomb){if(g.mode!=='adventure'||!g.bombs)return null;for(let rr=Math.max(0,r-1);rr<=Math.min(7,r+1);rr++)for(let cc=Math.max(0,c-1);cc<=Math.min(7,c+1);cc++){let i=rr*8+cc;if(g.board[i])cleared.add(i);g.board[i]=0;}g.bombs--;g.streak=0;points=cleared.size*5;}
 else {const id=g.tray[slot];if(!id||!fits(g,id,r,c))return null;const color=Object.keys(shapes).indexOf(id)%6+1;for(const [dr,dc] of shapes[id])g.board[(r+dr)*8+c+dc]=color;g.tray[slot]=null;g.placements++;
 let rows=[],cols=[];for(let n=0;n<8;n++){if(Array.from({length:8},(_,c)=>g.board[n*8+c]).every(Boolean))rows.push(n);if(Array.from({length:8},(_,r)=>g.board[r*8+n]).every(Boolean))cols.push(n);}for(const rr of rows)for(let cc=0;cc<8;cc++)cleared.add(rr*8+cc);for(const cc of cols)for(let rr=0;rr<8;rr++)cleared.add(rr*8+cc);for(const i of cleared)g.board[i]=0;count=rows.length+cols.length;g.streak=count?g.streak+1:0;combo=mult(count);sm=mult(g.streak);points=shapes[id].length*5+count*100*combo*sm;coins=count*10+(count>1?10*combo:0)+(g.streak>1?10*sm:0);if(g.mode==='timeAttack')g.budget+=count>=3?5000:count===2?2000:0;}
 g.score+=points;g.lines+=count;g.moves++;g.last={points,combo,sm,coins,cleared:[...cleared],bomb};
 let l=g.level?levels[g.level-1]:null;
 if(g.mode==='rush'&&g.score>=5000||l&&g.score>=l.targetScore&&g.lines>=l.targetLines)g.outcome='won';
 else if(l&&(l.maxMoves&&g.moves>=l.maxMoves||l.maxPlacements&&g.placements>=l.maxPlacements))g.outcome='lost';
 else {if(g.tray.every(x=>x===null)){if(l){g.ti++;if(g.ti>=l.trays.length){g.outcome='lost';return g.last;}g.tray=[...l.trays[g.ti]];}else g.tray=tray(g.score);}if(!g.bombs&&!g.tray.filter(Boolean).some(s=>possible(g,s)))g.outcome='lost';}
 return g.last;
}
if(typeof module!=='undefined')module.exports={shapes,mult,tray,newGame,fits,possible,stars,move};
