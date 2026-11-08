extends CharacterBody2D

signal morreu(inimigo: Node2D)

const TIRO_INIMIGO_SCENE = preload("res://tiro_inimigo.tscn")
const DINHEIRO_SCENE = preload("res://dinheiro_item.tscn")

@export var tipo_inimigo: String = "comum" # "comum", "caminhao", "aviao", "tanque"
@export var tipo_cor: String = "cinza"
@export var comportamento: String = "perseguidor" # "perseguidor", "atirador"
@export var vida_max: int = 1
@export var valor_tap: int = 10
@export var intervalo_tiro: float = 2.0
@export var distancia_tiro: float = 110.0
@export var base_speed: float = 40.0

var vida: int = 1
var speed: float = 40.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var player: Node2D = null

var morto: bool = false
var tempo_recarga: float = 0.0

func _ready() -> void:
	add_to_group("inimigos")
	var area = get_node_or_null("Area2D")
	if area and not area.body_entered.is_connected(_on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)
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
		return
		
	var vetor_player = player.global_position - global_position
	var distancia = vetor_player.length()
	var direcao = vetor_player.normalized()
	
	if comportamento == "perseguidor":
		velocity = direcao * speed
	elif comportamento == "atirador":
		if distancia > distancia_tiro + 25:
			velocity = direcao * speed
		elif distancia < distancia_tiro - 25:
			velocity = -direcao * speed
		else:
			velocity = Vector2.ZERO
			
		tempo_recarga -= delta
		if tempo_recarga <= 0.0:
			atirar_no_player(direcao)
			tempo_recarga = intervalo_tiro + randf_range(-0.3, 0.4)
			
	if anim:
		if velocity.length() > 0:
			if velocity.x < 0:
				anim.flip_h = true
			elif velocity.x > 0:
				anim.flip_h = false
		else:
			if direcao.x < 0:
				anim.flip_h = true
			elif direcao.x > 0:
				anim.flip_h = false

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("tomar_dano"):
				collider.tomar_dano(1)
			break

func atirar_no_player(direcao: Vector2) -> void:
	var tiro = TIRO_INIMIGO_SCENE.instantiate()
	tiro.direction = direcao
	tiro.global_position = global_position + direcao * 12
	get_parent().add_child(tiro)

func tomar_dano(qtd: int = 1) -> void:
	if morto:
		return
		
	vida -= qtd
	
	# Feedback visual de impacto (pisca vermelho rapidamente)
	modulate = Color(1.8, 0.4, 0.4, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.12)
	
	if vida <= 0:
		morto = true
		remove_from_group("inimigos")
		
		# Dropa moedas de acordo com o porte do inimigo
		var item = DINHEIRO_SCENE.instantiate()
		item.global_position = global_position
		item.valor = valor_tap
		get_parent().add_child(item)
		
		morreu.emit(self)
		queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("tiros") or area.name.begins_with("Tiro"):
		tomar_dano(1)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("tomar_dano"):
			body.tomar_dano(1)
