## This list of user-configurable settings is populated automatically based on the config object
## from the main script.
extends VBoxContainer

@onready var config: Node = get_tree().get_root().get_node("main/config")

func _ready():
	config.load_config()
	for key in config.get_keys():
		# Create a new setting areay for this key
		var label_text: String
		if typeof(config.get_value(key)) == TYPE_NIL:  # This is a header
			# Add a ruler before
			add_child(HSeparator.new())
			label_text = config.get_label(key)
		else:
			label_text = "    " + config.get_label(key)

		var container = HBoxContainer.new()

		# Add the label
		var label = Label.new()
		label.text = label_text
		
		container.add_child(label)
		
		# Add the control
		match(typeof(config.get_value(key))):
			TYPE_NIL:
				pass
				
			TYPE_STRING:
				var control = LineEdit.new()
				control.text = config.get_value(key)
				control.text_changed.connect(
					func(value):
						config.set_value(key, value)
				)				
				container.add_child(control)

			TYPE_FLOAT, TYPE_INT:
				var control = LineEdit.new()
				control.text = str(config.get_value(key))
				control.text_changed.connect(
					func(value):
						config.set_value(key, float(value))
				)				
				container.add_child(control)
				
			TYPE_BOOL:
				var control = CheckButton.new()
				control.button_pressed = config.get_value(key)
				container.add_child(control)
				control.toggled.connect(
					func(value):
						config.set_value(key, value)
				)				
				container.add_child(control)

		# Add the unit
		var unit = Label.new()
		unit.text = config.get_unit(key)
		container.add_child(unit)
		
		# Add this whole setting to the list
		add_child(container)
