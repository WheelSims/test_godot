extends Control

@export var SIMULATOR_USERS_FILENAME = "user://simulator_users.json"
@export var PLAYABLE_SCENES_FOLDER_PATH = "res://PlayableScenes"
@export var THUMBNAIL_FOLDER_PATH = "res://ControlGUI/Thumbnails"
var _current_scene_node: Node3D = null

# --- UI users ---
@export var patient_list: VBoxContainer
var current_node_patient
var user_row := preload("user.tscn")

# --- Scene Buttons ---
var scene_button := preload("scene_button.tscn")
@export var scene_container: GridContainer

# --- UI DBox ---
@export var btn_dbox: Button
@export var btn_dbox_up: Button
@export var btn_dbox_down: Button
# --- DBox manuel ---
var dbox_manual_mode := false
var manual_heave := 0.0
var dbox_step := 0.02
# --- maintien appuyé ---
var dbox_hold_dir := 0
var dbox_speed := 0.2

#Preferences
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
	# Patients
	load_users()
	#Preferences
	load_preferences()
	
	_create_map_buttons()

func _process(delta: float) -> void:
	if dbox_manual_mode and dbox_hold_dir != 0:
		var new_heave := clampf(manual_heave + dbox_speed * dbox_hold_dir * delta, -0.5, 0.5)
		if absf(new_heave - manual_heave) > 0.0001:
			manual_heave = new_heave
			_send_heave_target()

# -------------------------------------------------------------------
# Helpers : récupération du player et du nœud DBox
# -------------------------------------------------------------------
func _get_player() -> Node:
	var root := get_tree().get_root()

	var n := root.get_node_or_null("Park/Player")
	if n and n.has_node("DBox"):
		return n

	n = root.get_node_or_null("Player")
	if n and n.has_node("DBox"):
		return n

	for child in root.get_children():
		if child.name == "Player" and child.has_node("DBox"):
			return child
		if child.has_node("Player"):
			var p := child.get_node_or_null("Player")
			if p and p.has_node("DBox"):
				return p
	return null

func _get_dbox_node() -> Node:
	var p := _get_player()
	if p:
		var d := p.get_node_or_null("DBox")
		if d:
			return d
	print("⚠️ DBox introuvable : player trouvé =", p)
	return null

# -------------------------------------------------------------------
# User management
# -------------------------------------------------------------------
func _on_btn_add_user_pressed() -> void:
	var new_row := user_row.instantiate()

	new_row.get_node("Name").connect("text_submitted", Callable(self, "save_users"))
	new_row.get_node("Name").connect("focus_exited",   Callable(self, "save_users"))
	new_row.get_node("LineWheelDist").connect("text_submitted", Callable(self, "save_users"))
	new_row.get_node("LineWheelDist").connect("focus_exited",   Callable(self, "save_users"))
	new_row.get_node("LineMass").connect("text_submitted", Callable(self, "update_selected_patient_mass"))
	new_row.get_node("LineMass").connect("focus_exited",   Callable(self, "update_selected_patient_mass"))

	# Sélection unique : bind de la row
	new_row.get_node("CheckBox").connect("toggled", Callable(self, "_on_row_checkbox_toggled").bind(new_row))

	patient_list.add_child(new_row)
	save_users()

func _on_btn_remove_user_pressed() -> void:
	if patient_list.get_child_count() > 0:
		if not current_node_patient:
			current_node_patient = patient_list.get_child(patient_list.get_child_count() - 1)
		patient_list.remove_child(current_node_patient)
		current_node_patient.queue_free()
		save_users()
		_enforce_single_selection()

func save_users(_new_text: String = "") -> void:
	var data: Array[Dictionary] = []
	for row in patient_list.get_children():
		data.append({
			"name": (row.get_node("Name") as LineEdit).text,
			"wheel_distance": (row.get_node("LineWheelDist") as LineEdit).text.to_float(),
			"mass": (row.get_node("LineMass") as LineEdit).text.to_float(),
			"selected": (row.get_node("CheckBox") as CheckBox).button_pressed,
		})
	var file := FileAccess.open(SIMULATOR_USERS_FILENAME, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	update_selected_patient_mass()

func save_preferences()->void:
	var file := FileAccess.open(PREFERENCES_FILENAME, FileAccess.WRITE)
	file.store_string(JSON.stringify(_parameters, "\t"))
	file.close()

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

		(new_row.get_node("Name") as LineEdit).text = str(patient.get("name", ""))
		(new_row.get_node("LineWheelDist") as LineEdit).text = str(patient.get("wheel_distance", ""))
		(new_row.get_node("LineMass") as LineEdit).text = str(patient.get("mass", ""))
		(new_row.get_node("CheckBox") as CheckBox).button_pressed = bool(patient.get("selected", false))

		new_row.get_node("Name").connect("text_submitted", Callable(self, "save_users"))
		new_row.get_node("Name").connect("focus_exited",   Callable(self, "save_users"))
		new_row.get_node("LineWheelDist").connect("text_submitted", Callable(self, "save_users"))
		new_row.get_node("LineWheelDist").connect("focus_exited",   Callable(self, "save_users"))
		new_row.get_node("LineMass").connect("text_submitted", Callable(self, "save_users"))
		new_row.get_node("LineMass").connect("focus_exited",   Callable(self, "save_users"))
		new_row.get_node("CheckBox").connect("toggled", Callable(self, "_on_row_checkbox_toggled").bind(new_row))

		patient_list.add_child(new_row)
		if (new_row.get_node("CheckBox") as CheckBox).button_pressed:
			current_node_patient = new_row

	_enforce_single_selection()

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
# Lancement PARK + plein écran sans bordure
# -------------------------------------------------------------------
func _kill_existing_simulators() -> void:
	if _current_scene_node:
		_current_scene_node.queue_free()

func _create_map_buttons()->void:
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
				var image_path = THUMBNAIL_FOLDER_PATH + "/" + name_without_ext + ".png"
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
						_set_scene(scene_instance)
				)
				scene_container.add_child(_scene_button_instance)
				
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Error while opening PlayableScenes folder")

func _set_scene(scene_instance: Node3D)->void:
	_kill_existing_simulators()
	_current_scene_node = scene_instance

	await get_tree().process_frame
	await get_tree().process_frame

	
	get_tree().get_root().add_child(scene_instance)
	var second_window := scene_instance.get_node_or_null("Player/FloorProjector")
	var motors := scene_instance.get_node_or_null("Player/Motors")
	var dbox := scene_instance.get_node_or_null("Player/DBox")
	
	

	var screen_count: int = DisplayServer.get_screen_count()
	
	if _parameters["has_floor_cam"]:
		second_window = scene_instance.get_node_or_null("Player/FloorProjector") as Window
		if second_window and screen_count > 1:
			_prepare_display_window(second_window, 1)
	else:
		second_window.queue_free()
	if not _parameters["has_dbox"]:
		dbox.queue_free()
	if not _parameters["has_motors"]:
		motors.queue_free()

	var third_window := scene_instance.get_node_or_null("Player/FrontProjector") as Window
	if third_window and screen_count > 2:
		_prepare_display_window(third_window, 2)
		
	update_selected_patient_mass()

# Met la Window en plein écran exclusif sur l'écran demandé
# et adapte SubViewportContainer/SubViewport pour remplir la fenêtre.
func _prepare_display_window(win: Window, screen_index: int) -> void:
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
	for row in patient_list.get_children():
		if (row.get_node("CheckBox") as CheckBox).button_pressed:
			var player := _get_player()
			if player:
				player.mass = (row.get_node("LineMass") as LineEdit).text.to_float()
# -------------------------------------------------------------------
# DBox : manuel + maintien
# -------------------------------------------------------------------
func _on_btn_dbox_pressed() -> void:
	dbox_manual_mode = !dbox_manual_mode
	btn_dbox.text = "DBox : Manual" if dbox_manual_mode else "DBox : Auto"
	btn_dbox_up.visible = dbox_manual_mode
	btn_dbox_down.visible = dbox_manual_mode
	dbox_hold_dir = 0
	var dbox := _get_dbox_node()
	print("Toggle DBox manual ->", dbox_manual_mode, " | dbox=", dbox)
	if dbox:
		dbox.manual_mode = dbox_manual_mode
		if not dbox_manual_mode:
			manual_heave = 0.0
			dbox.manual_target_heave = 0.0

func _on_dbox_up_button_down() -> void:
	if dbox_manual_mode:
		dbox_hold_dir = +1

func _on_dbox_down_button_down() -> void:
	if dbox_manual_mode:
		dbox_hold_dir = -1

func _on_dbox_button_up() -> void:
	dbox_hold_dir = 0
	_send_heave_target()

func _send_heave_target() -> void:
	var dbox := _get_dbox_node()
	if dbox:
		dbox.manual_target_heave = manual_heave
		dbox.send(7, manual_heave, 0.0, 0.0)
		print("DBox MANUAL heave =", manual_heave, "  path=", dbox.get_path())
	else:
		print("DBox introuvable (chemin) — scène/chemins à vérifier")


# =========================
# Sélection unique patients
# =========================
func _on_row_checkbox_toggled(pressed: bool, row: Node) -> void:
	if pressed:
		current_node_patient = row
		for other in patient_list.get_children():
			if other != row:
				var ocb := other.get_node("CheckBox") as CheckBox
				if ocb.button_pressed:
					ocb.button_pressed = false
	save_users()
	update_selected_patient_mass()

func _enforce_single_selection(preferred_row: Node = null) -> void:
	var found := false
	for row in patient_list.get_children():
		var cb := row.get_node("CheckBox") as CheckBox
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
