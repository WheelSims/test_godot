extends Control

@onready var main: Node = get_tree().get_root().get_node("main")
@onready var config: Node = get_tree().get_root().get_node("main/config")
@onready var node_aimings_list = $main_panel/margin_container/main_vbox_container/aimings_panel/ScrollContainer/aimings_list
@onready var node_aiming_button = $main_panel/margin_container/main_vbox_container/aiming_button
	

var group = ButtonGroup.new()
var selected_key = null

var items = {}

var duration_timer = 10

func _ready():
	
	node_aiming_button.pressed.connect(_on_button_pressed)
	
	create_item("coordinates.left_wheel_center")
	create_item("coordinates.right_wheel_center")
	create_item("coordinates.left_hand")
	create_item("coordinates.right_hand")
	
	update_values()


func _process(_delta: float) -> void:
	if config.value_changed("biofeedback", "coordinates.left_wheel_center") \
	or config.value_changed("biofeedback", "coordinates.right_wheel_center") \
	or config.value_changed("biofeedback", "coordinates.left_hand") \
	or config.value_changed("biofeedback", "coordinates.right_hand"):
		update_values()


func create_item(key):
	
	node_aimings_list.add_child(HSeparator.new())
	
	var label = Label.new()
	label.text = config.get_label(key)
	node_aimings_list.add_child(label)
	
	var h_container = HBoxContainer.new()
	
	var button = Button.new()
	button.text = "       Select       "
	button.toggle_mode = true
	button.button_group = group
	
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0.0, 0.39, 0.58)
	button.add_theme_stylebox_override("pressed", pressed)
	
	button.pressed.connect(_on_item_selected.bind(key))
	h_container.add_child(button)
	
	var v_container = VBoxContainer.new()
	
	var value_labels = []
	
	for i in range(3):
		var label_value = Label.new()
		label_value.text = "..."
		v_container.add_child(label_value)
		value_labels.append(label_value)
	
	h_container.add_child(v_container)
	node_aimings_list.add_child(h_container)
	
	items[key] = {"labels": value_labels}
	
	if selected_key == null:
		button.button_pressed = true
		selected_key = key


func update_values():
	
	for key in items.keys():
		
		var value = config.get_value(key)
		var labels = items[key]["labels"]
		
		for i in range(3):
			labels[i].text = "   " + str(snapped(value[i], 0.0001)) + "..."


func _on_item_selected(key):
	selected_key = key
		
		
func _on_button_pressed():
	
	# Delay
	var t = duration_timer
	for i in range(duration_timer):
		node_aiming_button.disabled = true
		node_aiming_button.text = str(t)
		await get_tree().create_timer(1.0).timeout
		t -= 1
	node_aiming_button.disabled = false
	node_aiming_button.text = "AIMING"
	
	
	var pos = [] # Initialize probe's positions
	var coordinates = selected_key
	
	var ID_frame_reference = 102
	var ID_probe = 999
	
	if main:
		# Get probe's positions
		if main.get_node("optitrack"):
	
			if coordinates == "coordinates.left_wheel_center" or coordinates == "coordinates.right_wheel_center":
				ID_frame_reference = 102
			elif coordinates == "coordinates.left_hand":
				ID_frame_reference = 201
				
			elif coordinates == "coordinates.right_hand":
				ID_frame_reference = 202

			var node_optitrack = main.get_node("optitrack")
			if node_optitrack.get_node(str(ID_probe)) and node_optitrack.get_node(str(ID_frame_reference)):
				
				var node_probe = node_optitrack.get_node(str(ID_probe))
				var node_frame_reference = node_optitrack.get_node(str(ID_frame_reference))
				
				var T0S = node_frame_reference.global_transform.affine_inverse()
				
				pos = T0S.origin + T0S.basis * node_probe.position

		# Set XXX coordinates using probe position
		if main.get_node("config"):
			main.get_node("config").set_value(coordinates, [pos.x, pos.y, pos.z])
