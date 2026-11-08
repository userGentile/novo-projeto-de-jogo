extends Area2D

@export var velocidade: float = 120.0
@export var dano: int = 1
@export var tempo_vida_max: float = 3.0

var direcao: Vector2 = Vector2.DOWN
var tempo_vida: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("tiros_inimigos_m2")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	rotation = direcao.angle()

func _physics_process(delta: float) -> void:
	position += direcao * velocidade * delta
	tempo_vida += delta
	if tempo_vida >= tempo_vida_max:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	_acertar(body)

func _on_area_entered(area: Area2D) -> void:
	_acertar(area)

func _acertar(alvo: Node) -> void:
	if alvo.is_in_group("player_m2") or alvo.is_in_group("player") or alvo.name == "Player":
		if alvo.has_method("receber_dano"):
			alvo.receber_dano(dano)
		elif alvo.has_method("tomar_dano"):
			alvo.tomar_dano(dano)
		queue_free()
	elif alvo is TileMapLayer or alvo is StaticBody2D:
		queue_free()
