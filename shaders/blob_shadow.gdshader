// Soft round blob shadow under billboard sprites (cheaper than real sprite shadows).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	float d = distance(UV, vec2(0.5));
	float a = smoothstep(0.5, 0.12, d) * strength;
	ALBEDO = vec3(0.0);
	ALPHA = a;
}
