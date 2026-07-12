shader_type canvas_item;
render_mode unshaded;

// Memory-lantern chiaroscuro: a restrained screen grade that binds the
// painterly sprites, procedural shapes, normal lighting, and ash effects into
// one cold-shadow / warm-highlight visual language.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.72;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.018;
uniform float vignette_strength : hint_range(0.0, 0.8) = 0.32;
uniform float memory_fringe : hint_range(0.0, 0.004) = 0.0012;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 source = texture(screen_texture, uv).rgb;
	float luma = dot(source, vec3(0.2126, 0.7152, 0.0722));

	// Split-tone rather than a flat tint: blue-green ash in the dark, hand-lit
	// amber in highlights. This preserves item readability and skin warmth.
	float shadow_mask = 1.0 - smoothstep(0.16, 0.66, luma);
	float light_mask = smoothstep(0.48, 0.92, luma);
	vec3 graded = mix(source, source * vec3(0.69, 0.84, 0.89), shadow_mask * 0.24 * grade_strength);
	graded = mix(graded, graded * vec3(1.10, 1.035, 0.86), light_mask * 0.18 * grade_strength);

	// Cyan-dominant memory light gets a tiny optical split. It reads as an
	// unstable recovered image without blurring normal gameplay.
	float cyan_signal = smoothstep(0.05, 0.32, source.b - source.r);
	float fringe = memory_fringe * cyan_signal * grade_strength;
	graded.r = texture(screen_texture, uv + vec2(fringe, 0.0)).r;
	graded.b = texture(screen_texture, uv - vec2(fringe, 0.0)).b;

	vec2 centered = uv * 2.0 - 1.0;
	float vignette = smoothstep(0.34, 1.32, dot(centered, centered));
	graded *= 1.0 - vignette * vignette_strength;

	// Fine animated ash-grain plus an almost invisible scan cadence. Both are
	// resolution-aware and intentionally below UI/text contrast thresholds.
	vec2 grain_cell = floor(uv * vec2(1280.0, 720.0) + vec2(TIME * 29.0, TIME * 17.0));
	float grain = (hash21(grain_cell) - 0.5) * grain_strength;
	float cadence = sin(uv.y * 720.0 * 3.14159265) * 0.0035;
	graded += grain + cadence;

	COLOR = vec4(max(graded, vec3(0.0)), 1.0);
}
