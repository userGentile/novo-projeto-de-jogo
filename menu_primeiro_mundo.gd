extends Control

@onready var botao_jogar: Button = $BotaoIniciar
@onready var botao_sair: Button = $BotaoSair

func _ready() -> void:
	if botao_jogar:
		botao_jogar.pressed.connect(_on_jogar_pressed)
	if botao_sair:
		botao_sair.pressed.connect(_on_sair_pressed)

func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://jogo.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
