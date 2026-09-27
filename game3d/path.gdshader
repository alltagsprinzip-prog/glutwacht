shader_type spatial;
render_mode diffuse_lambert_wrap, cull_disabled;
uniform int surface_kind=0;
uniform bool preview=false;
varying vec3 world_point;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_point.xz;
 float variation=noise(p*.64);float grain=noise(p*43.0);
 vec3 earth=mix(vec3(.29,.22,.13),vec3(.48,.37,.23),variation*.6+grain*.15);
 vec3 color=earth;
 if(surface_kind==0){
  // World coordinates keep joints continuous where several paths meet.
  vec2 q=p*2.2;float row=floor(q.y);q.x+=hash(vec2(row,17.0))*.8;
  q.x*=mix(.78,1.25,hash(vec2(row,3.0)));
  vec2 cell=floor(q);vec2 f=fract(q);
  float edge=min(min(f.x,1.0-f.x),min(f.y,1.0-f.y));
  float bevel=smoothstep(.025,.12,edge);
  vec3 stone=mix(vec3(.40,.41,.34),vec3(.66,.63,.49),hash(cell));
  color=mix(earth*.85,stone*(.86+.14*grain),bevel);
  color+=vec3(.07)*smoothstep(.04,.11,edge)*(1.0-smoothstep(.11,.19,edge));
 }else if(surface_kind==1){
  vec2 q=p*15.0;vec2 f=fract(q)-.5;float pebble=1.0-smoothstep(.25,.5,length(f));
  color=mix(earth,mix(vec3(.40,.39,.31),vec3(.64,.60,.48),hash(floor(q))),pebble*.85);
 }else{color=earth*(.96+.04*sin(p.y*2.3+noise(p)*5.0));}
 float edge=min(UV.x,1.0-UV.x)*2.0;
 float feather=smoothstep(.04,.27,edge-(noise(p*6.0)-.5)*.17);
 float tufts=(1.0-smoothstep(.15,.42,edge))*noise(p*18.0);
 color=mix(color,vec3(.24,.34,.105),tufts*.55);
 if(preview)color=mix(color,vec3(.50,.86,.62),.35);
 ALBEDO=color;ROUGHNESS=.96;SPECULAR=.06;
 ALPHA=feather;ALPHA_SCISSOR_THRESHOLD=.12+hash(floor(p*70.0))*.72;
}
