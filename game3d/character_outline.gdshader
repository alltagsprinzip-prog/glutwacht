shader_type spatial;
render_mode unshaded, cull_front;
uniform float width = 0.015;
void vertex() { VERTEX += NORMAL * width; }
void fragment() { ALBEDO = vec3(0.055, 0.065, 0.085); }
