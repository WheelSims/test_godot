@tool
extends EditorScript
## object_size_baker convert the scenes passed in the bake_config inspector to [ObjectInfo] objects.
## to use it: right click on the script -> Execute or Ctrl+Shift+X

var config: BakeConfig = load(
	"res://games/races/obstacle_race/generator/baker/bake_config_res.tres"
)


func _run():
	var objects_to_bake: Array[PackedScene] = load_packed_scenes_from_folder(
		config.objects_to_bake_folder_path
	)
	for scene in objects_to_bake:
		var instance = scene.instantiate()
		EditorInterface.get_edited_scene_root().add_child(instance)

		instance.force_update_transform()
		var object_info = ObjectInfo.new()
		if instance is WorldScaleCalculator:
			object_info.scene = scene
			var inst: WorldScaleCalculator = instance
			inst.get_precise_size()
			object_info.type = inst.object_type
			if inst.object_type == WorldScaleCalculator.ObjectType.OBSTACLE:
				object_info.sizes = inst.write_sizes_with_rotation([90, 45, -45, 0])
			else:
				object_info.sizes = inst.write_sizes_with_rotation()
			object_info.local_scale = inst.get_size()
		else:
			print("The Packed Scene %s is not a WorldScaleCalculator." % scene.resource_name)

		if not DirAccess.dir_exists_absolute(config.object_info_folder_path):
			DirAccess.make_dir_recursive_absolute(config.object_info_folder_path)

		var path = config.object_info_folder_path + instance.name + ".tres"
		object_info.take_over_path(path)
		ResourceSaver.save(object_info, path)
		EditorInterface.get_resource_filesystem().scan()
		print(path)

		instance.queue_free()


func load_packed_scenes_from_folder(folder_path: String) -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []

	var dir := DirAccess.open(folder_path)
	if dir == null:
		push_error("Cannot open folder: " + folder_path)
		return scenes

	dir.list_dir_begin()

	var file_name := dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			if file_name.ends_with(".tscn"):
				var full_path := folder_path.path_join(file_name)
				var scene := load(full_path) as PackedScene
				if scene:
					scenes.append(scene)

		file_name = dir.get_next()

	dir.list_dir_end()
	return scenes
