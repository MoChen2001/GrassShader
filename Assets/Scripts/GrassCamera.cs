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
            Matrix4x4 matrixVP = targetCamera.projectionMatrix * targetCamera.worldToCameraMatrix;
            Matrix4x4 invVP = matrixVP.inverse;
            targetMaterial.SetMatrix("_InvVP", invVP);

            Graphics.Blit(source, destination, targetMaterial);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
