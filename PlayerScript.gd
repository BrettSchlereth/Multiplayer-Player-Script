extends KinematicBody

#Puppet
puppet var puppet_pos = Vector3()
puppet var puppet_motion = Vector3()
puppet var puppet_rot_x = 0
puppet var puppet_rot_y = 0
#Physics
var moveSpeed : float = 5.0
var jumpForce : float = 5.0
var gravity: float = 12.0

#Camera
var minLookAngle : float = -90.0
var maxLookAngle : float = 90.0
var lookSensitivity : float = 10.0

#Vectors
var vel : Vector3 = Vector3()
var mouseDelta : Vector2 = Vector2()

#Components
onready var camera : Camera = get_node("Camera")

func _ready():
	#hide and lock the mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	puppet_pos = translation
	if is_network_master():
		get_node("Camera").current = true
	
func _physics_process(delta):
	var motion = Vector3()
	#Movement inputs
	if is_network_master():
		#Reset the x and z velocity
		vel.x = 0
		vel.z = 0
		if Input.is_action_pressed("move_forward"):
			motion.y -= 1
		if Input.is_action_pressed("move_backward"):
			motion.y += 1
		if Input.is_action_pressed("move_left"):
			motion.x -= 1
		if Input.is_action_pressed("move_right"):
			motion.x += 1
		#Pauses game
		if Input.is_action_just_pressed("ui_cancel"):
			togglePauseGame()
		
		#Normalizes diagonal movement velocity
		motion = motion.normalized()
		
		var forward = global_transform.basis.z
		var right = global_transform.basis.x
		
		var relativeDir = (forward * motion.y + right * motion.x)
		
		#Set the velocity
		vel.x = relativeDir.x * moveSpeed
		vel.z = relativeDir.z * moveSpeed
		
		#Apply gravity
		vel.y -= gravity * delta
		vel = move_and_slide(vel, Vector3.UP)
		
		#Jumping
		if Input.is_action_pressed("jump") and is_on_floor():
			vel.y = jumpForce
		
		#Signals the puppet motion and position
		rset("puppet_motion", motion)
		rset("puppet_pos", translation)
	else:
		translation = puppet_pos
		motion = puppet_motion
	
func _process(delta):
	#Rotate the camera along the x axis
	if !$PauseMenu.visible:
		if is_network_master():
			camera.rotation_degrees.x -= mouseDelta.y * lookSensitivity * delta
			#clamp camera x axis
			camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, minLookAngle, maxLookAngle)
			#rotate the player along their y axis
			rotation_degrees.y -= mouseDelta.x * lookSensitivity * delta
			
			#reset the mouse delta vector
			mouseDelta = Vector2()
			#Signals the puppet camera and player rotations
			rset("puppet_rot_x", rotation_degrees.y)
			rset("puppet_rot_y", camera.rotation_degrees.x)
		else:
			rotation_degrees.y = puppet_rot_x
			camera.rotation_degrees.x = puppet_rot_y
			pass
		
	pass
		
func _input(event):
	#Gets the mouse position
	if is_network_master():
		if event is InputEventMouseMotion:
			mouseDelta = event.relative
	pass
	
func set_player_name(new_name):
	get_node("Label").set_text(new_name)

#Hides or shows the mouse cursor
func toggleMouseCapture():
	if Input.get_mouse_mode() != 2:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass


func togglePauseGame():
	$PauseMenu.visible = !$PauseMenu.visible
	toggleMouseCapture()
	pass

#Function to manage button pressed
func _on_Button_pressed(buttonName):
	var error
	match buttonName:
		"Quit":
			gamestate.end_game()
			error = get_tree().change_scene("res://Assets/Scenes/lobby.tscn")
			pass
