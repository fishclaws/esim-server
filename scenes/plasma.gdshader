shader_type spatial;

uniform int MAX_STEPS = 50;
uniform float MAX_DIST = 10;
uniform float MIN_HIT_DIST = 0.0001;
uniform float DERIVATIVE_STEP = 0.0001;

uniform float fov = 45.0;
uniform vec3 cameraPos = vec3(-5.0, 0.0, 0.0);
uniform vec3 front = vec3(1.0, 0.0, 0.0);
uniform vec3 up = vec3(0.0, 1.0, 0.0);


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

float sdPlane( vec3 p, vec4 n )
{
    // n must be normalized
    return dot(p,n.xyz) + n.w;
}

float sdSphere( vec3 p, vec3 c, float s )
{
    return length(c-p)-s;
}

float sdf(vec3 p)
{
    float res = sdSphere(p, vec3( 1.0, 0.0, 0.0), 2.0);
    return res;
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sdf(vec3(p.x + DERIVATIVE_STEP, p.y, p.z)) - sdf(vec3(p.x - DERIVATIVE_STEP, p.y, p.z)),
        sdf(vec3(p.x, p.y + DERIVATIVE_STEP, p.z)) - sdf(vec3(p.x, p.y - DERIVATIVE_STEP, p.z)),
        sdf(vec3(p.x, p.y, p.z  + DERIVATIVE_STEP)) - sdf(vec3(p.x, p.y, p.z - DERIVATIVE_STEP))
    ));
}

float raymarch(vec3 rayDir)
{
    vec3 ambientColor = vec3(1.0, 1.0, 1.0);
	vec3 hitColor = vec3(1.0, 1.0, 1.0);
	vec3 missColor = vec3(0.0, 0.0, 0.0);
	
	float depth = 0.0;
	float minDist = MAX_DIST;
	float alpha = 0.0;
	for (int i=0; depth<MAX_DIST && i<MAX_STEPS; ++i)
	{
		vec3 pos = cameraPos + rayDir * depth;
		float dist = sdf(pos) + noise(pos* 5.0 + TIME);
		minDist = min(minDist, dist);
		if (dist < MIN_HIT_DIST) {
           alpha += noise(estimateNormal(pos * 10.0)* 100.0) * .02 + dist * .2;
			if (alpha >= 1.0) {
				return 1.0;
			}
		}
		depth += dist;
	}
    return alpha;
}

vec3 getRayDirection(vec2 resolution, vec2 uv)
{
	float aspect = resolution.x / resolution.y;
	float fov2 = radians(fov) / 2.0;
	
	// convert coordinates from [0, 1] to [-1, 1]
	// and invert y axis to flow from bottom to top
	vec2 screenCoord = (uv - 0.5) * 2.0;
	screenCoord.x *= aspect;
	screenCoord.y = -screenCoord.y;
	
	vec2 offsets = screenCoord * tan(fov2);
	
	vec3 rayFront = normalize(front);
	vec3 rayRight = normalize(cross(rayFront, normalize(up)));
	vec3 rayUp = cross(rayRight, rayFront);
	vec3 rayDir = rayFront + rayRight * offsets.x + rayUp * offsets.y;
	
	return normalize(rayDir);
}

void fragment()
{
	vec2 resolution = vec2(600);
	
	vec3 rayDir = getRayDirection(resolution, UV);
	float rm = raymarch(rayDir);
	EMISSION = vec3(1.0, .7, 0.3);
	ALPHA = length(rm);
	
}