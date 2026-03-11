extends Control

# -------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------
var SIMULATOR_USERS_FILENAME = "user://simulator_users.json"
var PLAYABLE_SCENES_FOLDER_PATH = "res://playable_scenes"




var _current_scene_node: Node3D = null

# --- UI users ---

## Select user_list node in the arborescence
@export var user_list: VBoxContainer

var selected_user
var user_row := preload("user.tscn")

# --- Scene Buttons ---
var scene_button := preload("scene_button.tscn")
@export var scene_container: GridContainer

# --- Settings ---
@export var PREFERENCES_FILENAME = "user://preferences.json"
@export var _dbox_toggle: CheckButton
@export var _floor_cam_toggle: CheckButton
@export var _motors_toggle: CheckButton
var _parameters := {
	"has_dbox": true,
	"has_floor_cam": true,
	"has_motors": true,
}


func _ready() -> void:
	load_users()
	load_preferences()
	_create_scene_buttons()

func get_player() -> RigidBody3D:
	for item in get_tree().get_root().get_children():
		var player = item.get_node_or_null("player")
		if player:
			return player
	return null
	
# -------------------------------------------------------------------
# User management
# -------------------------------------------------------------------
func load_users() -> void:
	if not FileAccess.file_exists(SIMULATOR_USERS_FILENAME):
		return

	var file := FileAccess.open(SIMULATOR_USERS_FILENAME, FileAccess.READ)
	var parsed_v: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed_v) != TYPE_ARRAY:
		printerr("User file " + SIMULATOR_USERS_FILENAME + " seems corrupted.")
		return
	var result: Array = parsed_v

	for user in result:
		var patient: Dictionary = user as Dictionary
		var new_row := user_row.instantiate()

		(new_row.get_node("selected") as CheckBox).button_pressed = bool(patient.get("selected", false))
		(new_row.get_node("name") as LineEdit).text = str(patient.get("name", ""))
		(new_row.get_node("mass") as LineEdit).text = str(patient.get("mass", ""))

		new_row.get_node("selected").connect("toggled", Callable(self, "_on_row_checkbox_toggled").bind(new_row))
		new_row.get_node("name").connect("text_submitted", Callable(self, "save_users"))
		new_row.get_node("name").connect("focus_exited",   Callable(self, "save_users"))
		new_row.get_node("mass").connect("text_submitted", Callable(self, "save_users"))
		new_row.get_node("mass").connect("focus_exited",   Callable(self, "save_users"))

		user_list.add_child(new_row)
		if (new_row.get_node("selected") as CheckBox).button_pressed:
			selected_user = new_row

	#_enforce_single_selection()


func _on_btn_add_user_pressed() -> void:
	var new_row := user_row.instantiate()

	new_row.get_node("name").connect("text_submitted", Callable(self, "save_users"))
	new_row.get_node("name").connect("focus_exited",   Callable(self, "save_users"))
	new_row.get_node("mass").connect("text_submitted", Callable(self, "update_selected_patient_mass"))
	new_row.get_node("mass").connect("focus_exited",   Callable(self, "update_selected_patient_mass"))

	# Sélection unique : bind de la row
	new_row.get_node("selected").connect("toggled", Callable(self, "_on_row_checkbox_toggled").bind(new_row))

	user_list.add_child(new_row)
	save_users()

func _on_btn_remove_user_pressed() -> void:
	if user_list.get_child_count() > 0:
		if not selected_user:
			selected_user = user_list.get_child(user_list.get_child_count() - 1)
		user_list.remove_child(selected_user)
		selected_user.queue_free()
		save_users()
		_enforce_single_selection()

func save_users(_new_text: String = "") -> void:
	var data: Array[Dictionary] = []
	for row in user_list.get_children():
		data.append({
			"name": (row.get_node("name") as LineEdit).text,
			"mass": (row.get_node("mass") as LineEdit).text.to_float(),
			"selected": (row.get_node("selected") as CheckBox).button_pressed,
		})
	var file := FileAccess.open(SIMULATOR_USERS_FILENAME, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	update_selected_patient_mass()

func save_preferences()->void:
	var file := FileAccess.open(PREFERENCES_FILENAME, FileAccess.WRITE)
	file.store_string(JSON.stringify(_parameters, "\t"))
	file.close()


func load_preferences()->void:
	if not FileAccess.file_exists(PREFERENCES_FILENAME):
		return
	
	var file := FileAccess.open(PREFERENCES_FILENAME, FileAccess.READ)
	var parsed_v: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed_v) != TYPE_DICTIONARY:
		printerr("User file " + SIMULATOR_USERS_FILENAME + " seems corrupted.")
		return
	var result: Dictionary = parsed_v
	
	_parameters["has_dbox"] = bool(result.get("has_dbox", false))
	_parameters["has_floor_cam"] = bool(result.get("has_floor_cam", false))
	_parameters["has_motors"] = bool(result.get("has_motors", false))

	_dbox_toggle.set_pressed_no_signal(_parameters["has_dbox"])
	_floor_cam_toggle.set_pressed_no_signal(_parameters["has_floor_cam"])
	_motors_toggle.set_pressed_no_signal(_parameters["has_motors"])

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
						var scene_instance = load(path).instantiate()
						get_tree().get_root().add_child(scene_instance)
						_enter_scene(scene_instance)
				)
				scene_container.add_child(_scene_button_instance)
				
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Error while opening PlayableScenes folder")

## Enter the selected scene
func _enter_scene(scene_instance: Node3D)->void:

	# Quit the current scene if there is one loaded
	if _current_scene_node:
		_current_scene_node.queue_free()

	_current_scene_node = scene_instance

	await get_tree().process_frame
	await get_tree().process_frame
	
	get_tree().get_root().add_child(scene_instance)
	var floor_window := scene_instance.get_node_or_null("player/floor_projector") as Window
	var motors := scene_instance.get_node_or_null("player/motors")
	var dbox := scene_instance.get_node_or_null("player/dbox")

	var screen_count: int = DisplayServer.get_screen_count()
	
	if _parameters["has_floor_cam"]:
		if floor_window and screen_count > 1:
			_set_window_full_screen(floor_window, 1)
	else:
		if floor_window:
			floor_window.queue_free()
	if (not _parameters["has_dbox"]) and (dbox != null):
		dbox.queue_free()
	if (not _parameters["has_motors"]) and (motors != null):
		motors.queue_free()

	var front_window := scene_instance.get_node_or_null("player/front_projector") as Window
	if front_window and screen_count > 2:
		_set_window_full_screen(front_window, 2)
		
	update_selected_patient_mass()

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
	if _current_scene_node:
		_current_scene_node.queue_free()
	else:
		get_tree().quit()

# -------------------------------------------------------------------
# Masse du patient sélectionné
# -------------------------------------------------------------------
func update_selected_patient_mass() -> void:
	for row in user_list.get_children():
		if (row.get_node("selected") as CheckBox).button_pressed:
			var player := get_player()
			if player:
				player.mass = (row.get_node("mass") as LineEdit).text.to_float()
			else:
				print("Player not found, mass not updated.")

# -------------------------------------------------------------------
# DBox : manuel + maintien
# -------------------------------------------------------------------

# =========================
# Sélection unique patients
# =========================
func _on_row_checkbox_toggled(pressed: bool, row: Node) -> void:
	if pressed:
		selected_user = row
		for other in user_list.get_children():
			if other != row:
				var ocb := other.get_node("selected") as CheckBox
				if ocb.button_pressed:
					ocb.button_pressed = false
	save_users()
	update_selected_patient_mass()

func _enforce_single_selection(preferred_row: Node = null) -> void:
	var found := false
	for row in user_list.get_children():
		var cb := row.get_node("selected") as CheckBox
		if preferred_row and row == preferred_row:
			if cb.button_pressed and not found:
				found = true
			elif cb.button_pressed and found:
				cb.button_pressed = false
			continue
		if cb.button_pressed:
			if found:
				cb.button_pressed = false
			else:
				found = true


func _on_motors_toggle_toggled(toggled_on: bool) -> void:
	_parameters["has_motors"] = toggled_on
	save_preferences()


func _on_floor_cam_toggle_toggled(toggled_on: bool) -> void:
	_parameters["has_floor_cam"] = toggled_on
	save_preferences()
	
func _on_dbox_toggle_toggled(toggled_on: bool) -> void:
	_parameters["has_dbox"] = toggled_on
	save_preferences()


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
