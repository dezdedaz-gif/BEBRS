extends CharacterBody3D

const SPEED := 2.9
const GRAVITY := 20.0

var game
var model
var facing: float = 0.0
var speed_mult: float = 1.0  # сломанные ноги замедляют (система повреждений)
var dash_t: float = 0.0  # рывок / выпад: оставшееся время
var dash_dir: Vector3 = Vector3.ZERO
var scripted: bool = false  # катсцена двигает героя сама (концовка)

func setup(g, m) -> void:
	game = g
	model = m
	add_child(model)
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.26
	shape.height = 1.2
	cs.shape = shape
	cs.position.y = 0.6
	add_child(cs)

func _physics_process(delta: float) -> void:
	# в укрытии (клетка, стол) герой сидит на месте, позицию задаёт игра
	if scripted or (game != null and game.action != null and (game.action.hiding != "" or game.action._moving_hide)):
		velocity = Vector3.ZERO
		return
	if dash_t > 0.0:
		dash_t = maxf(0.0, dash_t - delta)
		var sp := SPEED * 3.1 * (0.45 + dash_t / 0.3 * 0.55)
		velocity = Vector3(dash_dir.x * sp, -0.5, dash_dir.z * sp)
		move_and_slide()
		model.move_amount = 1.0
		return
	var dir := Vector2.ZERO
	if game != null and not game.input_locked():
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var tv: Vector2 = game.touch_vector()
		if tv.length() > dir.length():
			dir = tv
	velocity.x = dir.x * SPEED * speed_mult
	velocity.z = dir.y * SPEED * speed_mult
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var c := col.get_collider()
		if c is RigidBody3D:
			var n := col.get_normal()
			(c as RigidBody3D).apply_central_impulse(Vector3(-n.x, 0.0, -n.z) * 1.4 * (c as RigidBody3D).mass * delta * 6.0)
	if dir.length() > 0.1:
		facing = lerp_angle(facing, atan2(dir.x, dir.y), clampf(12.0 * delta, 0.0, 1.0))
		model.rotation.y = facing
	model.move_amount = clampf(dir.length(), 0.0, 1.0)
