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

// ****DONE: 
//	-> declare inbound and outbound varyings to pass along vertex data
//		(hint: inbound matches TCS naming and is still an array)
//		(hint: outbound matches GS/FS naming and is singular)
//	-> copy varying data from input to output
//	-> displace surface along normal using height map, project result
//		(hint: start by testing a "pass-thru" shader that only copies 
//		gl_Position from the previous stage to get the hang of it)

layout (triangles, equal_spacing) in;

//Uniforms
uniform mat4 uP;
uniform sampler2D uTex_hm;

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
	//Copy input varying data to output	(average of everythiing in vVertexData_tess) - Blue book page 76 for formula - Thornton guided us in the direction of the page
	vVertexData.vTangentBasis_view = gl_TessCoord.x * vVertexData_tess[0].vTangentBasis_view + 
		gl_TessCoord.y * vVertexData_tess[1].vTangentBasis_view +
		gl_TessCoord.z * vVertexData_tess[2].vTangentBasis_view;
	vVertexData.vTexcoord_atlas = gl_TessCoord.x * vVertexData_tess[0].vTexcoord_atlas + 
		gl_TessCoord.y * vVertexData_tess[1].vTexcoord_atlas +
		gl_TessCoord.z * vVertexData_tess[2].vTexcoord_atlas;

	//Blue book p. 366 -> example of displace from height texture
	//Components of blend for LOD
	float height = texture(uTex_hm, vVertexData.vTexcoord_atlas.xy).x;
	vec4 position = vVertexData.vTangentBasis_view[3];
	vec4 normal = normalize(vVertexData.vTangentBasis_view[2]);

	//Perform blend
	vVertexData.vTangentBasis_view[3] = position + normal * height;

	//Set gl_Position to the position we copied over (average of the positions from vVertexData_tess)
	gl_Position = uP * vVertexData.vTangentBasis_view[3];
}
