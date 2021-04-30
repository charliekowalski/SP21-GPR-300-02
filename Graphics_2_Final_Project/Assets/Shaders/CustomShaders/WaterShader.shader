//Shader "Custom/WaterShader"
//{
//    Properties
//    {
//        _Color ("Color", Color) = (1,1,1,1)
//        _MainTex ("Albedo (RGB)", 2D) = "white" {}
//        _Glossiness ("Smoothness", Range(0,1)) = 0.5
//        _Metallic ("Metallic", Range(0,1)) = 0.0
//    }
//    SubShader
//    {
//        Tags { "RenderType"="Opaque" }
//        LOD 200
//
//        CGPROGRAM
//        // Physically based Standard lighting model, and enable shadows on all light types
//        #pragma surface surf Standard fullforwardshadows
//
//        // Use shader model 3.0 target, to get nicer looking lighting
//        #pragma target 3.0
//
//        sampler2D _MainTex;
//
//        struct Input
//        {
//            float2 uv_MainTex;
//        };
//
//        half _Glossiness;
//        half _Metallic;
//        fixed4 _Color;
//
//        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
//        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
//        // #pragma instancing_options assumeuniformscaling
//        UNITY_INSTANCING_BUFFER_START(Props)
//            // put more per-instance properties here
//        UNITY_INSTANCING_BUFFER_END(Props)
//
//        void surf (Input IN, inout SurfaceOutputStandard o)
//        {
//            // Albedo comes from a texture tinted by color
//            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
//            o.Albedo = c.rgb;
//            // Metallic and smoothness come from slider variables
//            o.Metallic = _Metallic;
//            o.Smoothness = _Glossiness;
//            o.Alpha = c.a;
//        }
//        ENDCG
//    }
//    FallBack "Diffuse"
//}

//Tutorial we followed: https://www.youtube.com/watch?v=bR8DHcj6Htg
Shader "Custom/WaterShader"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_ShallowWaterColour("Shallow Water Colour", Color) = (0.04, 0.49, 0.8, 1.0)
		_DeepWaterColour("Deep Water Colour", Color) = (0.01, 0.0, 0.32, 1.0)
		_Strength("Strength", Float) = 1
		_Depth("Depth", Float) = 1
	}

	SubShader
	{
		Pass
		{
			//Lighting and Shadows tutorial: https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
			// indicate that our pass is the "base" pass in forward
			// rendering pipeline. It gets ambient and main directional
			// light data set up; light direction in _WorldSpaceLightPos0
			// and color in _LightColor0
			//Tags {"LightMode" = "ForwardBase"}			//THIS BREAKS IT

			//Start program
			CGPROGRAM

			//Define functions - Vertex and Fragment Shaders
			#pragma vertex VertexFunc
			#pragma fragment FragmentFunc
			#include "UnityLightingCommon.cginc" //For _LightColor0
			#include "UnityCG.cginc"	//For _LightColor0

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

			//// Z buffer to linear 0..1 depth (0 at camera position, 1 at far plane).
			//// Does NOT work with orthographic projections.
			//// Does NOT correctly handle oblique view frustums.
			//// zBufferParam = { (f-n)/n, 1, (f-n)/n*f, 1/f }
			//float Linear01Depth(float depth, float4 zBufferParam)	//https://cyangamedev.wordpress.com/2019/06/01/scene-color-depth-nodes/
			//{
			//	return 1.0 / (zBufferParam.x * depth + zBufferParam.y);
			//}

			//------------------------------------------------------------------------------------------------------------------------

			//Got names from https://docs.unity3d.com/Manual/SL-VertexProgramInputs.html
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
				//fixed4 colorRGBA : COLOR;
				fixed4 diffuseColor : COLOR0; //Diffuse Lighting Colour
				fixed3 ambientLighting : COLOR1;	//Ambient Lighting
				float2 uv : TEXCOORD0;
				float3 interp0 : TEXCOORD1;
				SHADOW_COORDS(1)	//Shadow data goes into TEXCOORD1
			};

			//Passing in stuff
			fixed4 _ShallowWaterColour;
			fixed4 _DeepWaterColour;
			float _Strength;
			float _Depth;
			sampler2D _MainTex;
			float4 _MainTex_ST;

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
				UNITY_TRANSFER_DEPTH(OUT.uv);

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
				gradientNoiseDisplaced = mul(/*_Displacement*/0.5, gradientNoise);

				//Set G in finalPos to gradientNoiseDisplaced
				finalPos.g = gradientNoiseDisplaced;

				//Transform from object-space to clip-space
				OUT.position = UnityObjectToClipPos(float4(finalPos, 1.0));
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				return OUT;
			}

			//SV_Target is the render target
			fixed4 FragmentFunc(v2f IN) : SV_Target
			{
				//Sample the _MainTex at the uv
				fixed4 pixelColor = tex2D(_MainTex, IN.uv);

				//Interpolation parameter (camera stuff here: https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html)
				float sceneDepth = Linear01Depth(IN.uv) * _ProjectionParams.z;	//_ProjectionParams.z for camera far plane
				fixed4 screenPosition = ComputeScreenPos(TransformWorldToHClip(IN.interp0.xyz), _ProjectionParams.x);
				float interpolationParameter = (sceneDepth - (screenPosition.a + _Depth)) * _Strength;
				interpolationParameter = clamp(interpolationParameter, 0.0, 1.0);

				//Perform Interpolation (Lerp) bewteen shallowWaterColour and deepWaterColour


				//Multiply by lighting and shading
				fixed shadow = SHADOW_ATTENUATION(IN);
				fixed3 lightingAndShading = IN.diffuseColor * shadow + IN.ambientLighting;
				pixelColor.rgb *= lightingAndShading;

				return pixelColor * _ShallowWaterColour;
			}

			//End program
			ENDCG
		}

		//Shadow casting support
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}