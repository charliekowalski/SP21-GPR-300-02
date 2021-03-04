/*
	Copyright 2011-2021 Daniel S. Buckstein

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/

/*
	animal3D SDK: Minimal 3D Animation Framework
	By Daniel S. Buckstein
	
	drawPhongNM_fs4x.glsl
	Output Phong shading with normal mapping.
*/

#version 450

#define MAX_LIGHTS 1024

// ****TO-DO:
//	-> declare view-space varyings from vertex shader							//Done?
//	-> declare point light data structure and uniform block
//	-> declare uniform samplers (diffuse, specular & normal maps)
//	-> calculate final normal by transforming normal map sample
//	-> calculate common view vector
//	-> declare lighting sums (diffuse, specular), initialized to zero
//	-> implement loop in main to calculate and accumulate light
//	-> calculate and output final Phong sum

uniform int uCount;

layout (location = 0) out vec4 rtFragColor;

//Varyings from VS
in vec4 vPosition;
in vec4 vNormal;

// simple point light
struct a3_PointLightData
{
	vec4 position;						// position in rendering target space
	vec4 worldPos;						// original position in world space
	vec4 color;							// RGB color with padding
	float radius;						// radius (distance of effect from center)
	float radiusSq;						// radius squared (if needed)
	float radiusInv;					// radius inverse (attenuation factor)
	float radiusInvSq;					// radius inverse squared (attenuation factor)
} pointLight;

uniform xyz
{
	
};

//Uniform samplers (diffuse, specular & normal maps)
uniform sampler


//Diffuse
uniform vec3 vDiffuseMaterial;
uniform vec3 vDiffuseLight;
float fDotProduct = max(0.0, dot(vNormal, vLightDir));
vec3 vDiffuseColor = vDiffuseMaterial * vDiffuseLight * fDotProduct;

//Specular
uniform vec3 vSpecularMaterial;
uniform vec3 vSpecularLight;float shininess = 128.0;
vec3 vReflection = reflect(-vLightDir, vEyeNormal);
float EyeReflectionAngle = max(0.0, dot(vEyeNormal, vReflection);
fSpec = pow(EyeReflectionAngle, shininess);
vec3 vSpecularColor = vSpecularLight * vSpecularMaterial * fSpec;

// location of viewer in its own space is the origin
const vec4 kEyePos_view = vec4(0.0, 0.0, 0.0, 1.0);

// declaration of Phong shading model
//	(implementation in "utilCommon_fs4x.glsl")
//		param diffuseColor: resulting diffuse color (function writes value)
//		param specularColor: resulting specular color (function writes value)
//		param eyeVec: unit direction from surface to eye
//		param fragPos: location of fragment in target space
//		param fragNrm: unit normal vector at fragment in target space
//		param fragColor: solid surface color at fragment or of object
//		param lightPos: location of light in target space
//		param lightRadiusInfo: description of light size from struct
//		param lightColor: solid light color
void calcPhongPoint(
	out vec4 diffuseColor, out vec4 specularColor,
	in vec4 eyeVec, in vec4 fragPos, in vec4 fragNrm, in vec4 fragColor,
	in vec4 lightPos, in vec4 lightRadiusInfo, in vec4 lightColor
);

void main()
{
	// DUMMY OUTPUT: all fragments are OPAQUE MAGENTA
	rtFragColor = vec4(1.0, 0.0, 1.0, 1.0);
}




out VS_OUT
{
vec2 texcoord;
vec3 eyeDir;
vec3 lightDir;
} vs_out;

uniform vec3 light_pos = vec3(0.0, 0.0, 100.0);
void main(void)
{
// Calculate vertex position in view space.
vec4 P = mv_matrix * position;
// Calculate normal (N) and tangent (T) vectors in view space from
// incoming object space vectors.
vec3 N = normalize(mat3(mv_matrix) * normal);
vec3 T = normalize(mat3(mv_matrix) * tangent);
// Calculate the bitangent vector (B) from the normal and tangent
// vectors.
vec3 B = cross(N, T);
// The light vector (L) is the vector from the point of interest to
// the light. Calculate that and multiply it by the TBN matrix.
vec3 L = light_pos - P.xyz;
vs_out.lightDir = normalize(vec3(dot(V, T), dot(V, B), dot(V, N)));
// The view vector is the vector from the point of interest to the
// viewer, which in view space is simply the negative of the position.
// Calculate that and multiply it by the TBN matrix.
vec3 V = -P.xyz;
vs_out.eyeDir = normalize(vec3(dot(V, T), dot(V, B), dot(V, N)));
}