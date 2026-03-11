extends Control

# -------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------
var SIMULATOR_USERS_FILENAME = "user://simulator_users.json"
var PLAYABLE_SCENES_FOLDER_PATH = "res://playable_scenes"

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------
@onready var main: Node = get_tree().get_root().get_node("main")
@onready var config: Node = main.get_node("config")


# --- Scene Buttons ---
var scene_button := preload("scene_button.tscn")
@export var scene_container: GridContainer

# --- Settings ---
@export var _dbox_toggle: CheckButton
@export var _floor_cam_toggle: CheckButton
@export var _motors_toggle: CheckButton
var _parameters := {
	"has_dbox": true,
	"has_floor_cam": true,
	"has_motors": true,
}


func _ready() -> void:	
	_create_scene_buttons()

func get_player() -> RigidBody3D:
	for item in get_tree().get_root().get_children():
		var player = item.get_node_or_null("player")
		if player:
			return player
	return null
	



# -------------------------------------------------------------------
# Load scenes
# -------------------------------------------------------------------
## Create all the scene buttons with their thumbnail if they exist.
func _create_scene_buttons()->void:
	var dir := DirAccess.open(PLAYABLE_SCENES_FOLDER_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				var scene_path = PLAYABLE_SCENES_FOLDER_PATH + "/" + file_name
				
				var _scene_button_instance := scene_button.instantiate()				
				_scene_button_instance.set_meta("scene_path", scene_path)
				
				#Label of the button
				var label: Label = _scene_button_instance.get_node_or_null("Label")
				var name_without_ext = file_name.trim_suffix(".tscn")
				var display_name = name_without_ext.capitalize()
				if label:
					label.text = display_name
					
				#Thumbnail of the button
				var image_path = PLAYABLE_SCENES_FOLDER_PATH + "/" + name_without_ext + ".png"
				var image := load(image_path)
				var thumbail: TextureRect = _scene_button_instance.get_node_or_null("Thumbnail")
				if thumbail:
					thumbail.texture = image
				
				#Button connection to scene instantiation
				_scene_button_instance.pressed.connect(
					func():
						var path = _scene_button_instance.get_meta("scene_path")
						main.load_scene(path)
				)
				scene_container.add_child(_scene_button_instance)
				
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Error while opening PlayableScenes folder")

## TODO Being replaced by main/load_scene. Enter the selected scene
func _enter_scene(scene_instance: Node3D)->void:
	pass
#
	## Quit the current scene if there is one loaded
	#if _current_scene_node:
		#_current_scene_node.queue_free()
#
	#_current_scene_node = scene_instance
#
	#await get_tree().process_frame
	#await get_tree().process_frame
	#
	#get_tree().get_root().add_child(scene_instance)
	#var floor_window := scene_instance.get_node_or_null("player/floor_projector") as Window
	#var motors := scene_instance.get_node_or_null("player/motors")
	#var dbox := scene_instance.get_node_or_null("player/dbox")
#
	#var screen_count: int = DisplayServer.get_screen_count()
	#
	#if _parameters["has_floor_cam"]:
		#if floor_window and screen_count > 1:
			#_set_window_full_screen(floor_window, 1)
	#else:
		#if floor_window:
			#floor_window.queue_free()
	#if (not _parameters["has_dbox"]) and (dbox != null):
		#dbox.queue_free()
	#if (not _parameters["has_motors"]) and (motors != null):
		#motors.queue_free()
#
	#var front_window := scene_instance.get_node_or_null("player/front_projector") as Window
	#if front_window and screen_count > 2:
		#_set_window_full_screen(front_window, 2)
		#
	#update_selected_patient_mass()

## Set a window full screen on the selected screen.
func _set_window_full_screen(win: Window, screen_index: int) -> void:
	win.set_current_screen(screen_index)
	win.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	_fit_subviewport_to_window(win)
	if not win.is_connected("size_changed", Callable(self, "_on_display_window_resized")):
		win.size_changed.connect(_on_display_window_resized.bind(win))

func _fit_subviewport_to_window(win: Window) -> void:
	var container := win.get_node_or_null("SubViewportContainer") as SubViewportContainer
	if container:
		# Godot 4 -> utiliser set_anchors_preset, pas anchors_preset(...)
		container.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		container.offset_left = 0
		container.offset_top = 0
		container.offset_right = 0
		container.offset_bottom = 0

	var sv := win.get_node_or_null("SubViewportContainer/SubViewport") as SubViewport
	if sv:
		sv.size = Vector2i(win.size.x, win.size.y)
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sv.disable_3d = false
		sv.own_world_3d = false

func _on_display_window_resized(win: Window) -> void:
	var sv := win.get_node_or_null("SubViewportContainer/SubViewport") as SubViewport
	if sv:
		sv.size = Vector2i(win.size.x, win.size.y)


func _on_button_stop_pressed() -> void:
	# TODO remove call to private variable
	if main._current_scene_node:
		main.unload_scene()
	else:
		get_tree().quit()


# -------------------------------------------------------------------
# DBox : manuel + maintien
# -------------------------------------------------------------------


func _on_motors_toggle_toggled(toggled_on: bool) -> void:
	config.set_value("motors.enabled", toggled_on)

	
func _on_dbox_toggle_toggled(toggled_on: bool) -> void:
	config.set_value("d_box.enabled", toggled_on)


func _on_onboard_button_pressed() -> void:
	var player := get_player()
	if player:
		player.current_mode = player.CurrentMode.ONBOARDING
	else:
		print("Launch a scene before clicking this button.")

func _on_play_button_pressed() -> void:
	var player := get_player()
	if player:
		player.current_mode = player.CurrentMode.PLAYING
	else:
		print("Launch a scene before clicking this button.")
