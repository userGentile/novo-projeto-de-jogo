extends Area2D

const SPEED: float = 135.0
const TEMPO_VIDA_MAX: float = 2.8

var direction: Vector2 = Vector2.DOWN
var tempo_vida: float = 0.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	add_to_group("tiros_inimigos")
	rotation = direction.angle()
	
	if sprite:
		sprite.scale = Vector2(1.35, 0.7)
		var tw: Tween = create_tween()
		tw.tween_property(sprite, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	tempo_vida += delta
	if tempo_vida >= TEMPO_VIDA_MAX:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("tomar_dano"):
			body.tomar_dano(1)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass
