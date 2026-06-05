## This script sets up a Global Variable of type Autoload
## It can hold instances of different signals. Each receives information
## from a single script of interest
extends Node

# signal pertaining to the current scene (main.gd)
@warning_ignore("unused_signal")
signal session_scene

# signal pertaining to player.gd, which saves (global_position, rotation)
@warning_ignore("unused_signal")
signal player_trajectory

# signal force_capture will be added later
