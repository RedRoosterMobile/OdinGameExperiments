@vertex
fn vs_main(@builtin(vertex_index) vertex_index : u32) -> @builtin(position) vec4<f32> {
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(3.0, -1.0),
        vec2<f32>(-1.0, 3.0)
    );
    return vec4<f32>(pos[vertex_index], 0.0, 1.0);
}

@fragment
fn fs_main(@builtin(position) coord : vec4<f32>) -> @location(0) vec4<f32> {
    let uv = coord.xy / vec2<f32>(800.0, 600.0);
    return vec4<f32>(uv.x, uv.y, 0.5, 1.0);
}
