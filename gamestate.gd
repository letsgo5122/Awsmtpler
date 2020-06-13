extends Node
#------WS config start-------------------------------------
const Listen_PORT = 5122 
const PROTO_NAME = "Robin"
#onready var PORT = OS.get_environment("PORT")

#heroku server,Heroku websocketclient URL
#var SERVER_IP = "gdmtpler.herokuapp.com"
#var CON2URL = "wss://" + SERVER_IP+ ":" + str("443")+ "/gd/"

#local server ,local server websocketclient URL
var SERVER_IP = "127.0.0.1"
var CON2URL ="ws://" + "127.0.0.1"+ ":" + str("5122")
#------WS config end----------------------------------------

var player_stats = {"name":"","score":0}
var players = {}
signal refreshList(players)
signal serverState(player_name)
var npcTimer
var npcTimerVal = 5
onready var world = load("res://world/world.tscn").instance()
onready var args = Array(OS.get_cmdline_args())

func _ready():
	if OS.get_name()=="HTML5":
		OS.set_window_maximized(true)
	#TranslationServer.set_locale('zh')
	randomize()
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	if args.has("-s"):
		print("starting server...\n")
		serverStart()
		
	npcTimer = Timer.new()
	npcTimer.set_wait_time(npcTimerVal)
	npcTimer.connect("timeout",self,"_on_timer_timeout")
	add_child(npcTimer) #to process
	npcTimer.start() #to start

func _player_connected(id):
	# Called on both clients and server when a peer connects. Send my info to it.
	#print("player_connected =",id)
	#rpc_id(id,"register_player", player_stats)
	pass
remote func register_player(new_id, player_stats):
	#var new_id = get_tree().get_rpc_sender_id()
	players[new_id] = player_stats
	add_player(new_id)
	#print("register_player: ",player_stats,"   players: ",players)
	if get_tree().is_network_server():
		for idp in players:
			if idp != new_id && idp != 1: # Don't display server at client side
				#send exist players to new_id 
				rpc_id(new_id,"register_player", idp, players[idp])
				#send new_id to all players except server self
				if idp != 1:
					rpc_id(idp,"register_player", new_id, players[new_id])
	emit_signal("refreshList", players)
	
func _connected_ok():
	#Connected to server ok
	var player_id = get_tree().get_network_unique_id()
	players[player_id] = player_stats
	add_player(player_id)
	rpc_id(1,"register_player",player_id, player_stats)
	#print("_connected_ok ")
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func join_game(new_player_name):
	player_stats["name"] = new_player_name
	var host = WebSocketClient.new()
	host.connect_to_url(CON2URL, PoolStringArray([PROTO_NAME]), true)
	get_tree().set_network_peer(host)
	addWorld()
	get_node("/root/lobby/CanvasLayer/InfoPanel").visible=false

func serverStart():
	player_stats["name"] = "*Server*"
	var host = WebSocketServer.new()
	#Heroku Server:nginx proxy_pass to 5122 on Heroku Server 
	host.listen(Listen_PORT, PoolStringArray([PROTO_NAME]), true)
	print("Listen on SVR_PORT: ",Listen_PORT)
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().set_network_peer(host)
	emit_signal("serverState",player_stats)
	addWorld()
	var player_id = get_tree().get_network_unique_id()
	players[player_id] = player_stats
	#add_player(player_id) #Don't display server in server side
	get_node("/root/lobby/CanvasLayer/InfoPanel").visible=false
func addWorld():
	get_tree().get_root().call_deferred("add_child", world)
	#get_tree().get_root().add_child(world)
	

func rndSpawn():
	var spawn = Vector2(rand_range(200, 600),rand_range(200, 500))
	#print("spawn",spawn)
	return spawn

func rndVelocity():
	var dir = randi() % 2
	if dir == 0:
		return Vector2(1,0)
	else:
		return Vector2(-1,0)
		
func add_player(id):
	#if id != 1:
	#var player_scene= load("res://characters/player.tscn")
	var player_scene= load("res://characters/hero.tscn")
	#var player_gui = load("res://gui/GUI.tscn").instance()
	#player_gui.set_name(str(id))
	var player = player_scene.instance()
	player.set_name(str(id))
	player.setPlayerName(players[id]["name"])
	player.set_network_master(id)
	world.get_node("players").add_child(player)
	#world.get_node("wcl").add_child(player_gui)
	player.position = rndSpawn()
	#set exist player state
	player.rpc("set_stats", id, players[id]["score"])
	#add npc
	if get_tree().is_network_server():
		if get_node("/root/world/npc").get_child_count()>0:
			for n in get_node("/root/world/npc").get_children():
				#print("pos %s ;dir %s; name: %s " % [n.get_position(), n.dir , n.name] )
				rpc_id(id,"addNpc", n.get_position(), n.direction, n.name)
	
remotesync func update_player_stats(id ,newscore):
	players[id]["score"] = newscore
	#print("update_player_stats:",players)
	
func _player_disconnected(id):
	if get_tree().is_network_server():
		#print("_player_disconnected :",id)
		for p_id in players:
			if p_id != id  && p_id != 1:
				rpc_id(p_id,"unregister_player",id)
		unregister_player(id)
		
func _connected_fail():
	print("_connected_fail")
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	get_tree().get_root().queue_free()

remote func unregister_player(id):
	get_node("/root/world/players").get_node(str(id)).queue_free()
	players.erase(id)
	emit_signal("refreshList", players)
	
#Spawn npc
func _on_timer_timeout():
	if get_node("/root").has_node("world"):#check if server start up
		if get_node("/root/world/npc").get_child_count() > get_node("/root/world/players").get_child_count()+2:
			return
		if get_tree().is_network_server():
			var pos = rndSpawn()
			var dir = rndVelocity()
			var npcName = str(pos.x).substr(5)
			rpc("addNpc",pos,dir,npcName)
			addNpc(pos,dir,npcName)
			#FRUIT
			pos = rndSpawn()
			var fruit_Name = Fruit_Name()
			var fruit_Alphbet = Fruit_Alphbet()
			rpc("addFruit",fruit_Name, fruit_Alphbet,pos)
			addFruit(fruit_Name, fruit_Alphbet, pos)
			
remote func addNpc(pos:Vector2,dir:Vector2,npcName):
	var npc_scene= load("res://enemy/dragon.tscn")
	var npc = npc_scene.instance()
	npc.set_name(npcName)
	npc.setNpcName("D"+npcName)
	npc.position = pos
	npc.direction = dir
	world.get_node("npc").add_child(npc)

remote func addFruit(fruit_name, fruit_alphbet, pos:Vector2):
	var fruit_scene = load("res://items/fruit.tscn").instance()
	fruit_scene.get_node("Sprite").texture = load("res://images/icons/"+fruit_name+".png")
	fruit_scene.setFruitName(fruit_alphbet)
	fruit_scene.position = pos
	fruit_scene.scale = Vector2(0.6, 0.6)
	world.get_node("fruits").add_child(fruit_scene)
	
enum alphbet {A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z}
enum fruit {banana, lemon, melon, bottle, winebottle}
func Fruit_Name():
	var fruit_Name = fruit.keys()[randi() %fruit.size() ]
	return fruit_Name
func Fruit_Alphbet():
	var fruit_Alphbet = alphbet.keys()[randi() % alphbet.size()]
	return fruit_Alphbet
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass
