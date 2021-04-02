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
	
	drawTangentBases_gs4x.glsl
	Draw tangent bases of vertices and/or faces, and/or wireframe shapes, 
		determined by flag passed to program.
*/

#version 450

// ****TO-DO: 
//	-> declare varying data to read from vertex shader
//		(hint: it's an array this time, one per vertex in primitive)
//	-> use vertex data to generate lines that highlight the input triangle
//		-> wireframe: one at each corner, then one more at the first corner to close the loop
//		-> vertex tangents: for each corner, new vertex at corner and another extending away 
//			from it in the direction of each basis (tangent, bitangent, normal)
//		-> face tangents: ditto but at the center of the face; need to calculate new bases
//	-> call "EmitVertex" whenever you're done with a vertex
//		(hint: every vertex needs gl_Position set)
//	-> call "EndPrimitive" to finish a new line and restart
//	-> experiment with different geometry effects

// (2 verts/axis * 3 axes/basis * (3 vertex bases + 1 face basis) + 4 to 8 wireframe verts = 28 to 32 verts)
#define MAX_VERTICES 32

layout (triangles) in;
//gl_in[3] --> array of verts passed in from passTangentBasis_ubo_transform_vs4x.glsl

uniform mat4 uP;

in vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
} vVertexData[];	//From same VS!

layout (line_strip, max_vertices = MAX_VERTICES) out;

out vec4 vColor;

void drawWireframe()
{
	//Get vertex information
	//Draw vertices (v0, v1, v2, v0)

	//Red first line
	vColor = vec4 (1.0, 0.0, 0.0, 1.0);
	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	gl_Position = gl_in[1].gl_Position;
	EmitVertex();
	EndPrimitive();
	
	//Green second line
	vColor = vec4 (0.0, 1.0, 0.0, 1.0);
	gl_Position = gl_in[1].gl_Position;
	EmitVertex();
	gl_Position = gl_in[2].gl_Position;
	EmitVertex();
	EndPrimitive();

	//Blue third line
	vColor = vec4 (0.0, 0.0, 1.0, 1.0);
	gl_Position = gl_in[2].gl_Position;
	EmitVertex();
	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	EndPrimitive();
}

void drawVertexTangents()
{
	//vTangentBasis_view[0] --> tangent,	vTangentBasis_view[1] --> bitangent,	vTangentBasis_view[2] --> normal

	//Bases
	vec4 tangentAway;
	vec4 bitangentAway;
	vec4 normalAway;

	//For each corner (represented by the index i)
	for (int i = 0; i < 4; i++)
	{
		//Bases
		tangentAway = vVertexData[i].vTangentBasis_view[0];
		bitangentAway = vVertexData[i].vTangentBasis_view[1];
		normalAway = vVertexData[i].vTangentBasis_view[2];

		//Set points
		//Tangent
		vColor = vec4 (1.0, 0.0, 0.0, 1.0);
		gl_Position = gl_in[i].gl_Position;
		EmitVertex();
		gl_Position = gl_in[i].gl_Position + uP * normalize(tangentAway);
		EmitVertex();

		//Bitangent
		vColor = vec4 (0.0, 1.0, 0.0, 1.0);
		gl_Position = gl_in[i].gl_Position;
		EmitVertex();
		gl_Position = gl_in[i].gl_Position + uP * normalize(bitangentAway);
		EmitVertex();

		//Normal
		vColor = vec4 (0.0, 0.0, 1.0, 1.0);
		gl_Position = gl_in[i].gl_Position;
		EmitVertex();
		gl_Position = gl_in[i].gl_Position + uP * normalize(normalAway);
		EmitVertex();
		EndPrimitive();
	}

//	//Corner 1
//	tangentAway = vVertexData[1].vTangentBasis_view[0];
//	bitangentAway = vVertexData[1].vTangentBasis_view[1];
//	normalAway = vVertexData[1].vTangentBasis_view[2];
//	gl_Position = gl_in[1].gl_Position;
//	EmitVertex();
//	gl_Position = gl_in[1].gl_Position + uP * normalize(tangentAway);
//	gl_Position = gl_in[1].gl_Position + uP * normalize(bitangentAway);
//	gl_Position = gl_in[1].gl_Position + uP * normalize(normalAway);
//	EmitVertex();
//	EndPrimitive();
//
//	//Corner 2
//	tangentAway = vVertexData[2].vTangentBasis_view[0];
//	bitangentAway = vVertexData[2].vTangentBasis_view[1];
//	normalAway = vVertexData[2].vTangentBasis_view[2];
//	gl_Position = gl_in[2].gl_Position;
//	EmitVertex();
//	gl_Position = gl_in[2].gl_Position + uP * normalize(tangentAway);
//	gl_Position = gl_in[2].gl_Position + uP * normalize(bitangentAway);
//	gl_Position = gl_in[2].gl_Position + uP * normalize(normalAway);
//	EmitVertex();
//	EndPrimitive();
}

void main()
{
	drawWireframe();
	drawVertexTangents();
}
