extends Area2D

const SPEED: float = 240.0
const TEMPO_VIDA_MAX: float = 2.5

var direction: Vector2 = Vector2.RIGHT
var tempo_vida: float = 0.0

@onready var visual: Node2D = get_node_or_null("Imagem-tiro")

func _ready() -> void:
	add_to_group("tiros")
	rotation = direction.angle()
	
	if visual:
		visual.scale = Vector2(1.4, 0.45)
		var tw: Tween = create_tween()
		tw.tween_property(visual, "scale", Vector2(1.125, 0.557), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	tempo_vida += delta
	if tempo_vida >= TEMPO_VIDA_MAX:
		queue_free()

func _impactar(alvo: Node) -> void:
	if alvo.has_method("tomar_dano"):
		if alvo.get_method_argument_count("tomar_dano") >= 2:
			alvo.tomar_dano(1, direction)
		else:
			alvo.tomar_dano(1)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		return
	
	if body.is_in_group("inimigos"):
		_impactar(body)
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("inimigos"):
		_impactar(area)
	elif area.get_parent() and area.get_parent().is_in_group("inimigos"):
		_impactar(area.get_parent())
