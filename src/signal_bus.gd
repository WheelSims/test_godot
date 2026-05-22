## This script sets up a Global Variable of type Autoload
## It can hold instances of different signals. Each receives information
## from a single script of interest
extends Node

# signal pertaining to the current participant ("test", ID, or name)
#signal participant_id

# signal pertaining to the current scene (main.gd)
signal session_scene

# signal pertaining to player.gd, which saves (global_position, rotation)
signal player_trajectory

# signal force_capture will be added later
