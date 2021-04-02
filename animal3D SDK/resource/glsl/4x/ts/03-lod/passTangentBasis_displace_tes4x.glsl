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
	
	passTangentBasis_displace_tes4x.glsl
	Pass interpolated and displaced tangent basis.
*/

#version 450

// ****TO-DO: 
//	-> declare inbound and outbound varyings to pass along vertex data
//		(hint: inbound matches TCS naming and is still an array)
//		(hint: outbound matches GS/FS naming and is singular)
//	-> copy varying data from input to output
//	-> displace surface along normal using height map, project result
//		(hint: start by testing a "pass-thru" shader that only copies 
//		gl_Position from the previous stage to get the hang of it)

layout (triangles, equal_spacing) in;

in vbVertexData_tess {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
} vVertexData_tess[];

out vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
} vVertexData;

void main()
{
	//Copy input varying data to output
	vVertexData.vTangentBasis_view = vVertexData_tess[gl_PrimitiveID].vTangentBasis_view;
	vVertexData.vTexcoord_atlas = vVertexData_tess[gl_PrimitiveID].vTexcoord_atlas;

	//Blue book page 76 for formula - Thornton guided us in the direction of the page
	//This makes the output patch the same as the input patch
	gl_Position = gl_TessCoord.x * gl_in[0].gl_Position + 
		gl_TessCoord.y * gl_in[1].gl_Position +
		gl_TessCoord.z * gl_in[2].gl_Position;

	//Similar idea with blending points, but for the stuff in vVertexData_tess --> array with 3 vertices in it, get the weighted average (just blend) of the 3 with gl_TessCoord
	//--> SHOULD render normally after this is done
	//Blue book p. 366 -> example of displace from height texture
}
