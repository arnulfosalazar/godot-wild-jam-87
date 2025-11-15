extends Node3D

var held_item: Node3D = null
var toggle_held: bool = false
# Optional offset (if you want to rotate items to fit the player hand)
@export var item_offset: Transform3D = Transform3D.IDENTITY


func is_empty() -> bool:
	return held_item == null


func hold_item(item: Node3D) -> void:
	if held_item != null:
		return  # hand already full

	held_item = item
	item.reparent(self)

	# Snap item to the socket
	item.transform = item_offset


func drop_item(new_parent: Node = null) -> Node3D:
	if held_item == null:
		return null

	var dropped = held_item

	# If no parent provided, drop into the current scene root
	if new_parent == null:
		new_parent = get_tree().current_scene

	dropped.reparent(new_parent)
	held_item = null

	return dropped


func remove_item() -> void:
	# Used if the item destroys itself (e.g., consumed)
	if held_item:
		held_item = null
