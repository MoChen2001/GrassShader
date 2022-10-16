// 使用该Shader 的前提是 Scale 都是 1，否则效果是错误的
Shader "MyShader/MyGrass"
{
    Properties
    {
        [Header(Grass Properties)]
        _TessDegree("Tess Degree", Range(0.1, 10)) = 1
        _GrassWidth("Grass Width", Range(0.1, 2)) = 1
        _GrassHeight("Grass Height", Range(0.5, 5)) = 1
        _BowDegree("Bow Degree", Range(-0.25,0.25)) = 0

        [Header(Color Properties)]
        _BottomColor("Bottom Color", Color) = (0, 0, 0, 0)
        _TopColor("Top Color", Color) = (1, 1, 1, 1)

        [Header(Wind)]
        _RandomWindNoise("Random Wind Noise", 2D) = "white"{}
        _RandomWindFrequency("Random Wind Frequency", Range(0.001, 0.1)) = 0.05
        _RandomWindStrength("Random Wind Strength", Range(0.001, 1)) = 0.1


        [Header(Trample)]
        _TrampleTexture("Trample Texture", 2D) = "white"{}
        _TrampleDegree("Trample Degree", Range(0, 1)) = 0.5

    }
    SubShader
    {

        Pass
        {
            Cull off

            CGPROGRAM

            #pragma vertex VertexShaderFunc
            #pragma hull HullShaderFunc
            #pragma domain DomainShaderFunc
            #pragma geometry GeometryShaderFunc
            #pragma fragment FragmentShaderFunc


            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct FPatchTess
            {
                float EdgeTess[4] : SV_Tessfactor;
                float InsideTess[2] : SV_InsideTessFactor;
            };

            struct FVertexIn
            {
                float4 Position : POSITION;
                float4 Tangent : TANGENT;
                float3 Normal : NORMAL;
                float2 UV : TEXCOORD0;
            };

            struct FVertexOut
            {
                float4 Position : SV_POSITION;
                float4 Tangent : TANGENT;
                float3 Normal : NORMAL;
                float2 UV : TEXCOORD0;
            };


            struct FHullOut
            {
                float4 Position : SV_POSITION;
                float4 Tangent : TANGENT;
                float3 Normal : NORMAL;
                float2 UV : TEXCOORD0;
            };

            struct FDomainOut
            {
                float4 Position : SV_POSITION;
                float4 Tangent : TANGENT;
                float2 UV : TEXCOORD0;
                float2 WorldPositionXZ : TEXCOORD1;
                float3 Normal : NORMAL;
            };

            struct FGeometryOut
            {
                float4 PositionH : SV_POSITION;
                float4 Color : TEXCOORD0;
            };

            float _TessDegree;
            float _BowDegree;

            float _GrassWidth;
            float _GrassHeight;

            float4 _BottomColor;
            float4 _TopColor;

            sampler2D _RandomWindNoise;
            float4 _RandomWindNoise_ST;
            float _RandomWindFrequency;
            float _RandomWindStrength;

            sampler2D _TrampleTexture;
            float4 _TrampleTexture_ST;
            float _TrampleDegree;


            // 结果为 [-1, 1]
            float Rand(float3 co)
            {
                return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
            }


            float3x3 AngleAxis3x3(float angle, float3 axis)
            {
                float c, s;
                sincos(angle, s, c);
                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;
                return float3x3
                (
                    t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                    t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                    t * x * z - s * y, t * y * z + s * x, t * z * z + c
                );
            }


            FVertexOut VertexShaderFunc(FVertexIn inPoint)
            {
                FVertexOut outPoint;
                outPoint.Position = inPoint.Position;
                outPoint.Tangent = inPoint.Tangent;
                outPoint.Normal = inPoint.Normal;
                outPoint.UV = inPoint.UV;
                return outPoint;
            }

            FPatchTess PatchconstantShaderFunc(InputPatch<FVertexOut, 4> inPoints)
            {
                FPatchTess res;
                res.EdgeTess[0] = _TessDegree;
                res.EdgeTess[1] = _TessDegree;
                res.EdgeTess[2] = _TessDegree;
                res.EdgeTess[3] = _TessDegree;
                res.InsideTess[0] = _TessDegree;
                res.InsideTess[1] = _TessDegree;
                return res;
            }

            [UNITY_domain("quad")]
            [UNITY_partitioning("integer")]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_outputcontrolpoints(4)]
            [UNITY_patchconstantfunc("PatchconstantShaderFunc")]
            FHullOut HullShaderFunc(InputPatch<FVertexOut, 4> inPoints, int pointID : SV_OutputControlPointID)
            {
                FHullOut res;
                res.Position = inPoints[pointID].Position;
                res.Tangent = inPoints[pointID].Tangent;
                res.Normal = inPoints[pointID].Normal;
                res.UV = inPoints[pointID].UV;
                return res;
            }


            [UNITY_domain("quad")]
            FDomainOut DomainShaderFunc(FPatchTess tess, float2 uv : SV_DomainLocation, OutputPatch<FHullOut,4> inPoints)
            {
                FDomainOut res;
                res.Position = lerp( lerp(inPoints[0].Position, inPoints[1].Position, uv.x), lerp(inPoints[2].Position, inPoints[3].Position, uv.x), uv.y);
                res.Tangent = lerp( lerp(inPoints[0].Tangent, inPoints[1].Tangent, uv.x), lerp(inPoints[2].Tangent, inPoints[3].Tangent, uv.x), uv.y );
                res.Normal = lerp( lerp(inPoints[0].Normal, inPoints[1].Normal, uv.x) , lerp(inPoints[2].Normal, inPoints[3].Normal, uv.x), uv.y);
                res.UV = lerp( lerp(inPoints[0].UV, inPoints[1].UV, uv.x), lerp(inPoints[2].UV, inPoints[3].UV, uv.x), uv.y);
                float4 PositionW = mul(unity_ObjectToWorld, res.Position);
                res.WorldPositionXZ = float2(PositionW.x, PositionW.z);
                return res;
            }

            [maxvertexcount(7)]
            void GeometryShaderFunc(point FDomainOut inPoints[1], inout TriangleStream<FGeometryOut> mTriOut)
            {

                float RandPosition = Rand(inPoints[0].Position.xyz);
                float4 basePosition = inPoints[0].Position + float4(RandPosition, 0, RandPosition, 0) * 0.5;
                float2 baseUV = inPoints[0].UV;
                float2 baseWorldPos = inPoints[0].WorldPositionXZ;

                float3 normal = inPoints[0].Normal.xyz;
                float3 tangent = inPoints[0].Tangent.xyz;
                float3 bitNormal = cross(tangent, normal);
                float3x3 tangentToLocal= {
                    tangent.x, bitNormal.x, normal.x,
                    tangent.y, bitNormal.y, normal.y,
                    tangent.z, bitNormal.z, normal.z
                };

                float4 minUV = float4(TRANSFORM_TEX(float2(0,0),_TrampleTexture), 0, 0);
                float4 maxUV = float4(TRANSFORM_TEX(float2(1,1),_TrampleTexture), 0, 0);
                float4 zeroWorldPos = tex2Dlod(_TrampleTexture, minUV);
                float4 oneWorldPos = tex2Dlod(_TrampleTexture, maxUV);
                float2 minWorldPosXZ = float2(min(zeroWorldPos.x, oneWorldPos.x), min(zeroWorldPos.z, oneWorldPos.z));
                float2 maxWorldPosXZ = float2(max(zeroWorldPos.x, oneWorldPos.x), max(zeroWorldPos.z, oneWorldPos.z));
                float4 targetUV = float4(TRANSFORM_TEX(float2( min(max(baseWorldPos.x - minWorldPosXZ.x / maxWorldPosXZ.x - minWorldPosXZ.x,0),1),
                min(max(baseWorldPos.y - minWorldPosXZ.y / maxWorldPosXZ.y - maxWorldPosXZ.y, 0),1)),_TrampleTexture) , 0, 0);
                float4 trampleResult = tex2Dlod(_TrampleTexture, targetUV);
                float3x3 trampleRotation = AngleAxis3x3(trampleResult.w * UNITY_PI * _TrampleDegree, float3(1, 0, 0));


                // 在切线空间中围绕 N 进行随机的旋转，保证看起来不是那么假
                float3x3 rotationMatrix = AngleAxis3x3(RandPosition * UNITY_TWO_PI, float3(0, 0, 1));

                // 旋转的角度只能在 [0-180]
                // 前向弯曲的矩阵
                float3x3 bowRotationMatrix = AngleAxis3x3(RandPosition * UNITY_PI * _BowDegree, float3(1, 0, 0));

                // 随机风矩阵
                float2 uv = TRANSFORM_TEX(baseUV,_RandomWindNoise) + float2(_RandomWindFrequency,_RandomWindFrequency) * _Time.y;
                // 只需要 [0.5, 1] 这一部分
                float3 windSample = float3(tex2Dlod(_RandomWindNoise, float4(uv, 0, 0)).xyz * 2 - 1);
                float3 wind = normalize(float3(windSample.x, windSample.y, 0));
                float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample.x * _RandomWindStrength, wind);



                // 最终矩阵
                float3x3 lastMatrix = mul(tangentToLocal, mul(windRotation,mul(trampleRotation, mul(rotationMatrix, bowRotationMatrix))));


                float4 offsetArray[7];
                float perWidth = _GrassWidth / 2;
                float perHeight = _GrassHeight / 3;
                offsetArray[0] = float4(float3(perWidth, 0, 0), 0);
                offsetArray[1] = float4(float3(-perWidth, 0, 0), 0);
                offsetArray[2] = float4(float3(perWidth, 0, perHeight), 0);
                offsetArray[3] = float4(float3(-perWidth, 0, perHeight), 0);
                offsetArray[4] = float4(float3(perWidth, 0, perHeight * 2), 0);
                offsetArray[5] = float4(float3(-perWidth, 0, perHeight * 2), 0);
                offsetArray[6] = float4(float3(0, 0, perHeight * 3), 0);


                [unroll]
                for(int i = 0; i < 7; ++i)
                {
                    offsetArray[i] = float4(mul(lastMatrix, offsetArray[i].xyz), 0);

                    FGeometryOut res;
                    res.PositionH = UnityObjectToClipPos(basePosition + offsetArray[i]);
                    // 0, 1 -> 0    2, 3 -> 0.333   4, 5 -> 0.666   6 -> 1
                    res.Color = trampleResult;//float4(trampleResult.w,trampleResult.w,trampleResult.w,trampleResult.w);
                    //res.Color = lerp(_BottomColor, _TopColor, floor(i / 2) / 3);
                    mTriOut.Append(res);
                }
                
            
            }



            fixed4 FragmentShaderFunc(FGeometryOut inPoint) : SV_Target
            {   
                return inPoint.Color;
            }

            
            ENDCG
        }
    }
}