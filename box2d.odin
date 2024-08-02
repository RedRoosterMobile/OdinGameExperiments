package main

// custom physics https://github.com/johnBuffer/VerletSFML
import b2 "box2d"
import "core:fmt"
import rl "vendor:raylib"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
TIME_STEP: f64 : 1.0 / 60.0

Shape :: enum {
  Circle,
  Box,
}

Body :: struct {
  shape: Shape,
  id:    b2.Body_ID,
}

state := struct {
  world_id:      b2.World_ID,
  ground_id:     b2.Body_ID,
  ground_rect:   rl.Rectangle,
  box_width:     f32,
  box_height:    f32,
  circle_radius: f32,
  bodies:        [dynamic]Body,
} {
  ground_rect   = {0, 0, 1280, 120},
  box_width     = 20,
  box_height    = 20,
  circle_radius = 10,
}

shape_def := b2.Shape_Def {
  filter = {category_bits = 1, mask_bits = 4294967295}, // b2.default_shape_def()
  // enable_sensor_events = true, // b2.default_shape_def()
  enable_contact_events = true, // b2.default_shape_def()
  friction = 0.5,
  density = 1,
  restitution = 0.5,
}

main :: proc() {
  rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Box2d")
  // NOTE When using SetTargetFPS(60) and my TIME_STEP is 1/60, lag steadily builds from 0.016 to 0.033,
  // and then resest to 0.16. Without the settargetfps, lag hovers around the 0.016 to 0.018 mark
  rl.SetTargetFPS(60)
  rl.SetConfigFlags({.VSYNC_HINT})
  defer rl.CloseWindow()
  // rl_flip_y_axis() // Places origin in bottom-left corner, with up = Y+

  initialize_physics()
  populate_world()
  defer b2.destroy_world(state.world_id)

  // Game loop setup
  previous := rl.GetTime()
  lag: f64 = 0

  for !rl.WindowShouldClose() {
    // Handle game loop timer
    current := rl.GetTime()
    elapsed := current - previous
    previous = current
    lag += elapsed

    processInput()

    // Fixed update
    for lag >= TIME_STEP {
      update()
      lag -= TIME_STEP
    }

    render()
  }
}

initialize_physics :: proc() {
  world_def := b2.default_world_def()
  world_def.restitution_threshold = 0.2
  state.world_id = b2.create_world(&world_def)

  ground_body_def := b2.default_body_def()
  ground_body_def.position = b2.Vec2{state.ground_rect.x, state.ground_rect.y}
  state.ground_id = b2.create_body(state.world_id, &ground_body_def)

  ground_box := b2.make_box(state.ground_rect.width, state.ground_rect.height)
  ground_shape_def := b2.default_shape_def()
  b2.create_polygon_shape(state.ground_id, &ground_shape_def, &ground_box)
}

populate_world :: proc() {
  for i in 0 ..< 20 {
    append(&state.bodies, Body{.Circle, create_shape(state.world_id, .Circle, {100 + f32(i) * 20, 650})})
  }

  px: f32 = 400
  py: f32 = 400
  num_per_row := 10
  num_row := 0

  for _ in 0 ..< 50 {
    append(&state.bodies, Body{.Box, create_shape(state.world_id, .Box, {px, py})})

    num_row += 1

    if num_row == num_per_row {
      py += 30
      px = 200
      num_per_row -= 1
      num_row = 0
    }

    px += 30
  }
}

create_shape :: proc(world_id: b2.World_ID, shape: Shape, pos: b2.Vec2) -> (body_id: b2.Body_ID) {
  body_def := b2.Body_Def {
    gravity_scale = 1, // b2.default_body_def()
    enable_sleep  = true, // b2.default_body_def()
    is_awake      = true, // b2.default_body_def()
    is_enabled    = true, // b2.default_body_def()
    type          = .Dynamic,
    position      = pos,
  }

  body_id = b2.create_body(world_id, &body_def)

  switch shape {
    case .Box:
      box := b2.make_box(state.box_width / 2.0, state.box_height / 2.0)
      b2.create_polygon_shape(body_id, &shape_def, &box)
    case .Circle:
      circle := b2.Circle {
        radius = state.circle_radius,
      }
      b2.create_circle_shape(body_id, &shape_def, &circle)
  }

  return
}

processInput :: proc() {}

update :: proc() {
  // FIXME: playing with these numbers
  b2.world_step(state.world_id, 0.1, 10)
}

render :: proc() {
  rl.BeginDrawing()
  defer rl.EndDrawing()
  rl.ClearBackground({12, 34, 45, 255})

  // Draw ground
  rl.DrawRectangleRec(state.ground_rect, rl.RED)

  // Draw bodies
  for body in state.bodies {
    position := b2.body_get_position(body.id)

    switch body.shape {
      case .Box:
        angle := b2.body_get_angle(body.id) * (180 / 3.14)
        rl.DrawRectanglePro(
          {position.x, position.y, state.box_width, state.box_height},
          {state.box_width / 2.0, state.box_height / 2.0},
          angle,
          rl.YELLOW,
        )
      case .Circle:
        rl.DrawCircleV(position, state.circle_radius, rl.GREEN)
    }
  }
}