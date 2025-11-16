extends Node3D

class_name Item

@export var item_name : String = "Unknown Item"
@export var item_type : String = "Generic"
@export var hover_color : Color = Color.YELLOW
@export var normal_color : Color = Color.WHITE

var mesh_instance: MeshInstance3D
var original_material: Material
var hover_material: StandardMaterial3D
var is_highlighted: bool = false

func _ready():
	# Add to pickup group so player can interact with it
	add_to_group("pickup")
	
	# Find the mesh instance for highlighting
	mesh_instance = find_child("MeshInstance3D")
	if mesh_instance:
		original_material = mesh_instance.get_surface_override_material(0)
		
		# Create hover material
		hover_material = StandardMaterial3D.new()
		hover_material.albedo_color = hover_color
		hover_material.emission_enabled = true
		hover_material.emission = hover_color * 0.3
		hover_material.rim_enabled = true
		hover_material.rim_tint = 0.5

func on_use(_player):
	pass

func get_item_name() -> String:
	return item_name

func get_item_type() -> String:
	return item_type

func set_hover_highlight(enabled: bool) -> void:
	if not mesh_instance:
		return
	
	is_highlighted = enabled
	
	if enabled:
		mesh_instance.set_surface_override_material(0, hover_material)
		# Optional: Add a subtle scale effect
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ONE * 1.1, 0.1)
	else:
		mesh_instance.set_surface_override_material(0, original_material)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ONE, 0.1)
