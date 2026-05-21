extends Node3D
@export var serial_port: String = "COM5"  # Arduino serial port
@export var baud_rate: int = 250000  # Baudrate
# Feel Settings
@export var forward_gain: float = 5.0  # Forward force
var wheel_distance: float = 0.6
## Shutdown settings
@export var stop_threshold: float = 0.05 

# Inertia parameters (lerp)
@export var angular_inertia: float = 5.0  
@export var inertia_min: float = 1.0  #Inertia when you don't push
@export var inertia_max: float = 1.0   #Inertia when pushing
@export var push_decay_time: float = 1.0  #Time without thrust before returning to inertia_min

#Global variable
var serial: GdSerial  
var is_connected: bool = false 
var current_speed: float = 0.0  
var current_angular: float = 0.0  
var target_speed: float = 0.0  
var target_angular: float = 0.0  
var time_since_wheel_active: float = 0.0  
var push_count_left: int = 0 
var push_count_right: int = 0 
var push_count_total: int = 0 

# Memory to detect NEW outbreaks
var last_push_count_total: int = 0
var time_since_last_push: float = 999.0  #Time since the last detected surge

func _ready():
	serial = GdSerial.new()
	var ports = serial.list_ports()
	print("Available ports : ", ports)
	serial.set_port(serial_port)
	serial.set_baud_rate(baud_rate)

	if serial.open():
		is_connected = true
		print("[MiWe] Arduino connected to ", serial_port)
	else:
		print("[MiWe] Connection failed on ", serial_port)

func _physics_process(delta: float) -> void:
	if is_connected:
		while serial.bytes_available() > 0:
			var data = serial.readline()
			if data != "":
				process_arduino_data(data, delta)
	time_since_wheel_active += delta
	time_since_last_push += delta

	# Dynamic inertia
	var push_factor: float = clamp(1.0 - (time_since_last_push / push_decay_time), 0.0, 1.0)
	var dynamic_inertia: float = lerp(inertia_min, inertia_max, push_factor)

	#gradually interpolating the current speed towards the target speed
	current_speed = lerp(current_speed, target_speed, clamp(dynamic_inertia * delta, 0.0, 1.0))
	current_angular = lerp(current_angular, target_angular, clamp(angular_inertia * delta, 0.0, 1.0))
	if Globals.player:
		Globals.player.set_linear_speed(current_speed)
		Globals.player.set_angular_speed(current_angular)

#speed reading
func process_arduino_data(line: String, _delta: float):
	var values = line.strip_edges().split("\t")
	if values.size() < 2:
		return
	var left_speed = float(values[0])      
	var right_speed = float(values[1])    

# Activity detection
	var wheel_active = abs(left_speed) > stop_threshold or abs(right_speed) > stop_threshold
	if wheel_active:
		time_since_wheel_active = 0.0

	target_speed = forward_gain * (left_speed + right_speed) * 0.5
	target_angular = (right_speed - left_speed) / wheel_distance

	# Reading the thrust counters
	if values.size() >= 15:
		push_count_total = int(values[2])   
		push_count_left = int(values[8])   
		push_count_right = int(values[14])  

		if push_count_total > last_push_count_total:
			time_since_last_push = 0.0
			last_push_count_total = push_count_total

# Cleaning at game close
func _exit_tree():
	if is_connected:
		serial.close()
	if Globals.player:
		Globals.player.set_linear_speed(0.0)
		Globals.player.set_angular_speed(0.0)
	print("[MiWe] Arduino déconnecté.")
