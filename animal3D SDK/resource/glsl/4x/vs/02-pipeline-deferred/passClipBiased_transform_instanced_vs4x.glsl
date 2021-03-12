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
	
	passClipBiased_transform_instanced_vs4x.glsl
	Calculate and biased clip coordinate with instancing.
*/

#version 450

#define MAX_INSTANCES 1024

// ****DONE?:
//	-> declare uniform block containing MVP for all lights
//	-> calculate final clip-space position
//	-> declare varying for biased clip-space position
//	-> calculate and copy biased clip to varying
//		(hint: bias matrix is provided as a constant)

layout (location = 0) in vec4 aPosition;

flat out int vVertexID;
flat out int vInstanceID;

//Biased clip-space position varying
out vec4 vBiasedClipSpacePosition;

uniform sModelMatrixStack
{
	mat4 modelMat;						// model matrix (object -> world)
	mat4 modelMatInverse;				// model inverse matrix (world -> object)
	mat4 modelMatInverseTranspose;		// model inverse-transpose matrix (object -> world skewed)
	mat4 modelViewMat;					// model-view matrix (object -> viewer)
	mat4 modelViewMatInverse;			// model-view inverse matrix (viewer -> object)
	mat4 modelViewMatInverseTranspose;	// model-view inverse transpose matrix (object -> viewer skewed)
	mat4 modelViewProjectionMat;		// model-view-projection matrix (object -> clip)
	mat4 atlasMat;						// atlas matrix (texture -> cell)
} lightingMatrices;

// bias matrix
const mat4 bias = mat4(
	0.5, 0.0, 0.0, 0.0,
	0.0, 0.5, 0.0, 0.0,
	0.0, 0.0, 0.5, 0.0,
	0.5, 0.5, 0.5, 1.0
);

void main()
{
	//Clip-space
	gl_Position = lightingMatrices.modelViewProjectionMat * aPosition;

	//Biased clip-space position
	vBiasedClipSpacePosition = bias * gl_Position;

	vVertexID = gl_VertexID;
	vInstanceID = gl_InstanceID;
}
