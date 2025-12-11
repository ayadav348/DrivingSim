extends VehicleBody3D

# --- Dependencies ---
var xr_interface : XRInterface

# --- Car Variables ---
@export var STEER_SPEED = 1.5
@export var STEER_LIMIT = 0.6
var steer_target = 0
@export var engine_force_value = 40
var turbo_boost = 1

# --- Effect References ---
# Directly getting materials on load. 
# Ensure "TunnelMesh" and "3DRig/3DLayer/Speed" exist or this line will error.
@onready var tunnel_mat = $TunnelMesh.get_active_material(0)
@onready var screen_mat = $"3DRig/3DLayer/Speed".material

# --- State ---
var is_vr_mode = false

func _ready():
	# Pause the game initially to let user pick a mode
	get_tree().paused = true
	
	# Connect Menu Buttons
	$"Menu/VBoxContainer/3DButton".pressed.connect(_start_standard)
	$"Menu/VBoxContainer/VRButton".pressed.connect(_start_vr)
	
	# Prepare XR Interface
	xr_interface = XRServer.find_interface("OpenXR")

func _start_standard():
	# 2D Mode Setup
	is_vr_mode = false
	get_viewport().use_xr = false
	
	# Toggle Rigs
	$"3DRig".visible = true
	$VRRig.visible = false
	$"3DRig/look/Camera3D".make_current()
	
	# Hide Menu & Unpause
	$Menu.visible = false
	get_tree().paused = false

func _start_vr():
	# VR Mode Setup
	# We still check .initialize() because it returns false if no headset is found
	if xr_interface and xr_interface.initialize():
		is_vr_mode = true
		get_viewport().use_xr = true
		
		# Toggle Rigs
		$"3DRig".visible = false
		$VRRig.visible = true
		$VRRig/XRCamera3D.make_current()
		
		# Hide Menu & Unpause
		$Menu.visible = false
		get_tree().paused = false
	else:
		print("VR Failed to Initialize. Check Project Settings or Connection.")

func _physics_process(delta):
	# --- 1. Speed Calculation ---
	var speed = linear_velocity.length() * Engine.get_frames_per_second() * delta
	traction(speed)
	
	# Update HUD
	$Hud/speed.text = str(round(speed * 3.8 * 0.62137119 * turbo_boost)) + "  MPH"

	# --- 2. Steering Logic ---
	var fwd_mps = transform.basis.x.x
	steer_target = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	steer_target *= STEER_LIMIT
	
	# --- 3. Engine / Gas Logic ---
	if Input.is_action_pressed("ui_down"):
		if speed < 20 and speed != 0:
			engine_force = clamp(engine_force_value * 3 / speed, 0, 300)
		else:
			engine_force = engine_force_value
	elif Input.is_action_pressed("ui_up"):
		if fwd_mps >= -1:
			if speed < 30 and speed != 0:
				engine_force = -clamp(engine_force_value * 10 / speed, 0, 300)
			else:
				engine_force = -engine_force_value
		else:
			brake = 1
	else:
		brake = 0.0
		engine_force = 0
		
	# --- 4. Handbrake Logic ---
	if Input.is_action_pressed("ui_select"):
		brake = 3
		$wheal2.wheel_friction_slip = 0.8
		$wheal3.wheel_friction_slip = 0.8
	else:
		$wheal2.wheel_friction_slip = 3
		$wheal3.wheel_friction_slip = 3
		
	# Apply Steering
	steering = move_toward(steering, steer_target, STEER_SPEED * delta)

	# --- 5. Turbo Logic ---
	if Input.is_action_just_pressed("ui_turbo"):
		$Hud/TurboLabel.visible = true
		turbo_boost = 342
		$TubroTimer.start()
		apply_turbo_visuals(true)

func traction(speed):
	apply_central_force(Vector3.DOWN * speed)

func _on_tubro_timer_timeout() -> void:
	turbo_boost = 1
	$Hud/TurboLabel.visible = false
	apply_turbo_visuals(false)

func apply_turbo_visuals(active: bool):
	var tween = create_tween().set_parallel(true)
	
	if active:
		if is_vr_mode:
			# VR Effect
			tween.tween_property(tunnel_mat, "shader_parameter/warp_speed", 2.0, 0.5)
		else:
			# Standard Screen Effect
			tween.tween_property($"3DRig/look/Camera3D", "fov", 110, 0.2)
			tween.tween_property(screen_mat, "shader_parameter/blur_strength", 0.05, 0.3)
	else:
		if is_vr_mode:
			# Reset VR
			tween.tween_property(tunnel_mat, "shader_parameter/warp_speed", 0.0, 0.5)
		else:
			# Reset Standard
			tween.tween_property($"3DRig/look/Camera3D", "fov", 75, 0.5)
			tween.tween_property(screen_mat, "shader_parameter/blur_strength", 0.0, 0.5)
