shader_type spatial;

uniform vec3 color: source_color;
uniform vec3 color2: source_color;
void vertex() {
	// Called for every vertex the material is visible on.
}


float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

void fragment() {
	float d = distance(UV, vec2(.5,.5));
	float dist = d;
	float theta = atan((UV.y - .06 * noise(UV * 10.0 + TIME * .1) - .5) / (UV.x - .06 * noise(UV * 10.0 - TIME * .1) - .5));
	dist /= noise(vec2(theta * 100.0, TIME * .01)) * 1.0;
	ALPHA = smoothstep(.5, 0.2, dist + .1 * noise(vec2(theta * 100.0, TIME * .1)));
	ALPHA += (1.0 - d) * .1;
	vec3 c = mix(color.rgb, color2.rgb, dist + cos(TIME * .1));
	c = mix(c, mix(color2, vec3(1.0), 0.0), smoothstep(.2, .1, d));
	ALPHA *= 2.0;
	EMISSION.rgb = c.rgb;
	ALPHA -= smoothstep(.2, 0., d);
}

void light() {
	// Called for every pixel for every light affecting the material.
}
