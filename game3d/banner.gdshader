shader_type spatial;
render_mode cull_disabled;
uniform vec4 fabric : source_color = vec4(.08,.27,.55,1.0);
void vertex(){VERTEX.z+=sin(TIME*2.1+UV.x*5.0+UV.y*2.0)*.11*UV.x;}
void fragment(){
 float trim=step(UV.y,.065)+step(.935,UV.y)+step(.93,UV.x);
 float crest=1.0-step(.15,abs(UV.x-.5)+abs(UV.y-.5));
 ALBEDO=mix(fabric.rgb,vec3(.92,.68,.25),clamp(trim+crest,0.0,1.0));ROUGHNESS=.9;
}
