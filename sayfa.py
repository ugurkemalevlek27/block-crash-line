"""Mushaf sayfa videosu (yatay 1920x1080): kapak + her ayet (önce meal, sonra Arapça kelime kelime) + kapanış.
Kullanım: python3 sayfa.py <dil:tr|en|de> <sayfa_no> <sure_no> <ayet_bas> <ayet_son>
"""
import json, sys, base64, subprocess, pathlib, html as H
from playwright.sync_api import sync_playwright

LANG, PAGE, SURA, A1, A2 = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
K = pathlib.Path(__file__).parent
DATA = pathlib.Path("/mnt/user-data/uploads/ANLAYARAK PROJELERI/Anlayarak Kur'an Okuyorum/YAYIN-2026-09-27/public/data")
AUD = DATA.parent / "audio"
EXTRA = K / "extra"   # en-/de- sesleri
OUT = K / f"page{PAGE}-{LANG}"; OUT.mkdir(exist_ok=True)

def b64(p): return base64.b64encode(open(p, "rb").read()).decode()
F = K / "node_modules/@fontsource"
fonts = "".join(f"@font-face{{font-family:P;font-weight:{w};src:url(data:font/woff2;base64,{b64(F/'poppins/files'/f'poppins-{s}-{w}-normal.woff2')})}}" for w in [500, 600, 700] for s in ["latin", "latin-ext"])
fonts += f"@font-face{{font-family:AQ;src:url(data:font/woff2;base64,{b64(F/'amiri-quran/files/amiri-quran-arabic-400-normal.woff2')})}}"
LOGO = b64(K / "logo.png")

SN = {1: ("Fâtiha Sûresi","Surah Al-Fatihah","Sure Al-Fatiha"), 2: ("Bakara Sûresi","Surah Al-Baqarah","Sure Al-Baqara")}[SURA]
T = {
 "tr": dict(sura=SN[0], page=f"{PAGE}. Sayfa", order="Önce Türkçe meal, sonra Arapça", reader="Okuyucu: Ebubekir Şâtırî · Meal sesi: Hayri Küçükdeniz",
            kur="Kur'ân-ı Kerîm", brand="Anlayarak Kur'an Okuyorum", site="anlayarakkuranokuyorum.com", meal_lbl="Türkçe meal", ar_lbl="Arapça"),
 "en": dict(sura=SN[1], page=f"Page {PAGE}", order="English meaning first, then Arabic", reader="Reciter: Abu Bakr al-Shatri · English: Ibrahim Walk (Saheeh Intl.)",
            kur="The Noble Qur'an", brand="Read & Understand the Quran", site="readandunderstandquran.com", meal_lbl="English", ar_lbl="Arabic"),
 "de": dict(sura=SN[2], page=f"Seite {PAGE}", order="Zuerst die deutsche Bedeutung, dann Arabisch", reader="Rezitator: Abu Bakr asch-Schatri · Deutsch: Nail ibn Radhan (Bubenheim)",
            kur="Der edle Koran", brand="Den Koran verstehen", site="denkoranverstehen.com", meal_lbl="Deutsch", ar_lbl="Arabisch"),
}[LANG]

import glob
CF = glob.glob(str(DATA/f"chunks/{SURA:03d}_*.json"))[0]
chunks = {}
for ch in json.load(open(CF)):
    for a in ch["ayetler"]: chunks[a["n"]] = a
timing = {}
for g in sorted(DATA.glob("kelime-zaman/g*.json")): timing.update(json.load(open(g))["verses"])
if LANG == "en":
    meal = {int(k.split(":")[1]): v["text"] for k, v in json.load(open(DATA/"mealler/en-sahih.json"))["verses"].items() if k.startswith(f"{SURA}:")}
    kel = json.load(open(DATA/f"kelime-en/{SURA:03d}.json"))
elif LANG == "de":
    raw = json.load(open(DATA/"mealler/de-bubenheim.json"))
    vv = raw["verses"] if "verses" in raw else raw
    meal = {int(k.split(":")[1]): (v["text"] if isinstance(v, dict) else v) for k, v in vv.items() if k.startswith(f"{SURA}:")}
    kel = json.load(open(DATA/f"kelime-de/{SURA:03d}.json"))

def dur(p):
    return float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(p)]).decode())

CSS = f"""{fonts}
*{{margin:0;padding:0;box-sizing:border-box}}
body{{width:1920px;height:1080px;overflow:hidden;font-family:P;color:#fff;position:relative;
background:radial-gradient(ellipse 1700px 1100px at 50% 30%,#237853 0%,#11583a 32%,#023f25 62%,#012b1a 85%,#011f13 100%)}}
.pat{{position:absolute;inset:0;opacity:.04;background-image:repeating-linear-gradient(45deg,#fff 0 2px,transparent 2px 80px),repeating-linear-gradient(-45deg,#fff 0 2px,transparent 2px 80px)}}
.top{{position:absolute;top:34px;left:60px;right:60px;display:flex;align-items:center;justify-content:space-between}}
.br{{display:flex;align-items:center;gap:16px;font:600 30px P}} .br img{{width:64px;height:64px;border-radius:50%}}
.mid{{font:600 34px P;color:#E3B547}}
.pill{{font:700 34px P;color:#0b2e20;background:#E3B547;padding:8px 28px;border-radius:40px}}
.words{{position:absolute;top:130px;left:60px;right:60px;height:600px;display:flex;flex-wrap:wrap;flex-direction:row-reverse;justify-content:center;align-content:center;gap:var(--g)}}
.w{{display:flex;flex-direction:column;align-items:center;padding:10px 16px 12px;border-radius:18px;background:#ffffff0d;border:2px solid #ffffff14;transition:none}}
.w .a{{font:400 var(--af)/1.9 AQ;direction:rtl;padding-bottom:6px}} .w .m{{font:500 var(--mf)/1.2 P;margin-top:4px;color:#ffffffc8;text-align:center;max-width:var(--mw)}}
.w.on{{background:#E3B547;border-color:#E3B547}} .w.on .a{{color:#0b2e20}} .w.on .m{{color:#0b2e20}}
.meal{{position:absolute;left:110px;right:110px;bottom:120px;min-height:180px;display:flex;align-items:center;justify-content:center;text-align:center;
font:500 var(--tf)/1.4 P;color:#ffffffd9;padding:22px 40px;border-radius:24px;background:#00000026;border:2px solid #ffffff12}}
.meal.on{{color:#fff;border-color:#E3B547;background:#E3B54722;box-shadow:0 0 40px #E3B54733}}
.lbl{{position:absolute;bottom:322px;left:50%;transform:translateX(-50%);font:700 24px P;letter-spacing:3px;text-transform:uppercase;color:#E3B547;opacity:0}}
.foot{{position:absolute;bottom:36px;left:60px;right:60px;display:flex;justify-content:space-between;font:500 24px P;color:#ffffffaa}}
.bar{{position:absolute;bottom:0;left:0;height:8px;background:#E3B547}}
"""

def page_html(n, words, meal_text, nn, total):
    cnt = len(words)
    af, mf, mw, g = (86, 27, 300, 20) if cnt <= 12 else (72, 24, 260, 16) if cnt <= 16 else (62, 22, 230, 14)
    tl = len(meal_text); tf = 38 if tl < 130 else 34 if tl < 190 else 30 if tl < 260 else 26
    chips = "".join(f'<div class="w" id="w{i}"><div class="a">{H.escape(a)}</div><div class="m">{H.escape(m)}</div></div>' for i, (a, m) in enumerate(words))
    return f"""<!DOCTYPE html><html><head><meta charset=utf-8><style>{CSS}</style></head><body style="--af:{af}px;--mf:{mf}px;--mw:{mw}px;--g:{g}px;--tf:{tf}px">
<div class=pat></div>
<div class=top><div class=br><img src="data:image/png;base64,{LOGO}">{T['brand']}</div><div class=mid>{T['sura']} · {T['page']}</div><div class=pill>{SURA}:{n}</div></div>
<div class=words>{chips}</div>
<div class=lbl id=lbl></div><div class=meal id=meal>{H.escape(meal_text)}</div>
<div class=foot><div>{T['order']}</div><div>{T['site']}</div></div>
<div class=bar style="width:{(nn+1)/total*100:.2f}%"></div>
<script>function st(mode,i){{document.querySelectorAll('.w').forEach(e=>e.classList.remove('on'));document.getElementById('meal').classList.toggle('on',mode=='m');
if(mode=='a'&&i>=0)document.getElementById('w'+i).classList.add('on');}}</script></body></html>"""

def cover_html(end=False):
    sub = T['order'] if not end else T['site']
    return f"""<!DOCTYPE html><html><head><meta charset=utf-8><style>{CSS}
.c{{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center}}
.c img{{width:170px;height:170px;border-radius:50%;margin-bottom:34px}}
.k{{font:600 40px P;color:#ffffffe0}} .t{{font:700 120px/1.15 P;margin-top:18px}} .r{{font:600 62px P;color:#E3B547;margin-top:26px}} .s{{font:500 36px P;color:#ffffffcc;margin-top:46px}}
</style></head><body><div class=pat></div><div class=c><img src="data:image/png;base64,{LOGO}">
<div class=k>{T['kur']}</div><div class=t>{T['page']}</div><div class=r>{T['sura']} {A1}–{A2}</div><div class=s>{sub}</div></div></body></html>"""

segs = []  # (image, seconds)
audio = []  # (file or None for silence, seconds)
GAP = 0.35
ayets = list(range(A1, A2 + 1))
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page(viewport={"width": 1920, "height": 1080})
    pg.set_content(cover_html()); pg.wait_for_timeout(300); pg.screenshot(path=str(OUT/"cover.jpg"), quality=92, type="jpeg")
    segs.append((OUT/"cover.jpg", 3.0)); audio.append((None, 3.0))
    # birimler: TR'de birleşik meal parçaları (ör. 38-39) tek meal sesiyle okunur
    raw_chunks = json.load(open(CF))
    units = []
    for ch in raw_chunks:
        vs = [v for v in ch["verses"] if A1 <= v <= A2]
        if not vs: continue
        if LANG == "tr": units.append((vs, AUD/"tr"/ch["audio_tr"].split("/")[-1].split("?")[0], ch.get("meal_full") or " ".join(chunks[v]["meal"] for v in vs)))
        else:
            for v in vs: units.append(([v], EXTRA/f"{LANG}-{SURA:03d}{v:03d}.mp3", meal[v]))
    for idx, (vs, mfile, mt) in enumerate(units):
        for j, n in enumerate(vs):
            a = chunks[n]
            if LANG == "tr": words = [(w["ar"], w["tr"]) for w in a["words"]]
            else:
                ms = kel[n-1]; words = [(w["ar"], ms[i] if i < len(ms) else "") for i, w in enumerate(a["words"])]
            afile = AUD/"ar"/f"{SURA:03d}{n:03d}.mp3"
            pg.set_content(page_html(n if len(vs) == 1 else f"{vs[0]}–{vs[-1]}", words, mt, idx, len(units))); pg.wait_for_timeout(200)
            if j == 0:
                pg.evaluate("st('m',-1)"); im = OUT/f"{n:03d}-m.jpg"; pg.screenshot(path=str(im), quality=90, type="jpeg")
                md = dur(mfile); segs.append((im, md + GAP)); audio += [(mfile, md), (None, GAP)]
            ad = dur(afile); tm = timing.get(f"{SURA}:{n}") or [[1, 0, int(ad*1000)]]
            pg.evaluate("st('a',-1)"); im0 = OUT/f"{n:03d}-a.jpg"; pg.screenshot(path=str(im0), quality=90, type="jpeg")
            starts = [t[1]/1000 for t in tm]
            if starts[0] > 0.05: segs.append((im0, starts[0]))
            for i, t in enumerate(tm):
                pg.evaluate(f"st('a',{t[0]-1})"); im = OUT/f"{n:03d}-a{i:02d}.jpg"; pg.screenshot(path=str(im), quality=90, type="jpeg")
                end = starts[i+1] if i + 1 < len(tm) else ad
                segs.append((im, max(0.04, end - starts[i])))
            segs[-1] = (segs[-1][0], segs[-1][1] + GAP)
            audio += [(afile, ad), (None, GAP)]
    pg.set_content(cover_html(end=True)); pg.wait_for_timeout(300); pg.screenshot(path=str(OUT/"end.jpg"), quality=92, type="jpeg")
    segs.append((OUT/"end.jpg", 3.0)); audio.append((None, 3.0))
    b.close()

# video: concat demuxer
with open(OUT/"v.txt", "w") as f:
    for im, d in segs: f.write(f"file '{im}'\nduration {d:.3f}\n")
    f.write(f"file '{segs[-1][0]}'\n")
# ses: her parçayı 48k stereo wav'a çevir, ses seviyesini eşitle (loudnorm), birleştir
parts = []
for i, (fp, d) in enumerate(audio):
    w = OUT/f"a{i:03d}.wav"
    if fp is None:
        cmd = ["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", f"{d:.3f}", str(w)]
    else:
        cmd = ["ffmpeg", "-y", "-v", "error", "-i", str(fp), "-af", "loudnorm=I=-16:TP=-1.5:LRA=11,aresample=48000", "-ac", "2", "-ar", "48000", "-t", f"{d:.3f}", str(w)]
    subprocess.run(cmd, check=True); parts.append(w)
with open(OUT/"a.txt", "w") as f:
    for w in parts: f.write(f"file '{w}'\n")
subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(OUT/"a.txt"), "-c:a", "pcm_s16le", str(OUT/"audio.wav")], check=True)
final = K/f"Sayfa-{PAGE:03d}-{LANG}.mp4"
subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(OUT/"v.txt"), "-i", str(OUT/"audio.wav"),
                "-vf", "fps=30,format=yuv420p", "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", str(final)], check=True)
print(final, dur(final))
