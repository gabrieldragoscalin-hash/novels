shader_type spatial;
render_mode unshaded, cull_front;
void vertex(){VERTEX+=NORMAL*0.023;}
void fragment(){ALBEDO=vec3(0.006,0.012,0.013);}
