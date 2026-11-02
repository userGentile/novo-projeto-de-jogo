extends CharacterBody2D
 
signal vida_alterada(vida_atual: int, vida_max: int)
signal ouro_alterado(total_ouro: int)
signal morreu

@export var velocidade: float = 90.0
@export var vida_max: int = 5
@export var intervalo_ataque: float = 0.8
@export var tempo_invulneravel: float = 0.6

var vida: int = 5
var ouro: int = 0
var invulneravel: bool = false

var cena_tiro: PackedScene = preload("res://mundo dois/tiro_m2.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var timer_ataque: Timer = $TimerAtaque
@onready var timer_invul: Timer = $TimerInvulneravel

@onready var label_vida: Label = $HUD/MarginContainer/HBoxContainer/VidaContainer/LabelVida
@onready var label_ouro: Label = $HUD/MarginContainer/HBoxContainer/OuroContainer/LabelOuro

func _ready() -> void:
	add_to_group("player_m2")
	vida = vida_max
	_atualizar_hud()
	
	timer_ataque.wait_time = intervalo_ataque
	timer_ataque.timeout.connect(_atacar)
	timer_ataque.start()
	
	timer_invul.wait_time = tempo_invulneravel
	timer_invul.one_shot = true
	timer_invul.timeout.connect(_on_timer_invulneravel_timeout)

func _physics_process(_delta: float) -> void:
	var direcao := Vector2.ZERO
	direcao.x = Input.get_axis("ui_left", "ui_right")
	direcao.y = Input.get_axis("ui_up", "ui_down")
	
	# Suporte opcional a WASD caso nao estejam no InputMap
	if direcao == Vector2.ZERO:
		if Input.is_key_pressed(KEY_A):
			direcao.x -= 1.0
		if Input.is_key_pressed(KEY_D):
			direcao.x += 1.0
		if Input.is_key_pressed(KEY_W):
			direcao.y -= 1.0
		if Input.is_key_pressed(KEY_S):
			direcao.y += 1.0

	if direcao != Vector2.ZERO:
		direcao = direcao.normalized()
		if direcao.x != 0:
			sprite.flip_h = direcao.x < 0

	velocity = direcao * velocidade
	move_and_slide()

func _atacar() -> void:
	var inimigo_mais_proximo = _obter_inimigo_mais_proximo()
	if not inimigo_mais_proximo:
		return
	
	var tiro = cena_tiro.instantiate()
	tiro.global_position = global_position
	tiro.direcao = (inimigo_mais_proximo.global_position - global_position).normalized()
	get_tree().current_scene.add_child(tiro)

func _obter_inimigo_mais_proximo() -> Node2D:
	var inimigos = get_tree().get_nodes_in_group("inimigos_m2")
	var menor_distancia: float = INF
	var mais_proximo: Node2D = null
	
	for inimigo in inimigos:
		if inimigo is Node2D and is_instance_valid(inimigo):
			var dist = global_position.distance_to(inimigo.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				mais_proximo = inimigo
				
	return mais_proximo

func receber_dano(quantidade: int = 1) -> void:
	if invulneravel or vida <= 0:
		return
	
	vida = maxi(vida - quantidade, 0)
	vida_alterada.emit(vida, vida_max)
	_atualizar_hud()
	
	if vida <= 0:
		morrer()
	else:
		_iniciar_invulnerabilidade()

func _iniciar_invulnerabilidade() -> void:
	invulneravel = true
	timer_invul.start()
	var tween = create_tween().set_loops(int(tempo_invulneravel / 0.15))
	tween.tween_property(sprite, "modulate:a", 0.3, 0.075)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.075)

func _on_timer_invulneravel_timeout() -> void:
	invulneravel = false
	sprite.modulate.a = 1.0

func adicionar_ouro(quantidade: int = 1) -> void:
	ouro += quantidade
	ouro_alterado.emit(ouro)
	_atualizar_hud()

func morrer() -> void:
	morreu.emit()
	get_tree().reload_current_scene()

func _atualizar_hud() -> void:
	if label_vida:
		label_vida.text = "x %d" % vida
	if label_ouro:
		label_ouro.text = "x %d" % ouro
