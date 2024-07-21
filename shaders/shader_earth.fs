#version 330 core

in vec3 fragment_position;
in vec3 fragment_normal;

out vec4 color;

uniform samplerCube cubemap_sampler;
uniform float time;

void main() {
    color = texture(cubemap_sampler, -fragment_normal);
}
