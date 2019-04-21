#include "Common.hlsli" // Shaders can also use include files - note the extension

void main( uint3 DTid : SV_DispatchThreadID )
{

}

LightingPixelShaderInput main(BasicVertex modelVertex)
{
	LightingPixelShaderInput output; // This is the data the pixel shader requires from this vertex shader

    float sinY = sin(modelVertex.position.y * radians(360.0f) + gWiggle);
    modelVertex.position.y += 0.9f * sinY;

	// Input position is x,y,z only - need a 4th element to multiply by a 4x4 matrix. Use 1 for a point (0 for a vector) - recall lectures
	float4 modelPosition = float4(modelVertex.position, 1);

	float4 worldPosition = mul(gWorldMatrix, modelPosition);
	float4 viewPosition = mul(gViewMatrix, worldPosition);
	output.projectedPosition = mul(gProjectionMatrix, viewPosition);


	// Also transform model normals into world space using world matrix - lighting will be calculated in world space
	// Pass this normal to the pixel shader as it is needed to calculate per-pixel lighting
	float4 modelNormal = float4(modelVertex.normal, 0);      // For normals add a 0 in the 4th element to indicate it is a vector
	output.worldNormal = mul(gWorldMatrix, modelNormal).xyz; // Only needed the 4th element to do this multiplication by 4x4 matrix...
															 //... it is not needed for lighting so discard afterwards with the .xyz
	output.worldPosition = worldPosition.xyz; // Also pass world position to pixel shader for lighting

 


	// Pass texture coordinates (UVs) on to the pixel shader, the vertex shader doesn't need them
	output.uv = modelVertex.uv;



	return output; // Ouput data sent down the pipeline (to the pixel shader)
}
