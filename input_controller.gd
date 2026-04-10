@tool
## Central controller for handling mouse interactions with Draggable objects and projecting 2D input into the 3D world.
extends Node

## Gizmo to initialize the drag plane (origin is global_position and normal is basis Y)
@export var drag_plane_gizmo: Marker3D
@export var click_threshold_time_ms: int = 200
@export var click_threshold_distance: float = 10.0

signal on_mouse_entered_draggable (draggable: Draggable, input_info: InputEventMouse)
signal on_mouse_exited_draggable (draggable: Draggable, input_info: InputEventMouse)
signal on_drag_began (draggable: Draggable, input_info: InputEventMouse)
signal on_dragged (draggable: Draggable, input_info: InputEventMouse)
signal on_drag_ended (draggable: Draggable, input_info: InputEventMouse)
signal on_clicked (draggable: Draggable, input_info: InputEventMouse)

enum ClickStatus { 
	NOTHING = 0,
	BEGAN = 1,
	CONVERTED_TO_DRAG = 2,
}

var plane: Plane
var input_info: InputEventMouse

var _draggable: Draggable
var _hover: Draggable
var _input_start_time: int
var _input_start_position: Vector2
var _click_status: ClickStatus

var is_dragging: bool = false


## Initializes the drag plane using the provided gizmo.
func _ready ():
	if drag_plane_gizmo:
		plane = Plane(drag_plane_gizmo.basis.y, drag_plane_gizmo.global_position)


## Main input handler for managing mouse motion, clicks, and drag transitions.
func _input (event: InputEvent) -> void:
	if event is InputEventMouse:
		input_info = event
		# Handle mouse movement for dragging or determining if a click should become a drag
		if event is InputEventMouseMotion:
			if is_dragging:
				drag(_draggable)
			elif (
					_click_status == ClickStatus.BEGAN
					and _hover
					and (
						Time.get_ticks_msec() - _input_start_time >= click_threshold_time_ms
						or _input_start_position.distance_to(event.position) >= click_threshold_distance
					)
			):
				begin_drag(_hover)
		# Handle button presses and releases to distinguish between clicks and drag completion
		elif event is InputEventMouseButton:
			if event.button_index != MOUSE_BUTTON_LEFT:
				return
			if event.pressed:
				_input_start_time = Time.get_ticks_msec()
				_input_start_position = event.position
				_click_status = ClickStatus.BEGAN
			elif event.is_released():
				var target = _hover if _hover else _draggable
				if target:
					if _click_status == ClickStatus.BEGAN:
						click(target)
					elif _click_status == ClickStatus.CONVERTED_TO_DRAG:
						end_drag(target)
				_click_status = ClickStatus.NOTHING


## Registers a Draggable object as being currently hovered by the mouse.
func register_mouse_enter_in_draggable (draggable: Draggable) -> bool:
	if is_dragging:
		return false
	_hover = draggable
	on_mouse_entered_draggable.emit(draggable, input_info)
	return true


## Unregisters a Draggable object when the mouse leaves its area.
func register_mouse_exit_in_draggable (draggable: Draggable) -> bool:
	if is_dragging:
		return false
	if _hover == draggable:
		_hover = null
	on_mouse_exited_draggable.emit(draggable, input_info)
	return true


## Initiates a drag operation for the specified Draggable object.
func begin_drag (draggable: Draggable) -> void:
	if not draggable or not draggable.draggable:
		return
	is_dragging = true
	# Handle swapping between draggables if another one is already active
	if _draggable:
		if _draggable == draggable:
			return
		else:
			end_drag(_draggable)
	_click_status = ClickStatus.CONVERTED_TO_DRAG
	draggable._before_begin_drag(input_info.position)
	on_drag_began.emit(draggable, input_info)
	_draggable = draggable


## Updates the state of the current drag operation.
func drag (draggable: Draggable) -> void:
	if not is_dragging:
		return
	draggable._before_drag(input_info.position)
	on_dragged.emit(draggable, input_info)


## Concludes the current drag operation.
func end_drag (draggable: Draggable) -> void:
	if not is_dragging:
		return
	is_dragging = false
	draggable._before_end_drag(input_info.position)
	_draggable = null
	on_drag_ended.emit(draggable, input_info)


## Triggers a click event on the specified Draggable object.
func click (draggable: Draggable) -> void:
	on_clicked.emit(draggable, input_info)
	draggable._before_click(input_info.position)


## Projects a 2D mouse position into a 3D world position via ray-plane intersection.
func mouse_to_world_position (mouse_position: Vector2) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		push_error("There is no 3D camera in the scene. Function 'mouse_to_world_position' needs one.")
		return Vector3.ZERO
	# Default to horizontal plane if no custom plane is defined
	if not plane:
		plane = Plane(camera.basis.z, Vector3.ZERO)
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_dir = camera.project_ray_normal(mouse_position)
	var point = plane.intersects_ray(ray_origin, ray_dir)
	if point:
		return point
	push_warning("No intersection found with the drag plane (%s)." % str(plane))
	return Vector3.ZERO
