#include "Common.hlsli" // Shaders can also use include files - note the extension


//--------------------------------------------------------------------------------------
// Textures (texture maps)
//--------------------------------------------------------------------------------------

// Here we allow the shader access to a texture that has been loaded from the C++ side and stored in GPU memory (the words map and texture are used interchangeably)
//****| INFO | Normal map, now contains per pixel heights in the alpha channel ****//
Texture2D DiffuseSpecularMap : register(t0); // Diffuse map (main colour) in rgb and specular map (shininess level) in alpha - C++ must load this into slot 0
Texture2D NormalHeightMap : register(t1); // Normal map in rgb and height maps in alpha - C++ must load this into slot 1
SamplerState TexSampler : register(s0); // A sampler is a filter for a texture like bilinear, trilinear or anisotropic


//--------------------------------------------------------------------------------------
// Shader code
//--------------------------------------------------------------------------------------

float4 main(NormalMappingPixelShaderInput input) : SV_Target
{
    float3 modelNormal = normalize(input.modelNormal);
    float3 modelTangent = normalize(input.modelTangent);

    float3 modelBiTangent = cross(modelNormal, modelTangent);
    float3x3 invTangentMatrix = float3x3(modelTangent, modelBiTangent, modelNormal);
	

	//****| INFO |**********************************************************************************//
	// The following few lines are the parallax mapping. Converts the camera direction into model
	// space and adjusts the UVs based on that and the bump depth of the texel we are looking at
	// Although short, this code involves some intricate matrix work / space transformations
	//**********************************************************************************************//

	// Get normalised vector to camera for parallax mapping and specular equation (this vector was calculated later in previous shaders)
    float3 cameraDirection = normalize(gCameraPosition - input.worldPosition);

	// Transform camera vector from world into model space. Need *inverse* world matrix for this.
	// Only need 3x3 matrix to transform vectors, to invert a 3x3 matrix we transpose it (flip it about its diagonal)
    float3x3 invWorldMatrix = transpose((float3x3) gWorldMatrix);
    float3 cameraModelDir = normalize(mul(invWorldMatrix, cameraDirection)); // Normalise in case world matrix is scaled

	// Then transform model-space camera vector into tangent space (texture coordinate space) to give the direction to offset texture
	// coordinate, only interested in x and y components. Calculated inverse tangent matrix above, so invert it back for this step
    float3x3 tangentMatrix = transpose(invTangentMatrix);
    float2 textureOffsetDir = mul(cameraModelDir, tangentMatrix).xy;
	
	// Get the height info from the normal map's alpha channel at the given texture coordinate
	// Rescale from 0->1 range to -x->+x range, x determined by ParallaxDepth setting
    float textureHeight = gParallaxDepth * (NormalHeightMap.Sample(TexSampler, input.uv).a - 0.5f);
	
	// Use the depth of the texture to offset the given texture coordinate - this corrected texture coordinate will be used from here on
    float2 offsetTexCoord = input.uv + textureHeight * textureOffsetDir;


	//*******************************************

	//****| INFO |**********************************************************************************//
	// The above chunk of code is used only to calculate "offsetTexCoord", which is the offset in 
	// which part of the texture we see at this pixel due to it being bumpy. The remaining code is 
	// exactly the same as normal mapping, but uses offsetTexCoord instead of the usual input.uv
	//**********************************************************************************************//

	// Get the texture normal from the normal map. The r,g,b pixel values actually store x,y,z components of a normal. However, r,g,b
	// values are stored in the range 0->1, whereas the x, y & z components should be in the range -1->1. So some scaling is needed
    float3 textureNormal = 2.0f * NormalHeightMap.Sample(TexSampler, offsetTexCoord).rgb - 1.0f; // Scale from 0->1 to -1->1

	// Now convert the texture normal into model space using the inverse tangent matrix, and then convert into world space using the world
	// matrix. Normalise, because of the effects of texture filtering and in case the world matrix contains scaling
    float3 worldNormal = normalize(mul((float3x3) gWorldMatrix, mul(textureNormal, invTangentMatrix)));


	///////////////////////
	// Calculate lighting

    // Lighting equations

    // Light 1
    float3 light1Vector = gLight1Position - input.worldPosition;
    float light1Distance = length(light1Vector);
    float3 light1Direction = light1Vector / light1Distance; // Quicker than normalising as we have length for attenuation
    float3 diffuseLight1 = gLight1Colour * max(dot(worldNormal, light1Direction), 0) / light1Distance;

    float3 halfway = normalize(light1Direction + cameraDirection);
    float3 specularLight1 = diffuseLight1 * pow(max(dot(worldNormal, halfway), 0), gSpecularPower);


    // Light 2
    float3 light2Vector = gLight2Position - input.worldPosition;
    float light2Distance = length(light2Vector);
    float3 light2Direction = light2Vector / light2Distance;
    float3 diffuseLight2 = gLight2Colour * max(dot(worldNormal, light2Direction), 0) / light2Distance;

    halfway = normalize(light2Direction + cameraDirection);
    float3 specularLight2 = diffuseLight2 * pow(max(dot(worldNormal, halfway), 0), gSpecularPower);



    // Sample diffuse material colour for this pixel from a texture using a given sampler that you set up in the C++ code
    // Ignoring any alpha in the texture, just reading RGB
    float4 textureColour = DiffuseSpecularMap.Sample(TexSampler, offsetTexCoord); // Use offset texture coordinate from parallax mapping
    float3 diffuseMaterialColour = textureColour.rgb;
    float specularMaterialColour = textureColour.a;

    float3 finalColour = (gAmbientColour + diffuseLight1 + diffuseLight2) * diffuseMaterialColour +
                         (specularLight1 + specularLight2) * specularMaterialColour;

    return float4(finalColour, 1.0f); // Always use 1.0f for alpha - no alpha blending in this lab
}