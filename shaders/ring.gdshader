// Flat ring on the ground: used by the tap marker and (Milestone 3) the target ring.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float radius : hint_range(0.0, 0.5) = 0.42;
uniform float thickness : hint_range(0.0, 0.5) = 0.07;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float d = distance(UV, vec2(0.5));
	float ring = smoothstep(thickness, thickness * 0.5, abs(d - radius));
	ALBEDO = color.rgb;
	ALPHA = ring * color.a * alpha;
}
