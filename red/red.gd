extends KinematicBody2D
class_name red

onready var tree: SceneTree = get_tree()

onready var sprite: Sprite = $"%sprite"
onready var collider: CollisionShape2D = $"%collider"
onready var sprite_land_animator: AnimationPlayer = $"%sprite_land_animator"
onready var sprite_wall_animator: AnimationPlayer = $"%sprite_wall_animator"
onready var sprite_crouch_animator: AnimationPlayer = $"%sprite_crouch_animator"
onready var sprite_idle_animator: AnimationPlayer = $"%sprite_idle_animator"
onready var jump_sfx: AudioStreamPlayer = $"%jump_sfx"
onready var land_sfx: AudioStreamPlayer = $"%land_sfx"
onready var walk_sfx: AudioStreamPlayer = $"%walk_sfx"
onready var crouch_sfx: AudioStreamPlayer = $"%crouch_sfx"
onready var crouch_out_sfx: AudioStreamPlayer = $"%crouch_out_sfx"
onready var stomp_sfx: AudioStreamPlayer = $"%stomp_sfx"
onready var remote_camera: RemoteTransform2D = $"%remote_transform_2d"

onready var half_width: float = collider.shape.extents.x
onready var width: float = half_width * 2.0
onready var height: float = collider.shape.extents.y * 2.0

export var jump_dust_scene: PackedScene
export var land_dust_scene: PackedScene
export var walk_dust_scene: PackedScene

var frame: int = 0;

const WALK_SPRITE_SLANT: float = 6.0

const MAX_WALK: float = 90.0
const MAX_FALL: float = 160.0
const JUMP_VEL: float = 300.0
const GRAV: float = 750.0
const F_GRAV: float = 1920.0
const WALK_WEIGHT: float = 0.5
const TILT_WEIGHT: float = 0.5

var velocity: Vector2 = Vector2.ZERO

var state: int = 0

var direction: int = 0
var is_jump_pressed: bool = false
var is_jump_just_pressed: bool = false
var is_down_pressed: bool = false
var is_stomp_jump: bool = false


func _ready() -> void:
	tree.current_scene.red = self
	# start at idle
	set_state(0)


func _physics_process(delta: float) -> void:
	if tree.current_scene.is_tweening:
		return
	
	# INPUT
	direction = int(Input.get_axis("left", "right"))
	is_jump_pressed = Input.is_action_pressed("jump")
	is_jump_just_pressed = Input.is_action_just_pressed("jump")
	is_down_pressed = Input.is_action_pressed("down")
	
	# HANDLE STATE
	match state:
		0: # IDLE
			# update velocity
			velocity.x = lerp(velocity.x, MAX_WALK * direction, WALK_WEIGHT)  # direction
			velocity.y += GRAV * delta  # gravity
			
			# update position and velocity
			velocity = move_and_slide(velocity, Vector2.UP)
			
			# exit
			# fall
			if !is_on_floor():
				set_state(3)
			# rise
			elif is_jump_just_pressed:
				set_state(2, {"is_jump_just_pressed": is_jump_just_pressed})
			# crouch
			elif is_down_pressed:
				set_state(4)
			# walk
			elif direction && !is_on_wall():
				set_state(1)
			
		1: # WALK
			# update velocity
			velocity.x = lerp(velocity.x, MAX_WALK * direction, WALK_WEIGHT)  # direction
			velocity.y += GRAV * delta  # gravity
			
			# update position and velocity
			velocity = move_and_slide(velocity, Vector2.UP)
			
			# tilt sprite
			sprite.rotation_degrees = lerp(sprite.rotation_degrees, -WALK_SPRITE_SLANT * direction, TILT_WEIGHT)
			
			# walk dust & walk sound
			walk_dust_and_sound()
			
			# hit wall?
			var is_on_wall: bool = is_on_wall()
			
			# exit
			# fall
			if !is_on_floor():
				set_state(3)
			# rise
			elif is_jump_just_pressed:
				set_state(2, {"is_jump_just_pressed": is_jump_just_pressed})
			# crouch
			elif is_down_pressed:
				set_state(4)
			# idle
			elif !direction || is_on_wall:
				set_state(0, {"is_on_wall": is_on_wall})
				
		2: # RISE
			# update velocity
			velocity.x = lerp(velocity.x, MAX_WALK * direction, WALK_WEIGHT)  # direction
			if !is_stomp_jump:
				velocity.y += GRAV * delta if is_jump_pressed else F_GRAV * delta  # VARIED gravity
			else:
				velocity.y += GRAV * delta  # gravity
			
			# update position and velocity
			velocity = move_and_slide(velocity, Vector2.UP)
			
			# tilt sprite
			sprite.rotation_degrees = lerp(sprite.rotation_degrees, -WALK_SPRITE_SLANT * direction, TILT_WEIGHT)
			
			# exit
			# fall
			if velocity.y > 0:
				set_state(3)
			
		3: # FALL
			# update velocity
			velocity.x = lerp(velocity.x, MAX_WALK * direction, WALK_WEIGHT)  # direction
			velocity.y += GRAV * delta  # gravity
			
			# update position and velocity
			velocity = move_and_slide(velocity, Vector2.UP)
			
			# tilt sprite
			sprite.rotation_degrees = lerp(sprite.rotation_degrees, -WALK_SPRITE_SLANT * direction, TILT_WEIGHT)
			
			# exit
			# landed
			if is_on_floor():
				# crouch
				if is_down_pressed:
					set_state(4)
				# to idle
				elif !direction:
					set_state(0)
				# to walk
				elif direction:
					set_state(1)
				
		4: # CROUCH
			# update velocity
			velocity.y += GRAV * delta  # gravity
			
			# update position and velocity
			velocity = move_and_slide(velocity, Vector2.UP)
			
			# drop down check
			var is_drop_down: bool = is_drop_down()
			
			# exit
			# fall
			if !is_on_floor() || is_drop_down:
				set_state(3, {"is_drop_down": is_drop_down})
			# rise
			elif is_jump_just_pressed:
				set_state(2, {"is_jump_just_pressed": is_jump_just_pressed})
			# idle
			elif !is_down_pressed:
				set_state(0)


####################
#  SETTER & ENTRY  #
####################
func set_state(value, message = {}) -> void:
	var old_state: int = state
	state = value
		
	# ENTRY
	match state:
		0: # IDLE
			# from all
			sprite_idle_animator.play("default")
			sprite.rotation_degrees = 0.0
			
			# from fall
			if old_state == 3:
				sprite_idle_animator.play("RESET")
				sprite_land_animator.play("default")
				land_dust_and_sound()
			
			# from walk
			elif old_state == 1:
				# hit a wall (direction should has value then)
				if message.is_on_wall == true:
					wall_hit_animation_and_sound()
			
			# from crouch
			elif old_state == 4:
				sprite_idle_animator.play("RESET")
				sprite_crouch_animator.stop()
				sprite_crouch_animator.play("out")
				crouch_out_sfx.play()
			
		1: # WALK
			# from idle
			if old_state == 0:
				sprite_idle_animator.play("RESET")
			# from fall
			elif old_state == 3:
				sprite_land_animator.stop(true)
				sprite_land_animator.play("default")
				land_dust_and_sound()
				
		2: # RISE
			# from all
			# due to jump button
			if message.is_jump_just_pressed == true:
				velocity.y = -JUMP_VEL
				jump_dust_and_sound()
			# from outside (spring, enemies, anything)
			elif message.is_from_outside:
				velocity.y = -message.is_from_outside
				jump_dust_and_sound(true)
				is_stomp_jump = true
			
			# from idle
			if old_state == 0:
				sprite_idle_animator.play("RESET")
			# from crouch
			elif old_state == 4:
				sprite_idle_animator.play("RESET")
			
		3: # FALL
			# from all
			is_stomp_jump = false
			
			# from idle
			if old_state == 0:
				sprite_idle_animator.play("RESET")
			# from crouch
			elif old_state == 4:
				sprite_idle_animator.play("RESET")
				if message.is_drop_down == true:
					global_position.y += 1
			
		4: # CROUCH
			# from all
			velocity.x = 0.0
			sprite.rotation_degrees = 0.0
			sprite_crouch_animator.stop()
			sprite_crouch_animator.play("in")
			crouch_sfx.play()
			
			# from idle
			if old_state == 0:
				sprite_idle_animator.play("RESET")


#############
#  HELPERS  #
#############
func walk_dust_and_sound() -> void:
	if frame % 15 == 0:
		var walk_dust: Particles2D = walk_dust_scene.instance() as Particles2D
		tree.current_scene.add_child(walk_dust)
		walk_dust.global_position = global_position
		walk_sfx.play()
		frame = 0
	frame += 1


func land_dust_and_sound() -> void:
	var land_dust: Particles2D = land_dust_scene.instance() as Particles2D
	tree.current_scene.add_child(land_dust)
	land_dust.global_position = global_position
	land_sfx.play()


func wall_hit_animation_and_sound() -> void:
	if direction == 1:
		sprite_wall_animator.play("right_hit")
	elif direction == -1:
		sprite_wall_animator.play("left_hit")
	land_sfx.play()


func jump_dust_and_sound(is_outside: bool = false) -> void:
	var jump_dust: Particles2D = jump_dust_scene.instance() as Particles2D
	tree.current_scene.add_child(jump_dust)
	jump_dust.global_position = global_position
	jump_sfx.play() if !is_outside else stomp_sfx.play()


func is_drop_down() -> bool:
	if !Input.is_action_just_pressed("jump"):
		return false
		
	var collision_info: KinematicCollision2D = move_and_collide(Vector2.DOWN)
	if collision_info.collider.collision_layer == 4:  # platform layer
		return true
	
	return false


# called by land and crouch out animator
func play_idle_animation() -> void:
	if state != 0:
		return
		
	sprite_idle_animator.play("default")
