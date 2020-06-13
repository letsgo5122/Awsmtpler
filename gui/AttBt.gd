extends TouchScreenButton

var bt_Status = false
# Called when the node enters the scene tree for the first time.

func get_Status():
	return bt_Status



func _on_AttBt_pressed():
	bt_Status = true
	pass # Replace with function body.


func _on_AttBt_released():
	bt_Status = false
	pass # Replace with function body.


