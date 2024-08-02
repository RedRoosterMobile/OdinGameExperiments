package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import rl "vendor:raylib"

PixelWindowHeight :: 180

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		for _, entry in track.allocation_map {
			fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
		}
		for entry in track.bad_free_array {
			fmt.eprintf("%v bad free\n", entry.location)
		}
		mem.tracking_allocator_destroy(&track)
	}

	rl.InitWindow(1280, 720, "A shader")
	rl.SetWindowPosition(200, 200)
	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	texture := rl.LoadTexture("assets/basket.png")
	shader_outline := rl.LoadShader("", "assets/shaders/glsl330/outline.fs")

	outlineSize := f32(4.0)
	outline_color: [4]f32 = [4]f32{1.0, 0.0, 0.0, 1.0} // Normalized RED color
	textureSize: [2]f32 = [2]f32{f32(texture.width), f32(texture.height)}

	// Get shader locations
	outlineSizeLoc := rl.GetShaderLocation(shader_outline, "outlineSize")
	outlineColorLoc := rl.GetShaderLocation(shader_outline, "outlineColor")
	textureSizeLoc := rl.GetShaderLocation(shader_outline, "textureSize")

	// Set shader values (they can be changed later)
	rl.SetShaderValue(shader_outline, outlineSizeLoc, &outlineSize, rl.ShaderUniformDataType.FLOAT)
	rl.SetShaderValue(
		shader_outline,
		outlineColorLoc,
		&outline_color,
		rl.ShaderUniformDataType.VEC4,
	)
	rl.SetShaderValue(shader_outline, textureSizeLoc, &textureSize, rl.ShaderUniformDataType.VEC2)

	delta := f32(0.0)
	time := f64(0.0)
	for !rl.WindowShouldClose() {
		// UPDATE
		time = rl.GetTime()
		delta = rl.GetFrameTime()

		outlineSize = f32(((math.sin_f64(time * 5.)) * 0.5 + 0.5) * 3)
		rl.SetShaderValue(
			shader_outline,
			outlineSizeLoc,
			&outlineSize,
			rl.ShaderUniformDataType.FLOAT,
		)

		// DRAW
		rl.BeginDrawing()
			rl.ClearBackground({255, 255, 255, 255})


			//rl.DrawTextureV(texture, {0, 0}, rl.WHITE)
			//rl.DrawCircleV({400,400},30,rl.RED)
			// check: https://www.raylib.com/examples.html  texture outline
			rl.BeginShaderMode(shader_outline)
				// https://www.raylib.com/examples.html
				rl.DrawTexture(texture, 100, 0, rl.WHITE)
			rl.EndShaderMode()

			rl.DrawFPS(710, 10)


			// screen_height := f32(rl.GetScreenHeight())

			// camera := rl.Camera2D {
			// 	// zoom   = screen_height / PixelWindowHeight,
			// 	// offset = {f32(rl.GetScreenWidth() / 2), screen_height / 2},
			// 	// target = player_pos,
			// }
			// rl.BeginMode2D(camera)


			// //rl.DrawTexture(platform_texture, 200, 200, rl.WHITE)

			// rl.EndMode2D()

		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
	rl.UnloadTexture(texture)
	rl.UnloadShader(shader_outline)
	rl.CloseWindow()

	free_all(context.temp_allocator)
}
