shader_type spatial;
render_mode unshaded;

const int MAX_STEPS = 100;
const float MAX_DISTANCE = 50.0;
const float MIN_DISTANCE = 0.005;

void vertex() {
	//POSITION = vec4(VERTEX, 1.0);
}


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

float sdSphere (vec3 p, vec3 centrum, float radius) {
    return length(centrum-p) - radius;
}

// infinte repetitions
// adapted from https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
vec3 opRep(vec3 p, vec3 c) {
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return q;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float smooth_union( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float moon(vec3 p) {
	float a = sdSphere(p, vec3(0), .5);
	for (float i = 0.0; i < 10.0; i++) {
		float b = sdSphere(p , vec3(cos(i), sin(i + TIME) + noise(p * 2.0 - 1.0), sin(i + TIME) + noise(p + 1.0)) * .2, .001);
		a = opSmoothSubtraction(b, a, .2 + i / 100.0);
	}
	return a;
}

float get_distance(vec3 p) {
	//p = opRep(p, vec3(3)); // uncomment for repeating spheres
	float a = moon(p);
	float b = sdSphere(p + vec3(cos(TIME) * 3.0, .0, .0), vec3(.2, .2, .2), .1);
	return smooth_union(a, b, .5);
}


//rotate a vector... Not very happy with this huge function...
mat3 rotateXYZ(vec3 t)
{
      float cx = cos(t.x);
      float sx = sin(t.x);
      float cy = cos(t.y);
      float sy = sin(t.y);
      float cz = cos(t.z);
      float sz = sin(t.z);
      mat3 m=mat3(
        vec3(1, 0, 0),
        vec3(0, cx, -sx),
        vec3(0, sx, cx));

      m*=mat3(
        vec3(cy, 0, sy),
        vec3(0, 1, 0),
        vec3(-sy, 0, cy));

      return m*mat3(
        vec3(cz, -sz, 0),
        vec3(sz, cz, 0),
        vec3(0, 0, 1));
}

//SDF-Functions
float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float softmin(float f1, float f2, float val)
{
      float e = max(val - abs(f1 - f2), 0.0);
      return min(f1, f2) - e*e*0.25 / val;     
}

float opRepetition( in vec3 p, in vec3 s, vec2 r)
{
    vec3 q = p - s*round(p/s);
    return sdTorus( q, r );
}

float map(vec3 p)
{
      vec3 rotPlane=(rotateXYZ(vec3(1.5,.0,.0))*p);
      vec3 rotCube=(rotateXYZ(vec3(1,TIME * .01,sin(TIME + p.x * cos(TIME * .05) * 5.0)*.5))*p);
      float myplane=sdRoundBox(rotPlane-vec3(.0,.0,1.5),vec3(20.,20,.01),.1);
      float mycube=opRepetition(rotCube, vec3(1.0), vec2(.10,cos(TIME * .1) * .05));//sdRoundBox(rotCube+vec3(0.,.5,0.),vec3(.75/2.),.1);
      return(softmin(myplane,mycube,1.));
}

vec3 normal(vec3 p)
{
      vec2 eps=vec2(.005,0);
      return normalize(vec3(map(p+eps.xyy)-map(p-eps.xyy),
                            map(p+eps.yxy)-map(p-eps.yxy),
                            map(p+eps.yyx)-map(p-eps.yyx)));
}

// LIGHT
float diffuse_directional(vec3 n,vec3 l, float strength)
{
      return (dot(n,normalize(l))*.5+.5)*strength;
}

float specular_directional(vec3 n, vec3 l, vec3 v, float strength)
{
      vec3 r=reflect(normalize(l),n);
      return pow(max(dot(v,r),.0),128.)*strength;
}

float ambient_omni(vec3 p, vec3 l)
{
      float d=1.-abs(length(p-l))/100.;
      return pow(d,32.)*1.5;
}

//SHADOW
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t);
        if( h<0.0001 )
            return .0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}




vec4 raymarch(vec3 ray_origin, vec3 ray_dir, vec2 uv) {
	float t = 0.0;
	vec3 p = ray_origin;
	int i = 0;
	float alpha = 0.0;
	vec3 color;
	bool hit = false;
	float shading=.0;
	vec3 rd=normalize(vec3(uv,1.));
	p+= 1.5 * ray_dir;
	for (; i < MAX_STEPS; i++)
	{
		float d = map(p);
		t += d;
		if (t > MAX_DISTANCE)
			break;
		
		p += d * ray_dir;
		if (abs(d)  < MIN_DISTANCE) {
			hit = true;
			break;
		}
 	}

	t = length(ray_origin - p);
	if (hit)
	{
 		shading=length(p*.1);
        vec3 n=normal(p);
        vec3 l1=vec3(1,.5,-.25);
        float rl=ambient_omni(p,l1)*diffuse_directional(n,l1,.5)+specular_directional(n,l1,rd,.9);
        color=vec3(rl)+vec3(.1,.4,.1);
        color*=color;
		color+=shading * vec3(1.0, 0.0, 0.0) * (cos(TIME * 10.0) * .5 + .5);
        vec3 pos = ray_origin + t*rd;
        color=mix(vec3(.0),color,softshadow(pos,normalize(l1),.01,10.0,20.)*.25+.75);
	}

	color*=mix(color,vec3(1.,1.,1.),1.-exp(-.1*pow(t,128.)));
    color-=t*.05;
    color=sqrt(color);
	return vec4(color, 1.0);
}



void fragment() {
	vec2 uv = SCREEN_UV * 2.0 - 1.0;
	vec4 camera = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(uv, 1, 1);
	
	camera.x += cos(TIME) * .005;
	camera.z += sin(TIME) * .005;
	
	vec3 ray_origin = INV_VIEW_MATRIX[3].xyz;
	vec3 ray_dir = normalize(camera.xyz);
	
	vec4 col = raymarch(ray_origin, ray_dir, uv);
	
	ALPHA = col.a;
	if (col.rgb == vec3(0.0)) {
		discard;
	}
	ALBEDO = col.rgb;
}