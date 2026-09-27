shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform sampler2D leaves : source_color, filter_linear_mipmap;
void vertex(){
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float wind=sin(TIME*1.25+world.x*.21+world.z*.17)*.06;
 VERTEX.x+=wind*max(VERTEX.y-2.0,0.0);
}
void fragment(){
 vec4 leaf=texture(leaves,UV);
 ALBEDO=leaf.rgb*COLOR.rgb*vec3(.94,1.0,.88);
 ALPHA=leaf.a;ALPHA_SCISSOR_THRESHOLD=.42;ROUGHNESS=.92;SPECULAR=.12;
}
