#include "Common.hlsli" // Shaders can also use include files - note the extension

LightingPixelShaderInput main(BasicVertex modelVertex)
{
    LightingPixelShaderInput output; // This is the data the pixel shader requires from this vertex shader
    
    //Wiggle was here

    float4 modelPosition = float4(modelVertex.position, 1);

    float4 worldPosition = mul(gWorldMatrix, modelPosition);
    float4 viewPosition = mul(gViewMatrix, worldPosition);
    output.projectedPosition = mul(gProjectionMatrix, viewPosition);

    float4 modelNormal = float4(modelVertex.normal, 0);
    output.worldNormal = mul(gWorldMatrix, modelNormal).xyz;											
    output.worldPosition = worldPosition.xyz;

    output.uv = modelVertex.uv;

    return output; // Ouput data sent down the pipeline (to the pixel shader)
}
