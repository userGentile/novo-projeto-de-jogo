# Script do menu principal do Mundo 1
extends Control

@onready var botao_iniciar: Button = $BotaoIniciar
@onready var botao_sair: Button = $BotaoSair
@onready var overlay_iniciar: ColorRect = $BotaoIniciar/Overlay
@onready var overlay_sair: ColorRect = $BotaoSair/Overlay

func _ready() -> void:
	# Garante que os realces comecem invisiveis
	if overlay_iniciar:
		overlay_iniciar.visible = false
	if overlay_sair:
		overlay_sair.visible = false
	
	if botao_iniciar:
		botao_iniciar.pressed.connect(_on_iniciar_pressed)
		botao_iniciar.mouse_entered.connect(_on_iniciar_hover)
		botao_iniciar.mouse_exited.connect(_on_iniciar_exit)
	
	if botao_sair:
		botao_sair.pressed.connect(_on_sair_pressed)
		botao_sair.mouse_entered.connect(_on_sair_hover)
		botao_sair.mouse_exited.connect(_on_sair_exit)

func _on_iniciar_hover() -> void:
	if overlay_iniciar:
		overlay_iniciar.visible = true

func _on_iniciar_exit() -> void:
	if overlay_iniciar:
		overlay_iniciar.visible = false

func _on_sair_hover() -> void:
	if overlay_sair:
		overlay_sair.visible = true

func _on_sair_exit() -> void:
	if overlay_sair:
		overlay_sair.visible = false

func _on_iniciar_pressed() -> void:
	get_tree().change_scene_to_file("res://jogo.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
