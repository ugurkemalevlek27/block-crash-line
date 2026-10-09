"""Independent Python replay of authored solutions (does not execute Dart)."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SHAPES={'single':[(0,0)],'h2':[(0,0),(0,1)],'h3':[(0,0),(0,1),(0,2)],'h4':[(0,0),(0,1),(0,2),(0,3)],'v2':[(0,0),(1,0)],'v3':[(0,0),(1,0),(2,0)],'v4':[(0,0),(1,0),(2,0),(3,0)],'square':[(0,0),(0,1),(1,0),(1,1)],'L':[(0,0),(1,0),(2,0),(2,1)],'T':[(0,0),(0,1),(0,2),(1,1)],'Z':[(0,0),(0,1),(1,1),(1,2)]}
def mul(n): return [0,1,2,4,8][min(n,4)]
report=[]
for l in json.loads((ROOT/'assets/levels/levels.json').read_text()):
    b=[[int(c=='#') for c in r] for r in l['board']]; tray=list(l['trays'][0]); ti=0
    score=lines=streak=placements=moves=coins=0; bombs=l['bombs']; won=False
    assert all(len(t)==3 and len(set(t))==3 for t in l['trays'])
    assert not any(all(r) for r in b) and not any(all(b[r][c] for r in range(8)) for c in range(8))
    for a in l['solution']:
        assert not won, f"Level {l['id']} has extra moves after goal"
        r,c=a['row'],a['col']; moves+=1
        if a.get('bomb'):
            assert bombs>0; bombs-=1; streak=0
            for rr in range(max(0,r-1),min(8,r+2)):
                for cc in range(max(0,c-1),min(8,c+2)):
                    score+=5*b[rr][cc]; b[rr][cc]=0
        else:
            s=a['slot']; assert tray[s] is not None
            cells=SHAPES[tray[s]]
            for dr,dc in cells: assert 0<=r+dr<8 and 0<=c+dc<8 and not b[r+dr][c+dc], (l['id'],a)
            for dr,dc in cells: b[r+dr][c+dc]=1
            tray[s]=None; placements+=1
            rs=[rr for rr in range(8) if all(b[rr])]; cs=[cc for cc in range(8) if all(b[rr][cc] for rr in range(8))]
            count=len(rs)+len(cs); streak=streak+1 if count else 0
            score+=len(cells)*5+count*100*mul(count)*mul(streak); lines+=count
            coins+=count*10+(10*mul(count) if count>1 else 0)+(10*mul(streak) if streak>1 else 0)
            for rr,cc in {(rr,cc) for rr in rs for cc in range(8)}|{(rr,cc) for cc in cs for rr in range(8)}: b[rr][cc]=0
        won=score>=l['targetScore'] and lines>=l['targetLines']
        assert not l['maxMoves'] or moves<=l['maxMoves']
        assert not l['maxPlacements'] or placements<=l['maxPlacements']
        if not any(x is not None for x in tray) and not won:
            ti+=1; assert ti<len(l['trays']); tray=list(l['trays'][ti])
    assert won,(l['id'],score,lines)
    stars=max(s['stars'] for s in l['stars'] if s['maximum'] is None or {'moves':moves,'placements':placements,'elapsedMs':0}[s['metric']]<=s['maximum'])
    assert stars==3
    report.append(dict(level=l['id'],score=score,lines=lines,moves=moves,placements=placements,stars=stars,lineCoins=coins))
(ROOT/'LEVEL_VERIFICATION.json').write_text(json.dumps({'method':'Independent Python reference replay, not Dart execution','passed':len(report),'levels':report},indent=2))
print(f'PASS: {len(report)}/20 explicit solutions, all 3 stars')
