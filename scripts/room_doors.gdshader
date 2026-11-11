shader_type canvas_item;
// Light the EXISTING painted recesses. No separate doorway or wall sprites.
uniform vec4 exits = vec4(0.0); // north, east, south, west
float glow(vec2 uv, vec2 center, vec2 radius) {
	return exp(-3.0 * dot((uv-center)/radius,(uv-center)/radius));
}
void fragment() {
	// Godot already multiplies the sampled texture into fragment COLOR.
	vec4 stone = COLOR;
	float north = glow(UV,vec2(0.5,0.08),vec2(0.062,0.09));
	float east = glow(UV,vec2(0.98,0.493),vec2(0.06,0.065));
	float south = glow(UV,vec2(0.5,0.93),vec2(0.062,0.09));
	float west = glow(UV,vec2(0.02,0.493),vec2(0.06,0.065));
	float light = dot(vec4(north,east,south,west),exits);
	float sealed = dot(vec4(north,east,south,west),vec4(1.0)-exits);
	stone.rgb *= 1.0 - sealed * 0.7;
	stone.rgb += vec3(0.11,0.36,0.28) * light;
	COLOR = stone;
}
