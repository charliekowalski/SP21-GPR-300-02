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
//	-> declare view-space varyings from vertex shader
//	-> declare point light data structure and uniform block
//	-> declare uniform samplers (diffuse, specular & normal maps)				//COME BACK
//	-> calculate final normal by transforming normal map sample					//Deserialize it somehow (like presentation)
//	-> calculate common view vector
//	-> declare lighting sums (diffuse, specular), initialized to zero
//	-> implement loop in main to calculate and accumulate light					//Here
//	-> calculate and output final Phong sum

uniform int uCount;

layout (location = 0) out vec4 rtFragColor;

// location of viewer in its own space is the origin
const vec4 kEyePos_view = vec4(0.0, 0.0, 0.0, 1.0);

//Varying from VS
in vec4 vPosition;
in vec4 vNormal;		//Converted to vec4
in vec4 vTexcoord;
in vec4 vTangent;		//Converted to vec4
in vec4 vBiTangent;	//Converted to vec4

//Simple point light uniform block
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

//Samplers																								//FIND THE NUMBERS, MASON
layout (binding = 0) uniform sampler2D tex_diffuse;
layout (binding = 1) uniform sampler2D tex_Specular;
layout (binding = 2) uniform sampler2D tex_NM;

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
//	rtFragColor = vec4(1.0, 0.0, 1.0, 1.0);

	//Calculate final normal
//	vec3 N = normalize(texture(tex_NM, vTexcoord.xy).rgb * 2.0 - vec3(1.0));	//Blue book page 632, and 671
	vec3 N = (texture2D(tex_NM, vTexcoord.xy).rgb);	//Presentation - Lecture 10 nm pom - page 10

	//Calculate common view vector
	vec4 vecFragToEyeNormalized = normalize(kEyePos_view - vPosition);

	//Lighting sums (fidduse and specular)
	vec4 diffuseLighting = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 specularLighting = vec4(0.0, 0.0, 0.0, 0.0);
}