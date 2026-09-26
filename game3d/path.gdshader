shader_type spatial;
render_mode diffuse_lambert_wrap;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=UV*vec2(4.0,30.0);p.x+=mod(floor(p.y),2.0)*.5;
 vec2 cell=floor(p);vec2 edge=abs(fract(p)-.5);
 float stone=1.0-smoothstep(.37,.48,max(edge.x,edge.y));
 float shade=hash(cell);
 ALBEDO=mix(vec3(.22,.18,.12),mix(vec3(.31,.28,.21),vec3(.48,.44,.34),shade),stone);
 ALPHA=smoothstep(0.0,.08,min(UV.x,1.0-UV.x)+hash(floor(UV*40.0))*.025);ALPHA_SCISSOR_THRESHOLD=.4;
 ROUGHNESS=1.0;SPECULAR=.05;
}
