extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health := 5
var hurt_timer := 0.0
var knockback_velocity := 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var game_manager: Node = get_tree().get_first_node_in_group("GameManager")

func _ready():
	add_to_group("Player")
	if game_manager:
		game_manager.set_health(health)

func _physics_process(delta):
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			modulate = Color(1, 1, 1, 1)

	if abs(knockback_velocity) > 0.0:
		knockback_velocity = move_toward(knockback_velocity, 0.0, 900.0 * delta)

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 受傷時會被往敵人的反方向推開，讓攻擊更有手感。
	velocity.x += knockback_velocity

	move_and_slide()

func take_damage(amount: int, source_x: float = global_position.x):
	health = max(health - amount, 0)
	hurt_timer = 0.2
	modulate = Color(1, 0.6, 0.6, 1)
	var push_direction := 1.0 if source_x <= global_position.x else -1.0
	knockback_velocity = 180.0 * push_direction
	if game_manager:
		game_manager.set_health(health)
	print("Player HP: ", health)
