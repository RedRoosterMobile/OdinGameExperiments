package main
// TODO: write it yourself

import "core:fmt"
import "core:mem"
import "core:os"
import "core:math/linalg"
import rl "vendor:raylib"


// Define the VerletObject structure
/**
 * START Vertet struct
 */
VerletObject :: struct {
	position_current:      rl.Vector2,
	position_old: 		rl.Vector2,
	acceleration:  rl.Vector2,
	radius:        f32,
	color:         rl.Color,
}

update_position :: proc(a: ^VerletObject, dt: f32 ) {
   velocity := a.position_current - a.position_old;
   // safe the current position
   a.position_old = a.position_current
   // perform verlet integration
   a.position_current = a.position_current + velocity + a.acceleration * dt * dt
   fmt.eprintf("%v \n",a.position_current)
   a.acceleration = {}
}
accellerate :: proc(a: ^VerletObject, acc:rl.Vector2) {
	a.acceleration = a.acceleration + acc
	// fmt.eprintf("%v",a.acceleration)
}

/**
 * END Vertet struct
 */


 /**
 * START Solver struct
 */

 Solver :: struct {
	gravity            : rl.Vector2, //(0,1000)
    sub_steps          : u32,
    constraint_center  : rl.Vector2,
    constraint_radius  : f32,
    objects            : [dynamic]VerletObject,
    time               : f32,
    frame_dt           : f32,
};

solver_init :: proc() -> Solver {
    return Solver{
		gravity = rl.Vector2{0.0, 100.0},
        sub_steps = 1,
        constraint_center = rl.Vector2{1280/2,0},
        constraint_radius = 500.0,
        objects = make([dynamic]VerletObject, 0),
        time = 0.0,
        frame_dt = 0.0
    };
}

solver_update :: proc(s: ^Solver) {
    s.time += s.frame_dt;
    step_dt := s.frame_dt / cast(f32)(s.sub_steps);
    // fmt.eprintf("%v",s.frame_dt)
	for i := u32(0); i < s.sub_steps; i += 1 {
		
         solver_applyGravity(s);
        // // solver_checkCollisions(s, step_dt);
        solver_applyConstraint(s);
         solver_updateObjects(s, step_dt);
    }
}

solver_updateObjects :: proc(s: ^Solver, dt: f32) {
    for &obj in s.objects {
        update_position(&obj, dt);
    }
}


solver_applyGravity :: proc(s: ^Solver) {
    for &obj in s.objects {
        // verlet_object_accelerate(obj, s.gravity);
		accellerate(&obj,s.gravity)
    }
}
 /**
 * END Solver struct
 */

// part2 : constraints https://youtu.be/lS_qeBy3aQI?si=aTDFvnZGTKGlPSk0&t=145
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

	solver: = solver_init()
	// clean up dynamic array
	defer delete(solver.objects)
	
	vo := VerletObject {
       position_current = {1280/2, 0},
	   position_old = {1280/2, 0},
	   radius = 10,
	   color = rl.RED
    }
	append(&solver.objects,vo)

	for !rl.WindowShouldClose() {
		seconds = rl.GetFrameTime()

		// UPDATE
		solver.frame_dt = seconds
		solver_update(&solver)


		rl.BeginDrawing()
		rl.ClearBackground({0, 0, 0, 255})

		camera := rl.Camera2D {
			// zoom   = screen_height / PixelWindowHeight,
			// offset = {f32(rl.GetScreenWidth() / 2), screen_height / 2},
			// target = player_pos,
		}

		// DRAW
		rl.DrawCircleV(solver.objects[0].position_current, solver.objects[0].radius, solver.objects[0].color)
		//fmt.eprintf("%v \n",solver.objects[0].position_current)
		rl.BeginMode2D(camera)
        //rl.DrawTexture(platform_texture, 200, 200, rl.WHITE)
		rl.EndMode2D()
		rl.EndDrawing()
		
		free_all(context.temp_allocator)
	}
	free_all(context.temp_allocator)
}