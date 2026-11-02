extends CharacterBody2D

signal morreu(inimigo: CharacterBody2D)

const TIRO_INIMIGO_SCENE: PackedScene = preload("res://tiro_inimigo.tscn")
const DINHEIRO_SCENE: PackedScene = preload("res://dinheiro_item.tscn")

@export var tipo_inimigo: String = "comum"
@export var tipo_cor: String = "cinza"
@export var comportamento: String = "perseguidor"
@export var vida_max: int = 1
@export var valor_tap: int = 10
@export var intervalo_tiro: float = 2.0
@export var distancia_tiro: float = 110.0
@export var base_speed: float = 40.0

var vida: int = 1
var speed: float = 40.0
var morto: bool = false
var tempo_recarga: float = 0.0
var knockback: Vector2 = Vector2.ZERO

var player: Node2D = null

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var hit_tween: Tween

func _ready() -> void:
	add_to_group("inimigos")
	vida = vida_max
	speed = base_speed
	
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_parent().get_node_or_null("Player")
	
	if anim:
		if tipo_inimigo == "comum":
			anim.play(tipo_cor + "_walk")
		else:
			anim.play("default")
		
	if comportamento == "atirador":
		tempo_recarga = randf_range(0.5, 1.8)

func _physics_process(delta: float) -> void:
	if morto:
		return
		
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
		
	var vetor_player: Vector2 = player.global_position - global_position
	var distancia: float = vetor_player.length()
	var direcao: Vector2 = vetor_player.normalized() if distancia > 0.0 else Vector2.ZERO
	
	var target_velocity: Vector2 = Vector2.ZERO
	
	if comportamento == "perseguidor":
		target_velocity = direcao * speed
	elif comportamento == "atirador":
		if distancia > distancia_tiro + 25.0:
			target_velocity = direcao * speed
		elif distancia < distancia_tiro - 25.0:
			target_velocity = -direcao * speed
		else:
			target_velocity = Vector2.ZERO
			
		tempo_recarga -= delta
		if tempo_recarga <= 0.0:
			atirar_no_player(direcao)
			tempo_recarga = intervalo_tiro + randf_range(-0.3, 0.4)
			
	velocity = velocity.lerp(target_velocity, 1.0 - exp(-10.0 * delta))
	
	if knockback.length_squared() > 1.0:
		velocity += knockback
		knockback = knockback.lerp(Vector2.ZERO, 1.0 - exp(-14.0 * delta))
	else:
		knockback = Vector2.ZERO
			
	if anim:
		if absf(velocity.x) > 2.0:
			anim.flip_h = velocity.x < 0.0
		elif absf(direcao.x) > 0.01:
			anim.flip_h = direcao.x < 0.0

	move_and_slide()

func atirar_no_player(direcao: Vector2) -> void:
	var tiro: Area2D = TIRO_INIMIGO_SCENE.instantiate()
	tiro.direction = direcao
	tiro.global_position = global_position + direcao * 12.0
	get_parent().add_child(tiro)

func tomar_dano(qtd: int = 1, direcao_impacto: Vector2 = Vector2.ZERO) -> void:
	if morto:
		return
		
	vida -= qtd
	
	if direcao_impacto != Vector2.ZERO:
		knockback = direcao_impacto.normalized() * 65.0
	
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
		
	hit_tween = create_tween()
	hit_tween.set_parallel(true)
	
	modulate = Color(2.0, 0.4, 0.4, 1.0)
	hit_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	
	scale = Vector2(1.2, 0.8)
	hit_tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if vida <= 0:
		morrer()

func morrer() -> void:
	morto = true
	remove_from_group("inimigos")
	
	var item: Area2D = DINHEIRO_SCENE.instantiate()
	item.global_position = global_position
	item.valor = valor_tap
	get_parent().add_child(item)
	
	morreu.emit(self)
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("tiros") or area.name.begins_with("Tiro"):
		var dir_bala: Vector2 = Vector2.ZERO
		if "direction" in area:
			dir_bala = area.direction
		tomar_dano(1, dir_bala)
