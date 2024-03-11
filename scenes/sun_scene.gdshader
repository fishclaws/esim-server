// GLSL
// OPENGL SHADER LANGUAGE
// vec2, vec3, vec4
shader_type spatial;

varying vec3 position;
uniform vec3 color: source_color;

vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}


float fbm(vec3 x) {
	float v = 0.0;
	float a = 0.5;
	vec3 shift = vec3(100);
	for (int i = 0; i <6; ++i) {
		v += a * noise(x);
		x = x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}


void vertex() {
	// Called for every vertex the material is visible on.
	position = VERTEX.xyz;
	float variation = rand(VERTEX.xy + TIME * .0000001);
	position += pow(variation, 5.0) * .001;
}



void fragment() {
	// Called for every pixel the material is visible on.
	//EMISSION.rgb = vec3(1.0, 1.0, 0.2);
	vec3 pos0 = position.xyz * 100.0;
	vec3 pos1 = position.xyz * 10.0;
	vec3 pos2 = position.xyz * 20.0;
	pos0.x += TIME * .1;
	pos1.y += TIME * .5;
	pos2.z += TIME * .2;
	
	float sunSpot = fbm( pos2 + fbm( pos1 + fbm( pos0 ) * .0001 ) * 1.5 );
	
	
	
	// sunSpot is 0 - 1 but we want -1 to 1
	// so we multiply sunSpot by 2 and subtract 1
	sunSpot  = sunSpot * 2.0 - 1.0;
	vec3 sunColor = color + sunSpot;
	EMISSION.rgb = sunColor;
}
