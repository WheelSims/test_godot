## This script is autoloaded to keep a reference to the player from any scene, i.e.:
## Globals.player
extends Node
var player: RigidBody3D = null
@onready var main: Node = get_tree().get_root().get_node("main")
