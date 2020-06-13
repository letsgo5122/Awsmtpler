extends ItemList

enum fruit {banana, lemon, melon, bottle, winebottle}

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in fruit.keys():
		add_item(Fruit_Name(),load("res://images/icons/"+Fruit_Name()+".png"),true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func Fruit_Name():
	var fruit_Name = fruit.keys()[randi() %fruit.size() ]
	return fruit_Name
