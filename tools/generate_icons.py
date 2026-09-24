"""Original Glutwacht vector artwork. Run to regenerate the checked-in SVG set."""
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'assets3d'/'icons'
OUT.mkdir(parents=True,exist_ok=True)
shapes={
'wood':('<path d="M10 27 40 12 56 23 26 40Z" fill="#bb7636"/><path d="M10 27v19l16 9V40M26 40l30-17v19L26 55" fill="#855024"/><ellipse cx="18" cy="41" rx="8" ry="11" fill="#efd298"/><path d="m17 34 5 7-4 6m14-11 18-10m-18 18 18-10" fill="none"/>'),
'stone':'<path d="m8 40 9-24 24-5 16 20-6 21-32 3Z" fill="#8cacc6"/><path d="m17 16 13 15 11-20M30 31l27 0M30 31 19 55" fill="none"/><path d="m30 31 11-20 16 20Z" fill="#d3e4ed"/>',
'gold':'<ellipse cx="30" cy="47" rx="22" ry="9" fill="#c77a19"/><ellipse cx="30" cy="42" rx="22" ry="9" fill="#ffd15d"/><circle cx="36" cy="26" r="20" fill="#f5b32f"/><circle cx="36" cy="26" r="14" fill="#ffdc71"/><path d="m37 16-7 11h11l-7 10" fill="none"/>',
'gems':'<path d="m7 23 13-13h25l13 13-26 33Z" fill="#6fddd0"/><path d="m7 23 51 0M20 10 25 23 32 56 40 23 45 10M25 23l7-13 8 13" fill="none"/><path d="m9 23 11-11 5 11Z" fill="#c6fff1"/>',
'worker':'<path d="m19 51 24-33 7 5-24 34Z" fill="#d19a54"/><path d="m26 15 12-8 18 13-9 12Z" fill="#9ec5d6"/><path d="m27 16 19 13" fill="none"/>',
'info':'<circle cx="32" cy="32" r="24" fill="#66b9d6"/><circle cx="32" cy="19" r="3" fill="#fff3c4"/><path d="M32 29v16m-5 0h10" stroke="#fff3c4" fill="none" stroke-width="6"/>',
'upgrade':'<path d="m9 30 23-22 23 22H42v23H22V30Z" fill="#9cde6b"/><path d="m20 29 12-11 12 11M27 49h10" fill="none" stroke="#e8ffbd"/>',
'move':'<path d="m32 5 9 11h-6v13h13v-6l11 9-11 9v-6H35v13h6L32 59l-9-11h6V35H16v6L5 32l11-9v6h13V16h-6Z" fill="#a9dbec"/>',
'collect':'<path d="M12 27h40l-4 27H16Z" fill="#b37640"/><path d="m19 27 6-12h14l7 12" fill="none" stroke="#edc582"/><path d="M32 6v30m-8-8 8 8 8-8" fill="none" stroke="#ffe496" stroke-width="6"/>',
'attack':'<path d="m14 55 6-6 25-27 5-14-14 5-24 29Z" fill="#d6e7ec"/><path d="m13 35 16 15M9 53l8-8" fill="none" stroke="#dca944" stroke-width="7"/><path d="m49 54-29-32-5-14 14 5 24 29Z" fill="#bcd3df"/><path d="m36 50 16-15m-4 9 8 10" fill="none" stroke="#dca944" stroke-width="7"/>',
'shop':'<path d="M12 27h40v29H12Z" fill="#c49961"/><path d="m8 12 48 0 4 16H4Z" fill="#e88a4b"/><path d="M16 12 13 28m13-16-1 16m13-16 1 16m10-16 4 16" stroke="#ffe2a0" stroke-width="6"/><path d="M26 39h14v17H26Z" fill="#4b7381"/>',
'build':'<path d="m6 31 26-22 26 22H50v24H14V31Z" fill="#d89a52"/><path d="m6 31 26-22 26 22" fill="none" stroke="#f3ce80" stroke-width="7"/><path d="M26 36h12v19H26Z" fill="#467b82"/>',
'barracks':'<path d="M12 23h40v32H12ZM18 9h8v14h-8m20-14h8v14h-8" fill="#ae6760"/><path d="M27 35h10v20H27Z" fill="#3c5266"/><path d="M10 24h44" stroke="#edd499"/>',
'army':'<path d="m8 13 19 0 0 18c0 9-10 16-10 16S8 39 8 31Zm29 0h19v18c0 9-10 16-10 16s-9-8-9-16Z" fill="#70a5b5"/><path d="m32 9 9 11-9 26-9-26Z" fill="#e6ecdc"/><path d="M20 43h24m-12 0v14" stroke="#f0bf5c" stroke-width="7"/>',
'hero':'<path d="m10 9 22 5 22-5-2 27c-1 12-20 23-20 23S13 48 12 36Z" fill="#477f9e"/><path d="m32 18 4 11 12 1-9 8 3 12-10-7-10 7 3-12-9-8 12-1Z" fill="#ffcf60"/>',
'melee':'<path d="m12 48 29-33 14-7-4 16-31 30Z" fill="#cde4ec"/><path d="m12 33 21 19m-17-6-9 11" stroke="#ebb45b" stroke-width="7"/><path d="m24 40 23-23" stroke="#fff9cf" fill="none"/>',
'archers':'<path d="M19 7q42 25 0 50" fill="none" stroke="#dba355" stroke-width="7"/><path d="M19 7v50m-7-25h44m-9-7 9 7-9 7" fill="none" stroke="#e8f3e3"/>',
'heal':'<path d="M25 6h14v12l10 13v23H15V31l10-13Z" fill="#65c5a0"/><path d="M23 7h18v9H23Z" fill="#cc9759"/><path d="M32 29v18m-9-9h18" stroke="#f2ffce" stroke-width="6"/>',
'roll':'<path d="M12 29a22 22 0 1 1 6 22M12 29l-5-14m5 14 14-4" fill="none" stroke="#9be0e7" stroke-width="7"/><path d="m26 40 11-17 8 18Z" fill="#f4cd76"/>',
'skill':'<path d="m35 5-22 31h16l-3 23 27-34H36Z" fill="#ffda71"/><path d="m5 18 8 4M53 47l7 5M9 50l7-7" stroke="#f49e48"/>',
'clock':'<circle cx="32" cy="34" r="23" fill="#d6e2d3"/><path d="M32 18v17l12 7M25 5h14" fill="none" stroke-width="5"/><path d="M32 6v5" fill="none"/>',
'hp':'<path d="M32 56 9 33C-2 11 21 2 32 19 44 2 66 12 55 33Z" fill="#ef776a"/><path d="M12 20q5-9 13-1" fill="none" stroke="#ffc6a1" stroke-width="5"/>',
'lock':'<path d="M19 29V19a13 13 0 0 1 26 0v10" fill="none" stroke="#d9d5bb" stroke-width="7"/><rect x="12" y="27" width="40" height="31" rx="6" fill="#cdac65"/><circle cx="32" cy="39" r="4" fill="#4a5a63"/><path d="M32 41v8" fill="none"/>',
'star':'<path d="m32 5 8 17 19 3-14 14 3 19-16-9-17 9 3-19L5 25l19-3Z" fill="#ffd35f"/><path d="m32 12 5 14 14 2-12 8" fill="none" stroke="#fff0ad"/>',
'close':'<path d="m17 17 30 30m0-30L17 47" stroke="#ffe7b3" stroke-width="8" fill="none"/>',
'menu':'<path d="M13 17h38M13 32h38M13 47h38" fill="none" stroke="#f4ddaf" stroke-width="7"/>',
'xp':'<path d="M32 5 53 18v28L32 59 11 46V18Z" fill="#58a8c7"/><path d="m20 24 24 18m0-18L20 42" stroke="#eaf6d3" stroke-width="5"/>',
'arrow':'<path d="M10 32h42M38 17l15 15-15 15" fill="none" stroke="#ffe0a0" stroke-width="7"/>',
}
shapes['training']=shapes['worker'];shapes['power']=shapes['melee'];shapes['vitality']=shapes['hp'];shapes['warrior']=shapes['melee'];shapes['ninja']=shapes['attack'];shapes['shaman']=shapes['heal'];shapes['mage']=shapes['skill'];shapes['hall']=shapes['build'];shapes['lumber']=shapes['wood'];shapes['quarry']=shapes['stone'];shapes['goldmine']=shapes['gold'];shapes['smithy']=shapes['worker'];shapes['camp']=shapes['army'];shapes['hero_hall']=shapes['hero'];shapes['tower']=shapes['barracks'];shapes['wall']=shapes['barracks']
for name,content in shapes.items():
 (OUT/(name+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><g stroke="#263c43" stroke-width="2.8" stroke-linejoin="round" stroke-linecap="round">'+content+'</g></svg>')
print(f'{len(shapes)} original SVG icons generated')
