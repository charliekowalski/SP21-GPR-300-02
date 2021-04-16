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
	
	passTangentBasis_morph_transform_vs4x.glsl
	Calculate and pass morphed tangent basis.
*/

#version 450

#define MAX_OBJECTS 128

// ****TO-DO: 
//	-> declare morph target attributes
//	-> declare and implement morph target interpolation algorithm
//	-> declare interpolation time/param/keyframe uniform
//	-> perform morph target interpolation using correct attributes
//		(hint: results can be stored in local variables named after the 
//		complete tangent basis attributes provided before any changes)

/*
layout (location = 0) in vec4 aPosition;
layout (location = 2) in vec3 aNormal;
layout (location = 8) in vec4 aTexcoord;
layout (location = 10) in vec3 aTangent;
layout (location = 11) in vec3 aBitangent;
*/

//Start attributes form scratch (attributes represent morph targets)
//What is part of a single morph target? (see a3_DemoState-load.c around line 322)
//	-> position, normal, tangent
//	-> 16 available, 16 / 3 = 5 targets (int) + texcoord
//What is NOT part of a single morph target?
//	-> texcoord: shared because it is always the same in 2D, not a morphable attribute, does not change
//	-> bitangent: cross(normal, tangent)
//...

//Represent a single morth target
struct sMorphTarget
{
	vec4 position;
	vec3 normal;	float nPad;	//Dummy padding, we do not need a w for normal
	vec3 tangent;	float tPad;	//Dummy padding, we do not need a w for tangent
};

//Read the morph targets (hint: they are attributes)
layout (location = 0) in sMorphTarget aMorphTarget[5];
layout (location = 8) in vec4 aTexcoord;	//We copied this from vs/02.../passTangentBasis_ubo_transform_vs4x.glsl
//Procedurally calculate bitangent

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

uniform ubTransformStack
{
	sModelMatrixStack uModelMatrixStack[MAX_OBJECTS];
};
uniform int uIndex;

//Uniform block for teapot information
uniform ubAnimMorphTeapot
{
	float duration, durationInv;
	float time, param;
	uint index, count;
} teapotMorphData;

out vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
};

flat out int vVertexID;
flat out int vInstanceID;

//Interpolation algorithm
vec4 interpolate(vec4 startVec, vec4 endVec, float t)
{
	//LERP using mix function
	return mix(startVec, endVec, t);
}

void main()
{
	// DUMMY OUTPUT: directly assign input position to output position
	//gl_Position = aPosition;

	//Results of morphing
	vec4 aPosition;
	vec3 aTangent, aBitangent, aNormal;

	//Perform interpolation
	//Position
	aPosition = interpolate(aMorphTarget[uIndex].position, aMorphTarget[(uIndex + 1) % 4].position, teapotMorphData.param);

	//Tangent
	vec4 startPaddedTan = vec4(aMorphTarget[uIndex].tangent, aMorphTarget[uIndex].tPad);
	vec4 endPaddedTan = vec4(aMorphTarget[(uIndex + 1) % 5].tangent, aMorphTarget[(uIndex + 1) % 5].tPad);
	aTangent = vec3(interpolate(startPaddedTan, endPaddedTan, teapotMorphData.param));

	//Normal
	vec4 startPaddedNormal = vec4(aMorphTarget[uIndex].normal, aMorphTarget[uIndex].nPad);
	vec4 endPaddedNormal = vec4(aMorphTarget[(uIndex + 1) % 5].normal, aMorphTarget[(uIndex + 1) % 5].nPad);
	aNormal = vec3(interpolate(startPaddedNormal, endPaddedNormal, teapotMorphData.param));

	//Bitangent
//	vec4 startPaddedBitan = vec4(cross(aMorphTarget[uIndex].tangent, aMorphTarget[uIndex].normal), 1.0);
//	vec4 endPaddedBitan = vec4(cross(aMorphTarget[(uIndex + 1) % 5].tangent, aMorphTarget[(uIndex + 1) % 5].normal), 0.0);
	vec4 startPaddedBitan = vec4(cross(vec3(startPaddedNormal), vec3(startPaddedTan)), 1.0);
	vec4 endPaddedBitan = vec4(cross(vec3(endPaddedNormal), vec3(endPaddedTan)), 1.0);
//	aBitangent = vec3(interpolate(startPaddedBitan, endPaddedBitan, teapotMorphData.param));

	sModelMatrixStack t = uModelMatrixStack[uIndex];

	//Testing: copy the first morph target only --> will show teapot as if static (non-morphing but at least will be rendering)
	//...
	aPosition = aMorphTarget[0].position;

	vTangentBasis_view = t.modelViewMatInverseTranspose * mat4(aTangent, 0.0, aBitangent, 0.0, aNormal, 0.0, vec4(0.0));
	vTangentBasis_view[3] = t.modelViewMat * aPosition;
	gl_Position = t.modelViewProjectionMat * aPosition;
	
	vTexcoord_atlas = t.atlasMat * aTexcoord;

	vVertexID = gl_VertexID;
	vInstanceID = gl_InstanceID;
}
