class_name InteractionSystem
extends Node

var player: PlayerController
var session: GameSessionManager
var target: Object
var prompt: String = ""

func _physics_process(_delta: float) -> void:
	target = null
	prompt = ""
	if not session.active or not player.accepts_input():
		return
	var origin := player.camera.global_position
	var ray := PhysicsRayQueryParameters3D.create(origin, origin - player.camera.global_basis.z * 4.3, 3)
	var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and hit.collider.has_method("interaction_prompt"):
		target = hit.collider
		prompt = target.interaction_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if session.active and player.accepts_input() and event.is_action_pressed("interact"):
		if is_instance_valid(target) and not prompt.is_empty():
			target.interact()
