extends Node3D

class_name Item

@export var item_name : String
@export var item_type : String

func _ready():
	# Add to pickup group so player can interact with it
	add_to_group("pickup")
	
	# If this is a StaticBody3D or RigidBody3D, it should work with raycast
	# If this is a regular Node3D, we might need collision detection

func on_use(_player):
	pass
