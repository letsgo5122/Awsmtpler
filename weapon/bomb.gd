extends Area2D

var in_area = []
var from_player

func explod():
	#print("explod from_player  ",from_player)
	for p in in_area:
		if p.has_method("exploded"):
			p.rpc("exploded",from_player)
			
func done():
	queue_free()
	pass	
# Called when the node enters the scene tree for the first time.
func _ready():

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_bomb_body_entered(body):

	if not body in in_area:
		in_area.append(body)
		#print("_on_bomb_body_entered: " ,in_area)


func _on_bomb_body_exited(body):
	in_area.erase(body)
	#print("_on_bomb_body_exited: ",in_area)
	



func _on_bomb_area_entered(area):
	if not area in in_area:
		in_area.append(area)
	pass # Replace with function body.


func _on_bomb_area_exited(area):
	in_area.erase(area)
	pass # Replace with function body.
