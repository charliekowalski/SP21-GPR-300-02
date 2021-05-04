/*
    SOURCES:
        . POM code inspiration: our project 4 and a github link to help us bridge the gaps between animal3D and Unity code: https://github.com/przemyslawzaworski/Unity3D-CG-programming/blob/master/pom.shader
        . POM demo in Unity: https://www.youtube.com/watch?v=CpRuYJHGL10
        . Lighting and Shading: https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
*/

Shader "Custom/SandShader"
{
    Properties
    {
        //Sand texture
        _MainTex("Sand Texture", 2D) = "white" {}

        //Parallax Occlusion Mapping
        _HeightMap("Height map", 2D) = "white" {}
        _Parallax("Height scale", Range(0.01, 0.25)) = 0.125
        _ParallaxSamples("Parallax samples", Range(10, 100)) = 10
        _RaySize("Ray Length", Range(1, 10)) = 5
    }

        SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            sampler2D _HeightMap;
            float _Parallax;
            float _ParallaxSamples;
            float _RaySize;

            //Vertex Shader Inputs
            struct appdata
            {
                float4 vertex : POSITION;   //Position of current vertex
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            //Vertex Shader Outputs (Vertex to Fragment Shader conversion)
            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed3 diffuseColor : COLOR0; //Diffuse Lighting Colour
                float2 uv : TEXCOORD0;
                float4 worldPosition: TEXCOORD1;
                float3 tangentBasisView0 : TEXCOORD2;
                float3 tangentBasisView1 : TEXCOORD3;
                float3 tangentBasisView2 : TEXCOORD4;
                float3 normal  : TEXCOORD5;
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);

                //Convert data
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz));
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                o.tangentBasisView0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);
                o.tangentBasisView1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);
                o.tangentBasisView2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);
                o.normal = v.normal;

                //Dot product between normal and light direction for standard diffuse (Lambert) lighting
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));

                //Factor in the light color
                o.diffuseColor = nl * _LightColor0.rgb;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //Step along view vector until intersecting height map, determine precise intersection point, return resulting coordinate

                //THIS CODE IS CAUSING IT TO BREAK - loop is taking too long, apparently
                ////Lecture: lecture10 nm pom
                ////Lerp on the ray
                //fixed3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition.xyz);
                //fixed3 viewVec = i.tangentBasisView0.xyz * worldViewDir.x + i.tangentBasisView1.xyz * worldViewDir.y + i.tangentBasisView2.xyz * worldViewDir.z;
                //float3 coord = float3(i.uv, 0.0);
                //float t = 0.0;
                //float dt = 1.0 / _ParallaxSamples;
                //float3 startCoord = float3(coord.x, coord.y, 1);
                //float3 endCoord = coord - (viewVec / viewVec.z) * _RaySize;
                //endCoord.z = 0;

                ////Positions
                //float3 currentPos;
                //float3 prevPos;

                ////FINAL
                //float3 finalPos;
                //float3 finalPrevPos;
                //float3 finalHeightMapPos;
                //float3 finalHeightMapPrevPos;

                //[unroll]
                //for (int index = 0; index < _ParallaxSamples; index++)
                //{
                //    //Increase t
                //    t += dt;

                //    //Lerp
                //    float3 currentPos = lerp(startCoord, endCoord, t);
                //    prevPos = currentPos;

                //    //Sample the height map
                //    float4 heightMap = tex2D(_HeightMap, currentPos.xy);

                //    //If the ray height < bump map height
                //    if (currentPos.z < heightMap.z)
                //    {
                //        //"Save" the coordinates
                //        finalPos = currentPos;
                //        finalPrevPos = prevPos;
                //        finalHeightMapPos = heightMap.xyz;
                //        finalHeightMapPrevPos = tex2D(_HeightMap, finalPrevPos.xy).xyz;
                //        index = _ParallaxSamples + 1;   //Break loop
                //    }
                //}

                ////Calculte final point by lerping from finalPrevPos to finalPos by x
                //float deltaB = finalPrevPos.z - finalHeightMapPrevPos.z;
                //float deltaH = finalPos.z - finalHeightMapPos.z;
                //float x = (finalPrevPos.z - finalHeightMapPrevPos.z) / (deltaB - deltaH);

                ////Calculate final lerp
                //coord = lerp(finalPrevPos, finalPos, x);

                
                //Setup ray
                float3 normalDirection = normalize(i.normal);
                fixed3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition.xyz);
                fixed3 viewDir = i.tangentBasisView0.xyz * worldViewDir.x + i.tangentBasisView1.xyz * worldViewDir.y + i.tangentBasisView2.xyz * worldViewDir.z;
                float2 parallaxDirection = normalize(viewDir.xy);
                float rayLength = length(viewDir);
                float parallaxLength = sqrt(rayLength * rayLength - viewDir.z * viewDir.z) / viewDir.z;
                float2 parallaxOffset = parallaxDirection * parallaxLength * _Parallax;

                //Set up for finding intersection point
                float currentHeight = 0.0;
                float prevHeight = 1.0;

                float2 currentTextureOffset = i.uv.xy;
                float  currentBound = 1.0;
                float  parallaxAmount = 0.0;
                float2 pt1 = 0;
                float2 pt2 = 0;
                float2 dx = ddx(i.uv.xy);
                float2 dy = ddy(i.uv.xy);

                //Set up for stepping through to find intersection point
                float stepSize = 1.0 / _ParallaxSamples;
                float2 textureOffsetPerStep = stepSize * parallaxOffset;

                //Find the ray's intersecton point
                for (int stepIndex = 0; stepIndex < _ParallaxSamples; stepIndex++)
                {
                    currentTextureOffset -= textureOffsetPerStep;
                    currentHeight = tex2D(_HeightMap, currentTextureOffset,dx,dy).r;
                    currentBound -= stepSize;

                    if (currentHeight > currentBound)
                    {
                        pt1 = float2(currentBound, currentHeight);
                        pt2 = float2(currentBound + stepSize, prevHeight);
                        stepIndex = _ParallaxSamples + 1;   //Exit loop
                        prevHeight = currentHeight;
                    }
                    else
                    {
                        prevHeight = currentHeight;
                    }
                }

                //Calculate final bump offset
                float delta2 = pt2.x - pt2.y;
                float delta1 = pt1.x - pt1.y;
                float denominator = delta2 - delta1;

                if (denominator == 0.0f)
                {
                    parallaxAmount = 0.0f;
                }
                else
                {
                    parallaxAmount = (pt1.x * delta2 - pt2.x * delta1) / denominator;
                }

                i.uv.xy -= parallaxOffset * (1 - parallaxAmount);
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 pom = _LightColor0.rgb * saturate(dot(normalDirection, lightDirection));
                
                //Sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                //Apply lighting and POM
                //col.rgb *= i.diffuseColor * coord;    //USE THIS when the first approach works
                col.rgb *= i.diffuseColor * pom;

                return col;
            }
            ENDCG
        }
    }
}
