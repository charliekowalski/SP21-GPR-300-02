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
	
	postDeferredLightingComposite_fs4x.glsl
	Composite results of light pre-pass in deferred pipeline.
*/

#version 450

// ****DONE?:
//	-> declare samplers containing results of light pre-pass
//	-> declare samplers for texcoords, diffuse and specular maps
//	-> implement Phong sum with samples from the above
//		(hint: this entire shader is about sampling textures)

in vec4 vTexcoord_atlas;

//Samplers for lighting pre-passes
layout (binding = 0) uniform sampler2D diffuseLight;
layout (binding = 1) uniform sampler2D specularLight;

//Samplers for texcoords, diffuse and specular maps
layout (binding = 2) uniform sampler2D texcoordsSampler;	//What de fuk?
layout (binding = 3) uniform sampler2D diffuseMap;		//For colour
layout (binding = 4) uniform sampler2D specularMap;		//For colour

//Ambient
uniform float ambientValue;

layout (location = 0) out vec4 rtFragColor;

void main()
{
	//Phong sum = (diffuse light)(diffuse color)  + (specular light)(specular color) + (dim ambient constant color)
	rtFragColor = (texture2D(diffuseLight, vTexcoord_atlas.xy) * texture2D(diffuseMap, vTexcoord_atlas.xy))
		+ (texture2D(specularLight, vTexcoord_atlas.xy) * texture2D(specularMap, vTexcoord_atlas.xy))
		+ ambientValue;
}
