shader_type spatial;
uniform vec3 color: source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float dist = distance(UV, vec2(.5, .5));
	EMISSION = color.rgb;
	ALPHA = (.5 - dist) / .5 * 3.0;
}

void light() {
	// Called for every pixel for every light affecting the material.
}
