extends Node3D

var reversed = false
# Called when the node enters the scene tree for the first time.
func _ready():
	while(true):
		$Camera3D/MeshInstance3D.visible = true
		await get_tree().create_timer(1).timeout
		$Camera3D/MeshInstance3D.visible = false
		await get_tree().create_timer(5).timeout

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_animation_player_animation_finished(anim_name):
	await get_tree().create_timer(20).timeout
	
	reversed = !reversed
	if reversed:
		$AnimationPlayer.play_backwards(anim_name)
	else:
		$AnimationPlayer.play(anim_name)



