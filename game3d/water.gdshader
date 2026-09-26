shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec2 water_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 a=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(a),hash(a+vec2(1,0)),f.x),mix(hash(a+vec2(0,1)),hash(a+vec2(1,1)),f.x),f.y);}
void vertex(){water_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;VERTEX.y+=sin(water_pos.y*.8+TIME)*.025;}
void fragment(){
 vec2 flow=water_pos*vec2(.9,1.5)+vec2(TIME*.05,-TIME*.24);
 float n=noise2(flow)*.65+noise2(flow*2.3+vec2(2.1,TIME*.1))*.35;
 float edge=min(UV.x,1.0-UV.x);
 float shallow=1.0-smoothstep(.0,.23,edge);
 ALBEDO=mix(vec3(.026,.14,.155),vec3(.17,.28,.24),shallow)+vec3(.016,.032,.027)*n;
 float foam=(1.0-smoothstep(.015,.047+n*.026,edge))*.25;
 ALBEDO=mix(ALBEDO,vec3(.59,.67,.58),foam);
 NORMAL_MAP=normalize(vec3((noise2(flow+vec2(.12,0))-n)*.38,(noise2(flow+vec2(0,.12))-n)*.38,1.0))*.5+.5;
 ROUGHNESS=.23+shallow*.18;METALLIC=.05;SPECULAR=.75;
}
