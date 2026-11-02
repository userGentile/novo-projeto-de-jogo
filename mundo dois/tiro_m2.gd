extends Area2D

@export var velocidade: float = 220.0
@export var dano: int = 1
var direcao: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += direcao * velocidade * delta

func _on_body_entered(body: Node2D) -> void:
	_acertar(body)

func _on_area_entered(area: Area2D) -> void:
	_acertar(area)

func _acertar(alvo: Node) -> void:
	if alvo.is_in_group("inimigos_m2"):
		if alvo.has_method("receber_dano"):
			alvo.receber_dano(dano)
		elif alvo.has_method("take_damage"):
			alvo.take_damage(dano)
		queue_free()

func _on_timer_vida_timeout() -> void:
	queue_free()
