tool
extends Area2D

onready var tree: SceneTree = get_tree()

var horizontal_door_shape: Shape2D = preload("res://assets/tres/door.tres") as Shape2D 
var vertical_door_shape: Shape2D = preload("res://assets/tres/vertical_door.tres") as Shape2D 

const TWEEN_DURATION = 0.6

export(String, FILE) var target_room_scene

enum DIRECTION { left, top, right, down  }
export(DIRECTION) var direction = DIRECTION.left setget set_direction


# run in game only
func _ready() -> void:
	if Engine.editor_hint:
		return
	target_room_scene = load(target_room_scene) as PackedScene if target_room_scene else null


# run in editor and game
func set_direction(value) -> void:
	direction = value
	if (direction == DIRECTION.left):
		get_child(0).shape = horizontal_door_shape
	elif (direction == DIRECTION.top):
		get_child(0).shape = vertical_door_shape
	elif (direction == DIRECTION.right):
		get_child(0).shape = horizontal_door_shape
	elif (direction == DIRECTION.down):
		get_child(0).shape = vertical_door_shape


# run in game only
func _on_door_body_entered(red: red) -> void:
	# do not run this in editor
	if Engine.editor_hint:
		return
		
	# instance target room and add child
	var target_room: Node2D = target_room_scene.instance() as Node2D
	tree.current_scene.room_layer.add_child(target_room)
	
	# pause actors physics process
	tree.current_scene.is_tweening = true
	# disable collider / so target room door will not detect
	red.collider.disabled = true
	# detach red remote to cam
	red.remote_camera.remote_path = ""
	
	# remove camera limit
	tree.current_scene.cam.remove_limit()
	
	# these needs to be off during tween
	tree.current_scene.cam.limit_smoothed = false
	tree.current_scene.cam.smoothing_enabled = false
	
	# prepare tween
	var tween = tree.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# LEFT
	if (direction == DIRECTION.left):
		# set camera starting position
		tree.current_scene.cam.global_position = global_position + tree.current_scene.cam.half_size
		tree.current_scene.cam.reset_smoothing()
		# set red starting position
		red.global_position.x = global_position.x + red.half_width
		# tween cam
		tween.tween_property(tree.current_scene.cam, "global_position:x", -tree.current_scene.cam.size.x, TWEEN_DURATION).as_relative()
		# tween red - add 1 extra px to avoid next door
		tween.parallel().tween_property(red, "global_position:x", -red.width - 1.0, TWEEN_DURATION).as_relative()
		# callback
		tween.tween_callback(self, "on_tween_finished", [target_room, red])
	
	# RIGHT
	elif (direction == DIRECTION.right):
		# set camera starting position
		tree.current_scene.cam.global_position = global_position + tree.current_scene.cam.half_size
		tree.current_scene.cam.global_position.x -= tree.current_scene.cam.size.x
		tree.current_scene.cam.reset_smoothing()
		# set red starting position
		red.global_position.x = global_position.x - red.half_width
		# tween cam
		tween.tween_property(tree.current_scene.cam, "global_position:x", tree.current_scene.cam.size.x, TWEEN_DURATION).as_relative()
		# tween red - add 1 extra px to avoid next door
		tween.parallel().tween_property(red, "global_position:x", red.width + 1.0, TWEEN_DURATION).as_relative()
		# callback
		tween.tween_callback(self, "on_tween_finished", [target_room, red])
	
	# TOP
	elif (direction == DIRECTION.top):
		# set camera starting position
		tree.current_scene.cam.global_position = global_position + tree.current_scene.cam.half_size
		tree.current_scene.cam.reset_smoothing()
		# set red starting position
		red.global_position.y = global_position.y + red.height
		# tween cam (up by 176 not 180)
		tween.tween_property(tree.current_scene.cam, "global_position:y", -tree.current_scene.cam.size.y + 4.0, TWEEN_DURATION).as_relative()
		# tween red - add 2 extra tile to avoid next door
		tween.parallel().tween_property(red, "global_position:y", -red.height - 16.0, TWEEN_DURATION).as_relative()
		# callback
		tween.tween_callback(self, "on_tween_finished", [target_room, red])
	
	# DOWN
	elif (direction == DIRECTION.down):
		# set camera starting position
		tree.current_scene.cam.global_position = global_position + tree.current_scene.cam.half_size
		tree.current_scene.cam.global_position.y -= tree.current_scene.cam.size.y - 4.0
		tree.current_scene.cam.reset_smoothing()
		# set red starting position
		red.global_position.y = global_position.y
		# tween cam (down by 176 not 180)
		tween.tween_property(tree.current_scene.cam, "global_position:y", tree.current_scene.cam.size.y - 4.0, TWEEN_DURATION).as_relative()
		# tween red - add 1 extra px to avoid next door
		tween.parallel().tween_property(red, "global_position:y", red.height + 1.0, TWEEN_DURATION).as_relative()
		# callback
		tween.tween_callback(self, "on_tween_finished", [target_room, red])


func on_tween_finished(target_room, red) -> void:
	# camera limit
	tree.current_scene.cam.update_limit(target_room.cam_limit)
	# tween is over, turn on smoothing
	tree.current_scene.cam.limit_smoothed = true
	tree.current_scene.cam.smoothing_enabled = true
	
	# hook player remote to cam
	red.remote_camera.remote_path = tree.current_scene.cam.path
	tree.current_scene.cam.reset_smoothing()
	# pause actors physics process
	tree.current_scene.is_tweening = false
	# disable collider / so target room door will not detect
	red.collider.disabled = false
	
	# remove old room and update current room
	tree.current_scene.current_room.queue_free()
	tree.current_scene.current_room = target_room
