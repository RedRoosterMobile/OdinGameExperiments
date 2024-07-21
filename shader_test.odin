// todo:
// https://github.com/vassvik/odin-gl_examples/blob/master/example_shaderboy.odin

package main

import "core:fmt"
import "core:mem"
import "core:math"
import "core:os"

import "vendor:wgpu"
import "vendor:glfw"

main :: proc() {
    if !glfw.init() {
        fmt.println("Failed to initialize GLFW")
        return
    }
    defer glfw.terminate()

    window := glfw.create_window(800, 600, "Fullscreen Shader", nil, nil)
    if window == nil {
        fmt.println("Failed to create GLFW window")
        return
    }
    defer window.destroy()

    window.make_context_current()
    glfw.set_window_size_callback(window, window_size_callback)

    instance := wgpu.create_instance(nil)
    surface := wgpu.create_surface_from_glfw(instance, window)
    adapter := wgpu.request_adapter(instance, surface, nil)
    device := wgpu.request_device(adapter, nil)

    swapchain_descriptor := wgpu.SwapChainDescriptor{
        usage             = wgpu.TextureUsage_RenderAttachment,
        format            = wgpu.TextureFormat_BGRA8Unorm,
        width             = 800,
        height            = 600,
        present_mode      = wgpu.PresentMode_Fifo,
    }

    swapchain := wgpu.create_swapchain(device, surface, swapchain_descriptor)

    shader_source := os.read_file("shader.wgsl")
    shader_module := wgpu.create_shader_module(device, shader_source)

    pipeline_layout := wgpu.create_pipeline_layout(device, nil)

    render_pipeline_descriptor := wgpu.RenderPipelineDescriptor{
        layout= pipeline_layout,
        vertex= wgpu.VertexState{
            module=   shader_module,
            entry_point= "vs_main",
            buffers=  nil,
        },
        fragment= wgpu.FragmentState{
            module=     shader_module,
            entry_point= "fs_main",
            targets=    &[1]wgpu.ColorTargetState{
                wgpu.ColorTargetState{
                    format=    swapchain_descriptor.format,
                    blend=     nil,
                    write_mask= wgpu.ColorWriteMask_All,
                },
            },
        },
        primitive= wgpu.PrimitiveState{
            topology= wgpu.PrimitiveTopology_TriangleList,
            strip_index_format= wgpu.IndexFormat_Undefined,
            front_face= wgpu.FrontFace_CCW,
            cull_mode=  wgpu.CullMode_None,
        },
        depth_stencil= nil,
        multisample= wgpu.MultisampleState{
            count=                1,
            mask=                 ~u32(0),
            alpha_to_coverage_enabled= false,
        },
    }

    pipeline := wgpu.create_render_pipeline(device, render_pipeline_descriptor)

    while !window.should_close() {
        glfw.poll_events()

        // frame := wgpu.get_current_frame(swapchain)
        // if frame == nil {
        //     continue
        // }
        current_texture := wgpu.swap_chain_get_current_texture_view(swapchain)
        if current_texture == nil {
            continue
        }

        command_encoder := wgpu.create_command_encoder(device, nil)
        render_pass := wgpu.begin_render_pass(command_encoder, wgpu.RenderPassDescriptor{
            color_attachments= &[1]wgpu.RenderPassColorAttachment{
                wgpu.RenderPassColorAttachment{
                    view=     frame.view,
                    resolve_target= nil,
                    ops=      wgpu.Operations{
                        load= wgpu.LoadOp_Clear,
                        store= true,
                        clear_color= wgpu.Color{0.2, 0.3, 0.3, 1.0},
                    },
                },
            },
        })

        wgpu.set_pipeline(render_pass, pipeline)
        wgpu.draw(render_pass, 3, 1, 0, 0)
        wgpu.end_render_pass(render_pass)

        command_buffer := wgpu.finish_command_encoder(command_encoder)
        wgpu.queue_submit(device, &[1]wgpu.CommandBuffer{command_buffer})
        wgpu.present(swapchain)
    }

    wgpu.device_drop(device)
    wgpu.instance_drop(instance)
}

window_size_callback :: proc(window: ^glfw.Window, width: int, height: int) {
    wgpu.swapchain_resize(swapchain, width, height)
}
