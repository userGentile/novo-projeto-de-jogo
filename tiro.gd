extends Area2D

const SPEED = 220.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("tiros")
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		return
	
	if body.is_in_group("inimigos") and body.has_method("tomar_dano"):
		body.tomar_dano(1)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("inimigos") or area.get_parent().is_in_group("inimigos"):
		var alvo = area.get_parent() if area.get_parent().is_in_group("inimigos") else area
		if alvo.has_method("tomar_dano"):
			alvo.tomar_dano(1)
			queue_free()
