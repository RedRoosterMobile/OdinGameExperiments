package main

import "core:fmt"
import "core:os"
import rl "vendor:raylib"

main :: proc() {
	// x :: "what" // constant `x` has the untyped string value "what"

	// fmt.println("Hellope!")
	// fmt.println(len("Foo"))
	// fmt.println(x)

	// //for i := 0; i < 10; i += 1 {
	// for i in 0 ..< 10 {
	// 	fmt.println(i)
	// }
	// some_string := "Hello, 世界"
	// for character in some_string {
	// 	fmt.println(character)
	// }

	rl.InitWindow(640, 480, "Destructible")
	// rl.SetExitKey(.KEY_NULL)
	rl.SetTargetFPS(60)

	player_pos := rl.Vector2{320, 240}
    player_vel := rl.Vector2{0, 0}
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({55, 55, 55, 255})

		if (rl.IsKeyDown(.LEFT)) {
			player_pos.x += 100 * rl.GetFrameTime()
		} else if (rl.IsKeyDown(.RIGHT)) {
			player_pos.x -= 100 * rl.GetFrameTime()
		}

		rl.DrawRectangleV(player_pos, {64, 64}, rl.BLUE)
		rl.EndDrawing()
	}
}
