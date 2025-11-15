extends CharacterBody3D

@export var SPEED := 5.0
@export var JUMP_VELOCITY := 4.5
@export var mouse_sensitivity := 0.003

@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)

@onready var camera := $"Camera3D"
@onready var hand := $"HANDS"
@onready var handplacement := $"HANDPlacement"

var _mouse_input : bool = true
var _mouse_rotation : Vector3 = Vector3.ZERO
var _rotation_input : float = 0.0
var _tilt_input : float = 0.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().quit()
	if event.is_action_pressed("INTERACT"):
		try_pick_up()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_input:
		_rotation_input -= event.relative.x * mouse_sensitivity
		_tilt_input    -= event.relative.y * mouse_sensitivity

func _update_camera(_delta: float) -> void:
	_mouse_rotation.x += _tilt_input
	_mouse_rotation.y += _rotation_input

	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)

	rotation.y = _mouse_rotation.y

	camera.rotation.x = _mouse_rotation.x
	camera.rotation.z = 0.0

	_rotation_input = 0.0
	_tilt_input = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	_update_camera(delta)

	if Input.is_action_just_pressed("JUMP") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Vector2(
		Input.get_action_strength("RIGHT") - Input.get_action_strength("LEFT"),
		Input.get_action_strength("FORWARD") - Input.get_action_strength("BACKWARD")
	)

	var forward := -transform.basis.z
	var right   :=  transform.basis.x
	var move_dir := (forward * input_dir.y + right * input_dir.x).normalized()

	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

#==================================================================================

func try_pick_up() -> void:
	if hand.held_item != null:
		drop_item()
		return
		
	var ray := RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2)
	ray.collide_with_areas = true
	ray.collide_with_bodies = true

	camera.add_child(ray)
	ray.force_raycast_update()

	if ray.is_colliding():
		var item := ray.get_collider()
		if item and item.is_in_group("pickup"):
			hand.hold_item(item)

	ray.queue_free()
	



func drop_item() -> void:
	if hand.held_item == null:
		return
		
	var dropped_item = hand.drop_item()
	if dropped_item:
		# Position the dropped item in front of the player
		dropped_item.global_transform.origin = camera.global_transform.origin + (-camera.global_transform.basis.z * 2.0)
		hand.toggle_held = false
