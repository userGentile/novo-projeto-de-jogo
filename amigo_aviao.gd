extends Node2D

const TIRO_SCENE = preload("res://tiro.tscn")

# Configurações de órbita
var distancia_orbita: float = 32.0
var velocidade_rotacao: float = 2.5
var angulo_atual: float = 0.0

# Disparo automático
var tempo_recarga: float = 0.0
const INTERVALO_TIRO: float = 1.0
const ALCANCE_TIRO: float = 180.0

var player: Node2D = null
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("amigos")
	player = get_parent()
	# Se angulo_atual não tiver sido definido externamente, define aleatório
	if angulo_atual == 0.0:
		angulo_atual = randf_range(0, TAU)

func _physics_process(delta: float) -> void:
	# Atualiza posição orbital ao redor do player
	angulo_atual += velocidade_rotacao * delta
	if angulo_atual >= TAU:
		angulo_atual -= TAU
		
	var offset = Vector2(cos(angulo_atual), sin(angulo_atual)) * distancia_orbita
	position = offset
	
	# O avião aponta visualmente para a direção do movimento circular
	# ou para o inimigo mais próximo
	var inimigo = obter_inimigo_mais_proximo()
	if inimigo:
		var dir_inimigo = (inimigo.global_position - global_position).normalized()
		rotation = dir_inimigo.angle()
	else:
		rotation = angulo_atual + PI / 2.0
		
	# Disparo automático periódico
	tempo_recarga -= delta
	if tempo_recarga <= 0.0:
		if inimigo:
			atirar_no_inimigo(inimigo)
			tempo_recarga = INTERVALO_TIRO

func atirar_no_inimigo(inimigo: Node2D) -> void:
	var tiro = TIRO_SCENE.instantiate()
	var direcao = (inimigo.global_position - global_position).normalized()
	tiro.direction = direcao
	tiro.global_position = global_position + direcao * 8
	# Adiciona à cena principal do jogo
	get_tree().current_scene.add_child(tiro)

func obter_inimigo_mais_proximo() -> Node2D:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var mais_proximo: Node2D = null
	var menor_distancia: float = ALCANCE_TIRO
	
	for inimigo in inimigos:
		if is_instance_valid(inimigo):
			var dist = global_position.distance_to(inimigo.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				mais_proximo = inimigo
				
	return mais_proximo
