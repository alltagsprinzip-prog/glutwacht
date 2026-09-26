shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec2 water_pos;
void vertex(){water_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; VERTEX.y+=sin(water_pos.y*1.9+TIME*1.4)*0.035;}
void fragment(){
 float ripple=sin(water_pos.y*2.4+water_pos.x*.9-TIME*1.7)*sin(water_pos.x*3.2+TIME*.6);
 float streak=pow(max(0.0,sin(water_pos.y*5.0+water_pos.x*2.0-TIME*2.0)),18.0);
 ALBEDO=mix(vec3(.025,.32,.48),vec3(.07,.65,.72),ripple*.5+.5)+streak*.12;
 ROUGHNESS=.24;METALLIC=.18;SPECULAR=.65;
}
