extends Area2D

const SPEED = 130.0
var direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	add_to_group("tiros_inimigos")
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("tomar_dano"):
			body.tomar_dano(1)
		queue_free()
		return
		
	if body is TileMapLayer:
		if "água" in body.name.to_lower() or "agua" in body.name.to_lower():
			return
		queue_free()
	elif body is StaticBody2D:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	pass
