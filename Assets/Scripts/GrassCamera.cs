using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class GrassCamera : MonoBehaviour
{
    
    public Shader targetShader;
    public Material targetMaterial;
    public Camera targetCamera;
    public RenderTexture targetTexture;

    public Color32 ResultColor;

    private bool enablePost = false;

    private void Start()
    {
        targetCamera.depthTextureMode = DepthTextureMode.Depth;
        if (targetShader != null && !targetShader.isSupported)
        {
            enablePost = false;
        }
        else
        {
            enablePost = true;
            if (targetMaterial != null && targetMaterial.shader == targetShader)
            {
                return;
            }
            else
            {
                targetMaterial = new Material(targetShader);
                targetMaterial.hideFlags = HideFlags.DontSave;
                if (!targetMaterial)
                {
                    enablePost = false;
                }
            }
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (enablePost && targetMaterial != null)
        {
            //targetCamera.previousViewProjectionMatrix
            Matrix4x4 matrixVP =  GL.GetGPUProjectionMatrix(targetCamera.projectionMatrix, true) * targetCamera.worldToCameraMatrix;
            Matrix4x4 invVP = matrixVP.inverse;
            targetMaterial.SetMatrix("_InvVP", invVP);
            targetMaterial.SetColor("_ResultColor", ResultColor);
            targetTexture.wrapMode = TextureWrapMode.Clamp;
            Graphics.Blit(source, destination, targetMaterial);
            Graphics.Blit(destination, targetTexture);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
