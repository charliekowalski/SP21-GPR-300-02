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
	
	drawPhongPointLight_fs4x.glsl
	Output Phong shading components while drawing point light volume.
*/

#version 450

#define MAX_LIGHTS 1024

// ****DONE?:
//	-> declare biased clip coordinate varying from vertex shader
//	-> declare point light data structure and uniform block
//	-> declare pertinent samplers with geometry data ("g-buffers")
//	-> calculate screen-space coordinate from biased clip coord
//		(hint: perspective divide)
//	-> use screen-space coord to sample g-buffers
//	-> calculate view-space fragment position using depth sample
//		(hint: same as deferred shading)
//	-> calculate final diffuse and specular shading for current light only
//DO NOT DO A LOOP, ONE LIGHT PER SPHERE

flat in int vInstanceID;

//layout (location = 0) out vec4 rtFragColor;
layout (location = 0) out vec4 rtDiffuseLight;
layout (location = 1) out vec4 rtSpecularLight;

//Biased clip-space position varying
in vec4 vBiasedClipSpacePosition;

uniform sPointLightData
{
	vec4 position;						// position in rendering target space
	vec4 worldPos;						// original position in world space
	vec4 color;							// RGB color with padding
	float radius;						// radius (distance of effect from center)
	float radiusSq;						// radius squared (if needed)
	float radiusInv;					// radius inverse (attenuation factor)
	float radiusInvSq;					// radius inverse squared (attenuation factor)
} pointLightData;

uniform mat4 uPB_inv;

uniform sampler2D uImage00;		//The diffuse atlas //Found in the shader utility header
uniform sampler2D uImage01;		//The specular atlas

uniform sampler2D uImage04;		//Texcoord g-buffer
uniform sampler2D uImage05;		//Normal g-buffer
//uniform sampler2D uImage06;		//Position g-buffer ---- NOT NEEDED
uniform sampler2D uImage07;		//Depth g-buffer

void main()
{
	//Perspective-divide (we are NOT bringing it to screen-space, it is in clip, but the hint just say perspective divide, we will trust that that is enough)
	vec4 screenCoord = vBiasedClipSpacePosition / vBiasedClipSpacePosition.w;

	//Screen-space pos (used for the view-space pos)
	vec4 position_screen = vTexcoord_atlas;
	position_screen.z = texture(uImage07, vTexcoord_atlas.xy).r;

	//View-space pos
	vec4 position_view = uPB_inv * position_screen;
	position_view /= position_view.w;	//Reverse perspective-divide

	//For final diffuse and specular
	vec4 diffuseSample = texture(uImage00, screenCoord.xy);
	vec4 specularSample = texture(uImage01, screenCoord.xy);

	//Final diffuse and specular
	rtDiffuseLight = pointLightData.color * diffuseSample
	rtSpecularLight = pointLightData.color * specularSample;
}
