## This list of user-configurable settings is populated automatically based on the config object
## from the main script.
extends VBoxContainer


func _ready():
	Config.load_config()
	for key in Config.get_keys():
		# Create a new setting areay for this key

		if not Config.get_type(key):  # This is a header
			# Add a ruler before
			add_child(HSeparator.new())
			var label = Label.new()
			label.text = Config.get_label(key)
			add_child(label)
			continue

		if Config.get_type(key) == "string":
			# Label
			var container = HBoxContainer.new()
			var label = Label.new()
			label.text = Config.get_label(key)
			container.add_child(label)

			# Value
			var control = LineEdit.new()
			control.text = Config.get_value(key)
			control.text_changed.connect(func(value): Config.set_value(key, value))
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			container.add_child(control)
			add_child(container)
			continue

		if Config.get_type(key) in ["int", "float"]:
			if Config.get_min_value(key) and Config.get_max_value(key):
				# Slider type

				# Label on its own line
				var label = Label.new()
				label.text = Config.get_label(key)
				add_child(label)

				var container = HBoxContainer.new()
				# Value
				var value_text = Label.new()
				value_text.text = str(Config.get_value(key))
				var control = HSlider.new()
				control.min_value = Config.get_min_value(key)
				control.max_value = Config.get_max_value(key)
				control.step = Config.get_step_value(key)
				control.custom_minimum_size.x = 200
				control.scrollable = false
				control.value = Config.get_value(key)
				control.value_changed.connect(
					func(value):
						if Config.get_type(key) == "int":
							value = int(value)  # Not float
						value_text.text = str(value)
						Config.set_value(key, value)
				)
				container.add_child(control)
				container.add_child(value_text)

				# Unit
				var unit = Label.new()
				unit.text = Config.get_unit(key)
				container.add_child(unit)
				add_child(container)

			else:
				# Text box type
				# Label
				var container = HBoxContainer.new()
				var label = Label.new()
				label.text = Config.get_label(key)
				container.add_child(label)

				# Value
				var control = LineEdit.new()
				control.text = str(Config.get_value(key))
				control.text_changed.connect(func(value): Config.set_value(key, float(value)))
				container.add_child(control)

				# Unit
				var unit = Label.new()
				unit.text = Config.get_unit(key)
				container.add_child(unit)
				add_child(container)

			continue

		if Config.get_type(key) == "bool":
			var container = HBoxContainer.new()
			# Switch
			var control = CheckButton.new()
			control.button_pressed = Config.get_value(key)
			control.toggled.connect(func(value): Config.set_value(key, value))
			container.add_child(control)

			# Label
			var label = Label.new()
			label.text = Config.get_label(key)
			container.add_child(label)
			add_child(container)
			continue

		if Config.get_type(key) == "options":
			# Label on its own line
			var label = Label.new()
			label.text = Config.get_label(key)
			add_child(label)

			# Control
			var option_button = OptionButton.new()
			for item in Config.get_items(key):
				option_button.add_item(item)
			option_button.select(Config.get_value(key))
			option_button.item_selected.connect(func(value): Config.set_value(key, value))
			add_child(option_button)

		if Config.get_type(key) == "file":
			# Label
			var container = HBoxContainer.new()
			var label = Label.new()
			label.text = Config.get_label(key)
			container.add_child(label)

			# File dialog
			var dialog = FileDialog.new()
			dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			dialog.display_mode = FileDialog.DISPLAY_LIST
			dialog.access = FileDialog.ACCESS_FILESYSTEM
			dialog.use_native_dialog = true

			# Selection button
			var control = Button.new()
			control.text = Config.get_value(key)
			if control.text == "":
				control.text = "Click to select a file"

			control.pressed.connect(func(): dialog.popup_centered())

			dialog.file_selected.connect(
				func(value):
					Config.set_value(key, value)
					control.text = value
			)

			container.add_child(control)
			container.add_child(dialog)
			add_child(container)
			continue
			
		if Config.get_type(key) == "folder":
			# Label
			var container = HBoxContainer.new()
			var label = Label.new()
			label.text = Config.get_label(key)
			container.add_child(label)

			# File dialog
			var dialog = FileDialog.new()
			dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
			dialog.display_mode = FileDialog.DISPLAY_LIST
			dialog.access = FileDialog.ACCESS_FILESYSTEM
			dialog.use_native_dialog = true

			# Selection button
			var control = Button.new()
			control.text = Config.get_value(key)
			if control.text == "":
				control.text = "Click to select a folder"

			control.pressed.connect(
				func():
					dialog.popup_centered()
			)

			dialog.dir_selected.connect(
				func(value):
					Config.set_value(key, value)
					control.text = value
			)

			container.add_child(control)
			container.add_child(dialog)
			add_child(container)
			continue
