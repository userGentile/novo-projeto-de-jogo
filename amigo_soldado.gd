extends CharacterBody2D

signal morreu(amigo: CharacterBody2D)

const TIRO_SCENE: PackedScene = preload("res://tiro.tscn")

@export var base_speed: float = 75.0
@export var alcance_tiro: float = 160.0
@export var intervalo_tiro: float = 1.2

var vida: int = 1
var morto: bool = false
var tempo_recarga: float = 0.5
var offset_formacao: Vector2 = Vector2(-24, 0)
var player: CharacterBody2D = null

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("amigos")
	add_to_group("amigos_soldados")
	player = get_tree().get_first_node_in_group("player")
	if anim:
		anim.play("walk")

func _physics_process(delta: float) -> void:
	if morto:
		return
		
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
		
	var pos_alvo: Vector2 = player.global_position + offset_formacao
	var vetor_alvo: Vector2 = pos_alvo - global_position
	var dist: float = vetor_alvo.length()
	
	var target_vel: Vector2 = Vector2.ZERO
	if dist > 8.0:
		target_vel = vetor_alvo.normalized() * base_speed
		if anim and anim.animation != "walk":
			anim.play("walk")
	else:
		target_vel = Vector2.ZERO
		if anim and anim.animation != "idle":
			anim.play("idle")
			
	velocity = velocity.lerp(target_vel, 1.0 - exp(-12.0 * delta))
			
	if absf(velocity.x) > 1.0 and anim:
		anim.flip_h = velocity.x < 0.0
		
	move_and_slide()
	
	tempo_recarga -= delta
	if tempo_recarga <= 0.0:
		var inimigo: Node2D = _obter_inimigo_mais_proximo()
		if inimigo:
			_atirar_no_inimigo(inimigo)
			tempo_recarga = intervalo_tiro + randf_range(-0.15, 0.25)

func _atirar_no_inimigo(inimigo: Node2D) -> void:
	var tiro: Area2D = TIRO_SCENE.instantiate()
	var direcao: Vector2 = (inimigo.global_position - global_position).normalized()
	tiro.direction = direcao
	tiro.global_position = global_position + direcao * 10.0
	get_parent().add_child(tiro)

func _obter_inimigo_mais_proximo() -> Node2D:
	var inimigos: Array[Node] = get_tree().get_nodes_in_group("inimigos")
	var mais_proximo: Node2D = null
	var menor_distancia: float = alcance_tiro
	
	for inimigo in inimigos:
		if is_instance_valid(inimigo) and inimigo is Node2D:
			var dist: float = global_position.distance_to((inimigo as Node2D).global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				mais_proximo = inimigo as Node2D
				
	return mais_proximo

func tomar_dano(qtd: int = 1) -> void:
	if morto:
		return
		
	vida -= qtd
	if vida <= 0:
		morrer()

func morrer() -> void:
	if morto:
		return
	morto = true
	remove_from_group("amigos")
	remove_from_group("amigos_soldados")
	morreu.emit(self)
	
	modulate = Color(1.8, 0.3, 0.3, 0.9)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("tiros_inimigos"):
		tomar_dano(1)
		area.queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("inimigos"):
		tomar_dano(1)
