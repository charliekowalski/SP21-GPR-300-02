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
	
	postBlend_fs4x.glsl
	Blending layers, composition.
*/

#version 450

// ****TO-DO: --------------------------------------------------------------------------- Blue book p. 489 and Lecture 5: Bloom, slide 32
//	-> declare texture coordinate varying and set of input textures
//	-> implement some sort of blending algorithm that highlights bright areas
//		(hint: research some Photoshop blend modes)

layout (location = 0) out vec4 rtFragColor;

//Input textures
layout (binding = 0) uniform sampler2D sceneTexture;
layout (binding = 1) uniform sampler2D verticalBlur2;
layout (binding = 2) uniform sampler2D verticalBlur4;
layout (binding = 3) uniform sampler2D verticalBlur8;

//Texture coordiate varying
in vec4 vTexcoord_atlas;

void main()
{
	vec4 blend = vec4(0.0);
	blend += texelFetch(sceneTexture, ivec2(gl_FragCoord.xy), 0);				//Use gl_FragCoord for the scene pass
	blend += texelFetch(verticalBlur2, ivec2(vTexcoord_atlas.xy), 0);			//Use vTexcoord_atlas for postProcessing passes
	blend += texelFetch(verticalBlur4, ivec2(vTexcoord_atlas.xy), 0);			//...
	blend += texelFetch(verticalBlur8, ivec2(vTexcoord_atlas.xy), 0);			//...

		//Use texture instead of textlFetch
		//Use vTexcoord_atlas instgead of gl_FragCoord

	vec4 testBlend = 1.0 - (1.0 - texture2D(sceneTexture, vTexcoord_atlas.xy))
	* (1.0 - texture2D(verticalBlur2, vTexcoord_atlas.xy))
	* (1.0 - texture2D(verticalBlur4, vTexcoord_atlas.xy))
	* (1.0 - texture2D(verticalBlur8, vTexcoord_atlas.xy));

//	blend += texelFetch(verticalBlur8, ivec2(vTexcoord_atlas.xy), 0);			//Use vTexcoord_atlas for postProcessing passes
//	blend += texelFetch(verticalBlur4, ivec2(vTexcoord_atlas.xy), 0);			//Use vTexcoord_atlas for postProcessing passes
//	blend += texelFetch(verticalBlur2, ivec2(vTexcoord_atlas.xy), 0);			//Use vTexcoord_atlas for postProcessing passes
//	blend += texelFetch(sceneTexture, ivec2(gl_FragCoord.xy), 0);				//Use gl_FragCoord for the scene pass

//	vec4 testBlend = 1.0 - (1.0 - texelFetch(sceneTexture, ivec2(gl_FragCoord.xy), 0))
//		* (1.0 - texelFetch(verticalBlur2, ivec2(vTexcoord_atlas.xy), 0))
//		* (1.0 - texelFetch(verticalBlur4, ivec2(vTexcoord_atlas.xy), 0))
//		* (1.0 - texelFetch(verticalBlur8, ivec2(vTexcoord_atlas.xy), 0));

//	blend.rgb = vec3(1.0) - exp(-blend.rgb * 0.9);

	//rtFragColor = 1.0 - blend;
//	rtFragColor = blend;
	rtFragColor = testBlend;

	// DUMMY OUTPUT: all fragments are OPAQUE PURPLE
//	rtFragColor = vec4(0.5, 0.0, 1.0, 1.0);
}
