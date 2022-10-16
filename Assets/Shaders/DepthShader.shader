Shader "Custom/DepthGrayscale" 
{
    SubShader 
    {
        Tags { "RenderType"="Opaque" }
        
        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            sampler2D _CameraDepthTexture;
            float4x4 _InvVP;

            struct FVertexIn
            {
                float4 Position : POSITION;
                float2 UV : TEXCOORD0;
            };
            
            struct FFragIn 
            {
                float4 Position : SV_POSITION;
                float2 UV : TEXCOORD0;
            };
            
        

            FFragIn vert (FVertexIn v)
            {
                FFragIn o;
                o.Position = UnityObjectToClipPos(v.Position);     
                o.UV = v.UV;
                return o;
            }
            
            float4 frag(FFragIn i) : COLOR
            {
                float depth = tex2D(_CameraDepthTexture,i.UV).r;
                float4 proj = float4(i.UV * 2 - 1, depth * 2 - 1, 1);
                float4 positionW = mul(_InvVP, proj);
                positionW = positionW / positionW.w;
                
                float4 result;
                // result.x = depth;
                // result.y = depth;
                // result.z = depth;

                result.x = positionW.x;
                result.y = positionW.y;
                result.z = positionW.z;
                result.w = depth;
                return positionW;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}