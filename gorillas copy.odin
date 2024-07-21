package gorillas

import "core:fmt"
import "core:math"
import "core:math/rand"
import "vendor:raylib"


PLATFORM_WEB := true

MAX_BUILDINGS :: 15
MAX_EXPLOSIONS :: 200
MAX_PLAYERS :: 2

BUILDING_RELATIVE_ERROR: i32 = 30
BUILDING_MIN_RELATIVE_HEIGHT: i32 = 20
BUILDING_MAX_RELATIVE_HEIGHT: i32 = 60
BUILDING_MIN_GRAYSCALE_COLOR: i32 = 120
BUILDING_MAX_GRAYSCALE_COLOR: i32 = 200

MIN_PLAYER_POSITION: i32 = 5
MAX_PLAYER_POSITION: i32 = 20

GRAVITY := 9.81
DELTA_FPS := 60.001

Player :: struct {
	position:       raylib.Vector2,
	size:           raylib.Vector2,
	aiming_point:   raylib.Vector2,
	aiming_angle:   i32,
	aiming_power:   i32,
	previous_point: raylib.Vector2,
	previous_angle: i32,
	previous_power: i32,
	impact_point:   raylib.Vector2,
	is_left_team:   bool,
	is_player:      bool,
	is_alive:       bool,
}

Building :: struct {
	rectangle: raylib.Rectangle,
	color:     raylib.Color,
}

Explosion :: struct {
	position: raylib.Vector2,
	radius:   i32,
	active:   bool,
}

Ball :: struct {
	position: raylib.Vector2,
	speed:    raylib.Vector2,
	radius:   i32,
	active:   bool,
}

randIntn :: proc(min: i32, max: i32) -> i32 {
	return min + (rand.int31() % (max - min + 1))

}

screen_width: i32 = 800
screen_height: i32 = 450

game_over: bool = false
pause: bool = false

player: [MAX_PLAYERS]Player
building: [MAX_BUILDINGS]Building
explosion: [MAX_EXPLOSIONS]Explosion
ball: Ball

player_turn: i32 = 0
ball_on_air: bool = false

init_game :: proc() {
	ball.radius = 10
	ball_on_air = false
	ball.active = false

	init_buildings()
	init_players()

	for i in 0 ..< MAX_EXPLOSIONS {
		explosion[i].position = raylib.Vector2{0.0, 0.0}
		explosion[i].radius = 30
		explosion[i].active = false
	}
}

update_game :: proc() {
	if !game_over {
		if raylib.IsKeyPressed(.P) {
			pause = !pause
		}

		if !pause {
			if !ball_on_air {
				ball_on_air = update_player(player_turn)
			} else {
				if update_ball(player_turn) {
					left_team_alive: bool = false
					right_team_alive: bool = false

					for i in 0 ..< MAX_PLAYERS {
						if player[i].is_alive {
							if player[i].is_left_team {
								left_team_alive = true
							} else {
								right_team_alive = true
							}
						}
					}

					if left_team_alive && right_team_alive {
						ball_on_air = false
						ball.active = false
						player_turn += 1
						if player_turn == i32(MAX_PLAYERS) {
							player_turn = 0
						}
					} else {
						game_over = true
					}
				}
			}
		}
	} else {
		if raylib.IsKeyPressed(.ENTER) {
			init_game()
			game_over = false
		}
	}
}

draw_game :: proc() {
	raylib.BeginDrawing()
	

	raylib.ClearBackground(raylib.RAYWHITE)

	if !game_over {
		for i in 0 ..< MAX_BUILDINGS {
			raylib.DrawRectangleRec(building[i].rectangle, building[i].color)
		}

		for i in 0 ..< MAX_EXPLOSIONS {
			if explosion[i].active {
				raylib.DrawCircle(
					i32(explosion[i].position.x),
					i32(explosion[i].position.y),
					f32(explosion[i].radius),
					raylib.RAYWHITE,
				)
			}
		}

		for i in 0 ..< MAX_PLAYERS {
			if player[i].is_alive {
				// color := if player[i].is_left_team { raylib.BLUE } else { raylib.RED }
				color := raylib.WHITE
				if player[i].is_left_team {
					color = raylib.BLUE
				} else {
					color = raylib.RED
				}
				raylib.DrawRectangle(
					i32(player[i].position.x - player[i].size.x / 2),
					i32(player[i].position.y - player[i].size.y / 2),
					i32(player[i].size.x),
					i32(player[i].size.y),
					color,
				)
			}
		}

		if ball.active {
			raylib.DrawCircle(
				i32(ball.position.x),
				i32(ball.position.y),
				f32(ball.radius),
				raylib.MAROON,
			)
		}

		if !ball_on_air {
			if player[player_turn].is_left_team {
				raylib.DrawTriangle(
					raylib.Vector2 {
						player[player_turn].position.x - player[player_turn].size.x / 4,
						player[player_turn].position.y - player[player_turn].size.y / 4,
					},
					raylib.Vector2 {
						player[player_turn].position.x + player[player_turn].size.x / 4,
						player[player_turn].position.y + player[player_turn].size.y / 4,
					},
					player[player_turn].previous_point,
					raylib.GRAY,
				)

				raylib.DrawTriangle(
					raylib.Vector2 {
						player[player_turn].position.x - player[player_turn].size.x / 4,
						player[player_turn].position.y - player[player_turn].size.y / 4,
					},
					raylib.Vector2 {
						player[player_turn].position.x + player[player_turn].size.x / 4,
						player[player_turn].position.y + player[player_turn].size.y / 4,
					},
					player[player_turn].aiming_point,
					raylib.DARKBLUE,
				)
			} else {
				raylib.DrawTriangle(
					raylib.Vector2 {
						player[player_turn].position.x - player[player_turn].size.x / 4,
						player[player_turn].position.y + player[player_turn].size.y / 4,
					},
					raylib.Vector2 {
						player[player_turn].position.x + player[player_turn].size.x / 4,
						player[player_turn].position.y - player[player_turn].size.y / 4,
					},
					player[player_turn].previous_point,
					raylib.GRAY,
				)

				raylib.DrawTriangle(
					raylib.Vector2 {
						player[player_turn].position.x - player[player_turn].size.x / 4,
						player[player_turn].position.y + player[player_turn].size.y / 4,
					},
					raylib.Vector2 {
						player[player_turn].position.x + player[player_turn].size.x / 4,
						player[player_turn].position.y - player[player_turn].size.y / 4,
					},
					player[player_turn].aiming_point,
					raylib.MAROON,
				)
			}
		}

		if pause {
			raylib.DrawText(
				"GAME PAUSED",
				screen_width / 2 - raylib.MeasureText("GAME PAUSED", 40) / 2,
				screen_height / 2 - 40,
				40,
				raylib.GRAY,
			)
		}
	} else {
		raylib.DrawText(
			"PRESS [ENTER] TO PLAY AGAIN",
			raylib.GetScreenWidth() / 2 -
			raylib.MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20) / 2,
			raylib.GetScreenHeight() / 2 - 50,
			20,
			raylib.GRAY,
		)
	}
    raylib.EndDrawing()
}

unload_game :: proc() {
}

update_draw_frame :: proc() {
	update_game()
	draw_game()
}

init_buildings :: proc() {
	current_width: i32 = 0
	relative_width: f32 = f32(100.0) / (f32(100.0) - f32(BUILDING_RELATIVE_ERROR))
	building_width_mean: f32 = (f32(screen_width) * relative_width / f32(MAX_BUILDINGS)) + 1.0

	for i in 0 ..< MAX_BUILDINGS {
		building[i].rectangle.x = f32(current_width)
		building[i].rectangle.width = f32(
			randIntn(
				i32(building_width_mean * f32((100 - BUILDING_RELATIVE_ERROR / 2) / 100 + 1)),
				i32(building_width_mean) * i32((100 + BUILDING_RELATIVE_ERROR) / 100),
			),
		)

		current_width += i32(building[i].rectangle.width)
		current_heighth: i32 = randIntn(BUILDING_MIN_RELATIVE_HEIGHT, BUILDING_MAX_RELATIVE_HEIGHT)
		building[i].rectangle.y = f32(screen_height - (screen_height * current_heighth / 100))
		building[i].rectangle.height = f32(screen_height * current_heighth / 100 + 1)
		gray_level: i32 = randIntn(BUILDING_MIN_GRAYSCALE_COLOR, BUILDING_MAX_GRAYSCALE_COLOR)
		building[i].color = raylib.Color{u8(gray_level), u8(gray_level), u8(gray_level), 255}
	}
}

init_players :: proc() {
	for i in 0 ..< MAX_PLAYERS {
		player[i].is_alive = true
		player[i].is_left_team = (i % 2 == 0)
		player[i].is_player = true
		player[i].size = raylib.Vector2{40, 40}
		if player[i].is_left_team {
			player[i].position.x = f32(
				randIntn(
					screen_width * MIN_PLAYER_POSITION / 100,
					screen_width * MAX_PLAYER_POSITION / 100,
				),
			)
		} else {
			player[i].position.x = f32(
				screen_width -
				randIntn(
					screen_width * MIN_PLAYER_POSITION / 100,
					screen_width * MAX_PLAYER_POSITION / 100,
				),
			)
		}

		for j in 0 ..< MAX_BUILDINGS {
			if building[j].rectangle.x > player[i].position.x {
				player[i].position.x =
					building[j - 1].rectangle.x + building[j - 1].rectangle.width / 2
				player[i].position.y = building[j - 1].rectangle.y - player[i].size.y / 2
				break
			}
		}

		player[i].aiming_point = player[i].position
		player[i].previous_angle = 0
		player[i].previous_power = 0
		player[i].previous_point = player[i].position
		player[i].aiming_angle = 0
		player[i].aiming_power = 0
		player[i].impact_point = raylib.Vector2{-100, -100}
	}
}

update_player :: proc(player_turn: i32) -> bool {
	if raylib.GetMousePosition().y <= player[player_turn].position.y {
		if player[player_turn].is_left_team &&
		   raylib.GetMousePosition().x >= player[player_turn].position.x {
			player[player_turn].aiming_power = i32(
				math.sqrt(
					math.pow(
						f64(player[player_turn].position.x - raylib.GetMousePosition().x),
						2.0,
					) +
					math.pow(
						f64(player[player_turn].position.y - raylib.GetMousePosition().y),
						2.0,
					),
				),
			)
			player[player_turn].aiming_angle = i32(
				math.asin(
					(player[player_turn].position.y - raylib.GetMousePosition().y) /
					f32(player[player_turn].aiming_power),
				) *
				raylib.RAD2DEG,
			)
			player[player_turn].aiming_point = raylib.GetMousePosition()

			if raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT) {
				player[player_turn].previous_point = player[player_turn].aiming_point
				player[player_turn].previous_power = player[player_turn].aiming_power
				player[player_turn].previous_angle = player[player_turn].aiming_angle
				ball.position = player[player_turn].position
				return true
			}
		} else if !player[player_turn].is_left_team &&
		   raylib.GetMousePosition().x <= player[player_turn].position.x {
			player[player_turn].aiming_power = i32(
				math.sqrt(
					math.pow(
						f64(player[player_turn].position.x - raylib.GetMousePosition().x),
						2.0,
					) +
					math.pow(
						f64(player[player_turn].position.y - raylib.GetMousePosition().y),
						2.0,
					),
				),
			)
			player[player_turn].aiming_angle = i32(
				math.asin(
					(player[player_turn].position.y - raylib.GetMousePosition().y) /
					f32(player[player_turn].aiming_power),
				) *
				raylib.RAD2DEG,
			)
			player[player_turn].aiming_point = raylib.GetMousePosition()

			if raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT) {
				player[player_turn].previous_point = player[player_turn].aiming_point
				player[player_turn].previous_power = player[player_turn].aiming_power
				player[player_turn].previous_angle = player[player_turn].aiming_angle
				ball.position = player[player_turn].position
				return true
			}
		} else {
			player[player_turn].aiming_point = player[player_turn].position
			player[player_turn].aiming_power = 0
			player[player_turn].aiming_angle = 0
		}
	} else {
		player[player_turn].aiming_point = player[player_turn].position
		player[player_turn].aiming_power = 0
		player[player_turn].aiming_angle = 0
	}

	return false
}

update_ball :: proc(player_turn: i32) -> bool {
	explosion_number: i32 = 0

	if !ball.active {
		if player[player_turn].is_left_team {
			ball.speed.x = f32(
				math.cos(f64(player[player_turn].previous_angle) * raylib.DEG2RAD) *
				f64(player[player_turn].previous_power * 3 / i32(DELTA_FPS)),
			)
			ball.speed.y = f32(
				-math.sin(f64(player[player_turn].previous_angle) * raylib.DEG2RAD) *
				f64(player[player_turn].previous_power * 3 / i32(DELTA_FPS)),
			)
			ball.active = true
		} else {
			ball.speed.x = f32(
				-math.cos(f64(player[player_turn].previous_angle) * raylib.DEG2RAD) *
				f64(player[player_turn].previous_power * 3 / i32(DELTA_FPS)),
			)
			ball.speed.y = f32(
				-math.sin(f64(player[player_turn].previous_angle) * raylib.DEG2RAD) *
				f64(player[player_turn].previous_power * 3 / i32(DELTA_FPS)),
			)
			ball.active = true
		}
	}

	ball.position.x += ball.speed.x
	ball.position.y += ball.speed.y
	ball.speed.y += f32(GRAVITY / DELTA_FPS)

	if ball.position.x + f32(ball.radius) < 0 {
		return true
	} else if ball.position.x - f32(ball.radius) > f32(screen_width) {
		return true
	} else {
		for i in 0 ..< MAX_PLAYERS {
			if raylib.CheckCollisionCircleRec(
				ball.position,
				f32(ball.radius),
				raylib.Rectangle {
					player[i].position.x - player[i].size.x / 2,
					player[i].position.y - player[i].size.y / 2,
					player[i].size.x,
					player[i].size.y,
				},
			) {
				if i32(i) == player_turn {
					return false
				} else {
					player[player_turn].impact_point.x = ball.position.x
					player[player_turn].impact_point.y = ball.position.y + f32(ball.radius)
					player[i].is_alive = false
					return true
				}
			}
		}

		for i in 0 ..< MAX_EXPLOSIONS {
			if raylib.CheckCollisionCircles(
				ball.position,
				f32(ball.radius),
				explosion[i].position,
				f32(explosion[i].radius - ball.radius),
			) {
				return false
			}
		}

		for i in 0 ..< MAX_BUILDINGS {
			if raylib.CheckCollisionCircleRec(
				ball.position,
				f32(ball.radius),
				building[i].rectangle,
			) {
				player[player_turn].impact_point.x = ball.position.x
				player[player_turn].impact_point.y = ball.position.y + f32(ball.radius)
				explosion[explosion_number].position = player[player_turn].impact_point
				explosion[explosion_number].active = true
				explosion_number += 1
				return true
			}
		}
	}

	return false
}

main :: proc() {
	raylib.InitWindow(screen_width, screen_height, "classic game: gorilas")
	defer raylib.CloseWindow()

	init_game()
	raylib.SetTargetFPS(60)

	for !raylib.WindowShouldClose() {
		update_draw_frame()
	}

	unload_game()
}
