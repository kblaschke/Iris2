//
// Translator library functions
//

float xlat_lib_saturate( float x) {
  return clamp( x, 0.0, 1.0);
}

vec2 xlat_lib_saturate( vec2 x) {
  return clamp( x, 0.0, 1.0);
}

vec3 xlat_lib_saturate( vec3 x) {
  return clamp( x, 0.0, 1.0);
}

vec4 xlat_lib_saturate( vec4 x) {
  return clamp( x, 0.0, 1.0);
}

mat2 xlat_lib_saturate(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}

mat3 xlat_lib_saturate(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}

mat4 xlat_lib_saturate(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}


//
// Structure definitions
//

struct VS_OUTPUT {
    vec4 Position;
    vec2 TexCoord;
    vec4 Color;
};


//
// Global variable definitions
//

uniform vec4 cAmbientLight;
uniform vec4 cLightDiffuse;
uniform vec4 cMaterialAmbient;
uniform vec4 cMaterialDiffuse;
uniform mat4 matWorld;
uniform mat4 matWorldViewProjection;
uniform vec4 vLightPosition;
uniform float fMaxMovementFactor;
float xlat_mutable_fMaxMovementFactor;
uniform vec4 vTimePacked;
vec4 xlat_mutable_vTimePacked;

//
// Function declarations
//

VS_OUTPUT vs_main( in vec4 Position, in vec2 TexCoord, in vec3 Normal );

//
// Function definitions
//

VS_OUTPUT vs_main( in vec4 Position, in vec2 TexCoord, in vec3 Normal ) {
    vec4 worldPos;
    vec3 lightDir;
    float NdotL;
    VS_OUTPUT Output;

    worldPos = (( matWorld * Position ) * 31.0000);
    xlat_mutable_vTimePacked.y  = (xlat_mutable_vTimePacked.y  + sin( (worldPos.y  + xlat_mutable_vTimePacked.x ) ));
    xlat_mutable_vTimePacked.z  = (xlat_mutable_vTimePacked.z  + cos( (worldPos.x  - xlat_mutable_vTimePacked.x ) ));
    xlat_mutable_fMaxMovementFactor *= (1.00000 - TexCoord.y );
    xlat_mutable_fMaxMovementFactor *= (1.00000 + (cos( ((( -worldPos.x  ) - worldPos.z ) - worldPos.y ) ) * 0.500000));
    xlat_mutable_fMaxMovementFactor *= 0.500000;
    Position.x  += (xlat_mutable_vTimePacked.y  * xlat_mutable_fMaxMovementFactor);
    Position.y  += (xlat_mutable_vTimePacked.z  * xlat_mutable_fMaxMovementFactor);
    lightDir = normalize( (vLightPosition.xyz  - vec3( (Position * vLightPosition.w ))) );
    NdotL = clamp( dot( normalize( Normal ), lightDir), 0.000000, 1.00000);
    Output.Position = ( matWorldViewProjection * Position );
    Output.TexCoord = TexCoord;
    Output.Color = xlat_lib_saturate( ((cAmbientLight * cMaterialAmbient) + ((cLightDiffuse * cMaterialDiffuse) * NdotL)) );
    return Output;
}


//
// Translator's entry point
//
void main() {
    VS_OUTPUT xlat_retVal;
    xlat_mutable_vTimePacked = vTimePacked;
    xlat_mutable_fMaxMovementFactor = fMaxMovementFactor;

    xlat_retVal = vs_main( vec4(gl_Vertex), vec2(gl_MultiTexCoord0), vec3(gl_Normal));

    gl_Position = vec4( xlat_retVal.Position);
    gl_TexCoord[0] = vec4( xlat_retVal.TexCoord, 0.0, 0.0);
    gl_FrontColor = vec4( xlat_retVal.Color);
}
