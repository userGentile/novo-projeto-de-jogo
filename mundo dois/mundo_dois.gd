extends Node2D

## Gerenciador da cena principal do Mundo Dois (Vampire Survivors Style).
## Coordena o ciclo de jogo, controle de som/música (se aplicável), e game over/vitória.

@onready var player: CharacterBody2D = $"personagem mundo dois"
@onready var spawner: Node2D = $SpawnerM2

func _ready() -> void:
	# Garantir foco e inicialização limpa
	randomize()
	if player:
		if not player.morreu.is_connected(_on_player_morreu):
			player.morreu.connect(_on_player_morreu)

func _on_player_morreu() -> void:
	# Feedback de morte / reinício
	pass
