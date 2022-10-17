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

        [Header(RandomWind)]
        _RandomWindNoise("Random Wind Noise", 2D) = "white"{}
        _RandomWindFrequency("Random Wind Frequency", Range(0.001, 0.1)) = 0.05
        _RandomWindStrength("Random Wind Strength", Range(0.001, 1)) = 0.1

        [Header(ControllableWind)]
        _CtrlWindDirectionX("Controllable Wind Direction X Axis", Range(-1,1)) = 0
        _CtrlWindDirectionZ("Controllable Wind Direction Z Axis", Range(-1,1)) = 0
        _CtrlWindStrength("Controllable Wind Strength", Range(0, 1)) = 0.05


        [Header(Trample)]
        _TrampleTexture("Trample Texture", 2D) = "white"{}
        _TrampleDegree("Trample Degree", Range(-1, 1)) = 0.5

    }

    CGINCLUDE
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"
        #include "MathHelper.cginc"
        #include "UnityShadowLibrary.cginc"

        struct FPatchTess
        {
            float edgeTess[4] : SV_Tessfactor;
            float insideTess[2] : SV_InsideTessFactor;
        };

        struct FVertexIn
        {
            float4 position : position;
            float4 tangent : tangent;
            float3 normal : normal;
            float2 uv : TEXCOORD0;
        };

        struct FVertexOut
        {
            float4 position : SV_position;
            float4 tangent : tangent;
            float3 normal : normal;
            float2 uv : TEXCOORD0;
        };

        struct FGeometryOut
        {
            float4 pos : SV_position;
            float4 color : TEXCOORD0;
    #if UNITY_PASS_FORWARDBASE		
            SHADOW_COORDS(1)
    #endif
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

        float _CtrlWindDirectionX;
        float _CtrlWindDirectionZ;
        float _CtrlWindStrength;

        sampler2D _TrampleTexture;
        float4 _TrampleTexture_ST;
        float _TrampleDegree;



        FVertexOut vertexShaderFunc(FVertexIn inPoint)
        {
            FVertexOut outPoint;
            outPoint.position = inPoint.position;
            outPoint.tangent = inPoint.tangent;
            outPoint.normal = inPoint.normal;
            outPoint.uv = inPoint.uv;
            return outPoint;
        }

        FPatchTess patchconstantShaderFunc(InputPatch<FVertexOut, 4> inPoints)
        {
            FPatchTess res;
            res.edgeTess[0] = _TessDegree;
            res.edgeTess[1] = _TessDegree;
            res.edgeTess[2] = _TessDegree;
            res.edgeTess[3] = _TessDegree;
            res.insideTess[0] = _TessDegree;
            res.insideTess[1] = _TessDegree;
            return res;
        }

        [UNITY_domain("quad")]
        [UNITY_partitioning("integer")]
        [UNITY_outputtopology("triangle_cw")]
        [UNITY_outputcontrolpoints(4)]
        [UNITY_patchconstantfunc("patchconstantShaderFunc")]
        FVertexOut hullShaderFunc(InputPatch<FVertexOut, 4> inPoints, int pointID : SV_OutputControlPointID)
        {
            FVertexOut res;
            res.position = inPoints[pointID].position;
            res.tangent = inPoints[pointID].tangent;
            res.normal = inPoints[pointID].normal;
            res.uv = inPoints[pointID].uv;
            return res;
        }


        [UNITY_domain("quad")]
        FVertexOut domainShaderFunc(FPatchTess tess, float2 uv : SV_DomainLocation, OutputPatch<FVertexOut,4> inPoints)
        {
            FVertexOut res;
            res.position = lerp( lerp(inPoints[0].position, inPoints[1].position, uv.x), lerp(inPoints[2].position, inPoints[3].position, uv.x), uv.y);
            res.tangent = lerp( lerp(inPoints[0].tangent, inPoints[1].tangent, uv.x), lerp(inPoints[2].tangent, inPoints[3].tangent, uv.x), uv.y );
            res.normal = lerp( lerp(inPoints[0].normal, inPoints[1].normal, uv.x) , lerp(inPoints[2].normal, inPoints[3].normal, uv.x), uv.y);
            res.uv = lerp( lerp(inPoints[0].uv, inPoints[1].uv, uv.x), lerp(inPoints[2].uv, inPoints[3].uv, uv.x), uv.y);
            return res;
        }

        [maxvertexcount(7)]
        void geometryShaderFunc(point FVertexOut inPoints[1], inout TriangleStream<FGeometryOut> mTriOut)
        {

            float randposition = rand(inPoints[0].position.xyz);
            float4 baseposition = inPoints[0].position + float4(randposition, 0, randposition, 0) * 0.5;
            float2 baseUV = inPoints[0].uv;
            float4 baseWorldPos = (unity_ObjectToWorld,baseposition);

            float3 normal = inPoints[0].normal.xyz;
            float3 tangent = inPoints[0].tangent.xyz;
            float3 bitnormal = cross(tangent, normal);
            float3x3 tangentToLocal= {
                tangent.x, bitnormal.x, normal.x,
                tangent.y, bitnormal.y, normal.y,
                tangent.z, bitnormal.z, normal.z
            };

            // 在切线空间中围绕 N 轴进行随机的旋转，保证看起来不是那么假
            float3x3 rotationMatrix = angleAxis3x3(randposition * UNITY_TWO_PI, float3(0, 0, 1));

            // 前向弯曲的矩阵,旋转的角度只能在 [0-180]
            float3x3 bowRotationMatrix = angleAxis3x3(randposition * UNITY_PI * _BowDegree, float3(1, 0, 0));

            // 随机风矩阵
            float2 uv = TRANSFORM_TEX(baseUV,_RandomWindNoise) + float2(_RandomWindFrequency,_RandomWindFrequency) * _Time.y;
            float3 windSample = float3(tex2Dlod(_RandomWindNoise, float4(uv, 0, 0)).xyz * 2 - 1);
            float3 wind = normalize(float3(windSample.x, windSample.y, 0));
            float3x3 windRotation = angleAxis3x3(UNITY_PI * windSample.x * _RandomWindStrength, wind);


            // 可控风，用于模拟风特别大的时候，草倒下来的效果
            float3 ctrlWindAxis = float3(_CtrlWindDirectionX, 0, _CtrlWindDirectionZ);
            float2 windDir = normalize(float2(ctrlWindAxis.x, ctrlWindAxis.z));
            // 如果想要一波一波的那种效果可以用这个
            //float windStrength =  abs(sin(UNITY_PI * (baseUV.x * windDir.x  + baseUV.y * windDir.y))) * _CtrlWindStrength;
            float2 ctrlWind = windDir * _CtrlWindStrength * 0.04;


            // 踩踏效果的处理矩阵
            float4 minuv = float4(TRANSFORM_TEX(float2(0,0),_TrampleTexture), 0, 0);
            float4 maxuv = float4(TRANSFORM_TEX(float2(1,1),_TrampleTexture), 0, 0);
            float4 maxWorldPos = tex2Dlod(_TrampleTexture, maxuv);
            float4 minWorldPos = tex2Dlod(_TrampleTexture, minuv);
            float4 targetUV = float4(1 -((baseWorldPos.x - minWorldPos.x) / (maxWorldPos.x - minWorldPos.x)),//clamp(baseWorldPos.x, minWorldPos.x, maxWorldPos.x) / maxWorldPos.x),
                1 -((baseWorldPos.z - minWorldPos.z) / (maxWorldPos.z - minWorldPos.z)), 0, 0);
            float4 trampleResult = tex2Dlod(_TrampleTexture, targetUV);
            float3x3 trampleRotation = angleAxis3x3(UNITY_HALF_PI * _TrampleDegree, float3(1, 0, 0));

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
                float4 pointLocalPos = mul(unity_ObjectToWorld, baseposition + offsetArray[i]);

                // TODO: 感觉要优化的地方，就是大风的时候，草倒下的样子应该用一个平滑的曲线来表示，而不是直接钳制 
                pointLocalPos.xz += ctrlWind * max(i - 1, 0);
                pointLocalPos.xz += ctrlWind * max(i - 3, 0) * 0.5;
                pointLocalPos.xz += ctrlWind * max(i - 5, 0) * 0.2;

                res.pos = mul(UNITY_MATRIX_VP, pointLocalPos);
                
                #if UNITY_PASS_FORWARDBASE
                    TRANSFER_SHADOW(res);
                #endif

                res.color = lerp(_BottomColor, _TopColor, floor(i / 2) / 3);
                mTriOut.Append(res);
            }
        }

    ENDCG

    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            Cull off

            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vertexShaderFunc
            #pragma hull hullShaderFunc
            #pragma domain domainShaderFunc
            #pragma geometry geometryShaderFunc
            #pragma fragment fragmentShaderFunc   
            #include "Lighting.cginc"

            fixed4 fragmentShaderFunc(FGeometryOut inPoint) : SV_Target
            {   
                fixed shadow = SHADOW_ATTENUATION(inPoint);
                return inPoint.color * shadow;
            }
            ENDCG
        } 
        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM
            #pragma multi_compile_shadowcaster
            #pragma vertex vertexShaderFunc
            #pragma hull hullShaderFunc
            #pragma domain domainShaderFunc
            #pragma geometry geometryShaderFunc
            #pragma fragment fragmentShadowCaster   

            float4 fragmentShadowCaster(FGeometryOut i) : SV_TARGET
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        } 
    }
    FallBack "Diffuse"
}
