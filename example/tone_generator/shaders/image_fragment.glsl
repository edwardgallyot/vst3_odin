
#version 150 core

in vec4 frag_colour;
in vec2 out_texture_coordinate;
out vec4 out_colour;

uniform sampler2D tex;

void main()
{
    out_colour = texture(tex, out_texture_coordinate) * frag_colour;
}
