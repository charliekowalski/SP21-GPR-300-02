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
	
	passTangentBasis_shadowCoord_transform_vs4x.glsl
	Calculate and pass tangent basis, and shadow coordinate.
*/

#version 450

// ****DONE????:
// 1) core transformation and lighting setup:
//	-> declare data structures for projector and model matrix stacks
//		(hint: copy and slightly modify demo object descriptors)
//	-> declare uniform block for matrix data
//		(hint: must match how it is uploaded in update function)
//	-> use matrix data for current object to perform relevant transformations
//		(hint: model-view-projection sequence may be split up like last time, 
//		but per usual the final clip-space result is assigned to gl_Position)		-- this point and before was done in class
//	-> declare relevant attributes for lighting										// After class		Not sure
//	-> perform any additional transformations and write varyings for lighting		//Not sure
// 2) shadow mapping																//We think we nailed this
//	-> using the above setup, perform additional transformation to generate a 
//		"shadow coordinate", which is a "biased clip-space" coordinate from 
//		the light's point of view
//		(hint: transformation sequence is model-view-projection-bias)
//	-> declare and write varying for shadow coordinate

layout (location = 0) in vec4 aPosition;
layout (location = 1) in vec3 aSurfaceNormal;												//LOC MIGHT BE 2

//Varyings for normal vector, vector from object surface to light, and vector vector from object surface to camera
out vec3 vSurfaceNormal;
out vec3 vVecToLight;
out vec3 vVecToCamera;

flat out int vVertexID;
flat out int vInstanceID;

uniform int uIndex;

struct sProjectorMatrixStack
{
	mat4 projectionMat;					// projection matrix (viewer -> clip)
	mat4 projectionMatInverse;			// projection inverse matrix (clip -> viewer)
	mat4 projectionBiasMat;				// projection-bias matrix (viewer -> biased clip)
	mat4 projectionBiasMatInverse;		// projection-bias inverse matrix (biased clip -> viewer)
	mat4 viewProjectionMat;				// view-projection matrix (world -> clip)
	mat4 viewProjectionMatInverse;		// view-projection inverse matrix (clip -> world)
	mat4 viewProjectionBiasMat;			// view projection-bias matrix (world -> biased clip)
	mat4 viewProjectionBiasMatInverse;	// view-projection-bias inverse matrix (biased clip -> world)
};

struct sModelMatrixStack
{
	mat4 modelMat;						// model matrix (object -> world)
	mat4 modelMatInverse;				// model inverse matrix (world -> object)
	mat4 modelMatInverseTranspose;		// model inverse-transpose matrix (object -> world skewed)
	mat4 modelViewMat;					// model-view matrix (object -> viewer)
	mat4 modelViewMatInverse;			// model-view inverse matrix (viewer -> object)
	mat4 modelViewMatInverseTranspose;	// model-view inverse transpose matrix (object -> viewer skewed)
	mat4 modelViewProjectionMat;		// model-view-projection matrix (object -> clip)
	mat4 atlasMat;						// atlas matrix (texture -> cell)
};

//What's in the buffer:
//	. projectors (camera, main light)
//	. models
uniform ubTransformStack	//Uniform block
{
	sProjectorMatrixStack uCamera, uLight;
	sModelMatrixStack uModel[16];			// 16 models (c code, a3_DemoMode1_PostProc.h)
};

//Lighting data
struct sPointLightData
{
	vec4 position;						// position in rendering target space
	vec4 worldPos;						// original position in world space
	vec4 color;							// RGB color with padding
};

uniform ubLight
{
	sPointLightData uLightData[4];
};

//Lighting attributes
//attribute vec4 aLightWorldPosition;
//attribute vec4 aLightColour;

//Varyings for lighitng data
out vec4 vLightPosition;
out vec4 vLightColour;

//Varying for shadow coordinate
out vec4 vShadowCoord;

void main()
{
	//Calculate vectors (normal, to light, and to camera)
	vec4 p = uModel[uIndex].modelViewMat * aPosition;
	vSurfaceNormal = mat3(uModel[uIndex].modelViewMat) * aSurfaceNormal;
	vVecToLight = vec3(lightData.position) - p.xyz;
	vVecToCamera = -p.xyz;
	gl_Position = uCamera.projectionMat * p;

	//Apply transformations to the varyings
	vLightPosition = uLight.viewProjectionMat * lightData.worldPos;	//View-projection matrix (world -> clip)
	vLightColour = lightData.color;

	//Shadow coordinates
	vShadowCoord = (uLight.viewProjectionBiasMat * uModel[uIndex].modelMat) * aPosition;	//Shadow matrix * position

	// DUMMY OUTPUT: directly assign input position to output position
	//gl_Position = uCamera.projectionMat * uModel[uIndex].modelViewMat * aPosition;

	vVertexID = gl_VertexID;
	vInstanceID = gl_InstanceID;
}