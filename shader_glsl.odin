package main
//https://www.youtube.com/watch?v=A35vKCSa8NI
import "core:fmt"
import "core:mem"
import "core:math"
import "core:os"

import "vendor:wgpu"
import "vendor:glfw"

// Vertex shader (pass-through)
 vertex_shader: string = `
#version 450
layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aTexCoord;
layout(location = 0) out vec2 vTexCoord;
void main() {
    vTexCoord = aTexCoord;
    gl_Position = vec4(aPos, 0.0, 1.0);
}
`

// Fragment shader (simple color gradient)
 fragment_shader: string = `
#version 450
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 outColor;
void main() {
    outColor = vec4(vTexCoord, 0.5 + 0.5 * sin(vTexCoord.x * 10.0), 1.0);
}
`

main :: proc() {
    // Initialize GLFW
    if glfw.init() == false {
        fmt.println("Failed to initialize GLFW")
        return
    }
    defer glfw.terminate()

    // Create a GLFW window
    glfw.window_hint(glfw.CLIENT_API, glfw.NO_API)
    window := glfw.create_window(800, 600, "Fullscreen Shader", nil, nil)
    if window == nil {
        fmt.println("Failed to create GLFW window")
        return
    }
    defer window.destroy()

    // Initialize WGPU
    instance := wgpu.create_instance(nil)
    surface := wgpu.create_surface_from_glfw(window, instance)

    // Request an adapter
    adapter := wgpu.request_adapter(wgpu.RequestAdapterOptions{
        compatible_surface = surface,
    })
    if adapter == nil {
        fmt.println("Failed to get WGPU adapter")
        return
    }

    // Request a device
    device, queue := wgpu.request_device(adapter, nil)
    if device == nil {
        fmt.println("Failed to get WGPU device")
        return
    }

    // Create a swap chain
    swap_chain_descriptor := wgpu.SwapChainDescriptor{
        usage = wgpu.TextureUsage_RENDER_ATTACHMENT,
        format = wgpu.TextureFormat_BGRA8Unorm,
        width = 800,
        height = 600,
        present_mode = wgpu.PresentMode_Fifo,
    }
    swap_chain := wgpu.create_swap_chain(device, surface, swap_chain_descriptor)

    // Compile shaders
    vs_module := wgpu.create_shader_module(device, vertex_shader)
    fs_module := wgpu.create_shader_module(device, fragment_shader)

    // Create pipeline layout
    pipeline_layout := wgpu.create_pipeline_layout(device, nil)

    // Create render pipeline
    render_pipeline := wgpu.create_render_pipeline(device, wgpu.RenderPipelineDescriptor{
        layout = pipeline_layout,
        vertex = wgpu.VertexState{
            module = vs_module,
            entry_point = "main",
            buffers = nil,
        },
        fragment = wgpu.FragmentState{
            module = fs_module,
            entry_point = "main",
            targets = [1]wgpu.ColorTargetState{
                format = swap_chain_descriptor.format,
                blend = nil,
                write_mask = wgpu.ColorWriteMask_All,
            },
        },
        primitive = wgpu.PrimitiveState{
            topology = wgpu.PrimitiveTopology_TriangleList,
        },
    })

    // Main loop
    for (!window.should_close()) {
        // Poll events
        glfw.poll_events()

        // Acquire next image
        frame := swap_chain.get_current_texture_view()
        if frame == nil {
            fmt.println("Failed to acquire next swap chain texture")
            continue
        }

        // Begin render pass
        encoder := wgpu.create_command_encoder(device, nil)
        render_pass := encoder.begin_render_pass(wgpu.RenderPassDescriptor{
            color_attachments = [1]wgpu.RenderPassColorAttachment{
                view = frame,
                load_op = wgpu.LoadOp_Clear,
                store_op = wgpu.StoreOp_Store,
                clear_value = wgpu.Color{r = 0.0, g = 0.0, b = 0.0, a = 1.0},
            },
        })

        render_pass.set_pipeline(render_pipeline)
        render_pass.draw(3, 1, 0, 0)
        render_pass.end()

        // Submit commands
        commands := encoder.finish()
        queue.submit([1]wgpu.CommandBuffer{commands})

        // Present frame
        swap_chain.present()
    }

    // Clean up
    device.destroy()
    instance.destroy()
}
