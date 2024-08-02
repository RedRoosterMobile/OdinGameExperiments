package main

import verlet "verlet"

import "core:fmt"
import "core:mem"
import "core:os"
import "core:math/linalg"
import rl "vendor:raylib"

// main :: proc() {
//     //result := solver.solve()
// 	solver := verlet.Solver
//     fmt.println("test")
// }

// How do I create a multiple file package? #
// Put all the .odin source files for a package in a directory. Source files must have the same package declaration. All source files within a package can refer to items from other files. There is no need for a forward declarations or a header file like in C.



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

	rl.InitWindow(1280, 720, "A verlet physics integration")
	rl.SetWindowPosition(200, 200)
	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	seconds := f32(0)

	solver: = verlet.solver_init()
	
	// clean up dynamic array
	defer delete(solver.objects)
	
	vo := verlet.VerletObject {
       position = {1280/2, 0},
	   position_last = {1280/2, 0},
	   radius = 50,
	   color = rl.RED
    }
	append(&solver.objects,vo)
	vo2 := verlet.VerletObject {
		position = {1280/2-50, 0},
		position_last = {1280/2-50, 0},
		radius = 40,
		color = rl.BLUE
	 }
	 append(&solver.objects,vo2)

	for !rl.WindowShouldClose() {
		seconds = rl.GetFrameTime()

		// UPDATE
		solver.frame_dt = seconds
		verlet.solver_update(&solver)


		rl.BeginDrawing()
		rl.ClearBackground({0, 0, 0, 255})

		camera := rl.Camera2D {
			// zoom   = screen_height / PixelWindowHeight,
			// offset = {f32(rl.GetScreenWidth() / 2), screen_height / 2},
			// target = player_pos,
		}

		//solver.constraint_radius
		rl.DrawCircleV(solver.constraint_center, solver.constraint_radius, rl.WHITE)

		// DRAW
		rl.DrawCircleV(solver.objects[0].position, solver.objects[0].radius, solver.objects[0].color)
		rl.DrawCircleV(solver.objects[1].position, solver.objects[1].radius, solver.objects[1].color)
		//fmt.eprintf("%v \n",solver.objects[0].position)
		
		rl.BeginMode2D(camera)
        //rl.DrawTexture(platform_texture, 200, 200, rl.WHITE)
		rl.EndMode2D()
		rl.EndDrawing()
		
		free_all(context.temp_allocator)
	}
	free_all(context.temp_allocator)
}