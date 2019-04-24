//--------------------------------------------------------------------------------------
// Loading GPU shaders
// Creation of constant buffers to help send C++ values to shaders each frame
//--------------------------------------------------------------------------------------
#ifndef _SHADER_H_INCLUDED_
#define _SHADER_H_INCLUDED_

#include "Common.h"

//--------------------------------------------------------------------------------------
// Global Variables
//--------------------------------------------------------------------------------------

extern ID3D11VertexShader* gPixelLightingVertexShader;
extern ID3D11PixelShader*  gPixelLightingPixelShader;
extern ID3D11VertexShader* gBasicTransformVertexShader;
extern ID3D11PixelShader*  gLightModelPixelShader;
extern ID3D11PixelShader*  gDepthOnlyPixelShader;
extern ID3D11VertexShader* gWiggleVertexShader;
extern ID3D11PixelShader*  gWigglePixelShader;
extern ID3D11PixelShader*  gLerpPixelShader;
extern ID3D11VertexShader* gParallaxMappingVertexShader;
extern ID3D11PixelShader*  gParallaxMappingPixelShader;
extern ID3D11VertexShader* gNormalMappingVertexShader;
extern ID3D11PixelShader*  gNormalMappingPixelShader;

//--------------------------------------------------------------------------------------
// Shader creation / destruction
//--------------------------------------------------------------------------------------

// Load shaders required for this app, returns true on success
bool LoadShaders();

// Release shaders used by the app
void ReleaseShaders();

//--------------------------------------------------------------------------------------
// Constant buffer creation / destruction
//--------------------------------------------------------------------------------------

// Create and return a constant buffer of the given size
// The returned pointer needs to be released before quitting. Returns nullptr on failure
ID3D11Buffer* CreateConstantBuffer(int size);


//--------------------------------------------------------------------------------------
// Helper functions
//--------------------------------------------------------------------------------------

// Load a shader, include the file in the project and pass the name (without the .hlsl extension)
// to this function. The returned pointer needs to be released before quitting. Returns nullptr on failure
ID3D11VertexShader* LoadVertexShader(std::string shaderName);
ID3D11PixelShader*  LoadPixelShader (std::string shaderName);

// Helper function. Returns nullptr on failure.
ID3DBlob* CreateSignatureForVertexLayout(const D3D11_INPUT_ELEMENT_DESC vertexLayout[], int numElements);


#endif //_SHADER_H_INCLUDED_
