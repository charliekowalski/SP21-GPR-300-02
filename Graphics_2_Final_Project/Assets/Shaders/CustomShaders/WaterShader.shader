/*
	SOURCES:
		. Basic shader creation: https://www.youtube.com/watch?v=bR8DHcj6Htg
		. Lighting and Shading: https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
		. Unity Shader variable names: https://docs.unity3d.com/Manual/SL-VertexProgramInputs.html
		. Unity Depth Textures: https://docs.unity3d.com/Manual/SL-DepthTextures.html
		. Screenspace Coordinates: https://www.ronja-tutorials.com/post/039-screenspace-texture/#screenspace-coordinates-in-unlit-shaders
		. More Unity Shader Variables: https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
		. Phong Shading Tutorial: https://en.wikibooks.org/wiki/Cg_Programming/Unity/Smooth_Specular_Highlights
*/
Shader "Custom/WaterShader"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		_SpecularColour("Specular Colour", Color) = (1,1,1,1)
		_Shininess("Shininess", Float) = 10
		_ShallowWaterColour("Shallow Water Colour", Color) = (0.04, 0.49, 0.8, 1.0)
		_DeepWaterColour("Deep Water Colour", Color) = (0.01, 0.0, 0.32, 1.0)
		_Strength("Strength", Float) = 1
		_Depth("Depth", Float) = 1
		_NormalStrength("Normal Strength", Range(0, 1)) = 1
	}

	SubShader
	{
		Pass
		{
			//Tags { "LightMode" = "ForwardBase" }			//THIS BREAKS IT

			//Start program
			CGPROGRAM

			//Define functions - Vertex and Fragment Shaders
			#pragma vertex VertexFunc
			#pragma fragment FragmentFunc
			#include "UnityLightingCommon.cginc" //For _LightColor0
			#include "UnityCG.cginc"

			// compile shader into multiple variants, with and without shadows
			// (we don't care about any lightmaps yet, so skip these variants)
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			#include "AutoLight.cginc"	//For receiving shadows

			float2 Unity_GradientNoise_Dir_float(float2 p)
			{
				// Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
				p = p % 289;
				// need full precision, otherwise half overflows when p > 1
				float x = float(34 * p.x + 1) * p.x % 289 + p.y;
				x = (34 * x + 1) * x % 289;
				x = frac(x / 41) * 2 - 1;
				return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
			}

			float Unity_GradientNoise_float(float2 UV, float Scale)
			{
				float2 p = UV * Scale;
				float2 ip = floor(p);
				float2 fp = frac(p);
				float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
				float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
				float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
				float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
				fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
				return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
			}

			float4 ComputeScreenPos(float4 pos, float projectionSign)
			{
				float4 o = pos * 0.5f;
				o.xy = float2(o.x, o.y * projectionSign) + o.w;
				o.zw = pos.zw;
				return o;
			}

			// Tranforms position from world space to homogenous space
			float4 TransformWorldToHClip(float3 positionWS)
			{
				return mul(UNITY_MATRIX_VP, float4(positionWS, 1.0));
			}

			//Inverse Lerp
			float InverseLerp(float A, float B, float T)
			{
				return (T - A) / (B - A);
			}

			//Normal Strength
			float3 NormalStrength(float3 In, float Strength)
			{
				return float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
			}

			//------------------------------------------------------------------------------------------------------------------------

			//Vertex Shader Inputs
			struct appdata
			{
				float4 vertex : POSITION;	//Position of current vertex
				float3 normal : NORMAL;	//Normal
				float2 uv : TEXCOORD0;	//UV
			};

			//Vertex Shader Outputs (Vertex to Fragment Shader conversion)
			struct  v2f
			{
				float4 position : SV_POSITION;
				float3 normal : NORMAL;
				//fixed4 colorRGBA : COLOR;
				fixed4 diffuseColor : COLOR0; //Diffuse Lighting Colour
				fixed3 ambientLighting : COLOR1;	//Ambient Lighting
				float2 uv : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				float4 screenPosition : TEXCOORD2;
				float2 depthUV : TEXCOORD3;
				float4 posWorld : TEXCOORD4;
				SHADOW_COORDS(1)	//Shadow data goes into TEXCOORD1
			};

			//Passing in stuff
			fixed4 _SpecularColour;
			float _Shininess;
			fixed4 _ShallowWaterColour;
			fixed4 _DeepWaterColour;
			float _Strength;
			float _Depth;
			float _NormalStrength;
			sampler2D _MainTex;
			//sampler2D _CameraDepthTexture;
			float4 _MainTex_ST;
			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			//HERE is where we implement our functions
			v2f VertexFunc(appdata IN)
			{
				//Declare and initialise output
				v2f OUT;
				UNITY_INITIALIZE_OUTPUT(v2f, OUT);
				float3 finalPos;
				float4 objectSpacePos = IN.vertex;

				//Diffuse lighting (Lambert) --> dot product between normal and light direction
				half3 worldNormal = UnityObjectToWorldNormal(IN.normal);
				half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
				OUT.diffuseColor = nl * _LightColor0;	//Factor in the light color
				OUT.diffuseColor.rgb += ShadeSH9(half4(worldNormal, 1));	//Factor in ambient lighting (function from UnityCG.cginc include file)

				//Receive shadows
				TRANSFER_SHADOW(OUT)

				//Transfer depth
				//OUT.screenPosition = ComputeScreenPos(OUT.position);
				//COMPUTE_EYEDEPTH(OUT.screenPosition.z);
				UNITY_TRANSFER_DEPTH(OUT.depthUV);

				//Calculate screen-space position
				//OUT.screenPosition = ComputeScreenPos(TransformWorldToHClip(float3(IN.uv, 0.0)), _ProjectionParams.x);

				//Calculatge R and B in finalPos
				finalPos.r = objectSpacePos.r;
				finalPos.b = objectSpacePos.b;

				//Calculate value for G in objectSpacePos
				float gradientNoise;
				float gradientNoiseDisplaced;
				float scaledTime = _Time * 0.01;	//Time / 100
				float2 tiling = float2(1, 1);
				float2 tilingAndOffset = IN.uv * tiling * scaledTime;
				gradientNoise = Unity_GradientNoise_float(tilingAndOffset, 20);
				gradientNoiseDisplaced = mul(0.5, gradientNoise);

				//Set G in finalPos to gradientNoiseDisplaced
				finalPos.g = gradientNoiseDisplaced;

				//Matrices
				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				//Transform from object-space to clip-space
				OUT.position = UnityObjectToClipPos(float4(finalPos, 1.0));
				OUT.posWorld = mul(modelMatrix, finalPos);
				OUT.normalDir = normalize(mul(float4(IN.normal, 0.0), modelMatrixInverse).xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				//OUT.uv = IN.uv;

				return OUT;
			}

			//SV_Target is the render target
			fixed4 FragmentFunc(v2f IN) : SV_Target
			{
				//Sample the _MainTex at the uv
				fixed4 pixelColor = tex2D(_MainTex, IN.uv);

				//Depth - Doesn't wanna work because it thinks there is a 'v' in COMPUTE_EYEDEPTH(OUT.screenPosition.z);
				//float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPosition)));
				//float depth = sceneZ - IN.screenPosition.z;

				//Screen position
				IN.screenPosition = ComputeScreenPos(TransformWorldToHClip(IN.normalDir), _ProjectionParams.x);

				//Interpolation parameter
				float sceneDepth = Linear01Depth(IN.depthUV) * _ProjectionParams.z;	//_ProjectionParams.z for camera far plane
				float screenPositionAlpha = IN.screenPosition.a;
				float interpolationParameter = (sceneDepth - (screenPositionAlpha + _Depth)) * _Strength;
				interpolationParameter = clamp(interpolationParameter, 0.0, 1.0);

				//Perform Interpolation (Lerp) between shallowWaterColour and deepWaterColour
				float4 interpolatedWaterColour = lerp(_ShallowWaterColour, _DeepWaterColour, interpolationParameter);

				//Multiply by lighting and shading
				fixed shadow = SHADOW_ATTENUATION(IN);
				fixed3 lightingAndShading = IN.diffuseColor * shadow + IN.ambientLighting;
				pixelColor.rgb *= lightingAndShading;

				//Waves effect
				float2 tiling = float2(100, 100);
				float offset0 = _Time * 0.02;	//Time / 50
				float offset1 = _Time * -0.1;	//Time / -10
				float2 uv0 = IN.uv * tiling + offset0;
				float2 uv1 = IN.uv * tiling + offset1;

				//Sample the textures
				float4 texture0 = tex2D(_MainTex, uv0);
				float4 texture1 = tex2D(_MainTex, uv1);

				//Calculate the normal (tangent space)
				float inverseLerp = InverseLerp(0.0, _NormalStrength, interpolationParameter);
				IN.normal = UnityObjectToClipPos(NormalStrength(texture0 + texture1, inverseLerp));

				//Phong
				float3 normalDir = normalize(IN.normalDir);
				float3 viewDirection = normalize(
					_WorldSpaceCameraPos - IN.posWorld.xyz);
				float3 lightDirection;
				float attenuation;

				if (0.0 == _WorldSpaceLightPos0.w) // directional light?
				{
					attenuation = 1.0; // no attenuation
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				}
				else // point or spot light
				{
					float3 vertexToLightSource =
						_WorldSpaceLightPos0.xyz - IN.posWorld.xyz;
					float distance = length(vertexToLightSource);
					attenuation = 1.0 / distance; // linear attenuation 
					lightDirection = normalize(vertexToLightSource);
				}

				float3 ambientLighting = /*IN.ambientLighting;*/
					UNITY_LIGHTMODEL_AMBIENT.rgb * IN.diffuseColor.rgb;

				float3 diffuseReflection =
					attenuation * _LightColor0.rgb * IN.diffuseColor.rgb
					* max(0.0, dot(normalDir, lightDirection));

				float3 specularReflection;
				if (dot(normalDir, lightDirection) < 0.0)
					// light source on the wrong side?
				{
					specularReflection = float3(0.0, 0.0, 0.0);
					// no specular reflection
				}
				else // light source on the right side
				{
					specularReflection = attenuation * _LightColor0.rgb
						* _SpecColor.rgb * pow(max(0.0, dot(
							reflect(-lightDirection, normalDir),
							viewDirection)), _Shininess);
				}

				float4 lighting = float4(ambientLighting + diffuseReflection
					+ specularReflection, 1.0);

				//Debugging
				//return float4(sceneDepth, 0.0, 0.0, 1.0);

				return pixelColor * interpolatedWaterColour * lighting;
			}
			//End program
			ENDCG
		}
		//Shadow casting support
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }
			// pass for additional light sources
			Blend One One // additive blending 

			CGPROGRAM

			#pragma vertex vert  
			#pragma fragment frag 

			#include "UnityCG.cginc"
			uniform float4 _LightColor0;
			// color of light source (from "Lighting.cginc")

			// User-specified properties
			uniform float4 _Color;
			uniform float4 _SpecColor;
			uniform float _Shininess;

			struct vertexInput 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			struct vertexOutput 
			{
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
			};

			vertexOutput vert(vertexInput input)
			{
				vertexOutput output;

				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				output.posWorld = mul(modelMatrix, input.vertex);
				output.normalDir = normalize(
					mul(float4(input.normal, 0.0), modelMatrixInverse).xyz);
				output.pos = UnityObjectToClipPos(input.vertex);
				return output;
			}

			float4 frag(vertexOutput input) : COLOR
			{
				float3 normalDirection = normalize(input.normalDir);

				float3 viewDirection = normalize(
					_WorldSpaceCameraPos - input.posWorld.xyz);
				float3 lightDirection;
				float attenuation;

				if (0.0 == _WorldSpaceLightPos0.w) // directional light?
				{
					attenuation = 1.0; // no attenuation
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				}
				else // point or spot light
				{
					float3 vertexToLightSource =
						_WorldSpaceLightPos0.xyz - input.posWorld.xyz;
					float distance = length(vertexToLightSource);
					attenuation = 1.0 / distance; // linear attenuation 
					lightDirection = normalize(vertexToLightSource);
				}

				float3 diffuseReflection =
					attenuation * _LightColor0.rgb * _Color.rgb
					* max(0.0, dot(normalDirection, lightDirection));

				float3 specularReflection;
				if (dot(normalDirection, lightDirection) < 0.0)
					// light source on the wrong side?
					{
					specularReflection = float3(0.0, 0.0, 0.0);
					// no specular reflection
				}
				else // light source on the right side
				{
						specularReflection = attenuation * _LightColor0.rgb
						* _SpecColor.rgb * pow(max(0.0, dot(
						reflect(-lightDirection, normalDirection),
						viewDirection)), _Shininess);
				}

				return float4(diffuseReflection
						+ specularReflection, 1.0);
				// no ambient lighting in this pass
			}
			ENDCG
		}
	}
	Fallback "Specular"
}