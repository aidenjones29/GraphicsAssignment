#include "Common.hlsli" // Shaders can also use include files - note the extension

Texture2D DiffuseSpecularMap : register(t0); // Textures here can contain a diffuse map (main colour) in their rgb channels and a specular map (shininess) in the a channel
SamplerState TexSampler : register(s0); // A sampler is a filter for a texture like bilinear, trilinear or anisotropic - this is the sampler used for the texture above

Texture2D ShadowMapLight1 : register(t1); // Texture holding the view of the scene from a light
Texture2D ShadowMapLight2 : register(t2);
SamplerState PointClamp : register(s1); // No filtering for shadow maps (you might think you could use trilinear or similar, but it will filter light depths not the shadows cast...)


float4 main(LightingPixelShaderInput input) : SV_Target
{
    const float DepthAdjust = 0.0005f;
    input.worldNormal = normalize(input.worldNormal);
    
    //WIGGLE WAS HERE

    float3 cameraDirection = normalize(gCameraPosition - input.worldPosition);

	//----------
	// LIGHT 1

    float3 diffuseLight1 = 0; // Initialy assume no contribution from this light
    float3 specularLight1 = 0;

	// Direction from pixel to light
    float3 light1Direction = normalize(gLight1Position - input.worldPosition);

	// Check if pixel is within light cone
    if (dot(-light1Direction, gLight1Facing) > gLight1CosHalfAngle)
    {
	    float4 light1ViewPosition = mul(gLight1ViewMatrix, float4(input.worldPosition, 1.0f));
        float4 light1Projection = mul(gLight1ProjectionMatrix, light1ViewPosition);

        float2 shadowMapUV = 0.5f * light1Projection.xy / light1Projection.w + float2(0.5f, 0.5f);
        shadowMapUV.y = 1.0f - shadowMapUV.y; // Check if pixel is within light cone

        float depthFromLight = light1Projection.z / light1Projection.w - DepthAdjust; 

        if (depthFromLight < ShadowMapLight1.Sample(PointClamp, shadowMapUV).r)
        {
            float3 light1Dist = length(gLight1Position - input.worldPosition);
            diffuseLight1 = gLight1Colour * max(dot(input.worldNormal, light1Direction), 0) / light1Dist; // Equations from lighting lecture
            float3 halfway = normalize(light1Direction + cameraDirection);
            specularLight1 = diffuseLight1 * pow(max(dot(input.worldNormal, halfway), 0), gSpecularPower); // Multiplying by diffuseLight instead of light colour - my own personal preference
        }
    }

    float3 diffuseLight2 = 0; // Initialy assume no contribution from this light
    float3 specularLight2 = 0;

	// Direction from pixel to light
    float3 light2Direction = normalize(gLight2Position - input.worldPosition);

	// Check if pixel is within light cone
    if (dot(-light2Direction, gLight2Facing) > gLight2CosHalfAngle)
    {
        float4 light2ViewPosition = mul(gLight2ViewMatrix, float4(input.worldPosition, 1.0f));
        float4 light2Projection = mul(gLight2ProjectionMatrix, light2ViewPosition);

        float2 shadowMapUV = 0.5f * light2Projection.xy / light2Projection.w + float2(0.5f, 0.5f);
        shadowMapUV.y = 1.0f - shadowMapUV.y; // Check if pixel is within light cone

        float depthFromLight = light2Projection.z / light2Projection.w - DepthAdjust; 

        if (depthFromLight < ShadowMapLight2.Sample(PointClamp, shadowMapUV).r)
        {
            float3 light2Dist = length(gLight2Position - input.worldPosition);
            diffuseLight2 = gLight2Colour * max(dot(input.worldNormal, light2Direction), 0) / light2Dist; // Equations from lighting lecture
            float3 halfway = normalize(light2Direction + cameraDirection);
            specularLight2 = diffuseLight2 * pow(max(dot(input.worldNormal, halfway), 0), gSpecularPower); // Multiplying by diffuseLight instead of light colour - my own personal preference
        }
    }

	// Sum the effect of the lights - add the ambient at this stage rather than for each light (or we will get too much ambient)
    float3 diffuseLight = gAmbientColour + diffuseLight1 + diffuseLight2;
    float3 specularLight = specularLight1 + specularLight2;


	////////////////////
	// Combine lighting and textures

    // Sample diffuse material and specular material colour for this pixel from a texture using a given sampler that you set up in the C++ code
    float4 textureColour = DiffuseSpecularMap.Sample(TexSampler, input.uv);
    float3 diffuseMaterialColour = textureColour.rgb; // Diffuse material colour in texture RGB (base colour of model)
    float specularMaterialColour = textureColour.a; // Specular material colour in texture A (shininess of the surface)

    diffuseMaterialColour.g = 0.50;

    // Combine lighting with texture colours
    float3 finalColour = diffuseLight * diffuseMaterialColour + specularLight * specularMaterialColour;

    return float4(finalColour, 1.0f); // Always use 1.0f for output alpha - no alpha blending in this lab
}