extends CharacterBody2D

signal morreu(inimigo: CharacterBody2D)

const DINHEIRO_M2_SCENE: PackedScene = preload("res://mundo dois/dinheiro_m2.tscn")
const TIRO_INIMIGO_SCENE: PackedScene = preload("res://mundo dois/tiro_inimigo_m2.tscn")

const TEXTURA_SOLDADO: Texture2D = preload("res://verdadeira arte do mundo dois/Personagens/characters/pikeman-soldier.png")
const TEXTURA_GUERREIRO: Texture2D = preload("res://verdadeira arte do mundo dois/Personagens/characters/chain-warrior.png")
const TEXTURA_FEITICEIRO: Texture2D = preload("res://verdadeira arte do mundo dois/Personagens/characters/plague-sorcerer.png")

@export_enum("soldado", "guerreiro", "feiticeiro") var tipo: String = "soldado"

var vida_max: int = 1
var vida: int = 1
var velocidade: float = 45.0
var valor_ouro: int = 1
var morto: bool = false

var tempo_recarga_tiro: float = 0.0
var intervalo_tiro: float = 2.5
var distancia_tiro: float = 120.0
var knockback: Vector2 = Vector2.ZERO

var player: CharacterBody2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var hit_tween: Tween

func _ready() -> void:
	add_to_group("inimigos_m2")
	_configurar_tipo()
	_localizar_player()

func _configurar_tipo() -> void:
	match tipo:
		"soldado":
			vida_max = 1
			velocidade = 45.0
			valor_ouro = 1
			if sprite:
				sprite.texture = TEXTURA_SOLDADO
				sprite.scale = Vector2(0.09, 0.09)
		"guerreiro":
			vida_max = 3
			velocidade = 30.0
			valor_ouro = 2
			if sprite:
				sprite.texture = TEXTURA_GUERREIRO
				sprite.scale = Vector2(0.12, 0.12)
		"feiticeiro":
			vida_max = 2
			velocidade = 35.0
			valor_ouro = 2
			intervalo_tiro = 2.4
			tempo_recarga_tiro = randf_range(0.8, 1.8)
			if sprite:
				sprite.texture = TEXTURA_FEITICEIRO
				sprite.scale = Vector2(0.095, 0.095)
				
	vida = vida_max

func _localizar_player() -> void:
	player = get_tree().get_first_node_in_group("player_m2") as CharacterBody2D
	if player == null:
		var p = get_tree().get_first_node_in_group("player")
		if p is CharacterBody2D:
			player = p

func _physics_process(delta: float) -> void:
	if morto:
		return
		
	if player == null or not is_instance_valid(player):
		_localizar_player()
		if player == null:
			return
			
	var vetor_player: Vector2 = player.global_position - global_position
	var distancia: float = vetor_player.length()
	var direcao: Vector2 = vetor_player.normalized() if distancia > 0.0 else Vector2.ZERO
	
	var target_velocity: Vector2 = Vector2.ZERO
	
	if tipo == "soldado" or tipo == "guerreiro":
		target_velocity = direcao * velocidade
	elif tipo == "feiticeiro":
		if distancia > distancia_tiro + 20.0:
			target_velocity = direcao * velocidade
		elif distancia < distancia_tiro - 20.0:
			target_velocity = -direcao * velocidade
		else:
			target_velocity = Vector2.ZERO
			
		tempo_recarga_tiro -= delta
		if tempo_recarga_tiro <= 0.0:
			_atirar_no_player(direcao)
			tempo_recarga_tiro = intervalo_tiro + randf_range(-0.3, 0.3)
	
	velocity = velocity.lerp(target_velocity, 1.0 - exp(-10.0 * delta))
	
	if knockback.length_squared() > 1.0:
		velocity += knockback
		knockback = knockback.lerp(Vector2.ZERO, 1.0 - exp(-14.0 * delta))
	else:
		knockback = Vector2.ZERO
		
	if sprite and absf(direcao.x) > 0.05:
		sprite.flip_h = (direcao.x < 0.0)
		
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and (collider.is_in_group("player_m2") or collider.name == "Player"):
			if collider.has_method("receber_dano"):
				collider.receber_dano(1)
			elif collider.has_method("tomar_dano"):
				collider.tomar_dano(1)
			break

func _atirar_no_player(direcao: Vector2) -> void:
	var tiro = TIRO_INIMIGO_SCENE.instantiate()
	tiro.direcao = direcao
	tiro.global_position = global_position + direcao * 10.0
	get_parent().add_child(tiro)

func receber_dano(qtd: int = 1, direcao_tiro: Vector2 = Vector2.ZERO) -> void:
	if morto:
		return
		
	vida -= qtd
	
	if direcao_tiro != Vector2.ZERO:
		knockback = direcao_tiro.normalized() * 50.0
		
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
	hit_tween = create_tween()
	modulate = Color(2.0, 0.4, 0.4, 1.0)
	hit_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	
	if vida <= 0:
		morrer()

func take_damage(qtd: int = 1) -> void:
	receber_dano(qtd)

func morrer() -> void:
	morto = true
	remove_from_group("inimigos_m2")
	
	var drop = DINHEIRO_M2_SCENE.instantiate()
	drop.global_position = global_position
	drop.valor = valor_ouro
	get_parent().call_deferred("add_child", drop)
	
	morreu.emit(self)
	queue_free()
