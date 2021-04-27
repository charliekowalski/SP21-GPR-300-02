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

			struct appdata
			{
				float4 vertex : POSITION;	//Position of current vertex
				float2 uv : TEXCOORD0;	//UV
			};

			//Vertrex to Fragment shader conversion
			struct  v2f
			{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			//Passing in stuff
			fixed4 _Color;
			sampler2D _MainTex;

			//HERE is where we implement our functions
			v2f VertexFunc(appdata IN)
			{
				v2f OUT;

				//Transform from object-space to clip-space
				OUT.position = UnityObjectToClipPos(IN.vertex);
				OUT.uv = IN.uv;

				return OUT;
			}

			//SV_Target is the render target
			fixed4 FragmentFunc(v2f IN) : SV_Target
			{
				//Sample the _MainTex at the uv
				fixed4 pixelColor = tex2D(_MainTex, IN.uv);

				return pixelColor;
			}

			//End program
			ENDCG
		}
	}
}