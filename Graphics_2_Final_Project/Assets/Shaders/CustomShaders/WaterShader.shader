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
		_Color("Color", Color) = (0.04, 0.49, 0.8, 1.0)
		//_Displacement ("Displacement", Range(0.0, 1.0)) = 0.5
	}

	SubShader
	{
		Pass
		{
			//Start program
			CGPROGRAM

			//Define functions - Vertex and Fragment Shaders
			#pragma vertex VertexFunc
			#pragma fragment FragmentFunc

			//Optional, NVIDIA library
			//#include "UnityCG.cginc"

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

			//Got names from https://docs.unity3d.com/Manual/SL-VertexProgramInputs.html
			//Vertex Shader Inputs
			struct appdata
			{
				float4 vertex : POSITION;	//Position of current vertex
				//float3 normal : NORMAL;	//Normal
				//float4 tangent : TANGENT;	//Tangent
				float2 uv : TEXCOORD0;	//UV
			};

			//Vertex Shader Outputs (Vertex to Fragment Shader conversion)
			struct  v2f
			{
				float4 position : SV_POSITION;
				fixed4 color : COLOR;
				float2 uv : TEXCOORD0;
			};

			//Passing in stuff
			fixed4 _Color;
			sampler2D _MainTex;

			//HERE is where we implement our functions
			v2f VertexFunc(appdata IN)
			{
				//Declare and initialise output
				v2f OUT;
				UNITY_INITIALIZE_OUTPUT(v2f, OUT);
				float3 finalPos;
				float4 objectSpacePos = IN.vertex;

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
				OUT.uv = IN.uv;

				return OUT;
			}

			//SV_Target is the render target
			fixed4 FragmentFunc(v2f IN) : SV_Target
			{
				//Sample the _MainTex at the uv
				fixed4 pixelColor = tex2D(_MainTex, IN.uv);

				return pixelColor * _Color;
			}

			//End program
			ENDCG
		}
	}
}