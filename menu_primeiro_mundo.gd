extends Control

@onready var botao_jogar: TextureButton = $BotaoIniciar
@onready var botao_sair: TextureButton = $BotaoSair

# Cores de destaque ao passar o mouse
const COR_NORMAL = Color(1.0, 1.0, 1.0, 1.0)
const COR_HOVER = Color(1.35, 1.35, 1.35, 1.0) # Ilumina e realca as cores do botao

func _ready() -> void:
	if botao_jogar:
		botao_jogar.pressed.connect(_on_jogar_pressed)
		botao_jogar.mouse_entered.connect(_on_jogar_hover)
		botao_jogar.mouse_exited.connect(_on_jogar_exit)
	if botao_sair:
		botao_sair.pressed.connect(_on_sair_pressed)
		botao_sair.mouse_entered.connect(_on_sair_hover)
		botao_sair.mouse_exited.connect(_on_sair_exit)

func _on_jogar_hover() -> void:
	if botao_jogar:
		botao_jogar.modulate = COR_HOVER

func _on_jogar_exit() -> void:
	if botao_jogar:
		botao_jogar.modulate = COR_NORMAL

func _on_sair_hover() -> void:
	if botao_sair:
		botao_sair.modulate = COR_HOVER

func _on_sair_exit() -> void:
	if botao_sair:
		botao_sair.modulate = COR_NORMAL

func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://jogo.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
