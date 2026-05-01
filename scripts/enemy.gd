extends CharacterBody2D

@export var speed: float = 40.0
@export var direction: int = -1
@export var can_chase: bool = false
@export var detection_range: float = 120.0
@export var can_attack: bool = false
@export var attack_range_x: float = 14.0
@export var attack_range_y: float = 10.0
@export var attack_cooldown: float = 1.0
@export var can_be_countered: bool = true
@export var respawn_delay: float = 1.5

# 使用專案的重力設定，讓敵人和玩家一樣會落地。
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var attack_timer: float = 0.0
var attack_flash_timer: float = 0.0
var is_defeated: bool = false
var respawn_timer: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO
var spawn_direction: int = -1
var default_collision_layer: int = 0
var default_collision_mask: int = 0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_ray: RayCast2D = $RayCast2D
# 從 Player 群組中抓出玩家，之後追蹤時會用到這個節點。
@onready var player: Node2D = get_tree().get_first_node_in_group("Player")

func _ready() -> void:
	add_to_group("Enemy")
	spawn_position = global_position
	spawn_direction = direction
	default_collision_layer = collision_layer
	default_collision_mask = collision_mask
	floor_ray.position = Vector2.ZERO
	_update_facing()

func _physics_process(delta: float) -> void:
	if is_defeated:
		if respawn_timer > 0.0:
			respawn_timer -= delta
			if respawn_timer <= 0.0:
				_respawn()
		return

	if attack_timer > 0.0:
		attack_timer -= delta
	if attack_flash_timer > 0.0:
		attack_flash_timer -= delta
		if attack_flash_timer <= 0.0:
			animated_sprite.modulate = Color(1, 1, 1, 1)

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

	# 第三關開始加入攻擊：靠得很近時先停下並對玩家造成傷害。
	if can_attack and _is_player_in_attack_range():
		velocity.x = 0.0
		_try_attack()
	else:
		# 沒有進入攻擊距離時，就維持巡邏或追蹤移動。
		velocity.x = direction * speed

	move_and_slide()

	# 另一個轉向條件是撞牆，撞到就回頭。
	if is_on_wall():
		direction *= -1
		_update_facing()

	_try_counter_hit()

func _update_facing() -> void:
	animated_sprite.flip_h = direction > 0

func _is_player_in_range() -> bool:
	if player == null:
		return false
	# 用敵人和玩家的距離，判斷玩家是否進入追蹤範圍。
	return global_position.distance_to(player.global_position) < detection_range

func _is_player_in_attack_range() -> bool:
	if player == null:
		return false
	# 攻擊改成檢查水平與垂直距離，必須真的貼近玩家才算打到。
	var horizontal_distance: float = abs(player.global_position.x - global_position.x)
	var vertical_distance: float = abs(player.global_position.y - global_position.y)
	return horizontal_distance < attack_range_x and vertical_distance < attack_range_y

func _try_attack() -> void:
	if attack_timer > 0.0:
		return
	# 攻擊成功後進入冷卻，避免每一幀都連續扣血。
	attack_timer = attack_cooldown
	attack_flash_timer = 0.15
	animated_sprite.modulate = Color(1, 0.5, 0.5, 1)
	player.take_damage(1, global_position.x)

func _try_counter_hit() -> void:
	if not can_be_countered or player == null:
		return
	if player.velocity.y <= 0.0:
		return
	var horizontal_distance: float = abs(player.global_position.x - global_position.x)
	var vertical_offset: float = global_position.y - player.global_position.y
	if horizontal_distance < 12.0 and vertical_offset > 6.0 and vertical_offset < 20.0:
		_defeat_by_player()

func _defeat_by_player() -> void:
	is_defeated = true
	respawn_timer = respawn_delay
	global_position = spawn_position
	velocity = Vector2.ZERO
	animated_sprite.modulate = Color(1, 1, 1, 0.35)
	visible = false
	collision_layer = 0
	collision_mask = 0
	if player.has_method("heal"):
		player.heal(1)
		player.velocity.y = -220.0

func _respawn() -> void:
	is_defeated = false
	respawn_timer = 0.0
	global_position = spawn_position
	direction = spawn_direction
	velocity = Vector2.ZERO
	visible = true
	collision_layer = default_collision_layer
	collision_mask = default_collision_mask
	animated_sprite.modulate = Color(1, 1, 1, 1)
	_update_facing()
