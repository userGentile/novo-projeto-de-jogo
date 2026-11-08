extends CharacterBody2D

const SPEED = 80.0
const TIRO_SCENE = preload("res://tiro.tscn")
const AMIGO_AVIAO_SCENE = preload("res://amigo_aviao.tscn")
const BANDEIRA_SCENE = preload("res://bandeira_cura.tscn")

const CUSTO_MUNDO_DOIS = 2500
const MAX_AVIOES = 10
const COOLDOWN_BANDEIRA = 15.0
var tempo_recarga_bandeira: float = 0.0

# Custo do Amigo Avião
const CUSTO_AVIAO = 100

# Multiplicador de Tiro
const CUSTO_MULTIPLICADOR = 70
const MAX_MULTIPLICADORES = 9
var multiplicadores_tiro: int = 0

# Posições de cantos e direções de disparo para os tiros extras
const CONFIG_CANTOS = [
	{"offset": Vector2(8, -8), "dir": Vector2(1, -1)},     # Canto Superior Direito
	{"offset": Vector2(-8, -8), "dir": Vector2(-1, -1)},   # Canto Superior Esquerdo
	{"offset": Vector2(8, 8), "dir": Vector2(1, 1)},       # Canto Inferior Direito
	{"offset": Vector2(-8, 8), "dir": Vector2(-1, 1)},     # Canto Inferior Esquerdo
	{"offset": Vector2(0, -10), "dir": Vector2(0, -1)},    # Canto Superior
	{"offset": Vector2(0, 10), "dir": Vector2(0, 1)},      # Canto Inferior
	{"offset": Vector2(10, 0), "dir": Vector2(1, 0)},      # Canto Direito
	{"offset": Vector2(-10, 0), "dir": Vector2(-1, 0)},    # Canto Esquerdo
	{"offset": Vector2(0, 0), "dir": Vector2(-1, -1)}      # Canto Diagonal Reverso
]

# Mecânica de Vida
var max_vida: int = 3
var vida: int = 3
var invulneravel: bool = false
var tempo_invulneravel: float = 0.0
const DURACAO_INVULNERABILIDADE: float = 1.0

# Dinheiro Tap
var dinheiro_tap: int = 0

var ultima_direcao: Vector2 = Vector2.RIGHT

@onready var anim: AnimatedSprite2D = $"Animação"
@onready var hud_coracoes: HBoxContainer = $"CanvasLayer/Control/HBoxContainer"
@onready var label_onda: Label = $"CanvasLayer/Control/LabelOnda"
@onready var label_restantes: Label = $"CanvasLayer/Control/LabelRestantes"
@onready var container_numeros_dinheiro: HBoxContainer = $"CanvasLayer/Control/ContainerDinheiro/Numeros"
@onready var botao_compra_aviao: Button = $"CanvasLayer/Control/BotaoComprarAviao"
@onready var container_numeros_multi: HBoxContainer = $"CanvasLayer/Control/ContainerMulti/Numeros"
@onready var botao_compra_multi: Button = $"CanvasLayer/Control/BotaoComprarMulti"
@onready var botao_bandeira: Button = get_node_or_null("CanvasLayer/Control/BotaoBandeira")
@onready var botao_mundo_dois: Button = get_node_or_null("CanvasLayer/Control/BotaoMundoDois")

# Texturas dos números de 0 a 9 do tilemap
var texturas_digitos: Array[Texture2D] = []

func _ready() -> void:
	add_to_group("player")
	carregar_texturas_digitos()
	atualizar_hud_vida()
	atualizar_hud_dinheiro()
	atualizar_hud_multi()
	
	if botao_compra_aviao:
		botao_compra_aviao.pressed.connect(_on_comprar_aviao_pressed)
	if botao_compra_multi:
		botao_compra_multi.pressed.connect(_on_comprar_multi_pressed)
	if botao_bandeira:
		botao_bandeira.pressed.connect(colocar_bandeira_cura)
	if botao_mundo_dois:
		botao_mundo_dois.pressed.connect(viajar_mundo_dois)
	atualizar_botao_compra()

func carregar_texturas_digitos() -> void:
	var tilemap_tex = preload("res://arte/tilemap_packed.png")
	texturas_digitos.clear()
	for digito in range(10):
		var atlas = AtlasTexture.new()
		atlas.atlas = tilemap_tex
		atlas.region = Rect2(digito * 16, 160, 16, 16)
		texturas_digitos.append(atlas)

func _process(delta: float) -> void:
	if tempo_recarga_bandeira > 0.0:
		tempo_recarga_bandeira = maxf(0.0, tempo_recarga_bandeira - delta)
		atualizar_botao_bandeira()

	# Controle do tempo de invulnerabilidade após levar dano
	if invulneravel:
		tempo_invulneravel -= delta
		visible = int(tempo_invulneravel * 12) % 2 == 0
		if tempo_invulneravel <= 0.0:
			invulneravel = false
			visible = true

	var move_input = Vector2.ZERO
	
	if Input.is_action_pressed('ui_left'):
		move_input.x -= 1.0
	if Input.is_action_pressed('ui_right'):
		move_input.x += 1.0
	if Input.is_action_pressed('ui_up'):
		move_input.y -= 1.0
	if Input.is_action_pressed('ui_down'):
		move_input.y += 1.0
	
	if move_input != Vector2.ZERO:
		move_input = move_input.normalized()
		ultima_direcao = move_input
		velocity = move_input * SPEED
	else:
		velocity = Vector2.ZERO
	
	if Input.is_action_just_pressed("ui_accept"):
		atirar()
	
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("inimigos"):
			tomar_dano(1)
			break
		
	if anim:
		if velocity == Vector2.ZERO:
			anim.play("idle")
		else:
			anim.play("walk")

		if ultima_direcao.x < 0.0:
			anim.flip_h = true
		elif ultima_direcao.x > 0.0:
			anim.flip_h = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			comprar_multiplicador()
		elif event.keycode == KEY_B:
			comprar_amigo_aviao()
		elif event.keycode == KEY_E:
			colocar_bandeira_cura()
		elif event.keycode == KEY_P:
			viajar_mundo_dois()

func atirar() -> void:
	var tiro = TIRO_SCENE.instantiate()
	var inimigo_mais_proximo = obter_inimigo_mais_proximo()
	var direcao_tiro = ultima_direcao
	
	if inimigo_mais_proximo != null:
		direcao_tiro = (inimigo_mais_proximo.global_position - global_position).normalized()
	
	tiro.direction = direcao_tiro
	tiro.position = global_position + direcao_tiro * 12
	get_parent().add_child(tiro)
	
	# Disparo dos tiros extras nos cantos do jogador baseado nos multiplicadores adquiridos
	var qtd_extras = mini(multiplicadores_tiro, CONFIG_CANTOS.size())
	for i in range(qtd_extras):
		var cfg = CONFIG_CANTOS[i]
		var tiro_extra = TIRO_SCENE.instantiate()
		tiro_extra.direction = (cfg["dir"] as Vector2).normalized()
		tiro_extra.position = global_position + (cfg["offset"] as Vector2)
		get_parent().add_child(tiro_extra)

func obter_inimigo_mais_proximo() -> Node2D:
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null:
		return null
	var inimigos = tree.get_nodes_in_group("inimigos")
	var mais_proximo: Node2D = null
	var menor_distancia: float = INF
	
	for inimigo in inimigos:
		if is_instance_valid(inimigo):
			var dist = global_position.distance_to(inimigo.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				mais_proximo = inimigo
				
	return mais_proximo

func adicionar_dinheiro(qtd: int) -> void:
	dinheiro_tap += qtd
	atualizar_hud_dinheiro()
	atualizar_botao_compra()

func atualizar_hud_dinheiro() -> void:
	if container_numeros_dinheiro == null or texturas_digitos.size() < 10:
		return
		
	for child in container_numeros_dinheiro.get_children():
		child.queue_free()
		
	var texto = str(dinheiro_tap)
	for char in texto:
		var digito = int(char)
		var tr = TextureRect.new()
		tr.texture = texturas_digitos[digito]
		tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		container_numeros_dinheiro.add_child(tr)

func atualizar_hud_multi() -> void:
	if container_numeros_multi == null or texturas_digitos.size() < 10:
		return
		
	for child in container_numeros_multi.get_children():
		child.queue_free()
		
	var tr = TextureRect.new()
	tr.texture = texturas_digitos[clampi(multiplicadores_tiro, 0, 9)]
	tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	container_numeros_multi.add_child(tr)

func atualizar_botao_compra() -> void:
	if botao_compra_aviao:
		var total_avioes = 0
		for c in get_children():
			if c.is_in_group("amigos"):
				total_avioes += 1
		if total_avioes >= MAX_AVIOES:
			botao_compra_aviao.disabled = true
			botao_compra_aviao.text = "Avião (MAX)"
			botao_compra_aviao.modulate = Color(0.6, 0.8, 0.6, 0.8)
		else:
			botao_compra_aviao.text = "Avião (100 Tap) [B]"
			botao_compra_aviao.disabled = (dinheiro_tap < CUSTO_AVIAO)
			if dinheiro_tap >= CUSTO_AVIAO:
				botao_compra_aviao.modulate = Color(1, 1, 1, 1)
			else:
				botao_compra_aviao.modulate = Color(0.7, 0.7, 0.7, 0.8)

	if botao_mundo_dois:
		botao_mundo_dois.disabled = (dinheiro_tap < CUSTO_MUNDO_DOIS)
		if dinheiro_tap >= CUSTO_MUNDO_DOIS:
			botao_mundo_dois.modulate = Color(1.0, 1.0, 0.4, 1.0)
			botao_mundo_dois.text = "Viajar M2 (2500) [P]"
		else:
			botao_mundo_dois.modulate = Color(0.7, 0.7, 0.7, 0.8)
			botao_mundo_dois.text = "Mundo 2 (2500) [P]"

	if botao_compra_multi:
		if multiplicadores_tiro >= MAX_MULTIPLICADORES:
			botao_compra_multi.disabled = true
			botao_compra_multi.text = "Multi (MAX)"
			botao_compra_multi.modulate = Color(0.6, 0.8, 0.6, 0.8)
		else:
			botao_compra_multi.text = "Multi (70 Tap) [M]"
			botao_compra_multi.disabled = (dinheiro_tap < CUSTO_MULTIPLICADOR)
			if dinheiro_tap >= CUSTO_MULTIPLICADOR:
				botao_compra_multi.modulate = Color(1, 1, 1, 1)
			else:
				botao_compra_multi.modulate = Color(0.7, 0.7, 0.7, 0.8)

func _on_comprar_multi_pressed() -> void:
	comprar_multiplicador()

func comprar_multiplicador() -> void:
	if multiplicadores_tiro >= MAX_MULTIPLICADORES:
		return
	if dinheiro_tap >= CUSTO_MULTIPLICADOR:
		dinheiro_tap -= CUSTO_MULTIPLICADOR
		multiplicadores_tiro += 1
		atualizar_hud_dinheiro()
		atualizar_hud_multi()
		atualizar_botao_compra()

func _on_comprar_aviao_pressed() -> void:
	comprar_amigo_aviao()

func comprar_amigo_aviao() -> void:
	var total_avioes = 0
	for c in get_children():
		if c.is_in_group("amigos"):
			total_avioes += 1
	if total_avioes >= MAX_AVIOES:
		return

	if dinheiro_tap >= CUSTO_AVIAO:
		dinheiro_tap -= CUSTO_AVIAO
		atualizar_hud_dinheiro()
		atualizar_botao_compra()
		
		# Cria o amigo avião girando ao redor do player
		var aviao = AMIGO_AVIAO_SCENE.instantiate()
		
		# Distribui uniformemente os ângulos entre os aviões existentes
		var avioes_existentes = []
		for c in get_children():
			if c.is_in_group("amigos"):
				avioes_existentes.append(c)
				
		add_child(aviao)
		avioes_existentes.append(aviao)
		
		# Recalcula as fases orbitais para que fiquem bem espaçados
		var total = avioes_existentes.size()
		for i in range(total):
			avioes_existentes[i].angulo_atual = (TAU / total) * i

func tomar_dano(quantidade: int = 1) -> void:
	if invulneravel:
		return
		
	vida -= quantidade
	invulneravel = true
	tempo_invulneravel = DURACAO_INVULNERABILIDADE
	atualizar_hud_vida()
	
	if vida <= 0:
		morrer()

func morrer() -> void:
	get_tree().reload_current_scene()

func atualizar_hud_vida() -> void:
	if hud_coracoes:
		for i in range(hud_coracoes.get_child_count()):
			var coracao = hud_coracoes.get_child(i)
			if i < vida:
				coracao.modulate = Color(1, 1, 1, 1)
			else:
				coracao.modulate = Color(0.2, 0.2, 0.2, 0.5)

func atualizar_hud_onda(numero_onda: int, restantes: int) -> void:
	if label_onda:
		label_onda.text = "Onda: " + str(numero_onda)
	if label_restantes:
		label_restantes.text = "Inimigos: " + str(restantes)

func curar(qtd: int = 1) -> void:
	if vida < max_vida:
		vida = mini(vida + qtd, max_vida)
		atualizar_hud_vida()
		modulate = Color(0.6, 1.8, 0.6, 1.0)
		var tw = create_tween()
		tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

func colocar_bandeira_cura() -> void:
	if tempo_recarga_bandeira > 0.0:
		return
	tempo_recarga_bandeira = COOLDOWN_BANDEIRA
	atualizar_botao_bandeira()
	
	var bandeira = BANDEIRA_SCENE.instantiate()
	var offset_lado = Vector2(-20 if ultima_direcao.x >= 0 else 20, 0)
	get_parent().add_child(bandeira)
	bandeira.global_position = global_position + offset_lado

func atualizar_botao_bandeira() -> void:
	if botao_bandeira:
		if tempo_recarga_bandeira <= 0.0:
			botao_bandeira.disabled = false
			botao_bandeira.text = "Bandeira [E]"
			botao_bandeira.modulate = Color(1, 1, 1, 1)
		else:
			botao_bandeira.disabled = true
			botao_bandeira.text = "Bandeira (%.0fs)" % ceil(tempo_recarga_bandeira)
			botao_bandeira.modulate = Color(0.7, 0.7, 0.7, 0.8)

func ganhar_vida_extra() -> void:
	max_vida += 1
	vida = mini(vida + 1, max_vida)
	if hud_coracoes:
		var atlas = AtlasTexture.new()
		atlas.atlas = preload("res://arte/tilemap_packed.png")
		atlas.region = Rect2(240, 160, 16, 16)
		var tr = TextureRect.new()
		tr.texture = atlas
		tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		hud_coracoes.add_child(tr)
	atualizar_hud_vida()
	modulate = Color(1.8, 1.6, 0.2, 1.0)
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4)

func viajar_mundo_dois() -> void:
	if dinheiro_tap >= CUSTO_MUNDO_DOIS:
		dinheiro_tap -= CUSTO_MUNDO_DOIS
		atualizar_hud_dinheiro()
		atualizar_botao_compra()
		get_tree().change_scene_to_file("res://mundo_dois.tscn")
