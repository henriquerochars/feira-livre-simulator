class_name PlayerController
extends CharacterBody3D

const WALK_SPEED: float = 4.4
const SPRINT_SPEED: float = 6.8
const SENSITIVITY: float = 0.0022
var camera: Camera3D
var enabled: bool = false
var pitch: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.75
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = 78.0
	camera.near = 0.06
	add_child(camera)

func reset_position() -> void:
	position = Vector3(0.0, 0.12, 2.55)
	rotation = Vector3.ZERO
	pitch = -0.06
	camera.rotation.x = pitch
	velocity = Vector3.ZERO

func accepts_input() -> bool:
	# The dummy display cannot capture a mouse; scripted headless input still works.
	return enabled and (DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSITIVITY)
		pitch = clampf(pitch - event.relative.y * SENSITIVITY, -1.35, 1.35)
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	if accepts_input():
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = 7.0
		var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := global_basis * Vector3(movement.x, 0.0, movement.y)
		var speed: float = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	if position.y < -8.0:
		reset_position()
