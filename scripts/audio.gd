extends Node
# Original procedural Foley: filtered noise, impacts and metallic resonances.
# No third-party recording or runtime download. Per-cue cooldown limits combat clutter.
var muted=false
var sounds={}
var players:Array=[]
var next=0
var last_played={}
var rng=RandomNumberGenerator.new()
func _ready():
 rng.randomize()
 for i in range(10):
  var player=AudioStreamPlayer.new();player.volume_db=-14;add_child(player);players.append(player)
 for cue in ["attack","swing","bow","siege","shield","hit","hurt","dodge","skill","pickup","equip","click","victory","death","warning","relic","battle_start","build_done"]:
  sounds[cue]=[]
  for variant in range(3):sounds[cue].append(make_sound(cue,variant))
func make_sound(cue:String,variant:int=0) -> AudioStreamWAV:
 var sample_rate=22050;var duration=.34
 if cue in ["click","pickup","hit","shield"]:duration=.22
 elif cue in ["victory","battle_start","build_done"]:duration=1.05
 elif cue in ["skill","death","siege"]:duration=.65
 var random=RandomNumberGenerator.new();random.seed=abs(cue.hash())+variant*7919
 var data=PackedByteArray();data.resize(int(duration*sample_rate)*2)
 var smooth=0.0;var phase=0.0
 for i in range(int(duration*sample_rate)):
  var t=float(i)/sample_rate;var progress=t/duration
  var noise=random.randf_range(-1,1);smooth=lerpf(smooth,noise,.13)
  var fade=pow(1-progress,2.0);var attack=minf(t*600,1);var wave=0.0
  match cue:
   "attack","swing","dodge":
    var swell=sin(progress*PI);wave=(smooth*2.6+(noise-smooth)*.18)*swell*fade
   "bow":
    wave=smooth*1.8*sin(progress*PI)*fade+sin(t*TAU*(470+variant*27))*exp(-t*32)*.22
   "hit","hurt","siege":
    var base=65.0 if cue=="siege" else (105.0 if cue=="hit" else 85.0)
    phase+=TAU*(base+80*exp(-t*30))/sample_rate
    wave=sin(phase)*exp(-t*13)*.56+smooth*exp(-t*20)*1.8+(noise-smooth)*exp(-t*75)*.32
   "shield":
    wave=(sin(t*TAU*820)+sin(t*TAU*1327)*.5+sin(t*TAU*2171)*.25)*exp(-t*20)*.32+noise*exp(-t*100)*.26
   "skill","relic":
    phase+=TAU*(120+600*progress*progress)/sample_rate
    wave=sin(phase)*.3*fade+smooth*sin(progress*PI)*1.4+sin(t*TAU*1430)*exp(-t*12)*.1
   "pickup","equip","click":
    var base=1450.0 if cue=="pickup" else (650.0 if cue=="equip" else 420.0)
    wave=(sin(t*TAU*base)+sin(t*TAU*base*1.43)*.45)*exp(-t*38)*.25+noise*exp(-t*110)*.22
   "victory","build_done","battle_start":
    var step=mini(3,int(t*5));var notes=[196.0,246.94,293.66,392.0] if cue!="battle_start" else [110.0,110.0,164.81,220.0]
    var local=fmod(t,.2);var note=notes[step]*(1.0+variant*.003)
    wave=(sin(TAU*note*local)+sin(TAU*note*2*local)*.2)*exp(-local*12)*.3*fade+smooth*exp(-local*60)*.6*fade
   _:
    phase+=TAU*(180-100*progress)/sample_rate;wave=sin(phase)*.35*fade+smooth*.3*fade
  # Short fade-out prevents clicks at the end of any generated cue.
  wave*=attack*minf((duration-t)*200,1)
  data.encode_s16(i*2,int(clampf(wave,-.92,.92)*28000))
 var stream=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=sample_rate;stream.data=data;return stream
func play(cue:String):
 if muted or not sounds.has(cue) or players.is_empty():return
 var now=Time.get_ticks_msec();var gap=85 if cue in ["hit","swing","bow","shield","hurt"] else 40
 if now-int(last_played.get(cue,-1000))<gap:return
 last_played[cue]=now
 var player=players[next];player.stream=sounds[cue][rng.randi_range(0,2)];player.pitch_scale=rng.randf_range(.95,1.05)
 player.volume_db=-19 if cue in ["swing","bow","click"] else (-12 if cue in ["victory","battle_start"] else -15)
 player.play();next=(next+1)%players.size()
