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
	
	postBright_fs4x.glsl
	Bright pass filter.
*/

#version 450

// ****TO-DO:
//	-> declare texture coordinate varying and input texture
//	-> implement relative luminance function
//	-> implement simple "tone mapping" such that the brightest areas of the 
//		image are emphasized, and the darker areas get darker

layout (location = 0) out vec4 rtFragColor;
layout (binding = 0) uniform sampler2D hdr_image;

//Varyings
in vec4 vTexcoord_atlas;

void main()
{
	//----------------------------------------------- FROM BLUE BOOK p. 481-482 -----------------------------------------
	int i;
	float lum[25];
	vec2 tex_scale = vec2(1.0) / textureSize(hdr_image, 0);

	//Sample 25 texels centered on the current one (the sampler)
	for (i = 0; i < 25; i++)
	{
		vec2 tc = (2.0 * gl_FragCoord.xy +
			3.5 * vec2(i % 5 - 2, i / 5 - 2));
		vec3 col = texture(hdr_image, tc * tex_scale).rgb;							// Or this
		lum[i] = dot(col, vec3(0.3, 0.59, 0.11));
	}

	// Calculate weighted color of region
	vec3 vColor = texelFetch(hdr_image,
		2 * ivec2(gl_FragCoord.xy), 0).rgb;		//This HAS to be gl_FragCoord and not vTexcoord_atlas, everything is gray if vTexcoord_atlas

	float kernelLuminance = (
		(1.0 * (lum[0] + lum[4] + lum[20] + lum[24])) +
		(4.0 * (lum[1] + lum[3] + lum[5] + lum[9] +
		lum[15] + lum[19] + lum[21] + lum[23])) +
		(7.0 * (lum[2] + lum[10] + lum[14] + lum[22])) +
		(16.0 * (lum[6] + lum[8] + lum[16] + lum[18])) +
		(26.0 * (lum[7] + lum[11] + lum[13] + lum[17])) +
		(41.0 * lum[12])
		) / 273.0;

	//Compute the corresponding exposure (Charlie's custom S-shaped tonemapping curve)
	float insideFunction = (kernelLuminance - 0.5) * 0.25;
	float denominator = 1 + pow((1 - insideFunction), 48);
	float exposure = 1 / denominator;
	
	//Apply the exposure to this texel
	rtFragColor.rgb = 1.0 - exp2(-vColor * exposure);
	rtFragColor.a = 1.0f;


	// DUMMY OUTPUT: all fragments are OPAQUE ORANGE
//	rtFragColor = vec4(1.0, 0.5, 0.0, 1.0);
}
