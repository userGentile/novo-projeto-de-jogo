extends Node2D

const INIMIGO_M2_SCENE: PackedScene = preload("res://mundo dois/inimigo_m2.tscn")

@export var raio_spawn_min: float = 280.0
@export var raio_spawn_max: float = 380.0

@export var delay_entre_ondas: float = 2.0

var onda_atual: int = 1
var inimigos_vivos: int = 0
var mudando_de_onda: bool = false
var player: CharacterBody2D = null

func _ready() -> void:
	_localizar_player()
	iniciar_onda(onda_atual)

func _localizar_player() -> void:
	if player != null and is_instance_valid(player):
		return
	player = get_tree().get_first_node_in_group("player_m2") as CharacterBody2D
	if player == null:
		var p = get_tree().get_first_node_in_group("player")
		if p is CharacterBody2D:
			player = p
	if player == null:
		player = get_node_or_null("../Player") as CharacterBody2D

func iniciar_onda(numero: int) -> void:
	mudando_de_onda = false
	onda_atual = numero
	_localizar_player()
	
	var total_inimigos: int = 6 + (onda_atual - 1) * 3
	inimigos_vivos = total_inimigos
	atualizar_hud()
	
	for i in range(total_inimigos):
		_spawn_inimigo(i, total_inimigos)

func _spawn_inimigo(indice: int, total: int) -> void:
	var inimigo = INIMIGO_M2_SCENE.instantiate()
	var tipo_escolhido: String = "soldado"
	
	if onda_atual >= 3:
		var sorteio = randf()
		if sorteio < 0.25:
			tipo_escolhido = "feiticeiro"
		elif sorteio < 0.55:
			tipo_escolhido = "guerreiro"
		else:
			tipo_escolhido = "soldado"
	elif onda_atual == 2:
		if indice % 3 == 0:
			tipo_escolhido = "guerreiro"
		else:
			tipo_escolhido = "soldado"
	else:
		tipo_escolhido = "soldado"
		
	inimigo.tipo = tipo_escolhido
	inimigo.morreu.connect(_on_inimigo_morreu)
	inimigo.global_position = _calcular_posicao_spawn()
	
	get_parent().call_deferred("add_child", inimigo)

func _calcular_posicao_spawn() -> Vector2:
	_localizar_player()
	var centro = player.global_position if (player and is_instance_valid(player)) else global_position
	var angulo = randf_range(0.0, TAU)
	var distancia = randf_range(raio_spawn_min, raio_spawn_max)
	return centro + Vector2(cos(angulo), sin(angulo)) * distancia

func _on_inimigo_morreu(_inimigo: CharacterBody2D) -> void:
	inimigos_vivos = maxi(0, inimigos_vivos - 1)
	atualizar_hud()
	
	if inimigos_vivos == 0 and not mudando_de_onda:
		mudando_de_onda = true
		_concluir_onda()

func _concluir_onda() -> void:
	for t in get_tree().get_nodes_in_group("tiros_inimigos_m2"):
		if is_instance_valid(t):
			t.queue_free()
			
	await get_tree().create_timer(delay_entre_ondas).timeout
	iniciar_onda(onda_atual + 1)

func atualizar_hud() -> void:
	_localizar_player()
	if player == null:
		return
		
	if player.has_method("atualizar_hud_onda"):
		player.atualizar_hud_onda(onda_atual, inimigos_vivos)
	else:
		var hud = player.get_node_or_null("HUD")
		if hud:
			var label_onda = hud.get_node_or_null("MarginContainer/HBoxContainer/OndaContainer/LabelOnda")
			if label_onda:
				label_onda.text = "Onda: " + str(onda_atual)
