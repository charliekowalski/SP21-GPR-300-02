/*
    SOURCES:
        . POM code inspiration: our project 4 and a github link to help us bridge the gaps between animal3D and Unity code: https://github.com/przemyslawzaworski/Unity3D-CG-programming/blob/master/pom.shader
        . Lighting and Shading: https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
*/

Shader "Custom/SandShader"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
    }

        SubShader
    {
        Pass
        {
            //Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // compile shader into multiple variants, with and without shadows
            // (we don't care about any lightmaps yet, so skip these variants)
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #include "AutoLight.cginc"	//For receiving shadows


            //Vertex Shader Inputs
            struct appdata
            {
                float4 vertex : POSITION;   //Position of current vertex
                float3 normal : NORMAL;	//Normal
                float2 uv : TEXCOORD0;
            };

            //Vertex Shader Outputs (Vertex to Fragment Shader conversion)
            struct v2f
            {
                float2 uv : TEXCOORD0;
                SHADOW_COORDS(1) // put shadows data into TEXCOORD1
                float4 vertex : SV_POSITION;
                fixed3 diffuseColor : COLOR0; //Diffuse Lighting Colour
                //fixed3 ambientLighting : COLOR1;	//Ambient Lighting
            };

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);

                //Left this unchanged, default code
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                //Get vertex normal in world space
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                //Dot product between normal and light direction for standard diffuse (Lambert) lighting
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                //Factor in the light color
                o.diffuseColor = nl * _LightColor0.rgb;

                ////Shadows
                //o.ambientLighting = ShadeSH9(half4(worldNormal, 1));
                //TRANSFER_SHADOW(o);

                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                //Sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                ////Multiply by lighting and shading
                //fixed shadow = SHADOW_ATTENUATION(i);
                //fixed3 lightingAndShading = i.diffuseColor * shadow + i.ambientLighting;
                //col.rgb *= lightingAndShading;
                col.rgb *= i.diffuseColor;

                return col;
            }
            ENDCG
        }
        //UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
