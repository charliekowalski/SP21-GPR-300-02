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
	
	a3_DemoMode3_Curves-idle-update.c
	Demo mode implementations: animation scene.

	********************************************
	*** UPDATE FOR ANIMATION SCENE MODE      ***
	********************************************
*/

//-----------------------------------------------------------------------------

#include "../a3_DemoMode3_Curves.h"

//typedef struct a3_DemoState a3_DemoState;
#include "../a3_DemoState.h"

#include "../_a3_demo_utilities/a3_DemoMacros.h"


//-----------------------------------------------------------------------------
// UPDATE

void a3curves_update_graphics(a3_DemoState* demoState, a3_DemoMode3_Curves* demoMode)
{
	a3bufferRefillOffset(demoState->ubo_transform, 0, 0, sizeof(demoMode->modelMatrixStack), demoMode->modelMatrixStack);
	a3bufferRefillOffset(demoState->ubo_light, 0, 0, sizeof(demoMode->pointLightData), demoMode->pointLightData);
	a3bufferRefillOffset(demoState->ubo_curve, 0, 0, sizeof(demoMode->curveWaypoint), demoMode->curveWaypoint);
	a3bufferRefillOffset(demoState->ubo_curve, 0, sizeof(demoMode->curveWaypoint), sizeof(demoMode->curveTangent), demoMode->curveTangent);
}

void a3curves_update_animation(a3_DemoState* demoState, a3_DemoMode3_Curves* demoMode, a3f64 const dt)
{
	if (demoState->updateAnimation)
	{
		a3_SceneObjectData* sceneObjectData = demoMode->obj_teapot->dataPtr;

		// ****DONE: 
		//	-> interpolate teapot's position using algorithm that matches path drawn
		//		(hint: use the one that looks the best)
		//	-> update the animation timer
		//		(hint: check if we've surpassed the segment's duration)
		// teapot follows curved path

		//Indices
		int i1 = demoMode->curveSegmentIndex;
		int i0 = (i1 - 1) % demoMode->curveWaypointCount;
		int i2 = (i1 + 1) % demoMode->curveWaypointCount;
		int i3 = (i2 + 1) % demoMode->curveWaypointCount;

		//Update time
		demoMode->curveSegmentTime += (a3f32)dt;

		//Check if we reached the next segment
		if (demoMode->curveSegmentTime >= demoMode->curveSegmentDuration)
		{
			demoMode->curveSegmentTime -= demoMode->curveSegmentDuration;
			i1 = i2;
			i2 = (i1 + 1) % demoMode->curveWaypointCount;
			i3 = (i2 + 1) % demoMode->curveWaypointCount;
			i0 = (i1 - 1) % demoMode->curveWaypointCount;
		}

		//Update the index to the new starting index (i1)
		demoMode->curveSegmentIndex = i1;

		//Catmull Rom spline interpolation
		//Points
		a3real* p0 = demoMode->curveWaypoint[i0].v;
		a3real* p1 = demoMode->curveWaypoint[i1].v;
		a3real* p2 = demoMode->curveWaypoint[i2].v;
		a3real* p3 = demoMode->curveWaypoint[i3].v;
		a3real u = demoMode->curveSegmentTime * demoMode->curveSegmentDurationInv;

		//Interpolate
		a3real4CatmullRom(sceneObjectData->position.v, p0, p1, p2, p3, u);
	}
}

void a3curves_update_scene(a3_DemoState* demoState, a3_DemoMode3_Curves* demoMode, a3f64 const dt)
{
	void a3demo_update_defaultAnimation(a3f64 const dt, a3_SceneObjectComponent const* sceneObjectArray,
		a3ui32 const count, a3ui32 const axis, a3boolean const updateAnimation);
	void a3demo_update_bindSkybox(a3_SceneObjectComponent const* sceneObject_skybox,
		a3_ProjectorComponent const* projector_active);

	const a3mat4 bias = {
		0.5f, 0.0f, 0.0f, 0.0f,
		0.0f, 0.5f, 0.0f, 0.0f,
		0.0f, 0.0f, 0.5f, 0.0f,
		0.5f, 0.5f, 0.5f, 1.0f
	}, biasInv = {
		2.0f, 0.0f, 0.0f, 0.0f,
		0.0f, 2.0f, 0.0f, 0.0f,
		0.0f, 0.0f, 2.0f, 0.0f,
		-1.0f, -1.0f, -1.0f, 1.0f
	};

	a3_ProjectorComponent* projector = demoMode->proj_camera_main;

	a3_PointLightData* pointLightData;
	a3ui32 i;

	// update camera
	a3demo_updateSceneObject(demoMode->obj_camera_main, 1);
	a3demo_updateSceneObjectStack(demoMode->obj_camera_main, projector);
	a3demo_updateProjector(projector);
	a3demo_updateProjectorViewMats(projector);
	a3demo_updateProjectorBiasMats(projector, bias, biasInv);

	// update light
	a3demo_updateSceneObject(demoMode->obj_light_main, 1);
	a3demo_updateSceneObjectStack(demoMode->obj_light_main, projector);

	// update skybox
	a3demo_updateSceneObject(demoMode->obj_skybox, 0);
	a3demo_update_bindSkybox(demoMode->obj_skybox, projector);
	a3demo_updateSceneObjectStack(demoMode->obj_skybox, projector);

	// update scene objects
	a3demo_update_defaultAnimation((dt * 15.0), demoMode->obj_sphere,
		(a3ui32)(demoMode->obj_ground - demoMode->obj_sphere), 2, demoState->updateAnimation);

	// specific object animation
	a3curves_update_animation(demoState, demoMode, dt);

	a3demo_updateSceneObject(demoMode->obj_curve, 0);
	a3demo_updateSceneObjectStack(demoMode->obj_curve, projector);

	a3demo_updateSceneObject(demoMode->obj_sphere, 0);
	a3demo_updateSceneObjectStack(demoMode->obj_sphere, projector);

	a3demo_updateSceneObject(demoMode->obj_teapot, 0);
	a3demo_updateSceneObjectStack(demoMode->obj_teapot, projector);

	a3demo_updateSceneObject(demoMode->obj_ground, 0);
	a3demo_updateSceneObjectStack(demoMode->obj_ground, projector);

	// update light positions and transforms
	for (i = 0, pointLightData = demoMode->pointLightData;
		i < curvesMaxCount_pointLight;
		++i, ++pointLightData)
	{
		a3real4Real4x4Product(pointLightData->position.v,
			projector->sceneObjectPtr->modelMatrixStackPtr->modelMatInverse.m,
			pointLightData->worldPos.v);
	}
}

void a3curves_update(a3_DemoState* demoState, a3_DemoMode3_Curves* demoMode, a3f64 const dt)
{
	// update scene objects and related data
	a3curves_update_scene(demoState, demoMode, dt);

	// prepare and upload graphics data
	a3curves_update_graphics(demoState, demoMode);
}


//-----------------------------------------------------------------------------
