extends Node
class_name world

onready var tree: SceneTree = get_tree()

onready var red: red
onready var cam: cam

onready var room_layer: Node2D = $"%room_layer"

export var first_room_scene: PackedScene

var current_room: Node2D

var is_tweening = false


func _ready() -> void:
	# room 0 / save rooms
	var first_room: room = first_room_scene.instance() as room
	room_layer.add_child(first_room)
	current_room = first_room
	# position red
	red.global_position = first_room.red_position.global_position
	# camera limit
	cam.update_limit(first_room.cam_limit)
	# hook player remote to cam
	red.remote_camera.remote_path = cam.path
	cam.reset_smoothing()
