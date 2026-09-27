shader_type spatial;
render_mode cull_back;
uniform sampler2D rock_noise : repeat_enable, filter_linear_mipmap;
varying vec3 rock_position;
varying vec3 rock_normal;
void vertex() {
 rock_position=VERTEX;
 rock_normal=NORMAL;
}
void fragment() {
 vec3 p=rock_position;
 vec3 blend=pow(abs(normalize(rock_normal)),vec3(4.0));
 blend/=max(dot(blend,vec3(1.0)),0.001);
 float grain=texture(rock_noise,p.zy*0.23).r*blend.x+texture(rock_noise,p.xz*0.23).r*blend.y+texture(rock_noise,p.xy*0.23).r*blend.z;
 float chips=texture(rock_noise,p.xy*0.82+p.zy*0.19).r;
 float strata=sin(p.y*2.1+p.x*0.04+(grain-0.5)*3.6);
 float fracture=smoothstep(0.38,0.2,grain)*0.35+smoothstep(0.5,0.85,strata)*0.10;
 vec3 stone=mix(vec3(0.26,0.28,0.27),vec3(0.59,0.59,0.52),smoothstep(0.15,0.85,grain));
 stone*=1.0-fracture+(chips-0.5)*0.24;
 float moss=smoothstep(19.0,2.0,p.y)*smoothstep(0.4,0.91,rock_normal.y);
 vec3 grass=mix(vec3(0.14,0.24,0.075),vec3(0.29,0.39,0.14),grain);
 ALBEDO=mix(stone,grass,moss);
 ROUGHNESS=0.96;
 SPECULAR=0.12;
 // Small surface relief in camera coordinates; no extra terrain polygons.
 vec3 dpdx=dFdx(VERTEX),dpdy=dFdy(VERTEX);
 vec3 r1=cross(dpdy,NORMAL),r2=cross(NORMAL,dpdx);
 float det=dot(dpdx,r1);
 vec3 bump=(dFdx(grain)*r1+dFdy(grain)*r2)*sign(det)/max(abs(det),0.0001);
 NORMAL=normalize(NORMAL-bump*0.045);
}
