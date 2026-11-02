extends Node2D

const INIMIGO_COMUM_SCENE: PackedScene = preload("res://inimigo.tscn")
const INIMIGO_CAMINHAO_SCENE: PackedScene = preload("res://inimigo_caminhao.tscn")
const INIMIGO_AVIAO_SCENE: PackedScene = preload("res://inimigo_aviao.tscn")
const INIMIGO_TANQUE_SCENE: PackedScene = preload("res://inimigo_tanque.tscn")
const AMIGO_SOLDADO_SCENE: PackedScene = preload("res://amigo_soldado.tscn")

const CORES: Array[String] = ["cinza", "verde", "azul", "amarelo"]

const MAPA_MIN_X: float = 20.0
const MAPA_MAX_X: float = 580.0
const MAPA_MIN_Y: float = 20.0
const MAPA_MAX_Y: float = 280.0

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
	
	var total_inimigos: int = 9 + (onda_atual - 1) * 3
	inimigos_vivos = total_inimigos
	
	atualizar_hud()
	
	for i in range(total_inimigos):
		_spawn_inimigo(i, total_inimigos)

	if onda_atual % 2 == 0:
		_spawn_reforcos_aliados()

func _spawn_inimigo(indice: int, total: int) -> void:
	var cena_inimigo: PackedScene = INIMIGO_COMUM_SCENE
	var eh_atirador_comum: bool = (indice % 2 == 1)
	
	if onda_atual >= 7 and indice == 0:
		cena_inimigo = INIMIGO_TANQUE_SCENE
	elif onda_atual >= 5 and (indice == 1 or (onda_atual >= 8 and indice == total - 1)):
		cena_inimigo = INIMIGO_AVIAO_SCENE
	elif onda_atual >= 3 and (indice == 2 or (onda_atual >= 6 and indice == 3)):
		cena_inimigo = INIMIGO_CAMINHAO_SCENE
		
	var inimigo: CharacterBody2D = cena_inimigo.instantiate()
	
	if cena_inimigo == INIMIGO_COMUM_SCENE:
		inimigo.tipo_cor = CORES[randi() % CORES.size()]
		inimigo.comportamento = "atirador" if eh_atirador_comum else "perseguidor"
			
	inimigo.morreu.connect(_on_inimigo_morreu)
	inimigo.position = _sortear_posicao_borda()
	add_child(inimigo)

func _sortear_posicao_borda() -> Vector2:
	for tentativa in range(30):
		var borda: int = randi() % 4
		var pos: Vector2 = Vector2.ZERO
		
		match borda:
			0:
				pos = Vector2(randf_range(MAPA_MIN_X, MAPA_MAX_X), MAPA_MIN_Y)
			1:
				pos = Vector2(randf_range(MAPA_MIN_X, MAPA_MAX_X), MAPA_MAX_Y)
			2:
				pos = Vector2(MAPA_MIN_X, randf_range(MAPA_MIN_Y, MAPA_MAX_Y))
			3:
				pos = Vector2(MAPA_MAX_X, randf_range(MAPA_MIN_Y, MAPA_MAX_Y))
		
		if not _esta_na_agua(pos):
			return pos
			
	return Vector2(randf_range(100.0, 500.0), MAPA_MIN_Y)

func _esta_na_agua(pos_global: Vector2) -> bool:
	if agua_layer == null:
		agua_layer = get_node_or_null("Mundo/Água")
		
	if agua_layer:
		var pos_local: Vector2 = agua_layer.to_local(pos_global)
		var celula: Vector2i = agua_layer.local_to_map(pos_local)
		if agua_layer.get_cell_source_id(celula) != -1:
			return true
			
		for offset in [Vector2(-8, 0), Vector2(8, 0), Vector2(0, -8), Vector2(0, 8)]:
			var celula_offset: Vector2i = agua_layer.local_to_map(agua_layer.to_local(pos_global + offset))
			if agua_layer.get_cell_source_id(celula_offset) != -1:
				return true
				
	return false

func _on_inimigo_morreu(_inimigo: CharacterBody2D) -> void:
	inimigos_vivos = maxi(0, inimigos_vivos - 1)
	atualizar_hud()
	
	if inimigos_vivos == 0 and not mudando_de_onda:
		mudando_de_onda = true
		_concluir_onda()

func _concluir_onda() -> void:
	for t in get_tree().get_nodes_in_group("tiros_inimigos"):
		if is_instance_valid(t):
			t.queue_free()
			
	await get_tree().create_timer(1.5).timeout
	iniciar_onda(onda_atual + 1)

func atualizar_hud() -> void:
	if player == null:
		if is_inside_tree() and get_tree():
			player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		else:
			player = get_node_or_null("Player") as CharacterBody2D
			
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
		
	var posicoes: Array[Vector2] = [Vector2(-24, 0), Vector2(24, 0)]
	for offset in posicoes:
		var amigo: CharacterBody2D = AMIGO_SOLDADO_SCENE.instantiate()
		amigo.offset_formacao = offset
		amigo.global_position = player.global_position + offset
		add_child(amigo)
