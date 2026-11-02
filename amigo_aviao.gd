extends Node2D

const TIRO_SCENE: PackedScene = preload("res://tiro.tscn")
const INTERVALO_TIRO: float = 1.0
const ALCANCE_TIRO: float = 180.0

@export var distancia_orbita: float = 32.0
@export var velocidade_rotacao: float = 2.5

var angulo_atual: float = 0.0
var tempo_recarga: float = 0.0
var player: Node2D = null
var _timer_scan: float = 0.0
var _inimigo_alvo: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("amigos")
	player = get_parent()
	if is_zero_approx(angulo_atual):
		angulo_atual = randf_range(0.0, TAU)

func _physics_process(delta: float) -> void:
	angulo_atual = fposmod(angulo_atual + velocidade_rotacao * delta, TAU)
	position = Vector2.from_angle(angulo_atual) * distancia_orbita
	
	_timer_scan -= delta
	if _timer_scan <= 0.0:
		_inimigo_alvo = _obter_inimigo_mais_proximo()
		_timer_scan = 0.25
	
	if _inimigo_alvo and not is_instance_valid(_inimigo_alvo):
		_inimigo_alvo = null
	
	if _inimigo_alvo:
		var dir_inimigo: Vector2 = (_inimigo_alvo.global_position - global_position).normalized()
		rotation = lerp_angle(rotation, dir_inimigo.angle(), 1.0 - exp(-15.0 * delta))
	else:
		rotation = lerp_angle(rotation, angulo_atual + PI * 0.5, 1.0 - exp(-10.0 * delta))
		
	tempo_recarga -= delta
	if tempo_recarga <= 0.0 and _inimigo_alvo:
		_atirar(_inimigo_alvo)
		tempo_recarga = INTERVALO_TIRO

func _atirar(inimigo: Node2D) -> void:
	var tiro: Area2D = TIRO_SCENE.instantiate()
	var direcao: Vector2 = (inimigo.global_position - global_position).normalized()
	tiro.direction = direcao
	tiro.global_position = global_position + direcao * 8.0
	
	var scene_root: Node = get_tree().current_scene
	if scene_root:
		scene_root.add_child(tiro)
	else:
		get_parent().get_parent().add_child(tiro)

func _obter_inimigo_mais_proximo() -> Node2D:
	var inimigos: Array[Node] = get_tree().get_nodes_in_group("inimigos")
	var mais_proximo: Node2D = null
	var menor_distancia: float = ALCANCE_TIRO
	
	for inimigo in inimigos:
		if is_instance_valid(inimigo) and inimigo is Node2D:
			var dist: float = global_position.distance_to((inimigo as Node2D).global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				mais_proximo = inimigo as Node2D
				
	return mais_proximo
