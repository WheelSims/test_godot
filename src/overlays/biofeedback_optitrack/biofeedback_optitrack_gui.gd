extends Control

# ---------------------------------------------------------------------- #
# GUI for selecting and recording 3D coordinates using OptiTrack and aiming probe
# - wheel centers are recorded in the simulator reference frame 
# - hands are recorded in the forearm cluster reference frame
# ---------------------------------------------------------------------- #

@onready var main: Node = get_tree().get_root().get_node("main")
#@onready var config: Node = get_tree().get_root().get_node("main/config")

# UI elements
@onready var node_aimings_list = $main_panel/margin_container/main_vbox_container/aimings_panel/ScrollContainer/aimings_list
@onready var node_aiming_button = $main_panel/margin_container/main_vbox_container/aiming_button

var group = ButtonGroup.new() # Button group to allow only one selection at a time
var selected_key = null # Currently selected coordinate key
var items = {}

var duration_timer = 10 # Delay before recording (seconds)

func _ready():
	
	# Connect aiming button pressed signal
	node_aiming_button.pressed.connect(_on_button_pressed)
	
	# Add coordinate items to the aiming list
	create_item("coordinates.left_wheel_center")
	create_item("coordinates.right_wheel_center")
	create_item("coordinates.left_hand")
	create_item("coordinates.right_hand")
	
	update_values()


func _process(_delta: float) -> void:
	
	# Update aiming list values when coordinates change
	if Config.value_changed("biofeedback", "coordinates.left_wheel_center") \
	or Config.value_changed("biofeedback", "coordinates.right_wheel_center") \
	or Config.value_changed("biofeedback", "coordinates.left_hand") \
	or Config.value_changed("biofeedback", "coordinates.right_hand"):
		update_values()


func create_item(key):
	
	# Add a separator before each coordinate block
	node_aimings_list.add_child(HSeparator.new())
	
	# Add header using the name of the coordinate
	var label = Label.new()
	label.text = Config.get_label(key)
	node_aimings_list.add_child(label)
	
	# Add button to select the current coordinate
	var button = Button.new()
	button.text = "       Select       "
	button.toggle_mode = true
	button.button_group = group
	
	# Apply pressed style and set button to select this coordinate
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0.0, 0.39, 0.58)
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(func(): selected_key = key)
	
	var h_container = HBoxContainer.new()
	h_container.add_child(button)

	var v_container = VBoxContainer.new()

	# Add labels for the X, Y, Z components of the coordinate
	var value_labels = []
	for i in range(3):
		var label_value = Label.new()
		label_value.text = "..."
		v_container.add_child(label_value)
		value_labels.append(label_value)
	
	h_container.add_child(v_container)
	
	# Add the full coordinate block to the aiming list UI
	node_aimings_list.add_child(h_container)
	
	# Store the labels for updating later
	items[key] = {"labels": value_labels}
	
	# Select the one coordinate by default
	if selected_key == null:
		button.button_pressed = true
		selected_key = key


# Update displayed coordinate values in the UI
func update_values():
	
	for key in items.keys():
		
		var value = Config.get_value(key)
		var labels = items[key]["labels"]
		
		for i in range(3):
			labels[i].text = "   " + str(snapped(value[i], 0.0001)) + "..."


# Start aiming process with a countdown before recording position
func _on_button_pressed():
	
	# Countdown
	var t = duration_timer
	for i in range(duration_timer):
		node_aiming_button.disabled = true
		node_aiming_button.text = str(t)
		await get_tree().create_timer(1.0).timeout
		t -= 1
	node_aiming_button.disabled = false
	node_aiming_button.text = "AIMING"
	
	
	var pos = []
	var coordinates = selected_key
	
	# IDs of tracked objects
	var ID_frame_reference
	var ID_probe = 999
	
	if main:

		if main.get_node("optitrack"):
	
			# Set reference frame ID based on the selected coordinate
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
				
				# Get the inverse global transform of the frame reference
				var T0S = node_frame_reference.global_transform.affine_inverse()
				
				# Transform probe position into the reference frame coordinate system
				pos = T0S.origin + T0S.basis * node_probe.position

		# Save captured coordinates to configuration
		Config.set_value(coordinates, [pos.x, pos.y, pos.z])
