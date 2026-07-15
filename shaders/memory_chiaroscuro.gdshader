shader_type canvas_item;
render_mode unshaded;

// Ashland ink wash.
//
// This is deliberately a binding grade rather than a showy post-effect: cool
// charcoal settles into the shadows, bone/umber warms the lit paper, and cyan
// is reserved for recovered memory. The two neighbouring samples provide a
// tiny pigment bleed and the memory fringe, keeping the Web path to three
// screen reads per pixel.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.72;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.018;
uniform float vignette_strength : hint_range(0.0, 0.8) = 0.32;
uniform float memory_fringe : hint_range(0.0, 0.004) = 0.0012;
uniform float night_factor : hint_range(0.0, 1.0) = 0.0;
uniform float dusk_factor : hint_range(0.0, 1.0) = 0.0;
uniform float dawn_factor : hint_range(0.0, 1.0) = 0.0;
uniform vec4 region_tone : source_color = vec4(0.50, 0.61, 0.56, 1.0);
// Set by LightingDirector. Web defaults to the one-sample path; desktop keeps
// pigment bleed and the cyan optical fringe.
uniform bool low_effects = false;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel = 1.0 / vec2(textureSize(screen_texture, 0));
	vec3 source = texture(screen_texture, uv).rgb;
	vec3 neighbour_a = source;
	vec3 neighbour_b = source;
	if (!low_effects) {
		neighbour_a = texture(screen_texture, uv + texel * vec2(1.35, 0.75)).rgb;
		neighbour_b = texture(screen_texture, uv - texel * vec2(1.35, 0.75)).rgb;
	}

	float luma = dot(source, vec3(0.2126, 0.7152, 0.0722));
	float soft_luma = dot((source + neighbour_a + neighbour_b) / 3.0,
		vec3(0.2126, 0.7152, 0.0722));
	float shadow_mask = 1.0 - smoothstep(0.10, 0.58, soft_luma);
	float light_mask = smoothstep(0.48, 0.94, soft_luma);

	// Compress unrelated saturation in the dark like pigment sinking into wet
	// paper. Warm practical light and cyan memory still retain their identity.
	vec3 neutral = vec3(luma);
	float chroma_keep = 0.92 - shadow_mask * 0.14 * grade_strength;
	vec3 graded = mix(neutral, source, chroma_keep);
	vec3 cool_ink = vec3(0.74, 0.84, 0.84);
	vec3 warm_paper = vec3(1.055, 1.015, 0.91);
	graded *= mix(vec3(1.0), cool_ink, shadow_mask * 0.20 * grade_strength);
	graded *= mix(vec3(1.0), warm_paper, light_mask * 0.14 * grade_strength);

	// Time-of-day is a restrained colour separation, not a dark overlay. Night
	// cools the shadows while preserving warm practical lights; dusk and dawn
	// touch only midtones so interactables never disappear into the grade.
	vec3 night_ink = mix(vec3(0.72, 0.80, 0.90), region_tone.rgb, 0.32);
	graded *= mix(vec3(1.0), night_ink, shadow_mask * night_factor * 0.22);
	graded *= mix(vec3(1.0), vec3(1.08, 0.91, 0.79), dusk_factor * (1.0 - shadow_mask) * 0.10);
	graded *= mix(vec3(1.0), vec3(1.06, 0.95, 0.86), dawn_factor * (1.0 - shadow_mask) * 0.08);

	// A restrained wash bleed softens single-pixel colour noise without
	// blurring silhouettes. High-contrast edges receive a faint charcoal key.
	vec3 soft_colour = (source + neighbour_a + neighbour_b) / 3.0;
	if (!low_effects) {
		graded = mix(graded, soft_colour, shadow_mask * 0.045 * grade_strength);
		float ink_edge = smoothstep(0.035, 0.24, abs(luma - soft_luma));
		graded *= 1.0 - ink_edge * 0.075 * grade_strength;
	}

	// The optical split is confined to strongly cyan pixels and is mixed in,
	// never substituted for the grade. This avoids the old red/blue channel
	// reset that made every asset look as if it came from a different palette.
	if (!low_effects) {
		float cyan_signal = smoothstep(0.08, 0.34, source.b - source.r);
		float fringe_amount = cyan_signal * grade_strength * 0.18;
		vec3 fringe_colour = source;
		fringe_colour.r = neighbour_a.r;
		fringe_colour.b = neighbour_b.b;
		fringe_amount *= clamp(memory_fringe / 0.0012, 0.0, 1.5);
		graded = mix(graded, fringe_colour, fringe_amount);
	}

	// A broad oval vignette frames the playable space without black corners.
	vec2 centered = uv * 2.0 - 1.0;
	centered.x *= 0.82;
	float vignette = smoothstep(0.58, 1.58, dot(centered, centered));
	graded *= 1.0 - vignette * vignette_strength * 0.52;

	// Mostly stationary paper tooth is calmer than animated television noise;
	// a second, very slow field keeps the ashland from feeling frozen.
	vec2 paper_cell = floor(uv * vec2(640.0, 360.0));
	float paper = hash21(paper_cell) - 0.5;
	float tooth = paper;
	if (!low_effects) {
		vec2 ash_cell = floor(uv * vec2(320.0, 180.0) + floor(TIME * 0.8));
		float ash = hash21(ash_cell + 19.7) - 0.5;
		tooth = paper * 0.72 + ash * 0.28;
	}
	graded *= 1.0 + tooth * grain_strength * 0.78;

	COLOR = vec4(clamp(graded, vec3(0.0), vec3(1.0)), 1.0);
}
