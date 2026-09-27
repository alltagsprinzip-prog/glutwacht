extends Node
# Bundled Kenney CC0 Foley plus original musical/UI synthesis.
# Per-cue cooldown limits combat clutter; no runtime asset downloads.
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
 for cue in {"hit":["impactPunch_medium_000","impactPunch_medium_001","impactPunch_heavy_002"],"shield":["impactMetal_medium_000","impactMetal_medium_001","impactPlate_heavy_001"],"siege":["impactMining_000","impactMining_001","impactWood_heavy_000"],"stone":["impactMining_002","impactMining_003"],"wood":["impactWood_medium_000","impactWood_heavy_001"],"step":["footstep_grass_000","footstep_grass_001"],"swing":["knifeSlice","knifeSlice2"],"bow":["creak1","cloth1"],"dodge":["cloth1","cloth2"],"hurt":["impactPunch_medium_000","impactPunch_medium_001","impactPunch_heavy_002"]}:
  sounds[cue]=[]
  for file in {"hit":["impactPunch_medium_000","impactPunch_medium_001","impactPunch_heavy_002"],"shield":["impactMetal_medium_000","impactMetal_medium_001","impactPlate_heavy_001"],"siege":["impactMining_000","impactMining_001","impactWood_heavy_000"],"stone":["impactMining_002","impactMining_003"],"wood":["impactWood_medium_000","impactWood_heavy_001"],"step":["footstep_grass_000","footstep_grass_001"],"swing":["knifeSlice","knifeSlice2"],"bow":["creak1","cloth1"],"dodge":["cloth1","cloth2"],"hurt":["impactPunch_medium_000","impactPunch_medium_001","impactPunch_heavy_002"]}[cue]:sounds[cue].append(load("res://assets3d/audio/"+file+".ogg"))
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
 if muted or effects_volume<=0 or not sounds.has(cue) or players.is_empty():return
 var now=Time.get_ticks_msec();var gap=85 if cue in ["hit","swing","bow","shield","hurt"] else 40
 if now-int(last_played.get(cue,-1000))<gap:return
 last_played[cue]=now
 var player=players[next];player.stream=sounds[cue][rng.randi_range(0,sounds[cue].size()-1)];player.pitch_scale=rng.randf_range(.95,1.05)
 player.volume_db=-19 if cue in ["swing","bow","click"] else (-12 if cue in ["victory","battle_start"] else -15)
 player.volume_db+=linear_to_db(maxf(.00001,effects_volume))
 player.play();next=(next+1)%players.size()

var music_player:AudioStreamPlayer
var effects_volume=.8
func set_volumes(music:float,effects:float,enabled:bool=true):
 muted=not enabled;effects_volume=effects
 if music_player==null:
  music_player=AudioStreamPlayer.new();music_player.stream=make_music();add_child(music_player);music_player.play()
 music_player.volume_db=linear_to_db(maxf(.00001,music*.22)) if enabled else -80
 music_player.stream_paused=not enabled or music<=0
 for player in players:
  if not enabled or effects<=0:player.stop()
func make_music() -> AudioStreamWAV:
 # Original quiet eight-bar modal harp theme, looped without an audible seam.
 var rate=22050;var seconds=32.0;var data=PackedByteArray();data.resize(int(seconds*rate)*2)
 var notes=[196.0,293.66,392.0,440.0,329.63,293.66,246.94,293.66,174.61,261.63,349.23,392.0,293.66,261.63,220.0,261.63]
 for i in range(int(seconds*rate)):
  var t=float(i)/rate;var beat=int(t);var local=fmod(t,1.0);var note=notes[beat%notes.size()]
  var pluck=(sin(TAU*note*local)+.28*sin(TAU*note*2*local)+.08*sin(TAU*note*3*local))*exp(-local*4)*minf(1,local*120)
  var bass=98.0 if beat%16<8 else 87.307
  var pad=sin(TAU*bass*t)*.12*sin(PI*fmod(t,8.0)/8.0)
  var edge=minf(1,minf(t,seconds-t)*2)
  data.encode_s16(i*2,int((pluck*.38+pad)*edge*22000))
 var stream=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.data=data;stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=int(seconds*rate);return stream
