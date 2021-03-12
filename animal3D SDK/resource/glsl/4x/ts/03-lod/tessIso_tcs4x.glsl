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
	
	tessIso_tcs4x.glsl
	Basic tessellation control for isolines.
*/

#version 450

// ****DONE - IN-CLASS: 
//	-> set tessellation levels, adjust as needed

layout (vertices = 2) out;	//Specifying what a patch is (idle-render glPatchParameteri(GL_PATCH_VERTICES, 2); might not be needed!)

uniform vec2 uLevelOuter;	//Sets rules in application (that is why it is a uniform)

void main()
{
	//Set the rules
	gl_TessLevelOuter[0] = uLevelOuter[0];	//How many lines
	gl_TessLevelOuter[1] = uLevelOuter[1];	//How many subdivisions
}
