extends CharacterBody2D

@export var speed: float = 40.0
@export var direction: int = -1
@export var can_chase: bool = false
@export var detection_range: float = 120.0

# 使用專案的重力設定，讓敵人和玩家一樣會落地。
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_ray: RayCast2D = $RayCast2D
# 從 Player 群組中抓出玩家，之後追蹤時會用到這個節點。
@onready var player: Node2D = get_tree().get_first_node_in_group("Player")

func _ready() -> void:
	add_to_group("Enemy")
	floor_ray.position = Vector2.ZERO
	_update_facing()

func _physics_process(delta: float) -> void:
	# 套用重力，讓敵人會掉落並站回平台上。
	if not is_on_floor():
		velocity.y += gravity * delta

	# 把 RayCast 指向前下方，檢查下一步前面還有沒有地板。
	floor_ray.target_position = Vector2(10 * direction, 12)
	floor_ray.force_raycast_update()

	# 如果前面已經沒有地板，就先轉身，避免直接走下平台。
	if is_on_floor() and not floor_ray.is_colliding():
		direction *= -1
		_update_facing()
		floor_ray.target_position = Vector2(10 * direction, 12)

	# 第二關開始加入追蹤：玩家進入偵測範圍時，改成朝玩家方向移動。
	if can_chase and _is_player_in_range():
		# 如果玩家在右邊，就往右追。
		if player.global_position.x > global_position.x:
			direction = 1
			_update_facing()
		# 如果玩家在左邊，就往左追。
		elif player.global_position.x < global_position.x:
			direction = -1
			_update_facing()

	# 巡邏的核心：持續朝目前方向移動。
	velocity.x = direction * speed

	move_and_slide()

	# 另一個轉向條件是撞牆，撞到就回頭。
	if is_on_wall():
		direction *= -1
		_update_facing()

func _update_facing() -> void:
	animated_sprite.flip_h = direction > 0

func _is_player_in_range() -> bool:
	if player == null:
		return false
	# 用敵人和玩家的距離，判斷玩家是否進入追蹤範圍。
	return global_position.distance_to(player.global_position) < detection_range
