class_name XRCharacterController
extends XROrigin3D

#How far away before fade to black. Customizable
@export_range(0.01, 1.0, 0.01, "suffix:m") var max_distance = 0.2

@export_range(0.01, 1.0, 0.01, "suffix:m") var fade_distance = 0.1

@export var fade_effect : FadeEffect

#Sends out an in-engine warning if someone attempts to parent this to anything other than the character body.
func _get_configuration_warnings():
	var warnings : PackedStringArray
	
	var parent = get_parent()
	if not parent or not parent is CharacterBody3D:
		warnings.push_back("This node must be a child of a CharacterBody3D node.")
	
	#Must have an XRCamera3D node attached
	var camera = get_node_or_null("XRCamera3D")
	if not camera or not camera is XRCamera3D:
		warnings.push_back("This node must have an XRCamera3D child node.")

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var character_body : CharacterBody3D = get_parent()
	if not character_body:
		return
	
	var camera : XRCamera3D = get_node_or_null("XRCamera3D")
	if not camera:
		return
	
	#Finds where the camera is in the local space of our character body
	var camera_transform = transform * camera.transform
	
	#Determine new position
	var new_position : Vector3 = camera_transform.origin * Vector3(1.0, 0.0, 1.0)
	
	#Get position in world space
	new_position = character_body.global_transform * new_position
	
	#Move character body
	var original_position = character_body.global_position
	character_body.move_and_collide(new_position - original_position)
	
	#Check actual movement
	var delta_movement = character_body.global_position - original_position
	
	#Convert to local orientation
	delta_movement = character_body.global_basis.inverse() * delta_movement
	
	#Move origin in opposite direction
	position -= delta_movement
	
	#Determine forward vector
	var forward = camera_transform.basis.z * Vector3(1.0, 0.0, 1.0)
	
	#Create rotation transform out of forward vector
	camera_transform.origin = Vector3()
	var rotation_transform = camera_transform.looking_at(forward, Vector3.UP, true)
	
	#Apply this transform to character body
	character_body.transform.basis = rotation_transform.basis * character_body.transform.basis
	
	#Apply inverse to origin
	transform = rotation_transform.inverse() * transform
	
	#Calculate how far the player is from target location
	var distance = (character_body.global_position - new_position).length()
	
	var fade = clamp((distance - max_distance) / fade_distance, 0.0, 1.0)
	if fade_effect:
		fade_effect.fade = fade
	
