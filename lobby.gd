extends Node

var ShowPanel = false
func _ready():
	gamestate.connect("refreshList", self, "refreshList")
	gamestate.connect("serverState", self, "serverState")
	pass # Replace with function body.

func _on_join_pressed(): 
	var new_player_name = $CanvasLayer/InfoPanel/userName.text
	$CanvasLayer/InfoPanel/serverStart.disabled = true
	$CanvasLayer/InfoPanel/join.disabled = true
	$bg.visible = false
	gamestate.join_game(new_player_name)
	#my_func()
	
	pass # Replace with function body.
	
func my_func():
	var js_return = JavaScript.eval("alert('Calling JavaScript per GDScript!');")
	print(js_return) 

func _on_serverStart_pressed():
	gamestate.serverStart()
	pass # Replace with function body.

func refreshList(players):
	$CanvasLayer/InfoPanel/ItemList.clear()
	for player_id in players:
		$CanvasLayer/InfoPanel/ItemList.add_item(players[player_id]["name"])
		
func serverState(player_stats):
	$CanvasLayer/InfoPanel/serverStart.text = player_stats["name"]
	$CanvasLayer/InfoPanel/serverStart.disabled = true
	$CanvasLayer/InfoPanel/join.disabled = true
	
func _on_Info_toggled(button_pressed):
	if get_node("/root/").has_node("world"):
		if button_pressed:
			$CanvasLayer/InfoPanel.visible = true
			get_node("/root/world").visible=false
			$bg.visible = true
		else:
			$CanvasLayer/InfoPanel.visible = false
			get_node("/root/world").visible=true
			$bg.visible = false
	else:
		print("world not ready")

