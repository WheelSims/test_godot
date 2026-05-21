# SignalBus (of type Autoload - Global Variable) can hold multiple signal 
# instances. Each receives information from a single script of interest 
extends Node

# signal pertaining to player.gd
signal player_trajectory # saves (global_position, rotation)

# signal force_capture will be added later
