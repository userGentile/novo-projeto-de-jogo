extends Area2D

const SPEED_COLETA = 160.0
var valor: int = 10
var player: CharacterBody2D = null
var coletado: bool = false

func _ready() -> void:
	add_to_group("dinheiro_tap")
	# Encontra o jogador
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if coletado:
		return
		
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		# Se o jogador se aproximar (raio magnético estilo bullet heaven de 50px)
		if dist < 50.0:
			var direcao = (player.global_position - global_position).normalized()
			global_position += direcao * SPEED_COLETA * delta

func _on_body_entered(body: Node2D) -> void:
	if coletado:
		return
	if body.is_in_group("player") or body.name == "Player":
		coletado = true
		if body.has_method("adicionar_dinheiro"):
			body.adicionar_dinheiro(valor)
		queue_free()
