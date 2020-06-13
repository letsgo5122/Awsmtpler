extends Area2D

#export var dir = Vector2()
var speed = 20
var catch_speed = 35
var screen_size = Vector2(
	ProjectSettings.get("display/window/size/width"),
	ProjectSettings.get("display/window/size/height"))
onready var wall_L = get_node("/root/world/wall_L").get_position()
onready var wall_R = get_node("/root/world/wall_R").get_position()
onready var wall_T = get_node("/root/world/wall_T").get_position()
onready var wall_B = get_node("/root/world/wall_B").get_position()
enum NPC {IDLE, NEW_DIRECTION, MOVE, INJURED, STUNNED, CATCH}
export(NPC) var state = NPC.IDLE
#export var stunned = false
export var direction = Vector2()
#var hit = false
var hitCount = 0
var catchWho
var score = 1

func _ready():
	randomize()
	
func _process(delta):
#	moving(delta)
	if get_tree().is_network_server():
		if position.x < wall_L.x or position.x > wall_R.x or position.y < wall_T.y or position.y > wall_B.y:
			rpc("gone")
		else:
			#if hit:
			#	rpc("catchPlayer",delta,catchWho)
			#else:
				rpc("action_State",delta)
				
sync func action_State(delta):
	match state:
				NPC.IDLE:
					idle()
				NPC.MOVE:
					rpc("moving",delta)
				NPC.INJURED:
					injured_anim()
				NPC.CATCH:
					rpc("catchPlayer",delta,catchWho)
				NPC.STUNNED:
					stun()
func idle():
	$Anim.play("idle")
	
sync func moving(delta):
	direction_anim()
	position += speed * direction * delta
	
sync func catchPlayer(delta,catchWho):
	#print("catchPlayer: %s" % NPC.keys()[state])
	#check if player still connected
	if get_node("/root/world/players/").has_node(str(catchWho)):
		var player = get_node("/root/world/players/"+str(catchWho))
		direction = ( player.position - position).normalized()
		direction_anim()
		position += catch_speed * direction * delta
	else:
		state = NPC.IDLE

func injured_anim():
	#print("injured_anim: %s" % state)
	$Anim.play("injured")

func direction_anim():
	$Anim.play("walk")
	if direction.x > 0:
		$Sprite.flip_h = false
	if direction.x < 0:
		$Sprite.flip_h = true
	
	
puppet func stun():
	$Anim.play("stun")
	state = NPC.STUNNED
	
sync func exploded(by_who):
	if state==NPC.STUNNED:
		return
	var player=get_node("/root/world/players/"+str(by_who))
	#player.callv("update_score",[by_who,score])
	player.rpc("update_score", by_who, 1)
	rpc("stun")
	stun()
	
func damage(by_who):
	#print ("%s damage by %s" %[name, by_who])
	#hit = true
	state = NPC.INJURED
	catchWho = by_who
	if hitCount == 2: #gone by hit 3 times 
		rpc("gone")
	hitCount+=1
	
remotesync func gone():
	get_node("/root/world/npc").get_node(name).queue_free()
	#queue_free()
	
func setNpcName(newName):
	$npcName.text = newName
	
func choose(array):
	array.shuffle()
	return array.front()
	
sync func set_State(time_choose,state_choose,direction_choose):
	$Timer.wait_time = time_choose
	state = state_choose
	direction = direction_choose
	
func _on_Timer_timeout():
	if get_tree().is_network_server() && state!=NPC.STUNNED && state!= NPC.INJURED && state!=NPC.CATCH:
		var time_choose = choose([1,3,6])
		var state_choose = choose([NPC.IDLE, NPC.MOVE])
		var direction_choose = choose([Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN])
		rpc("set_State",time_choose,state_choose,direction_choose)
#func _on_Dragon_area_shape_entered(area_id, area, area_shape, self_shape):
#	print("area_id:%s area:%s area_shape:%s self_shape:%s" %[area_id, area, area_shape, self_shape])
#
#	pass # Replace with function body.
#

func _on_Dragon_area_entered(area):
	#on hit backward
	#print(area.name)
	if area.is_in_group("weapon"):
#		rpc("hitback",area.dir)
#		hitback(area.dir)
		rpc("hitback",Vector2(1,0))
		hitback(Vector2(1,0))
sync func hitback(dir):
	position += dir * 2.5
	

func _on_Dragon_body_entered(body):
	#print(body)
	if body.has_method("caught"):
			#body.rpc("damage",from_player)
			#body.callv("caught",[true])
			body.rpc("caught",true)
	pass # Replace with function body.


func _on_Dragon_body_exited(body):
	if body.has_method("caught"):
			#body.rpc("damage",from_player)
			#body.callv("caught",[false])
			body.rpc("caught",false)
	pass # Replace with function body.
