extends Control

# ---------------------------------------------------------------------- #
# This scene is used to test bridge communication between Godot and Python
# A list of availables functions from python can be tested, then can ve checked response received
# ---------------------------------------------------------------------- #

# UI elements
@onready var node_requests_list = $main_panel/margin_container/main_vbox_container/requests_panel/scroll_container/requests_list
@onready var node_send_button = $main_panel/margin_container/main_vbox_container/send_button

var group = ButtonGroup.new() # Button group to allow only one selection at a time
var selected_key = null # Currently selected coordinate key
var items = {}

var command = [] # List of availables functions in python app
var data

func _ready() -> void:
	
	## Connect send button pressed signal
	node_send_button.pressed.connect(_on_button_pressed)
	
	while not $python_bridge._udp_receiver_connected:
		await get_tree().create_timer(1.0).timeout

	## Add functions items to the fonctions list
	data = $python_bridge.receive_data()
	for i in data:
		create_item(i)
	
	## Add function item to receive python response packet one by one
	node_requests_list.add_child(HSeparator.new())
	create_item("receive data from python")


## Add item to the requests list gui
func create_item(key):
	
	# Add a separator before each coordinate block
	node_requests_list.add_child(HSeparator.new())
	
	# Add header using the name of the coordinate
	var label = Label.new()
	label.text = key
	#node_requests_list.add_child(label)
	
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
	h_container.add_child(label)
	node_requests_list.add_child(h_container)
	
	if selected_key == null:
		button.button_pressed = true
		selected_key = key

## Send request based on selected key
func _on_button_pressed():
	
	if selected_key == "receive data from python":
		data = $python_bridge.receive_data()
		print(data)
	elif selected_key == "close":
		queue_free()
	else:
		$python_bridge.send_request({"command": selected_key})
