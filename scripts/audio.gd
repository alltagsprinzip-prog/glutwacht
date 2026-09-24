extends Node
var muted=false
var sounds={}
var players:Array=[]
var next=0
func _ready():
 for i in range(6):
  var p=AudioStreamPlayer.new()
  p.volume_db=-14
  add_child(p)
  players.append(p)
 for type in ["attack","hit","hurt","dodge","skill","pickup","equip","victory","death","warning","relic"]:
  sounds[type]=make_sound(type)
func make_sound(type:String) -> AudioStreamWAV:
 var sample_rate=22050
 var duration=0.11
 var f=240.0
 match type:
  "hit":f=115;duration=0.07
  "hurt":f=75;duration=0.19
  "dodge":f=450;duration=0.15
  "skill":f=190;duration=0.4
  "pickup":f=820;duration=0.10
  "equip":f=560;duration=0.30
  "victory":f=440;duration=0.85
  "death":f=160;duration=0.7
  "warning":f=105;duration=0.25
  "relic":f=660;duration=0.23
 var data=PackedByteArray()
 data.resize(int(duration*sample_rate)*2)
 for i in range(int(duration*sample_rate)):
  var t=float(i)/sample_rate
  var env=pow(1.0-t/duration,2)*minf(t*300,1)
  var pitch=f*(1-t/duration*0.5)
  if type in ["pickup","equip","victory"]:pitch=f*(1.0+floor(t*7)*0.25)
  var wave=sin(TAU*pitch*t)*0.58+sin(TAU*pitch*2.01*t)*0.19
  if type in ["hit","attack","hurt"]:wave+=sin(i*12.9898)*cos(i*4.1414)*0.25
  data.encode_s16(i*2,int(clampf(wave*env,-1,1)*22000))
 var stream=AudioStreamWAV.new()
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate=sample_rate
 stream.data=data
 return stream
func play(type:String):
 if muted or not type in sounds:return
 players[next].stream=sounds[type]
 players[next].play()
 next=(next+1)%players.size()
