extends Area2D

onready var tree: SceneTree = get_tree()

export var walk_dust_scene: PackedScene
export var explosion_scene: PackedScene

onready var collider: CollisionShape2D = $"%collider"
onready var sprite_wall_animator: AnimationPlayer = $"%sprite_wall_animator"
onready var explosion_sfx: AudioStreamPlayer = $"%explosion_sfx"

const MAX_WALK: float = 15.0
var direction: int = 1
var old_global_position_x = 0
var hp: int = 3
var is_hurting: bool = false
var is_dead: bool = false

const STOMP_VEL: float = 200.0

var frame: int = 0


func _physics_process(delta: float) -> void:
	if tree.current_scene.is_tweening:
		return
		
	if is_hurting:
		return
		
	if is_dead:
		return
		
	old_global_position_x = global_position.x
	global_position.x += MAX_WALK * direction * delta
	walk_dust()


func _on_crawler_body_entered(body: Node) -> void:
	if is_dead:
		return
		
	# not red? bounce horizontally
	if body.name != "red":
		global_position.x = old_global_position_x
		if direction == 1:
			sprite_wall_animator.play("right_hit")
		else:
			sprite_wall_animator.play("left_hit")
		direction *= -1
	# red? red moving down? hurt & make red hop
	else:
		if body.velocity.y > 0:
			body.set_state(2, {
				"is_jump_just_pressed": false, 
				"is_from_outside": STOMP_VEL
			})
			hp -= 1
			if hp > 0:
				sprite_wall_animator.play("hurt")
				is_hurting = true
			else:
				explosion_sfx.play()
				sprite_wall_animator.play("dead")
				is_dead = true
				tree.current_scene.cam.shake_animator.play("small_shake")


func walk_dust() -> void:
	if frame % 15 == 0:
		var walk_dust: Particles2D = walk_dust_scene.instance() as Particles2D
		tree.current_scene.add_child(walk_dust)
		walk_dust.global_position = global_position
		frame = 0
	frame += 1


# called by dead animation in sprite wall animator
func create_explosion() -> void:
	var explosion: Particles2D = explosion_scene.instance() as Particles2D
	tree.current_scene.add_child(explosion)
	explosion.global_position = global_position - Vector2(0.0, 8.0)
	explosion.global_position += Vector2(rand_range(-16.0, 16.0), rand_range(-16.0, 16.0))


func _on_sprite_wall_animator_animation_finished(anim_name: String) -> void:
	is_hurting = false


func _on_crawler_area_entered(area: Area2D) -> void:
	global_position.x = old_global_position_x
	if direction == 1:
		sprite_wall_animator.play("right_hit")
	else:
		sprite_wall_animator.play("left_hit")
	direction *= -1
