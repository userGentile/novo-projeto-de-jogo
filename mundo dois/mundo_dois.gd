extends Node2D

@onready var player = $"Player"
@onready var spawner = $SpawnerM2

func _ready() -> void:
	randomize()
	if player:
		player.morreu.connect(_on_player_morreu)

func _on_player_morreu() -> void:
	pass
