extends Node
@onready var main: Node = get_tree().get_root().get_node("main")

func _ready():
	# Assign the game viewport to the main window
	main.scene_viewport.size.x = 1280
	main.scene_viewport.size.y = 768
	get_node("main_window/texture_rect").texture = main.scene_viewport.get_texture()
	
func _process(_delta):
	if not main.config.get_value("devices.screens.single_screen.enabled"):
		queue_free()
