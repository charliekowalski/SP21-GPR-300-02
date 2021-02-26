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
	
	postBlur_fs4x.glsl
	Gaussian blur.
*/

#version 450

// ****DONE:
//	-> declare texture coordinate varying and input texture
//	-> declare sampling axis uniform (see render code for clue)
//	-> declare Gaussian blur function that samples along one axis
//		(hint: the efficiency of this is described in class)

//GETTING HELP FROM https://learnopengl.com/Advanced-Lighting/Bloom and the Blue book, p. 487

//Blurring along an axis
//	-> sample neighbouring pixels, output weighted average
//		-> coordinate offest by some amount (+- displacement vector)
//			-> ex: horizontal, dv = vec2(1 / resolution (width), 0)
//			-> ex: vertical, dv = vec2(0, 1 / resolution (height))
//		same program for horizontal and vertical blurs,
//		how do we tell it which axis?
//			-> uniform

in vec4 vTexcoord_atlas;

uniform vec2 uAxis;

layout (location = 0) out vec4 rtFragColor;
layout (binding = 0) uniform sampler2D hdr_image;

uniform float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

void main()
{
	//The size of each textel
	vec2 textelSize = 1.0 / textureSize(hdr_image, 0);

	//The blur result
	vec3 result = texture(hdr_image, vTexcoord_atlas.xy).rgb * weight[0];

	if (uAxis.x == 0.0)		//Blur along y-axis
	{
		//Sample neighbouring pixels
		for(int i = 1; i < weight.length(); i++)
        {
            result += texture(hdr_image, vTexcoord_atlas.xy + vec2(0.0, textelSize.y * i)).rgb * weight[i];
            result += texture(hdr_image, vTexcoord_atlas.xy - vec2(0.0, textelSize.y * i)).rgb * weight[i];
        }
	}
	else if (uAxis.y == 0.0)	//Blur along x-axis
	{
		//Sample neighbouring pixels
		for(int i = 1; i < weight.length(); i++)
        {
            result += texture(hdr_image, vTexcoord_atlas.xy + vec2(textelSize.x * i, 0.0)).rgb * weight[i];
            result += texture(hdr_image, vTexcoord_atlas.xy - vec2(textelSize.x * i, 0.0)).rgb * weight[i];
        }
	}

	rtFragColor = vec4(result, 1.0);

	// DUMMY OUTPUT: all fragments are OPAQUE AQUA
//	rtFragColor = vec4(0.0, 1.0, 0.5, 1.0);
}