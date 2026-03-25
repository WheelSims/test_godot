extends Node
@onready var main: Node = get_tree().get_root().get_node("main")

func _ready():
	# Assign the game viewport to the main window
	main.scene_viewport.size.x = 1280
	main.scene_viewport.size.y = 768*2
	get_node("front_window/texture_rect").texture = main.scene_viewport.get_texture()
	get_node("floor_window/texture_rect").texture = main.scene_viewport.get_texture()
	
func _process(_delta):
	if Config.value_changed("front_floor_screens", "devices.screens.front_floor_screens.full_screen.enabled"):
		if Config.get_value("devices.screens.front_floor_screens.full_screen.enabled"):
			var screen_count = DisplayServer.get_screen_count()
			var screen_index = min(screen_count, Config.get_value("devices.screens.front_floor_screens.full_screen.front_screen_index")-1)
			screen_index = max(0, screen_index)
			$front_window.set_current_screen(screen_index)
			$front_window.mode = Window.MODE_FULLSCREEN


			screen_index = min(screen_count, Config.get_value("devices.screens.front_floor_screens.full_screen.floor_screen_index")-1)
			screen_index = max(0, screen_index)
			$floor_window.set_current_screen(screen_index)
			$floor_window.mode = Window.MODE_FULLSCREEN

		else:
			$front_window.mode = Window.MODE_WINDOWED
			$front_window.set_current_screen(0)
			$floor_window.mode = Window.MODE_WINDOWED
			$floor_window.set_current_screen(0)

	if not Config.get_value("devices.screens.front_floor_screens.enabled"):
		queue_free()
