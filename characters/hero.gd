extends KinematicBody2D

var ACCELERATION = 500
var MAX_SPEED = 120
const FRICTION = 450
var velocity = Vector2.ZERO

onready var animationPlayer = $Anim
onready var animTr = $AnimTr
onready var animState = animTr.get("parameters/playback")
enum ACT {IDLE, MOVE, ATTACT, STUNNED, HURT}
export(ACT) var state = ACT.MOVE
puppet var puppet_state
puppet var puppet_input_vector = Vector2.ZERO
puppet var puppet_pos =  Vector2()
puppet var puppet_animState 
puppet var puppet_velocity
puppet var puppet_score = ""
#export var stunned = false
var bomb_index = 0
var prev_bombing = false
var  prev_attacking = false
var input_vector = Vector2.ZERO
var blinking = false
var puppet_blinking
var hud = Label.new()
onready var player_id = get_tree().get_network_unique_id()
onready var _gui = load("res://gui/GUI.tscn").instance()
onready var _gui_Btm = load("res://gui/Btm_GUI.tscn").instance()
var jystk
onready var wcl = get_node("/root/world/wcl")
var gui_gauge = 0
var gui_hp = ""
var gui_Att_Bt
var gui_Bomb_Bt
var gui_Bomb_Number
var gui_Char_In
var qui_Char_In_Focus = false
var gui_SendChatBt

func _ready():
	if is_network_master():
		wcl.add_child(_gui)
		wcl.add_child(_gui_Btm)
		get_node("/root/world/wcl/GUI/HBoxContainer/nameLabel").text = $plName.text
		gui_gauge = get_node("/root/world/wcl/GUI/HBoxContainer/Bars/LifeBar/Gauge")
		gui_hp = get_node("/root/world/wcl/GUI/HBoxContainer/Bars/LifeBar/Count/Background/Number")
		gui_gauge.value = 5
		gui_hp.text = str(gui_gauge.value) 
		gui_Bomb_Number = get_node("/root/world/wcl/GUI/HBoxContainer/Counters/BombCounter/Background/Number")
		
		#jystk = get_node("/root/world/wcl/GUI/joystick/joystickBt")
		jystk = get_node("/root/world/wcl/Btm_GUI/HB/MC/joystick/joystickBt")
		gui_Att_Bt = get_node("/root/world/wcl/Btm_GUI/HB/AttMarg/AttBt")
		gui_Bomb_Bt =get_node("/root/world/wcl/Btm_GUI/HB/BombMarg/BombBt")
		#gui_Char_Out = get_node("/root/world/wcl/GUI/Chat/RichTextLabel")
		gui_Char_In = get_node("/root/world/wcl/Btm_GUI/HB/VB/HB/LineEdit")
		gui_Char_In.connect("focus_entered", self, "char_In_Focus_State",[true])
		gui_Char_In.connect("focus_exited", self, "char_In_Focus_State",[false])
		gui_SendChatBt = get_node("/root/world/wcl/Btm_GUI/HB/VB/HB/SendChat")
		gui_SendChatBt.connect("pressed",gui_SendChatBt,"printMsg")
		$Camera2D.make_current()

	$AnimTr.active = true

func char_In_Focus_State(state):
	qui_Char_In_Focus = state
	print("qui_Char_In_Focus:",qui_Char_In_Focus)
master func gui_update(hp):
	if hp!=null or player_id != 1:
		#print("HP:",hp)
		gui_gauge.value = int(hp)
		gui_hp.text = hp

remotesync func set_bomb(bomb_name, bomb_pos, by_who):
	#print("bomb_name  %s"%bomb_name,"bomb_pos %s" %bomb_pos,"by_who %s" %by_who)
	var bomb = load("res://weapon/bomb.tscn").instance()
	get_node("/root/world").add_child(bomb)
	bomb.position = bomb_pos
	bomb.from_player = by_who
	
remotesync func attack(pos, att_dir, by_who):
	var weapon = load("res://weapon/pineapple.tscn").instance()
	get_node("/root/world").add_child(weapon)
	weapon.position = pos
	if att_dir != null:
		weapon.dir = att_dir
	else:
		weapon.dir = Vector2(1, 0)
	weapon.from_player = by_who
	
func _process(delta):
	if is_network_master():
		get_input()
		rset("puppet_state",state)
	else:
		state = puppet_state
		
	match state:
			ACT.MOVE:
				move_state(delta)
			ACT.ATTACT:
				attack_state(delta)
			ACT.HURT:
				hurt_state(delta)
			ACT.STUNNED:
				stunned_state()
			ACT.IDLE:
				idle_state(delta)
#	if blinking: 
#		print("blinking")
#		get_node("BlinkPlayer").play("StartBlink")
#	else:
#		print("blinking off")
#		get_node("BlinkPlayer").play("NoBlink")

func get_input():
	if state == ACT.STUNNED or qui_Char_In_Focus:
		return
		
	if int(gui_Bomb_Number.text) > 0:
		var bombing = Input.is_action_pressed("set_bomb")
		if gui_Bomb_Bt.get_Status():
			bombing = true
		if bombing and not prev_bombing:
			#prev_bombing = gui_Bomb_Bt.get_Status() 
			prev_bombing = bombing 
		#print("prev_bombing%s "%prev_bombing)
			var bomb_name = get_name() + str(bomb_index)
			var bomb_pos = position
			rpc("set_bomb", bomb_name, bomb_pos, get_tree().get_network_unique_id())
			gui_Bomb_Number.text = str(int(gui_Bomb_Number.text) - 1)
		
	var attacking = Input.is_action_pressed("ui_attack")
	if gui_Att_Bt.get_Status():
		attacking = true
	if attacking and not prev_attacking:
			prev_attacking = attacking
			#prev_motion equal direction
			var pos = position
			#print(animTr.get("parameters/"+animState.get_current_node()+"/blend_position"))
			var att_dir = animTr.get("parameters/"+animState.get_current_node()+"/blend_position")
			rpc("attack", pos, att_dir, get_tree().get_network_unique_id())
	

		
	input_vector.x = Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down")-Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if jystk.get_value() != Vector2.ZERO:
		input_vector = jystk.get_value()
	rset("puppet_input_vector",input_vector)
	rset("puppet_pos",position)
	#state = ACT.MOVE
	
func move_state(delta):
	if !is_network_master():
		input_vector = puppet_input_vector
		position = puppet_pos

	if input_vector != Vector2.ZERO :
		animTr.set("parameters/Idle/blend_position",input_vector)
		animTr.set("parameters/Walk/blend_position",input_vector)
		animState.travel("Walk")
		velocity = velocity.move_toward(input_vector * MAX_SPEED , ACCELERATION * delta)
	else:
		animState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	velocity = move_and_slide(velocity)
	
func idle_state(delta):
	pass
func attack_state(delta):
	pass
	
func hurt_state(delta):
	#print("hurt_state")
	animState.travel("Hurt")
	
func stunned_state():
	#print("stunned_state")
	animState.travel("Stunned")
	pass
	
puppet func stun():
	state = ACT.STUNNED
	
master func exploded(by_who):
	if state ==  ACT.STUNNED:
		return
	rpc("stun")
	stun()
	
func setPlayerName(newName):
	$plName.text = newName
	
remotesync func update_score(id, score):
	gamestate.players[id]["score"] += score
	if gamestate.players[id]["score"] < 0:
		gamestate.players[id]["score"] = 0
	if gamestate.players[id]["score"] >=  100:
		gamestate.players[id]["score"] = 100
	#gamestate.rpc("update_player_stats",id,gamestate.players[id]["score"])
	$score.text = str(gamestate.players[id]["score"])
	#gamestate.callv("update_player_stats",[id,tmpscore])
	#update local 
	rpc("gui_update",$score.text)
	
#new user get all exist player score 
remotesync func set_stats(id, score):
	#print("id:",id, "  score:",score)
	$score.text = str(score) 

func _on_bomb_timer_timeout():
	prev_bombing = false

func damage(by_who):
	if state ==  ACT.STUNNED:
		return
	rpc("stun")
	stun()

func _on_attack_timer_timeout():
	prev_attacking = false
	
remotesync func caught(is_caught):
	#print("caught:",is_caught)
	#blinking = is_caught
	if is_network_master():
		rpc("update_score",player_id, -2)
		if is_caught:
			state = ACT.HURT
		else:
			state = ACT.MOVE
		rset("puppet_state",state)
	else:
		state = puppet_state

