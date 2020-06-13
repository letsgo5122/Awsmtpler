extends Button


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _ready():
	get_parent().get_node("LineEdit").set_focus_mode(1)
	pass

func printMsg():
	var msg = get_parent().get_node("LineEdit").text+"\n"
	#var s = "test messages"
	rpc("printMessage",msg)
	
remotesync func printMessage(msg):
	get_node("../../RichTextLabel").text += msg
	get_parent().get_node("LineEdit").text = ""
	


