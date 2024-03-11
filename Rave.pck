GDPC                                                                                           P   res://.godot/exported/133200997/export-b3ba771d613dc2a2c7a9c6567c828310-rave.res`A      �      A9B�S�M%z(|
]    P   res://.godot/exported/133200997/export-bd5f61cc60129c360f1454099baad8d9-rave.scn�      �      Ơ;T.�ܽD|�l��    ,   res://.godot/global_script_class_cache.cfg  `u             ��Р�8���8~$}P�    D   res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex�f      �      �̛�*$q�*�́        res://.godot/uid_cache.bin  @y      �       �}���+ت���g�	�	       res://icon.svg  �u      �      C��=U���^Qu��U3       res://icon.svg.import   �s      �       ��=��^2�n�xxs       res://project.binary�y      �      �P�M���~9gh��       res://scenes/Sun.gd �,      �       5�fh�u�B� ReLF       res://scenes/plasma.gdshader        �      -��V����#Ax       res://scenes/rave.gd *      }      �H'��.b��'4@i�m       res://scenes/rave.tscn.remap�t      a       {��S�z�X؇����d        res://scenes/sun_scene.gdshader �-      �      ����Ѷ���Ւ>       res://scenes/sun_scene.tscn �4      �      �%$�x`5l�Ig��        res://shaders/corona.gdshader   �B      h      3³��d�5U,�]p        res://shaders/corona_2.gdshader `G      N      tc�V�Å}4^AO�        res://shaders/glitch.gdshader   �H      �      �����I� ��ӼC        res://shaders/rave.tres.remap   �t      a       z%�S�u]��l�Rw���       res://shaders/torus.gdshaderPO      x      ��k�UAM%3���i��        shader_type spatial;

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
	
}  RSRC                    PackedScene            ��������                                            L      .. 	   Camera3D 	   position    scale    fov    resource_local_to_scene    resource_name    code    script    render_priority 
   next_pass    shader    shader_parameter/albedo    shader_parameter/point_size    shader_parameter/roughness *   shader_parameter/metallic_texture_channel    shader_parameter/specular    shader_parameter/metallic    shader_parameter/uv1_scale    shader_parameter/uv1_offset    shader_parameter/uv2_scale    shader_parameter/uv2_offset    shader_parameter/bg_color     shader_parameter/texture_albedo "   shader_parameter/texture_metallic #   shader_parameter/texture_roughness    lightmap_size_hint 	   material    custom_aabb    flip_faces    add_uv2    uv2_padding    size    subdivide_width    subdivide_height    subdivide_depth    shader_parameter/range    shader_parameter/noiseQuality     shader_parameter/noiseIntensity !   shader_parameter/offsetIntensity &   shader_parameter/colorOffsetIntensity    center_offset    orientation    shader_parameter/color    radius    height    radial_segments    rings    is_hemisphere    shader_parameter/color2    length 
   loop_mode    step    tracks/0/type    tracks/0/imported    tracks/0/enabled    tracks/0/path    tracks/0/interp    tracks/0/loop_wrap    tracks/0/keys    tracks/1/type    tracks/1/imported    tracks/1/enabled    tracks/1/path    tracks/1/interp    tracks/1/loop_wrap    tracks/1/keys    tracks/2/type    tracks/2/imported    tracks/2/enabled    tracks/2/path    tracks/2/interp    tracks/2/loop_wrap    tracks/2/keys    _data 	   _bundled       Script    res://scenes/rave.gd ��������   Shader    res://shaders/glitch.gdshader ��������	   Material    res://shaders/rave.tres V݋Y:�   Shader     res://scenes/sun_scene.gdshader ��������   Script    res://scenes/Sun.gd ��������   Shader    res://shaders/corona.gdshader ��������   Shader     res://shaders/corona_2.gdshader ��������      local://Shader_r1jdo O
         local://ShaderMaterial_06ipg �         local://BoxMesh_u2nsg �         local://ShaderMaterial_oih0e �         local://QuadMesh_a7q2a �         local://QuadMesh_we4w3 �         local://ShaderMaterial_opv0p �         local://SphereMesh_h1gvg =         local://ShaderMaterial_ghkl1 X         local://QuadMesh_6auue �         local://ShaderMaterial_6m1ch �         local://QuadMesh_fonfa G         local://Animation_qyx0l `         local://AnimationLibrary_b4inj          local://PackedScene_p4c4b e         Shader          h  // NOTE: Shader automatically converted from Godot Engine 4.2.dev2's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_front,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}




uniform vec4 bg_color: source_color;

float rand(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	float size = 100.0;
	float prob = 0.9;
	vec2 pos = floor(1.0 / size * FRAGCOORD.xy);
	float color = 0.0;
	float starValue = rand(pos);

	if (starValue > prob)
	{
		vec2 center = size * pos + vec2(size, size) * 0.5;
		float t = 0.9 + 0.2 * sin(TIME * 8.0 + (starValue - prob) / (1.0 - prob) * 45.0);
		color = 1.0 - distance(FRAGCOORD.xy, center) / (0.5 * size);
		color = color * t / (abs(FRAGCOORD.y - center.y)) * t / (abs(FRAGCOORD.x - center.x));
	}
	else if (rand(SCREEN_UV.xy / 20.0) > 0.996)
	{
		float r = rand(SCREEN_UV.xy);
		color = r * (0.85 * sin(TIME * (r * 5.0) + 720.0 * r) + 0.95);
	}
	EMISSION.rgb  = vec3(color) + bg_color.rgb;
}
          ShaderMaterial    	          
                               �?  �?  �?  �?        �?        �?               ?                  �?  �?  �?                          �?  �?  �?                                                   BoxMesh             ShaderMaterial 	   	          
                      $   )   �������?%        zC&   )   /n���?'   )   ���Q��?(   )   �������?      	   QuadMesh          	   QuadMesh                    
     �@  �@         ShaderMaterial    	          
                      +      ��s?���>      �?         SphereMesh             ShaderMaterial    	          
                      +      ��'?    ��?  �?1        �?��?      �?      	   QuadMesh             ShaderMaterial    	          
                      +        �?���>      �?      	   QuadMesh          
   Animation             new_animation 2         A5         value 6          7         8              9         :         ;               times !             A      transitions !        �?  �?      values              o�  zD       o�  �@      update        <         value =          >         ?              @         A         B               times !             transitions !             values              update        C         value D          E         F              G         H         I               times !             transitions !             values              update                 AnimationLibrary    J               new_animation                   PackedScene    K      	         names "         Rave    script    Node3D 	   Camera3D 
   transform    fov    Skybox    material_override    mesh 	   skeleton    MeshInstance3D    Torus    extra_cull_margin 	   SunScene    Sun    cast_shadow    corona    AnimationPlayer 
   libraries 	   autoplay (   _on_animation_player_animation_finished    animation_finished    	   variants                      �?              �?              �?    o�  zD     pB    @�E             @�E             @�E    o;  ��                                     pB              pB              pB        ����                       �@              �@              �@x�����A=   �E              �B              �B              �B�}�?    b1A   ]�?@F��<��d<nϢ���?@ ٷ;�Md�ົX�?@    &�ʿ                                           �@* ��    ��1  �@         �0  �@                           	                        od�?f_C�Q��!C<e�?@`��Y	<&�\;�e�?&`�������<=      
                                        new_animation       node_count    
         nodes     �   ��������       ����                            ����                          
      ����                     	                 
   
   ����                  	               
      ����      
                                 ����                    
      ����                                            
      ����                     	                 
   
   ����                     	                        ����                         conn_count             conns        	                              node_paths              editable_instances              version             RSRC   extends Node3D

var reversed = false
# Called when the node enters the scene tree for the first time.
func _ready():
	while(true):
		$Camera3D/MeshInstance3D.visible = true
		await get_tree().create_timer(1).timeout
		$Camera3D/MeshInstance3D.visible = false
		await get_tree().create_timer(5).timeout

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_animation_player_animation_finished(anim_name):
	await get_tree().create_timer(20).timeout
	
	reversed = !reversed
	if reversed:
		$AnimationPlayer.play_backwards(anim_name)
	else:
		$AnimationPlayer.play(anim_name)



   extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
          // GLSL
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
         [gd_scene load_steps=13 format=3 uid="uid://84de34ik50aw"]

[ext_resource type="Shader" path="res://scenes/sun_scene.gdshader" id="1_888b2"]
[ext_resource type="Script" path="res://scenes/Sun.gd" id="2_e71fj"]
[ext_resource type="Shader" path="res://scenes/plasma.gdshader" id="3_a01g5"]
[ext_resource type="Shader" path="res://scenes/corona.gdshader" id="3_koalg"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_opv0p"]
render_priority = 0
shader = ExtResource("1_888b2")
shader_parameter/color = Color(0.952941, 0.4, 0, 1)

[sub_resource type="SphereMesh" id="SphereMesh_o6ic7"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_dpoyi"]
render_priority = 0
shader = ExtResource("3_koalg")
shader_parameter/s = 0.24
shader_parameter/color = Color(1, 0.886275, 0, 1)
shader_parameter/color2 = Color(0.635294, 0, 0.133333, 1)

[sub_resource type="QuadMesh" id="QuadMesh_cnsv3"]

[sub_resource type="Environment" id="Environment_rpblw"]
volumetric_fog_enabled = true
volumetric_fog_emission_energy = 74.14
volumetric_fog_gi_inject = 0.21
volumetric_fog_length = 600.38

[sub_resource type="FogMaterial" id="FogMaterial_53yk5"]
density = 4.5873
emission = Color(0.894118, 0.917647, 0, 1)
height_falloff = 0.055953
edge_fade = 0.0933033

[sub_resource type="ShaderMaterial" id="ShaderMaterial_fbgxe"]
render_priority = 0
shader = ExtResource("3_a01g5")
shader_parameter/MAX_STEPS = 100
shader_parameter/MAX_DIST = 20.0
shader_parameter/MIN_HIT_DIST = 0.0001
shader_parameter/DERIVATIVE_STEP = 0.0001
shader_parameter/fov = 45.0
shader_parameter/cameraPos = Vector3(-5, 0, 0)
shader_parameter/front = Vector3(1, 0, 0)
shader_parameter/up = Vector3(0, 1, 0)

[sub_resource type="QuadMesh" id="QuadMesh_7c3sn"]

[node name="SunScene" type="Node3D"]

[node name="Sun" type="MeshInstance3D" parent="."]
transform = Transform3D(2.9999, 0.019848, 0.013972, -0.0198743, 2.99993, 0.0056106, -0.0139345, -0.00570298, 2.99996, 0, 0, 0)
material_override = SubResource("ShaderMaterial_opv0p")
cast_shadow = 0
mesh = SubResource("SphereMesh_o6ic7")
script = ExtResource("2_e71fj")
camera_path = NodePath("../Camera3D")

[node name="Corona" type="MeshInstance3D" parent="Sun"]
transform = Transform3D(3.99948, 0.0538108, 0.0359329, 0.0519777, -3.9948, 0.197034, 0.0385369, -0.196541, -3.99498, -0.00120987, -0.000495161, 0.260472)
material_override = SubResource("ShaderMaterial_dpoyi")
mesh = SubResource("QuadMesh_cnsv3")

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(-1, 0, 8.74227e-08, 0, 1, 0, -8.74227e-08, 0, -1, 0, 0, -3)
environment = SubResource("Environment_rpblw")

[node name="FogVolume" type="FogVolume" parent="."]
visible = false
shape = 0
material = SubResource("FogMaterial_53yk5")

[node name="OmniLight3D" type="OmniLight3D" parent="."]
light_color = Color(0.92549, 0.34902, 0, 1)
light_energy = 6.927
light_indirect_energy = 8.61
light_volumetric_fog_energy = 8.78
light_size = 0.201
omni_range = 1.724
omni_attenuation = 0.406126

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]
transform = Transform3D(-2, 0, -1.74846e-07, 0, 2, 0, 1.74846e-07, 0, -2, 0, 0, -1.2693)
visible = false
material_override = SubResource("ShaderMaterial_fbgxe")
cast_shadow = 0
mesh = SubResource("QuadMesh_7c3sn")
         RSRC                    ShaderMaterial            ��������                                                  resource_local_to_scene    resource_name    render_priority 
   next_pass    shader    script       Shader    res://shaders/torus.gdshader ��������      local://ShaderMaterial_580dw :         ShaderMaterial          ����                             RSRC           shader_type spatial;

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
        shader_type spatial;
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
  shader_type spatial;


uniform float range : hint_range(0.0, 0.1, 0.005)= 0.05;
uniform float noiseQuality : hint_range(0.0, 300.0, 0.1)= 250.0;
uniform float noiseIntensity : hint_range(-0.6, 0.6, 0.0010)= 0.0088;
uniform float offsetIntensity : hint_range(-0.1, 0.1, 0.001) = 0.03;
uniform float colorOffsetIntensity : hint_range(0.0, 5.0, 0.001) = 1.3;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float verticalBar(float pos, float UVY, float offset)
{
    float edge0 = (pos - range);
    float edge1 = (pos + range);

    float x = smoothstep(edge0, pos, UVY) * offset;
    x -= smoothstep(pos, edge1, UVY) * offset;
    return x;
}
const float saturation = 0.2;
void fragment() {
    vec2 uv = SCREEN_UV;
    for (float i = 0.0; i < 0.71; i += 0.1313)
    {
        float d = mod(TIME * i, 1.7);
        float o = sin(1.0 - tan(TIME * 0.24 * i));
    	o *= offsetIntensity;
        uv.x += verticalBar(d, UV.y, o);
    }
    
    float UVY = uv.y;
    UVY *= noiseQuality;
    UVY = float(int(UVY)) * (1.0 / noiseQuality);
    float noise = rand(vec2(TIME * 0.00001, UVY));
    uv.x += noise * noiseIntensity;

    vec2 offsetR = vec2(0.009 * sin(TIME), 0.0) * colorOffsetIntensity;
    vec2 offsetG = vec2(0.0073 * (cos(TIME * 0.97)), 0.0) * colorOffsetIntensity;
    
    float r = texture(SCREEN_TEXTURE, uv + offsetR).r;
    float g = texture(SCREEN_TEXTURE, uv + offsetG).g;
    float b = texture(SCREEN_TEXTURE, uv).b;
    vec4 tex = vec4(r, g, b, 1.0);
    EMISSION.rgb = tex.rgb;
}

void light() {
	// Called for every pixel for every light affecting the material.
}
        shader_type spatial;
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
}        GST2   �   �      ����               � �        �  RIFF�  WEBPVP8L�  /������!"2�H�$�n윦���z�x����դ�<����q����F��Z��?&,
ScI_L �;����In#Y��0�p~��Z��m[��N����R,��#"� )���d��mG�������ڶ�$�ʹ���۶�=���mϬm۶mc�9��z��T��7�m+�}�����v��ح�m�m������$$P�����එ#���=�]��SnA�VhE��*JG�
&����^x��&�+���2ε�L2�@��		��S�2A�/E���d"?���Dh�+Z�@:�Gk�FbWd�\�C�Ӷg�g�k��Vo��<c{��4�;M�,5��ٜ2�Ζ�yO�S����qZ0��s���r?I��ѷE{�4�Ζ�i� xK�U��F�Z�y�SL�)���旵�V[�-�1Z�-�1���z�Q�>�tH�0��:[RGň6�=KVv�X�6�L;�N\���J���/0u���_��U��]���ǫ)�9��������!�&�?W�VfY�2���༏��2kSi����1!��z+�F�j=�R�O�{�
ۇ�P-�������\����y;�[ ���lm�F2K�ޱ|��S��d)é�r�BTZ)e�� ��֩A�2�����X�X'�e1߬���p��-�-f�E�ˊU	^�����T�ZT�m�*a|	׫�:V���G�r+�/�T��@U�N׼�h�+	*�*sN1e�,e���nbJL<����"g=O��AL�WO!��߈Q���,ɉ'���lzJ���Q����t��9�F���A��g�B-����G�f|��x��5�'+��O��y��������F��2�����R�q�):VtI���/ʎ�UfěĲr'�g�g����5�t�ۛ�F���S�j1p�)�JD̻�ZR���Pq�r/jt�/sO�C�u����i�y�K�(Q��7őA�2���R�ͥ+lgzJ~��,eA��.���k�eQ�,l'Ɨ�2�,eaS��S�ԟe)��x��ood�d)����h��ZZ��`z�պ��;�Cr�rpi&��՜�Pf��+���:w��b�DUeZ��ڡ��iA>IN>���܋�b�O<�A���)�R�4��8+��k�Jpey��.���7ryc�!��M�a���v_��/�����'��t5`=��~	`�����p\�u����*>:|ٻ@�G�����wƝ�����K5�NZal������LH�]I'�^���+@q(�q2q+�g�}�o�����S߈:�R�݉C������?�1�.��
�ڈL�Fb%ħA ����Q���2�͍J]_�� A��Fb�����ݏ�4o��'2��F�  ڹ���W�L |����YK5�-�E�n�K�|�ɭvD=��p!V3gS��`�p|r�l	F�4�1{�V'&����|pj� ߫'ş�pdT�7`&�
�1g�����@D�˅ �x?)~83+	p �3W�w��j"�� '�J��CM�+ �Ĝ��"���4� ����nΟ	�0C���q'�&5.��z@�S1l5Z��]�~L�L"�"�VS��8w.����H�B|���K(�}
r%Vk$f�����8�ڹ���R�dϝx/@�_�k'�8���E���r��D���K�z3�^���Vw��ZEl%~�Vc���R� �Xk[�3��B��Ğ�Y��A`_��fa��D{������ @ ��dg�������Mƚ�R�`���s����>x=�����	`��s���H���/ū�R�U�g�r���/����n�;�SSup`�S��6��u���⟦;Z�AN3�|�oh�9f�Pg�����^��g�t����x��)Oq�Q�My55jF����t9����,�z�Z�����2��#�)���"�u���}'�*�>�����ǯ[����82һ�n���0�<v�ݑa}.+n��'����W:4TY�����P�ר���Cȫۿ�Ϗ��?����Ӣ�K�|y�@suyo�<�����{��x}~�����~�AN]�q�9ޝ�GG�����[�L}~�`�f%4�R!1�no���������v!�G����Qw��m���"F!9�vٿü�|j�����*��{Ew[Á��������u.+�<���awͮ�ӓ�Q �:�Vd�5*��p�ioaE��,�LjP��	a�/�˰!{g:���3`=`]�2��y`�"��N�N�p���� ��3�Z��䏔��9"�ʞ l�zP�G�ߙj��V�>���n�/��׷�G��[���\��T��Ͷh���ag?1��O��6{s{����!�1�Y�����91Qry��=����y=�ٮh;�����[�tDV5�chȃ��v�G ��T/'XX���~Q�7��+[�e��Ti@j��)��9��J�hJV�#�jk�A�1�^6���=<ԧg�B�*o�߯.��/�>W[M���I�o?V���s��|yu�xt��]�].��Yyx�w���`��C���pH��tu�w�J��#Ef�Y݆v�f5�e��8��=�٢�e��W��M9J�u�}]釧7k���:�o�����Ç����ս�r3W���7k���e�������ϛk��Ϳ�_��lu�۹�g�w��~�ߗ�/��ݩ�-�->�I�͒���A�	���ߥζ,�}�3�UbY?�Ӓ�7q�Db����>~8�]
� ^n׹�[�o���Z-�ǫ�N;U���E4=eȢ�vk��Z�Y�j���k�j1�/eȢK��J�9|�,UX65]W����lQ-�"`�C�.~8ek�{Xy���d��<��Gf�ō�E�Ӗ�T� �g��Y�*��.͊e��"�]�d������h��ڠ����c�qV�ǷN��6�z���kD�6�L;�N\���Y�����
�O�ʨ1*]a�SN�=	fH�JN�9%'�S<C:��:`�s��~��jKEU�#i����$�K�TQD���G0H�=�� �d�-Q�H�4�5��L�r?����}��B+��,Q�yO�H�jD�4d�����0*�]�	~�ӎ�.�"����%
��d$"5zxA:�U��H���H%jس{���kW��)�	8J��v�}�rK�F�@�t)FXu����G'.X�8�KH;���[             [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://bjgdotlfjn4cx"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}
                [remap]

path="res://.godot/exported/133200997/export-bd5f61cc60129c360f1454099baad8d9-rave.scn"
               [remap]

path="res://.godot/exported/133200997/export-b3ba771d613dc2a2c7a9c6567c828310-rave.res"
               list=Array[Dictionary]([])
     <svg height="128" width="128" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="124" height="124" rx="14" fill="#363d52" stroke="#212532" stroke-width="4"/><g transform="scale(.101) translate(122 122)"><g fill="#fff"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 813 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H447l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c3 34 55 34 58 0v-86c-3-34-55-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></g></svg>
             �B����H   res://scenes/rave.tscn�;�7�F�    res://scenes/sun_scene.tscnV݋Y:�   res://shaders/rave.tres�����B*   res://icon.svg      ECFG      application/config/name         Rave   application/run/main_scene          res://scenes/rave.tscn     application/config/features(   "         4.2    GL Compatibility       application/config/icon         res://icon.svg  #   rendering/renderer/rendering_method         gl_compatibility*   rendering/renderer/rendering_method.mobile         gl_compatibility            