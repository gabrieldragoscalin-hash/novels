shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 region = vec4(0.0,0.0,0.5,0.5);
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 stone_shadow : source_color = vec4(0.15,0.18,0.22,1.0);
uniform vec4 stone_mid : source_color = vec4(0.48,0.52,0.57,1.0);
uniform vec4 stone_high : source_color = vec4(0.76,0.79,0.82,1.0);
uniform vec4 gold : source_color = vec4(0.72,0.54,0.24,1.0);
uniform float gold_amount = 0.0;
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
 vec3 paint=texture(atlas,sample_region.xy+q*sample_region.zw).rgb;
 // Recolor the painted value structure, preserving cracks and carvings without the green cast.
 vec3 pigment=pow(max(paint,vec3(0.0)),vec3(1.0/2.2));
 float value=dot(pigment,vec3(0.2126,0.7152,0.0722));
 float shade=smoothstep(0.025,0.58,value);
 vec3 stone=mix(stone_shadow.rgb,stone_mid.rgb,smoothstep(0.0,0.46,shade));
 stone=mix(stone,stone_high.rgb,smoothstep(0.46,1.0,shade));
 float gilding=smoothstep(0.025,0.09,paint.r-paint.b)*smoothstep(0.03,0.20,paint.r)*gold_amount;
 ALBEDO=mix(stone,gold.rgb,gilding)*tint.rgb;
 ROUGHNESS=1.0;
}
