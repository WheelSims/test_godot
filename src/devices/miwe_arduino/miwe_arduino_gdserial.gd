extends Node3D
@export var serial_port: String = "COM5" 
@export var baud_rate: int = 250000  

# Feel Settings
@export var forward_gain: float = 2.5  
var wheel_distance: float = 0.6
@export var stop_threshold: float = 0.05  

var serial: GdSerial  #Object for communicating with Arduino
var is_connected: bool = false # Connection status

#linear and angular speed
var current_speed: float = 0.0  
var current_angular: float = 0.0  

var time_since_wheel_active: float = 0.0  #Time of the last wheel activity  


func _ready():
	serial = GdSerial.new()
	var ports = serial.list_ports()
	print("Ports disponibles : ", ports)
	serial.set_port(serial_port)
	serial.set_baud_rate(baud_rate)

	if serial.open():
		is_connected = true
		print("[MiWe] Arduino connecté sur ", serial_port)
	else:
		print("[MiWe] Échec de la connexion sur ", serial_port)

#loops through retrieving serial data from the Arduino
func _physics_process(delta: float) -> void:
	if is_connected:
		while serial.bytes_available() > 0:
			var data = serial.readline()
			if data != "":
				process_arduino_data(data, delta)

	time_since_wheel_active += delta


	if Globals.player:
		Globals.player.set_linear_speed(current_speed)
		Globals.player.set_angular_speed(current_angular)

#
func process_arduino_data(line: String, _delta: float):
	var values = line.strip_edges().split("\t")

	if values.size() < 2:
		return
		
	var left_speed = forward_gain * float(values[0])      
	var right_speed = forward_gain * float(values[1])    

# Activity detection
	var wheel_active = abs(left_speed) > stop_threshold or abs(right_speed) > stop_threshold
	if wheel_active:
		time_since_wheel_active = 0.0
	#kinematic model
	current_speed = forward_gain * (left_speed + right_speed) * 0.5
	current_angular = (right_speed - left_speed)/wheel_distance

# Cleaning at game close
func _exit_tree():
	if is_connected:
		serial.close()

	if Globals.player:
		Globals.player.set_linear_speed(0.0)
		Globals.player.set_angular_speed(0.0)

	print("[MiWe] Arduino déconnecté.")
