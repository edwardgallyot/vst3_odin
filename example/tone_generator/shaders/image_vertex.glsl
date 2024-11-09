#version 150 core

in vec2 position;
in vec4 in_colour;
in vec2 in_texture_coordinate;
out vec4 frag_colour;
out vec2 out_texture_coordinate;

void main()
{
    out_texture_coordinate  = in_texture_coordinate;
    frag_colour = in_colour;
    gl_Position = vec4(position, 0.0, 1.0);
}
