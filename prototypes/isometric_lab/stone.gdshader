shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 region = vec4(0.0,0.0,0.5,0.5);
uniform vec4 tint : source_color = vec4(1.0);
uniform int mapping = 0;
uniform float density = 0.18;
varying vec3 world_position;
varying vec3 world_normal;
void vertex(){
 world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment(){
 vec2 p=world_position.xz;
 vec4 sample_region=region;
 if(mapping==1){
  if(abs(world_normal.y)>0.5){p=world_position.xz;sample_region=vec4(0.0,0.0,0.5,0.5);}
  else{p=abs(world_normal.x)>0.5?world_position.zy:world_position.xy;}
 }
 vec2 q=mapping==2?UV:fract(p*density);
 q=clamp(q,vec2(0.004),vec2(0.996));
 ALBEDO=texture(atlas,sample_region.xy+q*sample_region.zw).rgb*tint.rgb;
 ROUGHNESS=1.0;
}
