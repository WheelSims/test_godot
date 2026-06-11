extends Node3D
## This script makes a pedestrian walk randomly in the walkable area. Each time it reaches a point,
## a new destination is established randomly and the new trajectory is created accordingly.
##
## If the pedestrian collides into an obstacle, it go back a little and defines a new random
## trajectory.
##
## To use a pedestrian object, drag pedestrian.tscn into the scene, then drag one of the humans
## (e.g., brian.tscn, kate.tscn) as a children of the Pedestrian node. The Pedestrian node controls
## the navigation, and its Human children controls its appearance, including the animation.

@export var walking_speed: float = 1.2
var max_target_distance: float = 20  # meters

## The human to move
@export var human: PackedScene
var human_instance: Node3D

@onready var navigation_agent: NavigationAgent3D = get_node("NavigationAgent3D")
@onready var down_ray = get_node("RayCast3DDown")

## True to spawn on a random point when the map is ready
@export var spawn_on_random_point: bool = false

@onready var is_spawn_point_set: bool = false
@onready var is_target_point_set: bool = false

var physics_delta: float


## Find a random point in the walkable environment
func find_random_point(distance: float) -> Vector3:
	var map = navigation_agent.get_navigation_map()
	#var random_point = NavigationServer3D.map_get_random_point(map, 1, true)
	var random_point = NavigationServer3D.map_get_closest_point(
		map, global_position + Vector3(randf_range(-distance, distance),0,randf_range(-distance,distance))
	)
	return random_point


## Set a new target anywhere in the walkable environment.
func target_new_random_point() -> void:
	is_target_point_set = false
	var new_point = find_random_point(max_target_distance)
	if new_point != Vector3.ZERO:
		# Map is ready
		navigation_agent.set_target_position(new_point)
		is_target_point_set = true


## Move to random point. This also sets a new target since the trajectory will change.
func move_to_random_point():
	is_spawn_point_set = false
	var map = navigation_agent.get_navigation_map()
	var new_point = NavigationServer3D.map_get_random_point(map, 1, true)

	if new_point != Vector3.ZERO:
		# Map is ready
		global_position = new_point
		target_new_random_point()
		is_spawn_point_set = true


## Set a new target 1.5 meters backward, in case we collided into an obstacle.
func new_back_target():
	var map = navigation_agent.get_navigation_map()
	navigation_agent.set_target_position(NavigationServer3D.map_get_random_point(map, 1, true))
	var forward = global_transform.basis.z.normalized()
	var target = global_position + forward * -1.5 # Back by 1.5 meter
	navigation_agent.set_target_position(NavigationServer3D.map_get_closest_point(map, target))


func _ready() -> void:
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	human_instance = human.instantiate()
	add_child(human_instance)


func _physics_process(delta):
	# Save the delta for use in _on_velocity_computed.
	physics_delta = delta
	
	if spawn_on_random_point and (not is_spawn_point_set):
		move_to_random_point()
		return
	if not is_target_point_set:
		target_new_random_point()
		return


	# Don't do anything when the map has never synchronized and is empty.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return

	# Always be at ground level
	if down_ray.is_colliding():
		global_position.y = down_ray.get_collision_point().y
	
	if navigation_agent.is_navigation_finished():
		target_new_random_point()
		return

	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	var new_velocity: Vector3 = global_position.direction_to(next_path_position) * walking_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	global_position = global_position.move_toward(global_position + safe_velocity, physics_delta * walking_speed)
	human_instance.velocity = safe_velocity


func _on_area_3d_body_shape_entered(_body_rid: RID, body: Node3D, _body_shape_index: int, _local_shape_index: int) -> void:
	pass
	#if body is not Surface:
		#new_back_target()
