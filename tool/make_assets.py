"""Reproducible original assets and explicit authored level JSON; no runtime generation."""
from pathlib import Path
import json, math, wave, struct, random
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
levels=[]
def add(board,trays,solution,lines=0,score=0,moves=0,placements=0,bombs=0,metric='moves'):
    n=len(solution)
    levels.append(dict(id=len(levels)+1,board=[''.join('#' if c else '.' for c in row) for row in board],trays=trays,solution=solution,targetScore=score,targetLines=lines,maxMoves=moves,maxPlacements=placements,bombs=bombs,stars=[dict(stars=1,metric=metric,maximum=moves or placements or None),dict(stars=2,metric=metric,maximum=n+2),dict(stars=3,metric=metric,maximum=n)]))
def step(slot,r,c): return dict(slot=slot,row=r,col=c)
def rowboard(lengths,vertical=False):
    b=[[0]*8 for _ in range(8)]
    for r,gap in enumerate(lengths):
        for c in range(8-gap): b[c][r] = 1 if vertical else b[c][r]
        if not vertical:
            for c in range(8-gap): b[r][c]=1
    return b
add(rowboard([2]),[['h2','v3','T']],[step(0,0,6)],lines=1)
add(rowboard([3,2]),[['h3','h2','L']],[step(0,0,5),step(1,1,6)],lines=2)
add(rowboard([4,3,2]),[['h4','h3','h2']],[step(0,0,4),step(1,1,5),step(2,2,6)],lines=3)
add(rowboard([2,3,4],True),[['v2','v3','v4']],[step(0,6,0),step(1,5,1),step(2,4,2)],lines=3)
b=[[0]*8 for _ in range(8)]
for k in range(8):
    if k!=3: b[3][k]=b[k][3]=1
add(b,[['single','square','Z']],[step(0,3,3)],lines=2)
for n in range(5):
    vertical=n%2==1
    lengths=[2,3,4] if n<3 else [4,3,2,2,3,4]
    ids=[('v' if vertical else 'h')+str(k) for k in lengths]
    trays=[ids[i:i+3] for i in range(0,len(ids),3)]
    sol=[step(i%3,8-k if vertical else i,i if vertical else 8-k) for i,k in enumerate(lengths)]
    add(rowboard(lengths,vertical),trays,sol,score=[600,650,700,3000,3100][n],moves=len(sol)+3)
for n in range(5):
    count=4+n//2
    vertical=n%2==1
    lengths=([2,3,4]*3)[:count]
    ids=[('v' if vertical else 'h')+str(k) for k in lengths]
    padded=ids[:]
    while len(padded)%3: padded.append(('v' if vertical else 'h')+str([2,3,4][len(padded)%3]))
    sol=[step(i%3,8-k if vertical else i,i if vertical else 8-k) for i,k in enumerate(lengths)]
    add(rowboard(lengths,vertical),[padded[i:i+3] for i in range(0,len(padded),3)],sol,lines=count,placements=count+2,metric='placements')
for n in range(5):
    # Diagonal holes admit none of square/L/T: a bomb is required to open a square.
    flipr=n in (2,3); flipc=n in (1,3)
    b=[[1]*8 for _ in range(8)]
    for i in range(8): b[7-i if flipr else i][7-i if flipc else i]=0
    r=7 if flipr else 0; c=7 if flipc else 0
    rr=6 if flipr else 0; cc=6 if flipc else 0
    sol=[dict(bomb=True,row=r,col=c),step(0,rr,cc)]
    trays=[['square','L','T'],['single','h2','v3']]
    if n==4:
        # Fill the next diagonal using T and L in already cleared lanes, then single.
        sol += [step(1,0,0),step(2,0,4),step(0,2,2)]
    add(b,trays,sol,lines=5 if n==4 else 4,moves=len(sol)+3,bombs=min(3,1+n//2))
(ROOT/'assets/levels/levels.json').write_text(json.dumps(levels,ensure_ascii=False,indent=2))
# Three original procedural instrumental sketches. Pentatonic plucks and breathy flute.
sr=22050
for track in range(3):
    duration=32; samples=[0.0]*(sr*duration)
    rng=random.Random(20261008+track)
    scale=[0,2,4,7,9,12,14,16]
    for n in range(24):
        start=int(n*1.25*sr); f=220*2**((scale[(n*3+track)%8]-12)/12)
        for k in range(min(int(sr*2.6),len(samples)-start)):
            t=k/sr; env=math.exp(-t*2.5)
            pluck=(math.sin(2*math.pi*f*t)+.35*math.sin(4*math.pi*f*t)+.15*math.sin(6*math.pi*f*t))*env
            flute=math.sin(2*math.pi*(f*2)*t + .02*math.sin(2*math.pi*5*t))*min(1,t*5)*math.exp(-t*1.5)
            samples[start+k]+=.13*pluck+.055*flute
    for k in range(len(samples)):
        t=k/sr; fade=min(1,t/2,(duration-t)/3)
        samples[k]=(samples[k]+.025*math.sin(2*math.pi*110*t)+.02*math.sin(2*math.pi*165*t))*max(0,fade)
    with wave.open(str(ROOT/f'assets/audio/music{track}.wav'),'wb') as w:
        w.setparams((1,2,sr,0,'NONE','not compressed')); w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,s))*32767)) for s in samples))
for name,f in [('place',520),('clear',880),('bomb',120)]:
    with wave.open(str(ROOT/f'assets/audio/{name}.wav'),'wb') as w:
        w.setparams((1,2,sr,0,'NONE','not compressed'))
        w.writeframes(b''.join(struct.pack('<h',int(8000*math.sin(2*math.pi*f*k/sr)*math.exp(-k/sr*12))) for k in range(sr//3)))
# Original stylized landscapes; all bundled and offline.
for name in ['bamboo','mountain','waterfall']:
    im=Image.new('RGB',(640,1120)); d=ImageDraw.Draw(im)
    for y in range(1120): d.line((0,y,640,y),fill=(12+int(y/60),34+int(y/35),48+int(y/50)))
    if name=='bamboo':
        for x in [40,145,250,360,480,580]:
            d.line((x,1120,x+50,0),fill=(40,100,68),width=20)
            for y in range(90,1120,140):
                d.line((x,y,x+35,y+2),fill=(103,148,79),width=4)
                d.polygon([(x+8,y),(x+100,y-60),(x+60,y-6)],fill=(45,126,74))
    else:
        for x,h in [(-80,350),(160,200),(350,400)]:
            d.polygon([(x,900),(x+170,h),(x+420,980)],fill=(45,67,93))
            d.polygon([(x+125,h+120),(x+170,h),(x+238,h+120)],fill=(152,175,190))
        if name=='waterfall':
            d.polygon([(300,450),(380,450),(420,1030),(260,1030)],fill=(72,166,196))
            for x in range(305,380,12): d.line((x,460,x+10,1030),fill=(174,224,224),width=3)
    im.save(ROOT/f'assets/backgrounds/{name}.png')
print('Authored 20 levels, 3 original audio tracks, effects, and 3 backgrounds')
