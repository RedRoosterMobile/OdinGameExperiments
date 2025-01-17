package verlet
import "core:math/linalg"
import rl "vendor:raylib"

// Define the VerletObject structure
VerletObject :: struct {
	position:      rl.Vector2,
	position_last: rl.Vector2,
	acceleration:  rl.Vector2,
	radius:        f32,
	color:         rl.Color,
}

// Define initializers for VerletObject
verlet_object_init :: proc() -> VerletObject {
	return VerletObject {
		position = rl.Vector2{},
		position_last = rl.Vector2{},
		acceleration = rl.Vector2{},
		radius = 10.0,
		color = rl.WHITE,
	}
}

verlet_object_init_position_radius :: proc(position_: rl.Vector2, radius_: f32) -> VerletObject {
	return VerletObject {
		position = position_,
		position_last = position_,
		acceleration = rl.Vector2{},
		radius = radius_,
		color = rl.WHITE,
	}
}

// Define methods for VerletObject
verlet_object_update :: proc(v: ^VerletObject, dt: f32) {
	displacement := v.position - v.position_last
	v.position_last = v.position
	v.position = rl.Vector2Add(
		v.position,
		rl.Vector2Add(displacement, rl.Vector2Scale(v.acceleration, dt * dt)),
	)
	v.acceleration = rl.Vector2{}
}

verlet_object_accelerate :: proc(v: ^VerletObject, a: rl.Vector2) {
	v.acceleration = rl.Vector2Add(v.acceleration, a)
}

verlet_object_setVelocity :: proc(v: ^VerletObject, velocity: rl.Vector2, dt: f32) {
	v.position_last = rl.Vector2Subtract(v.position, rl.Vector2Scale(velocity, dt))
}

verlet_object_addVelocity :: proc(v: ^VerletObject, velocity: rl.Vector2, dt: f32) {
	v.position_last = rl.Vector2Subtract(v.position_last, rl.Vector2Scale(velocity, dt))
}

verlet_object_getVelocity :: proc(v: ^VerletObject, dt: f32) -> rl.Vector2 {
	return rl.Vector2Scale(rl.Vector2Subtract(v.position, v.position_last), 1.0 / dt)
}

// Define the Solver structure
Solver :: struct {
	sub_steps:         u32,
	gravity:           rl.Vector2,
	constraint_center: rl.Vector2,
	constraint_radius: f32,
	objects:           [dynamic]VerletObject,
	time:              f32,
	frame_dt:          f32,
}

// Define initializers for Solver
solver_init :: proc() -> Solver {
	return Solver {
		sub_steps = 1,
		gravity = rl.Vector2{0.0, 1000.0},
		constraint_center = rl.Vector2{1260 / 2, 0},
		constraint_radius = 500.0,
		objects = make([dynamic]VerletObject, 0),
		time = 0.0,
		frame_dt = 0.0,
	}
}

// Define methods for Solver
solver_addObject :: proc(s: ^Solver, position: rl.Vector2, radius: f32) -> ^VerletObject {
	obj := verlet_object_init_position_radius(position, radius)
	append(&s.objects, obj)
	return &s.objects[len(s.objects) - 1]
}

solver_update :: proc(s: ^Solver) {
	s.time += s.frame_dt
	step_dt := s.frame_dt / f32(s.sub_steps)
	for i := s.sub_steps; i > 0; i -= 1 {
		//for i := u32(0); i < s.sub_steps; i += 1 {
		solver_applyGravity(s)
		solver_checkCollisions(s, step_dt)
		solver_applyConstraint(s)
		solver_updateObjects(s, step_dt)
	}
}

solver_setSimulationUpdateRate :: proc(s: ^Solver, rate: u32) {
	s.frame_dt = 1.0 / f32(rate)
}

solver_setConstraint :: proc(s: ^Solver, position: rl.Vector2, radius: f32) {
	s.constraint_center = position
	s.constraint_radius = radius
}

solver_setSubStepsCount :: proc(s: ^Solver, sub_steps: u32) {
	s.sub_steps = sub_steps
}

solver_setObjectVelocity :: proc(s: ^Solver, object: ^VerletObject, velocity: rl.Vector2) {
	verlet_object_setVelocity(object, velocity, s.frame_dt / f32(s.sub_steps))
}

solver_getObjects :: proc(s: ^Solver) -> ^[dynamic]VerletObject {
	return &s.objects
}

solver_getConstraint :: proc(s: ^Solver) -> rl.Vector3 {
	return rl.Vector3{s.constraint_center.x, s.constraint_center.y, s.constraint_radius}
}

solver_getObjectsCount :: proc(s: ^Solver) -> u64 {
	return u64(len(s.objects))
}

solver_getTime :: proc(s: ^Solver) -> f32 {
	return s.time
}

solver_getStepDt :: proc(s: ^Solver) -> f32 {
	return s.frame_dt / cast(f32)(s.sub_steps)
}

solver_applyGravity :: proc(s: ^Solver) {
	for &obj in &s.objects {
		verlet_object_accelerate(&obj, s.gravity)
	}
}

solver_checkCollisions :: proc(s: ^Solver, dt: f32) {
	response_coef := 0.75
	objects_count := len(s.objects)
	for i := 0; i < objects_count; i += 1 {
		object_1 := &s.objects[i]
		for k := i + 1; k < objects_count; k += 1 {
			object_2 := &s.objects[k]
			//v := rl.Vector2Subtract(object_1.position, object_2.position);
			v := object_1.position - object_2.position
			dist2 := v.x * v.x + v.y * v.y
			min_dist := object_1.radius + object_2.radius
			if dist2 < min_dist * min_dist {
				dist := linalg.sqrt(dist2)
				//n := rl.Vector2Scale(v, 1.0 / dist)
				n := (v * 1.0) / dist
				mass_ratio_1 := object_1.radius / (object_1.radius + object_2.radius)
				mass_ratio_2 := object_2.radius / (object_1.radius + object_2.radius)
				delta := 0.5 * response_coef * f64(dist - min_dist)
				// object_1.position = rl.Vector2Subtract(
				// 	object_1.position,
				// 	rl.Vector2Scale(n, mass_ratio_2 * delta),
				// )
				object_1.position = object_1.position - (n * (mass_ratio_2 * f32(delta)))
				object_2.position = rl.Vector2Add(
					object_2.position,
					rl.Vector2Scale(n, mass_ratio_1 * f32(delta)),
				)
			}
		}
	}
}

solver_applyConstraint :: proc(s: ^Solver) {
	for &obj in &s.objects {
		v := rl.Vector2Subtract(s.constraint_center, obj.position)
		dist := linalg.sqrt(v.x * v.x + v.y * v.y)
		if dist > (s.constraint_radius - obj.radius) {
			n := rl.Vector2Scale(v, 1.0 / dist)
			obj.position = rl.Vector2Subtract(
				s.constraint_center,
				rl.Vector2Scale(n, s.constraint_radius - obj.radius),
			)
		}
	}
}

solver_updateObjects :: proc(s: ^Solver, dt: f32) {
	for &obj in &s.objects {
		verlet_object_update(&obj, dt)
	}
}
