// TextureCopy.ps - HLSL Pixel Shader
// Simple 1:1 texture copy, no color conversion, no scaling logic
// BGRA8888 pixel format straight passthrough

Texture2D tex : register(t0);
SamplerState samp : register(s0);

struct PS_INPUT { float4 pos : SV_POSITION; float2 tex : TEXCOORD; }

float4 main(PS_INPUT input) : SV_TARGET
{
    return tex.Sample(samp, input.tex);
}
