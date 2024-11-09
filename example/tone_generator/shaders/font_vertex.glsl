#version 330 core

layout (location = 0) in vec2 xyPos;
layout (location = 1) in vec2 aTexCoords;
layout (location = 2 ) in vec3 in_colour;
out vec2 TexCoords;
out vec3 colour;

uniform mat2 projection;

void main() {

    colour = in_colour;
	gl_Position = vec4(projection * xyPos, 0, 1);
	TexCoords = aTexCoords;
}
