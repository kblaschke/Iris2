struct VS_OUTPUT 
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR;
};

VS_OUTPUT vs_main( 
    float4 Position : POSITION,
    float2 TexCoord : TEXCOORD0,
    float3 Normal   : NORMAL,

    uniform float4x4 matWorldViewProjection,
    uniform float4x4 matWorld,

    uniform float4 vTimePacked,
    uniform float4 vLightPosition,
    uniform float4 cLightDiffuse,
    uniform float4 cAmbientLight,

    uniform float4 cMaterialDiffuse,
    uniform float4 cMaterialAmbient,
    uniform float fMaxMovementFactor )
{
    VS_OUTPUT Output;

    float4 worldPos = mul( matWorld, Position)*31;
    // Apply 'random' value for position to disturb 
    vTimePacked[1] = vTimePacked[1] + sin(worldPos.y + vTimePacked[0] );
    vTimePacked[2] = vTimePacked[2] + cos(worldPos.x - vTimePacked[0] );

    // Calculate Offset  
    fMaxMovementFactor *= (1.0-TexCoord.y);
    fMaxMovementFactor *= 1.0 + cos(-worldPos.x-worldPos.z-worldPos.y)*0.5;
    fMaxMovementFactor *= 0.5;
    // Apply Offset
    Position.x += vTimePacked[1]*fMaxMovementFactor;
    Position.y += vTimePacked[2]*fMaxMovementFactor;

    float3 lightDir = normalize(vLightPosition.xyz -  (Position * vLightPosition.w));

    // Move to World
    float NdotL = clamp( dot( normalize( Normal ), lightDir ), 0.0, 1.0);
    Output.Position = mul( matWorldViewProjection, Position );
    Output.TexCoord = TexCoord;

    // Light the vertex
    Output.Color = saturate( ( cAmbientLight * cMaterialAmbient ) + ( cLightDiffuse * cMaterialDiffuse * NdotL ) );

    // Return
    return( Output );
}