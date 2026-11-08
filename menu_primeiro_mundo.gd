# Script do menu principal do Mundo 1
extends Control

@onready var botao_iniciar: Button = $BotaoIniciar
@onready var botao_sair: Button = $BotaoSair
@onready var realce_iniciar: TextureRect = $BotaoIniciar/Realce
@onready var realce_sair: TextureRect = $BotaoSair/Realce

# Cores de realce para o efeito de hover
# Usamos modulate com intensidade acima de 1.0 para criar um brilho suave e dourado no proprio botao
const COR_APAGADO = Color(1.0, 1.0, 1.0, 0.0)
const COR_BRILHO_INICIAR = Color(1.4, 1.3, 1.2, 1.0)
const COR_BRILHO_SAIR = Color(1.3, 1.3, 1.45, 1.0)

var tween_iniciar: Tween
var tween_sair: Tween

func _ready() -> void:
	if realce_iniciar:
		realce_iniciar.modulate = COR_APAGADO
	if realce_sair:
		realce_sair.modulate = COR_APAGADO
	
	if botao_iniciar:
		botao_iniciar.pressed.connect(_on_iniciar_pressed)
		botao_iniciar.mouse_entered.connect(_on_iniciar_hover)
		botao_iniciar.mouse_exited.connect(_on_iniciar_exit)
	
	if botao_sair:
		botao_sair.pressed.connect(_on_sair_pressed)
		botao_sair.mouse_entered.connect(_on_sair_hover)
		botao_sair.mouse_exited.connect(_on_sair_exit)

func _on_iniciar_hover() -> void:
	if not realce_iniciar:
		return
	if tween_iniciar and tween_iniciar.is_valid():
		tween_iniciar.kill()
	tween_iniciar = create_tween()
	tween_iniciar.tween_property(realce_iniciar, "modulate", COR_BRILHO_INICIAR, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_iniciar_exit() -> void:
	if not realce_iniciar:
		return
	if tween_iniciar and tween_iniciar.is_valid():
		tween_iniciar.kill()
	tween_iniciar = create_tween()
	tween_iniciar.tween_property(realce_iniciar, "modulate", COR_APAGADO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_sair_hover() -> void:
	if not realce_sair:
		return
	if tween_sair and tween_sair.is_valid():
		tween_sair.kill()
	tween_sair = create_tween()
	tween_sair.tween_property(realce_sair, "modulate", COR_BRILHO_SAIR, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_sair_exit() -> void:
	if not realce_sair:
		return
	if tween_sair and tween_sair.is_valid():
		tween_sair.kill()
	tween_sair = create_tween()
	tween_sair.tween_property(realce_sair, "modulate", COR_APAGADO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_iniciar_pressed() -> void:
	get_tree().change_scene_to_file("res://jogo.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
