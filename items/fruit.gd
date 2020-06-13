extends Area2D

#func _ready():
#	randomize()
	#var fruit_rand = fruit.keys()[randi() %fruit.size() ]
	#print(fruit_rand)
	#$Sprite.texture = load("res://images/icons/"+fruit_rand+".png")
	#var new_name = alphbet.keys()[randi() % alphbet.size()]

	#setFruitName(new_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func setFruitName(newName):
	$fruitName.text = newName

remotesync func gone():
	queue_free()

func _on_fruit_body_entered(body):
	body.rpc("update_score", int(body.name), 2)
	queue_free()
