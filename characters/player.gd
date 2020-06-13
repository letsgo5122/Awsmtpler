extends KinematicBody2D

onready var jystk= get_node("/root/world/canvas/GUI/joystick/joystickBt")
onready var hp = get_node("/root/world/canvas/GUI/HBoxContainer/Bars/LifeBar/Gauge")
const MOTION_SPEED = 100
puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()
puppet var puppet_score = ""
export var stunned = false
puppet var puppet_dir = Vector2()
var dir = Vector2()
export var blinking = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if is_network_master():
		hp.value = 100
		$Camera2D.make_current()
var current_anim = ""
var prev_bombing = false
var bomb_index = 0
var prev_attacking = false

remotesync func set_bomb(bomb_name, bomb_pos, by_who):
	#print("bomb_name  %s"%bomb_name,"bomb_pos %s" %bomb_pos,"by_who %s" %by_who)
	var bomb = load("res://weapon/bomb.tscn").instance()
	get_node("/root/world").add_child(bomb)
	bomb.position = bomb_pos
	bomb.from_player = by_who

remotesync func attack(pos, dir, by_who):
	var weapon = load("res://weapon/pineapple.tscn").instance()
	get_node("/root/world").add_child(weapon)
	weapon.position = pos
	weapon.dir = dir
	weapon.from_player = by_who
	
func _process(delta):
	var motion = Vector2()
	if is_network_master():
		print("joystic:%s " % jystk.get_value())
		if Input.is_action_pressed("ui_left") or jystk.get_value().x <0:
			motion += Vector2(-1, 0)
			dir = motion
		if Input.is_action_pressed("ui_right") or jystk.get_value().x >0:
			motion += Vector2(1, 0)
			dir = motion
		if Input.is_action_pressed("ui_up") or jystk.get_value().y<0:
			motion += Vector2(0, -1)
			dir = motion
		if Input.is_action_pressed("ui_down") or jystk.get_value().y>0:
			motion += Vector2(0, 1)
			dir = motion
		
		var bombing = Input.is_action_pressed("set_bomb")
		var attacking = Input.is_action_pressed("ui_attack")
		
		if stunned:
			bombing = false
			attacking = false
			motion = Vector2()
			
		if bombing and not prev_bombing:
			prev_bombing = bombing
			#print("prev_bombing%s "%prev_bombing)
			var bomb_name = get_name() + str(bomb_index)
			var bomb_pos = position
			rpc("set_bomb", bomb_name, bomb_pos, get_tree().get_network_unique_id())

		if attacking and not prev_attacking:
			prev_attacking = attacking
			#prev_motion equal direction
			var pos = position
			rpc("attack", pos, dir, get_tree().get_network_unique_id())
			
		
			
		rset("puppet_motion", motion)
		rset("puppet_pos", position)
		rset("puppet_dir", dir)
	else:
		position = puppet_pos
		motion = puppet_motion
		dir = puppet_dir
	var new_anim = "standing"
	if dir.y < 0:
		new_anim = "walk_up"
	elif dir.y > 0:
		new_anim = "walk_down"
	elif dir.x < 0:
		new_anim = "walk_left"
	elif dir.x > 0:
		new_anim = "walk_right"

	if stunned:
		new_anim = "stunned"
	if blinking: 
		get_node("BlinkPlayer").play("StartBlink")
	else:
		get_node("BlinkPlayer").play("NoBlink")
	if new_anim != current_anim:
		current_anim = new_anim
		get_node("anim").play(current_anim)
	
	
	# FIXME: Use move_and_slide
	move_and_slide(motion * MOTION_SPEED)
	if not is_network_master():
		puppet_pos = position # To avoid jitter

puppet func stun():
	stunned = true
	
master func exploded(by_who):
	if stunned:
		return
	rpc("stun")
	stun()
	
func setPlayerName(newName):
	$plName.text = newName
	$score.text = puppet_score

remote func stuning():
	stunned = true
	
func damage(by_who):
	if stunned:
		return
	rpc("stuning")
	stun()

func update_score(id, score):
	$score.text = str(int($score.text)+ score) 
	#print("update_score",id)
	gamestate.callv("update_player_stats",[id,int($score.text)])
	
func _on_attack_timer_timeout():
	prev_attacking = false

func _on_bomb_timer_timeout():
	prev_bombing = false
	pass # Replace with function body.
func rand_dir():
	dir = Vector2()
	var r = randi() %10 
	if r < 5:
		dir = Vector2(-1,0)
	else:
		dir = Vector2(1,0)
	return dir
	
func caught(is_caught):
	rpc("redblink",is_caught)
	redblink(is_caught)

remote func redblink(is_caught):
	blinking = is_caught
	
