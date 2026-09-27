shader_type spatial;
render_mode diffuse_lambert_wrap;
uniform float length=15.0;
uniform int surface_kind=0;
uniform bool preview=false;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=UV*vec2(4.0,length*2.0);p.x+=mod(floor(p.y),2.0)*.5;
 vec2 cell=floor(p);vec2 edge=abs(fract(p)-.5);
 float stone=1.0-smoothstep(.37,.48,max(edge.x,edge.y));
 float shade=hash(cell);
 ALBEDO=mix(vec3(.22,.18,.12),mix(vec3(.31,.28,.21),vec3(.48,.44,.34),shade),stone);
 if(surface_kind==1){float grain=hash(floor(UV*vec2(28.0,length*16.0)));ALBEDO=mix(vec3(.36,.35,.29),vec3(.59,.57,.48),grain);}
 if(surface_kind==2){float grain=hash(floor(UV*vec2(45.0,length*22.0)));ALBEDO=mix(vec3(.30,.23,.14),vec3(.43,.34,.21),grain*.65);}
 if(preview){ALBEDO=mix(ALBEDO,vec3(.50,.86,.62),.5);}
 ALPHA=smoothstep(0.0,.08,min(UV.x,1.0-UV.x)+hash(floor(UV*40.0))*.025);ALPHA_SCISSOR_THRESHOLD=.4;
 ROUGHNESS=1.0;SPECULAR=.05;
}
