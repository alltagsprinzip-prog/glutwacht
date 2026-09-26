shader_type spatial;
render_mode diffuse_lambert_wrap;
uniform vec4 grass_dark : source_color = vec4(0.22, 0.39, 0.07, 1.0);
uniform vec4 grass_light : source_color = vec4(0.40, 0.58, 0.16, 1.0);
uniform sampler2D meadow : source_color, filter_linear_mipmap, repeat_enable;
varying vec2 ground_uv;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
 vec2 a=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(a),hash(a+vec2(1,0)),f.x),mix(hash(a+vec2(0,1)),hash(a+vec2(1,1)),f.x),f.y);
}
void vertex() { ground_uv=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; }
void fragment() {
 float patch=noise2(ground_uv*0.07);
 vec3 detail=texture(meadow,ground_uv*.17).rgb;
 vec3 turned=texture(meadow,vec2(-ground_uv.y,ground_uv.x)*.113+vec2(.31,.47)).rgb;
 ALBEDO=mix(detail,turned,.35)*mix(vec3(.72,.81,.65),vec3(1.08,1.07,.94),patch);
 ROUGHNESS=1.0;SPECULAR=0.0;
}
