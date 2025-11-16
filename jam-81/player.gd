extends CharacterBody3D

@export var SPEED := 5.0
@export var JUMP_VELOCITY := 4.5
@export var mouse_sensitivity := 0.003

@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)

@onready var camera := $("Camera3D")
@onready var hand := $("HANDS")
@onready var handplacement := $("HANDPlacement")
@onready var interaction_ui := $"UI/InteractionUI"
@onready var item_name_label := $"UI/InteractionUI/ItemNameLabel"
@onready var placement_highlight := $"PlacementHighlight"

var _mouse_input : bool = true
var hovered_item: Node3D = null
var placement_mode: bool = false
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
	if event.is_action_pressed("JUMP") and hand.held_item != null:
		# Alternative drop method - drop immediately with space
		drop_item()


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
	_check_item_hover()
	_update_placement_highlight()

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
		if placement_mode:
			place_item()
		else:
			toggle_placement_mode()
		return

	# Increased range for easier pickup
	var ray := RayCast3D.new()
	ray.target_position = Vector3(0, 0, -4)  # Doubled the range
	ray.collide_with_areas = true
	ray.collide_with_bodies = true

	camera.add_child(ray)
	ray.force_raycast_update()

	if ray.is_colliding():
		var item := ray.get_collider()
		if item and item.is_in_group("pickup"):
			hand.hold_item(item)
			_hide_interaction_ui()

	ray.queue_free()
	



func drop_item() -> void:
	if hand.held_item == null:
		return
		
	var dropped_item = hand.drop_item()
	if dropped_item:
		# Position the dropped item in front of the player
		dropped_item.global_transform.origin = camera.global_transform.origin + (-camera.global_transform.basis.z * 2.0)
		hand.toggle_held = false
		placement_mode = false
		_hide_placement_highlight()

func _check_item_hover() -> void:
	var ray := RayCast3D.new()
	ray.target_position = Vector3(0, 0, -4)
	ray.collide_with_areas = true
	ray.collide_with_bodies = true

	camera.add_child(ray)
	ray.force_raycast_update()

	var new_hovered_item: Node3D = null
	if ray.is_colliding():
		var item := ray.get_collider()
		if item and item.is_in_group("pickup") and hand.held_item == null:
			new_hovered_item = item

	if new_hovered_item != hovered_item:
		_update_hover_highlight(hovered_item, new_hovered_item)
		hovered_item = new_hovered_item

	ray.queue_free()

func _update_hover_highlight(old_item: Node3D, new_item: Node3D) -> void:
	if old_item and old_item.has_method("set_hover_highlight"):
		old_item.set_hover_highlight(false)

	if new_item:
		if new_item.has_method("set_hover_highlight"):
			new_item.set_hover_highlight(true)
		_show_interaction_ui(new_item)
	else:
		_hide_interaction_ui()

func _show_interaction_ui(item: Node3D) -> void:
	if item.has_method("get_item_name"):
		item_name_label.text = item.get_item_name()
	else:
		item_name_label.text = "Unknown Item"
	
	interaction_ui.visible = true

func _hide_interaction_ui() -> void:
	interaction_ui.visible = false

func toggle_placement_mode() -> void:
	placement_mode = !placement_mode
	if placement_mode:
		_show_placement_highlight()
	else:
		_hide_placement_highlight()

func _show_placement_highlight() -> void:
	placement_highlight.visible = true
	_update_placement_highlight()

func _update_placement_highlight() -> void:
	if placement_mode and placement_highlight.visible:
		# Position the highlight in front of the player
		placement_highlight.global_transform.origin = camera.global_transform.origin + (-camera.global_transform.basis.z * 3.0)

func _hide_placement_highlight() -> void:
	placement_highlight.visible = false

func place_item() -> void:
	if hand.held_item == null:
		return

	var dropped_item = hand.drop_item()
	if dropped_item:
		# Place at highlight position
		dropped_item.global_transform.origin = placement_highlight.global_transform.origin
		placement_mode = false
		_hide_placement_highlight()
