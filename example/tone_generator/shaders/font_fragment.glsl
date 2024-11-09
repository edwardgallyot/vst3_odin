#version 330 core

in vec3 colour;
in vec2 TexCoords;
out vec4 FragColor;

uniform sampler2D glyph_texture;

void main() {
	FragColor = vec4(colour, texture(glyph_texture, TexCoords).r);
}
