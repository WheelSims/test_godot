## This list of user-configurable settings is populated automatically based on the config object
## from the main script.
extends VBoxContainer

@onready var config: Node = get_tree().get_root().get_node("main/config")

func _ready():
	config.load_config()
	for key in config.get_keys():
		# Create a new setting areay for this key
		
		if typeof(config.get_value(key)) == TYPE_NIL:  # This is a header
			# Add a ruler before
			add_child(HSeparator.new())
			var label = Label.new()
			label.text = config.get_label(key)
			add_child(label)
			continue
			
		if typeof(config.get_value(key)) == TYPE_STRING:  # This is a string config value
			# Label
			var container = HBoxContainer.new()
			var label = Label.new()
			label.text = config.get_label(key)
			container.add_child(label)

			# Value
			var control = LineEdit.new()
			control.text = config.get_value(key)
			control.text_changed.connect(
				func(value):
					config.set_value(key, value)
			)
			container.add_child(control)
			add_child(label)
			continue
			
		if (typeof(config.get_value(key)) == TYPE_INT) or (typeof(config.get_value(key)) == TYPE_FLOAT):
			if config.get_min_value(key) and config.get_max_value(key):
				# Slider type

				# Label on its own line
				var label = Label.new()
				label.text = config.get_label(key)
				add_child(label)

				var container = HBoxContainer.new()
				# Value
				var value_text = Label.new()
				value_text.text = str(config.get_value(key))
				var control = HSlider.new()
				control.min_value = config.get_min_value(key)
				control.max_value = config.get_max_value(key)
				control.custom_minimum_size.x = 200
				control.value = config.get_value(key)
				control.value_changed.connect(
					func(value):
						value_text.text = str(value)
						config.set_value(key, value)
				)				
				container.add_child(control)
				container.add_child(value_text)
				add_child(container)
				

				# Unit
				var unit = Label.new()
				unit.text = config.get_unit(key)
				container.add_child(unit)
				add_child(container)
				
			else:
				# Text box type
				# Label
				var container = HBoxContainer.new()
				var label = Label.new()
				label.text = config.get_label(key)
				container.add_child(label)

				# Value
				var control = LineEdit.new()
				control.text = str(config.get_value(key))
				control.text_changed.connect(
					func(value):
						config.set_value(key, float(value))
				)				
				container.add_child(control)

				# Unit
				var unit = Label.new()
				unit.text = config.get_unit(key)
				container.add_child(unit)
				add_child(container)

			continue

		if (typeof(config.get_value(key)) == TYPE_BOOL):
			var container = HBoxContainer.new()
			# Switch
			var control = CheckButton.new()
			control.button_pressed = config.get_value(key)
			container.add_child(control)
			control.toggled.connect(
				func(value):
					config.set_value(key, value)
			)				
			container.add_child(control)
			
			# Label
			var label = Label.new()
			label.text = config.get_label(key)
			container.add_child(label)
			add_child(container)
			continue
