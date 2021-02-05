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
	
	drawLambert_fs4x.glsl
	Output Lambertian shading.
*/

#version 450

// ****TO-DO: 
//	-> declare varyings to receive lighting and shading variables
//	-> declare lighting uniforms
//		(hint: in the render routine, consolidate lighting data 
//		into arrays; read them here as arrays)
//	-> calculate Lambertian coefficient
//	-> implement Lambertian shading model and assign to output
//		(hint: coefficient * attenuation * light color * surface color)
//	-> implement for multiple lights
//		(hint: there is another uniform for light count)

layout (location = 0) out vec4 rtFragColor;

//Varyings
in vec4 vPosition;
in vec4 vSurfaceNormal;

//Uniforms
uniform vec4 uLightPosition;	//Camera-space	//TO-DO:: Add lighting Uniforms in a3_DemoStateLoad (I believe)

void main()
{
	// DUMMY OUTPUT: all fragments are OPAQUE LIME
	//rtFragColor = vec4(0.5, 1.0, 0.0, 1.0);
	
	//Diffuse coefficient = dot product (unitSurfaceNormal, unitLightVector);
	vec4 unitSurfaceNormal = normalize(vSurfaceNormal);	//Normalise it because it gets interpolated
	vec4 unitLightingVector = normalize(uLightPosition - vPosition);	//Normalise it because it gets interpolated
	float kd = dot(unitSurfaceNormal, unitLightingVector);

	//DEBUGGING
	rtFragColor = vec4(kd, kd, kd, 1.0);
}
