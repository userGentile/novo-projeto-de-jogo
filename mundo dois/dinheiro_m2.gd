extends Area2D

const VELOCIDADE_ATRACAO: float = 180.0
const DISTANCIA_MAGNETICA: float = 45.0

@export var valor: int = 1
var player: CharacterBody2D = null
var coletado: bool = false

func _ready() -> void:
	add_to_group("drops_m2")
	body_entered.connect(_on_body_entered)
	_localizar_player()

func _physics_process(delta: float) -> void:
	if coletado:
		return
		
	if player == null or not is_instance_valid(player):
		_localizar_player()
		if player == null:
			return
			
	var dist = global_position.distance_to(player.global_position)
	if dist < DISTANCIA_MAGNETICA:
		var direcao = (player.global_position - global_position).normalized()
		global_position += direcao * VELOCIDADE_ATRACAO * delta

func _localizar_player() -> void:
	player = get_tree().get_first_node_in_group("player_m2") as CharacterBody2D
	if player == null:
		var p = get_tree().get_first_node_in_group("player")
		if p is CharacterBody2D:
			player = p

func _on_body_entered(body: Node2D) -> void:
	if coletado:
		return
	if body.is_in_group("player_m2") or body.is_in_group("player") or body.name == "Player":
		coletado = true
		if body.has_method("adicionar_ouro"):
			body.adicionar_ouro(valor)
		elif body.has_method("adicionar_dinheiro"):
			body.adicionar_dinheiro(valor)
		queue_free()
