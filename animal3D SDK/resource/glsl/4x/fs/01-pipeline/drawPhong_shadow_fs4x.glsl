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
	
	drawPhong_shadow_fs4x.glsl
	Output Phong shading with shadow mapping.
*/

#version 450

// ****TO-DO:
// 1) Phong shading
//	-> identical to outcome of last project										//COPIED FREOM BLUE BOOK, DONE????
// 2) shadow mapping
//	-> declare shadow map texture
//	-> declare shadow coordinate varying
//	-> perform manual "perspective divide" on shadow coordinate					//COPIED FREOM BLUE BOOK, DONE????
//	-> perform "shadow test" (explained in class)

layout (location = 0) out vec4 rtFragColor;
layout (binding = 0) uniform sampler2DShadow shadow_tex;	//Declare shadow map texture FROM BLUE BOOK

//Declare shadow coordinate varying
in vec4 vShadowCoord;

uniform int uCount;

//Varyings for normal vector, vector from object surface to light, and vector vector from object surface to camera
in vec3 vSurfaceNormal;
in vec3 vVecToLight;
in vec3 vVecToCamera;

// Material properties
uniform vec3 diffuse_albedo = vec3(0.5, 0.2, 0.7);
uniform vec3 specular_albedo = vec3(0.7);
uniform float specular_power = 128.0;

void main()
{
	//Normalise varyings
	vec3 n = normalize(vSurfaceNormal);
	vec3 l = normalize(vVecToLight);
	vec3 v = normalize(vVecToCamera);

	//Reflect
	vec3 r = reflect(-l, n);

	//Compute diffuse and specular
	vec3 diffuse = max(dot(n, l), 0.0) * diffuse_albedo;
	vec3 specular = pow(max(dot(r, v), 0.0), specular_power) * specular_albedo;

	//Assign to output
	rtFragColor = textureProj(shadow_tex, vShadowCoord) * vec4(diffuse + specular, 1.0);

	// DUMMY OUTPUT: all fragments are OPAQUE MAGENTA
	//rtFragColor = vec4(1.0, 0.0, 1.0, 1.0);
}
