## This script creates one window, sets it (or not) to fullscreen according to its Config value,
## and assigns the main scene's viewport to it.
extends Node
@onready var main: Node = get_tree().get_root().get_node("main")

func _ready():
	# Assign the game viewport to the main window
	main.scene_viewport.size.x = 1280
	main.scene_viewport.size.y = 768
	get_node("MainWindow/TextureRect").texture = main.scene_viewport.get_texture()


func _process(_delta):
	if (
		Config.value_changed("single_screen", "devices.screens.single_screen.full_screen.enabled")
		or Config.value_changed("single_screen", "devices.screens.single_screen.full_screen.screen_index")
	):
		if Config.get_value("devices.screens.single_screen.full_screen.enabled"):
			var screen_count = DisplayServer.get_screen_count()
			var screen_index = min(screen_count, Config.get_value("devices.screens.single_screen.full_screen.screen_index") - 1)
			screen_index = max(0, screen_index)
			$MainWindow.set_current_screen(screen_index)
			$MainWindow.mode = Window.MODE_FULLSCREEN
		else:
			$MainWindow.mode = Window.MODE_WINDOWED

	if not Config.get_value("devices.screens.single_screen.enabled"):
		queue_free()
