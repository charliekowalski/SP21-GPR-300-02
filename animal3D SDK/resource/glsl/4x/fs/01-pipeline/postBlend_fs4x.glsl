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

// ****TO-DO:
//	-> declare texture coordinate varying and set of input textures
//	-> implement some sort of blending algorithm that highlights bright areas
//		(hint: research some Photoshop blend modes)

layout (location = 0) out vec4 rtFragColor;

//Input textures
layout (binding = 0) uniform sampler2D sceneTexture;

//Input textures
in vec4 a3tex_unit00;
in vec4 a3tex_unit01;
in vec4 a3tex_unit02;
in vec4 a3tex_unit03;

//Texture coordiate varying
in vec4 vTexcoord_atlas;

void main()
{
//	vec4 blend = texture2D(a3tex_unit00, vTexcoord_atlas) + texture2D(a3tex_unit01, vTexcoord_atlas);// + a3tex_unit01 + a3tex_unit02 + a3tex_unit03;
//	vec4 blend = texelFetch(a3tex_unit00, ivec2(vTexcoord_atlas.xy), 0)
//		+ texelFetch(a3tex_unit01, ivec2(vTexcoord_atlas.xy), 1)
//		+ texelFetch(a3tex_unit02, ivec2(vTexcoord_atlas.xy), 2)
//		+ texelFetch(a3tex_unit03, ivec2(vTexcoord_atlas.xy), 3);

//	vec4 blend = (1.0 - a3tex_unit00) * (1.0 - a3tex_unit01) * (1.0 - a3tex_unit02) * (1.0 - a3tex_unit03);
	vec4 blend = texelFetch(sceneTexture, ivec2(gl_FragCoord.xy), 0);

//	rtFragColor = 1.0 - blend;
	rtFragColor = blend;

	// DUMMY OUTPUT: all fragments are OPAQUE PURPLE
//	rtFragColor = vec4(0.5, 0.0, 1.0, 1.0);
}
