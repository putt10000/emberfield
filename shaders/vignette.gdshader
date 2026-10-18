// Subtle vignette drawn by a full-screen ColorRect on its own CanvasLayer.
// One cheap draw call; works in the Compatibility renderer.
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float inner : hint_range(0.0, 1.0) = 0.38;
uniform float softness : hint_range(0.0, 1.0) = 0.5;
uniform vec3 tint : source_color = vec3(0.05, 0.02, 0.07);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.0, 0.9));
	float v = smoothstep(inner, inner + softness, d);
	COLOR = vec4(tint, v * intensity);
}
