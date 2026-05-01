extends Node

var score = 0
var max_health: int = 5
var current_health: int = 5

@onready var score_label: Label = $ScoreLabel
@onready var health_icons: Array[TextureRect] = [
	$HealthHUD/HealthRow/Fruit1,
	$HealthHUD/HealthRow/Fruit2,
	$HealthHUD/HealthRow/Fruit3,
	$HealthHUD/HealthRow/Fruit4,
	$HealthHUD/HealthRow/Fruit5,
]

func _ready() -> void:
	add_to_group("GameManager")
	_update_health_hud()

func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."

func set_health(value: int) -> void:
	current_health = clamp(value, 0, max_health)
	_update_health_hud()

func heal(amount: int) -> void:
	set_health(current_health + amount)

func _update_health_hud() -> void:
	for i in range(health_icons.size()):
		health_icons[i].visible = i < current_health
