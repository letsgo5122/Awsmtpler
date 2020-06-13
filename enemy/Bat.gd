extends KinematicBody2D

var knockback = Vector2.ZERO
var hit_count = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	knockback = move_and_slide(knockback)


func _on_HurtBox_area_entered(area):
	#print("name:%s area.dir:%s "%[area.name,area.dir])
	if area.is_in_group("weapon"):
		knockback = area.dir * 120
		hit_count += 1
		if hit_count == 3 :
			queue_free()
