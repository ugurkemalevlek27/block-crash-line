"""Create official Flutter platform shells without replacing authored source."""
from pathlib import Path
import tempfile,subprocess,shutil,plistlib
root=Path(__file__).resolve().parents[1]
if not shutil.which('flutter'): raise SystemExit('Flutter SDK not found. Install Flutter stable, then rerun python3 tool/bootstrap.py')
with tempfile.TemporaryDirectory(prefix='block_crash_') as temp:
    project=Path(temp)/'block_crash'
    subprocess.run(['flutter','create','--no-pub','--platforms=android,ios','--org','com.uke','--project-name','block_crash',str(project)],check=True)
    for name in ['android','ios']:
        dest=root/name
        if dest.exists():
            print(f'Keeping existing {name} shell')
        else: shutil.copytree(project/name,dest)
    if not (root/'.metadata').exists(): shutil.copy2(project/'.metadata',root/'.metadata')
android=root/'android/app/src/main/kotlin/com/uke/block_crash/MainActivity.kt'
android.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(root/'platform_templates/MainActivity.kt',android)
shutil.copy2(root/'platform_templates/AppDelegate.swift',root/'ios/Runner/AppDelegate.swift')
plist=root/'ios/Runner/Info.plist'
with plist.open('rb') as f: data=plistlib.load(f)
data['CFBundleDisplayName']='Block Crash Line'
data['NSPhotoLibraryUsageDescription']='Seçtiğiniz fotoğrafı oyun arka planı olarak kullanmak için.'
data['UISupportedInterfaceOrientations']=['UIInterfaceOrientationPortrait']
with plist.open('wb') as f: plistlib.dump(data,f)
manifest=root/'android/app/src/main/AndroidManifest.xml'
s=manifest.read_text().replace('android:label="block_crash"','android:label="Block Crash Line"')
manifest.write_text(s)
subprocess.run(['flutter','pub','get'],cwd=root,check=True)
print('Platform shells and continuous monotonic clock bridges installed.')
