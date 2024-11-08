#version 150 core

in vec2 position;
in vec3 in_colour;
out vec3 frag_colour;

void main()
{
    frag_colour = in_colour;
    gl_Position = vec4(position, 0.0, 1.0);
}
