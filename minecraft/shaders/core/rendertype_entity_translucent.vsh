#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position, Normal;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1, UV2;

uniform sampler2D Sampler0, Sampler1, Sampler2;

uniform mat4 ModelViewMat, ProjMat;
uniform int FogShape;

uniform vec3 Light0_Direction, Light1_Direction;

out float vertexDistance;
out vec4 vertexColor, lightMapColor, overlayColor, normal;
out vec2 texCoord0, texCoord1;
out vec3 a, b;

vec3 getCubeSize(int cube) {
    if(cube >= 2 && cube <= 7)
        return vec3(8, 4, 4);

    if(cube >= 8 && cube <= 15)
        return vec3(3, 6, 4);

    if(cube >= 16 && cube <= 23)
        return vec3(4, 6, 4);

    return vec3(8, 8, 8);
}

vec2 getBoxUV(int cube) {
    switch(cube) {
        case 0: // Head
            return vec2(0, 0);
        case 1: // Hat
            return vec2(32, 0);
        case 2: // Hip
        case 4: // Waist
        case 6: // Chest
            return vec2(16, 16);
        case 3:
        case 5:
        case 7: // Jacket
            return vec2(16, 32);
        case 8:
        case 10: // Right Arm
            return vec2(40, 16);
        case 9:
        case 11: // Right Sleeve
            return vec2(40, 32);
        case 12:
        case 14: // Left Arm
            return vec2(32, 48);
        case 13:
        case 15: // Left Sleeve
            return vec2(48, 48);
        case 16:
        case 18: // Right Leg
            return vec2(0, 16);
        case 17:
        case 19: // Right Pant
            return vec2(0, 32);
        case 20:
        case 22: // Left Leg
            return vec2(16, 48);
        case 21:
        case 23: // Left Pant
            return vec2(0, 48);

    }
    return vec2(0, 0);
}

float getYOffset(int cube) {
    float r = 0;
    switch(cube) {
        case 2:
        case 3:
            r = 8;
            break;
        case 4:
        case 5:
            r = 4;
            break;
        case 10: // Right Arm
        case 11: // Right Sleeve
        case 14: // Left Arm
        case 15: // Left Sleeve
        case 18: // Right Leg
        case 19: // Right Pant
        case 22: // Left Leg
        case 23: // Left Pant
            r = 6;
            break;
    }
    return r / 64.;
}

vec2 getUVOffset(int corner, vec3 cubeSize, float yOffset) {
    vec2 offset, uv;
    switch(corner / 4) {
        case 0: // Left
            offset = vec2(cubeSize.z + cubeSize.x, cubeSize.z);
            offset.y += yOffset;
            uv = vec2(cubeSize.z, cubeSize.y);
            break;
        case 1: // Right
            offset = vec2(0, cubeSize.z);
            offset.y += yOffset;
            uv = vec2(cubeSize.z, cubeSize.y);
            break;
        case 2: // Up
            offset = vec2(cubeSize.z, 0);
            uv = vec2(cubeSize.x, cubeSize.z);
            break;
        case 3: // Down
            offset = vec2(cubeSize.z + cubeSize.x, 0);
            uv = vec2(cubeSize.x, cubeSize.z);
            break;
        case 4: // Front
            offset = vec2(cubeSize.z, cubeSize.z);
            offset.y += yOffset;
            uv = vec2(cubeSize.x, cubeSize.y);
            break;
        case 5: // Back
			offset = vec2(2 * cubeSize.z + cubeSize.x, cubeSize.z);
            offset.y += yOffset;
            uv = vec2(cubeSize.x, cubeSize.y);
            break;
    }

    switch(corner % 4) {
        case 0:
            offset += vec2(uv.x, 0);
            break;
        case 2:
            offset += vec2(0, uv.y);
            break;
        case 3:
            offset += vec2(uv.x, uv.y);
            break;
    }

    return offset;
}

bool shouldRender(int cube, int corner) {
    if(corner / 8 != 1 || cube % 2 == 0 || cube == 1)
        return true;

    if(cube == 5)
        return false;

    bool r = false;
    switch(cube) {
        case 7:
        case 9:
        case 13:
        case 17:
        case 21:
            r = true;
    }

    if(corner / 4 == 3)
        r = !r;

    return r;
}

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    a = b = vec3(0);
    if(textureSize(Sampler0, 0) == vec2(64, 64) && UV0.y <= 0.25 && (gl_VertexID / 24 != 6 || UV0.x <= 0.5)) {

        switch(gl_VertexID % 4) {
            case 0: a = vec3(UV0, 1); break;
            case 2: b = vec3(UV0, 1); break;
        }
		// 1 3 5 9 11 13 15 17
        int cube = (gl_VertexID / 24) % 24;
        int corner = gl_VertexID % 24;
        if(shouldRender(cube, corner)) {
            vec3 cubeSize = getCubeSize(cube) / 64;
            vec2 boxUV = getBoxUV(cube) / 64;
            vec2 uvOffset = getUVOffset(corner, cubeSize, getYOffset(cube));
            texCoord0 = boxUV + uvOffset;
        }else {
            texCoord0 = vec2(-1);
        }
    }else {
        texCoord0 = UV0;
    }

    // vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    vertexDistance = length((ModelViewMat * vec4(Position, 1.0)).xyz);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
    overlayColor = texelFetch(Sampler1, UV1, 0);
    texCoord1 = UV0;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
}
