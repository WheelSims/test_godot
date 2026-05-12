extends Node3D

@export var serial_port: String = "COM5"  # Port série de l'arduino
@export var baud_rate: int = 250000  # Baudrate

# Paramètres de sensation
@export var forward_gain: float = 5.0  # Force avant
#@export var reverse_gain: float = 5.0  # Force marche arrière
#@export var turn_gain: float = 2.5  # Force de rotation
#@export var friction: float = 0.6  # Friction 
#@export var angular_friction: float = 1.0  # Ralentissement lors de la rotation 
#@export var max_speed: float = 2.0  # Vitesse max
var wheel_distance: float = 0.6

@export var slope_enabled: bool = true  # Active/désactive le système 
@export var slope_send_interval: float = 0.1  # Fréquence d'envoi (en secondes) 
@export var slope_amplification: float = 1.0  # Multiplie l'angle détecté 
@export var slope_min_angle: float = 0.02

## Paramètres arrêt
@export var stop_threshold: float = 0.05  # Seuil pour detecter un mouvement 
#@export var stop_timeout: float = 0.3  # Delai avant arret 
#@export var stop_deceleration: float = 2.0  # Vitesse de freinage autommatique

var time_since_last_slope_send: float = 0.0

var serial: GdSerial  # Objet pour communiquer avec arduino
var is_connected: bool = false # Etat de la connexion

var current_speed: float = 0.0  # Vitesse du joueur
var current_angular: float = 0.0  # Vitesse de rotation 
var time_since_wheel_active: float = 0.0  #Temps de la derniere activite des roues  
var current_slope: float =0.0

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


func _physics_process(delta: float) -> void:
	if is_connected:
		while serial.bytes_available() > 0:
			var data = serial.readline()
			if data != "":
				process_arduino_data(data, delta)


## Friction continue
	#if time_since_wheel_active > stop_timeout:
		#current_speed = move_toward(current_speed, 0.0, stop_deceleration * delta)
		#current_angular = move_toward(current_angular, 0.0, stop_deceleration * delta)
	#else:
		#current_speed = move_toward(current_speed, 0.0, friction * delta)
		#current_angular = move_toward(current_angular, 0.0, angular_friction * delta)
#
	#current_speed = clamp(current_speed, -max_speed, max_speed)

	if Globals.player:
		Globals.player.set_linear_speed(current_speed)
		Globals.player.set_angular_speed(current_angular)


func process_arduino_data(line: String, _delta: float):
	var values = line.strip_edges().split("\t")

	if values.size() < 2:
		return

	var left_speed = float(values[0])      
	var right_speed = float(values[1])     

# Détection d'activite
	var wheel_active = abs(left_speed) > stop_threshold or abs(right_speed) > stop_threshold
	if wheel_active:
		time_since_wheel_active = 0.0

	current_speed = forward_gain * (left_speed + right_speed) * 0.5
	current_angular = (right_speed - left_speed)/wheel_distance

# Nettoyage a la fermeture du jeu 
func _exit_tree():
	if is_connected:
		serial.close()
		if Globals.player:
			Globals.player.set_linear_speed(0.0)
			Globals.player.set_angular_speed(0.0)
		print("[MiWe] Arduino déconnecté.")
