extends Node2D

const INIMIGO_COMUM_SCENE = preload("res://inimigo.tscn")
const INIMIGO_CAMINHAO_SCENE = preload("res://inimigo_caminhao.tscn")
const INIMIGO_AVIAO_SCENE = preload("res://inimigo_aviao.tscn")
const INIMIGO_TANQUE_SCENE = preload("res://inimigo_tanque.tscn")
const AMIGO_SOLDADO_SCENE = preload("res://amigo_soldado.tscn")

const CORES = ["cinza", "verde", "azul", "amarelo"]

const MAPA_MIN_X = 20.0
const MAPA_MAX_X = 580.0
const MAPA_MIN_Y = 20.0
const MAPA_MAX_Y = 280.0

var onda_atual: int = 1
var inimigos_vivos: int = 0
var mudando_de_onda: bool = false
var player: CharacterBody2D = null

@onready var agua_layer: TileMapLayer = get_node_or_null("Mundo/Água")

func _ready() -> void:
	player = get_node_or_null("Player")
	iniciar_onda(onda_atual)

func iniciar_onda(numero: int) -> void:
	mudando_de_onda = false
	onda_atual = numero
	
	if onda_atual > 1 and (onda_atual - 1) % 10 == 0:
		if player == null:
			player = get_node_or_null("Player")
			if player == null and is_inside_tree() and get_tree():
				player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player and player.has_method("ganhar_vida_extra"):
			player.ganhar_vida_extra()
	
	var total_inimigos = 9 + (onda_atual - 1) * 3
	inimigos_vivos = total_inimigos
	
	atualizar_hud()
	
	for i in range(total_inimigos):
		spawn_inimigo_para_onda(i, total_inimigos)
		
	if onda_atual % 2 == 0:
		_spawn_reforcos_aliados()

func spawn_inimigo_para_onda(indice: int, total: int) -> void:
	var cena_inimigo: PackedScene = INIMIGO_COMUM_SCENE
	var eh_atirador_comum = (indice % 2 == 1)
	
	# Regras de aparição dos inimigos grandes:
	# Tanque: a partir da onda 7 (~1 ou 2 por onda)
	if onda_atual >= 7 and indice == 0:
		cena_inimigo = INIMIGO_TANQUE_SCENE
	# Avião: a partir da onda 5 (~1 ou 2 por onda)
	elif onda_atual >= 5 and (indice == 1 or (onda_atual >= 8 and indice == total - 1)):
		cena_inimigo = INIMIGO_AVIAO_SCENE
	# Caminhão: a partir da onda 3 (~1 ou 2 por onda)
	elif onda_atual >= 3 and (indice == 2 or (onda_atual >= 6 and indice == 3)):
		cena_inimigo = INIMIGO_CAMINHAO_SCENE
		
	var inimigo = cena_inimigo.instantiate()
	
	# Se for o inimigo comum, define a cor e comportamento
	if cena_inimigo == INIMIGO_COMUM_SCENE:
		var cor_aleatoria = CORES[randi() % CORES.size()]
		inimigo.tipo_cor = cor_aleatoria
		if eh_atirador_comum:
			inimigo.comportamento = "atirador"
		else:
			inimigo.comportamento = "perseguidor"
			
	inimigo.morreu.connect(_on_inimigo_morreu)
	
	var pos_spawn = sortear_posicao_valida_borda()
	inimigo.position = pos_spawn
	add_child(inimigo)

func sortear_posicao_valida_borda() -> Vector2:
	for tentativa in range(30):
		var borda = randi() % 4
		var pos = Vector2.ZERO
		
		match borda:
			0: # Topo
				pos = Vector2(randf_range(MAPA_MIN_X, MAPA_MAX_X), MAPA_MIN_Y)
			1: # Fundo
				pos = Vector2(randf_range(MAPA_MIN_X, MAPA_MAX_X), MAPA_MAX_Y)
			2: # Esquerda
				pos = Vector2(MAPA_MIN_X, randf_range(MAPA_MIN_Y, MAPA_MAX_Y))
			3: # Direita
				pos = Vector2(MAPA_MAX_X, randf_range(MAPA_MIN_Y, MAPA_MAX_Y))
		
		if not esta_na_agua(pos):
			return pos
			
	return Vector2(randf_range(100.0, 500.0), MAPA_MIN_Y)

func esta_na_agua(pos_global: Vector2) -> bool:
	if agua_layer == null:
		agua_layer = get_node_or_null("Mundo/Água")
		
	if agua_layer:
		var pos_local = agua_layer.to_local(pos_global)
		var celula = agua_layer.local_to_map(pos_local)
		if agua_layer.get_cell_source_id(celula) != -1:
			return true
			
		for offset in [Vector2(-8, 0), Vector2(8, 0), Vector2(0, -8), Vector2(0, 8)]:
			var celula_offset = agua_layer.local_to_map(agua_layer.to_local(pos_global + offset))
			if agua_layer.get_cell_source_id(celula_offset) != -1:
				return true
				
	return false

func _on_inimigo_morreu(inimigo: Node2D) -> void:
	inimigos_vivos -= 1
	if inimigos_vivos < 0:
		inimigos_vivos = 0
		
	atualizar_hud()
	
	if inimigos_vivos == 0 and not mudando_de_onda:
		mudando_de_onda = true
		chamar_proxima_onda()

func chamar_proxima_onda() -> void:
	for t in get_tree().get_nodes_in_group("tiros_inimigos"):
		if is_instance_valid(t):
			t.queue_free()
			
	var timer = get_tree().create_timer(1.5)
	await timer.timeout
	iniciar_onda(onda_atual + 1)

func atualizar_hud() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("atualizar_hud_onda"):
		player.atualizar_hud_onda(onda_atual, inimigos_vivos)

func _spawn_reforcos_aliados() -> void:
	if player == null:
		if is_inside_tree() and get_tree():
			player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		else:
			player = get_node_or_null("Player") as CharacterBody2D
	if player == null:
		return
		
	var posicoes = [Vector2(-24, 0), Vector2(24, 0)]
	for offset in posicoes:
		var amigo = AMIGO_SOLDADO_SCENE.instantiate()
		amigo.offset_formacao = offset
		amigo.global_position = player.global_position + offset
		add_child(amigo)
