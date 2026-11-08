extends Area2D

const DURACAO_TOTAL: float = 4.0
const INTERVALO_CURA: float = 1.0
const RAIO_CURA: float = 50.0

var tempo_vida: float = 0.0
var tempo_prox_cura: float = 0.0
var player: CharacterBody2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("bandeiras_cura")
	z_index = 10
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	visible = true
	modulate = Color.WHITE
	scale = Vector2(0.3, 0.3)
	
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var pulso: float = 1.0 + 0.04 * sin(tempo_vida * 6.0)
	var raio_atual: float = RAIO_CURA * pulso
	draw_circle(Vector2.ZERO, raio_atual, Color(0.2, 0.9, 0.3, 0.12))
	draw_arc(Vector2.ZERO, raio_atual, 0.0, TAU, 36, Color(0.35, 1.0, 0.45, 0.45), 1.5)

func _physics_process(delta: float) -> void:
	tempo_vida += delta
	queue_redraw()
	
	if tempo_vida >= DURACAO_TOTAL - 1.0:
		var fade_rate: float = (tempo_vida - (DURACAO_TOTAL - 1.0))
		modulate.a = clampf(0.3 + 0.7 * absf(cos(tempo_vida * 14.0)) * (1.0 - fade_rate * 0.5), 0.0, 1.0)
		
	if tempo_vida >= DURACAO_TOTAL:
		queue_free()
		return
		
	tempo_prox_cura -= delta
	if tempo_prox_cura <= 0.0:
		tempo_prox_cura = INTERVALO_CURA
		_aplicar_cura()

func _aplicar_cura() -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		
	if player and is_instance_valid(player):
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= RAIO_CURA:
			if player.has_method("curar"):
				player.curar(1)
				_animar_pulso_cura()

func _animar_pulso_cura() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.22, 1.22), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
