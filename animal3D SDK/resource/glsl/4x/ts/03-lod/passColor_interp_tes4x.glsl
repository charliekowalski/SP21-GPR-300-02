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
	
	passColor_interp_tes4x.glsl
	Pass color, outputting result of interpolation.
*/

#version 450

// ****TO-DO: 
//	-> declare uniform block for spline waypoint and handle data
//	-> implement spline interpolation algorithm based on scene object's path
//	-> interpolate along curve using correct inputs and project result

layout (isolines, equal_spacing) in;	//All subdivisions are equal space apart

uniform mat4 uP;

uniform ubCurve
{
	vec4 uCurveWaypoint[32];
	vec4 uCurveTangent[32];
};

uniform int uCount;	//Num of segments

out vec4 vColor;	//Fragment shader after this reads colour and outputs it

void main()
{
	int index0 = gl_PrimitiveID;	//Start waypoint index for this segment
	int index1 = (index0 + 1) % uCount;	//End waypoint index for this segment (make sure not to go over length of array)
	float t = gl_TessCoord.x;	//gl_TessCoord.x is 0 to 1, tells us how far along the line we are, good for LERP
	vec4 p = mix(uCurveWaypoint[index0], uCurveWaypoint[index1], t);	//WE HAVE TO IMPLEMENT A CURVE SAMPLER, DO NOT USE MIX
//	vec4 p = vec4(gl_TessCoord.xy, -1.0, 1.0);	//Near plane is -1
	
	gl_Position = uP * p;

	vColor = vec4(0.5, 0.5, t, 1.0);
}
