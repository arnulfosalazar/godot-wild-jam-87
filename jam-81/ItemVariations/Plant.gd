extends Item

func _ready():
	super._ready()  # Call parent _ready() to set up pickup group
	item_name = "Space Plant"
	item_type = "Plant"

func on_use(_player) -> void:
	print("Plant picked up: " + item_name)
