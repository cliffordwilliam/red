extends Camera2D
class_name cam

onready var tree: SceneTree = get_tree()
onready var path: NodePath = get_path()

onready var shake_animator: AnimationPlayer = $"%shake_animator"

onready var size: Vector2 = get_viewport_rect().size
onready var half_size: Vector2 = size * 0.5


func _ready() -> void:
	tree.current_scene.cam = self


func update_limit(room_cam_limit) -> void:
	limit_left = room_cam_limit.rect_global_position.x
	limit_top = room_cam_limit.rect_global_position.y
	limit_right = limit_left + room_cam_limit.rect_size.x
	limit_bottom = limit_top + room_cam_limit.rect_size.y
	reset_smoothing()


func remove_limit() -> void:
	limit_left = -1000000
	limit_top = -1000000
	limit_right = 1000000
	limit_bottom = 1000000
