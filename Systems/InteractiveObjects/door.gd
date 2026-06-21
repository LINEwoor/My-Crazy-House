extends InteractiveObject
class_name Door

@export var animator : AnimationPlayer
@export var isLocked : bool = false
@export var lock_id : int = -1
@export var canHand : bool = true
@export var animationName : String = "Open"
@export var autoClose : bool = false
@export var autoCloseDelay : float = 3.0

var isOpen : bool = false
var tween : Tween

signal door_opened
signal door_closed
signal door_locked

func _ready():
	if not animator:
		animator = get_node_or_null("AnimationPlayer")


func Interactive(activator = null):
	if activator is InteractiveButton:
		remote_interactive()
	else:
		if isOpen:
			close_door(activator)
		else:
			open_door(activator)

func open_door(character = null):
	if isOpen:
		return
	
	if isLocked:
		emit_signal("door_locked")
		_on_door_locked()
		return
	
	
	if character and not canHand:
		return
	
	isOpen = true
	animator.play(animationName)
	emit_signal("door_opened")
	
	if autoClose:
		start_auto_close_timer()

func close_door(character = null):
	if not isOpen:
		return
	
	isOpen = false
	animator.play_backwards(animationName)
	emit_signal("door_closed")
	
	if autoClose:
		cancel_auto_close()


func lock():
	isLocked = true

func unlock():
	isLocked = false

func _on_door_locked():
	if animator and animator.has_animation("locked"):
		animator.play("locked")

func start_auto_close_timer():
	cancel_auto_close()
	tween = create_tween()
	tween.tween_interval(autoCloseDelay)
	tween.tween_callback(_auto_close)

func cancel_auto_close():
	if tween and tween.is_valid():
		tween.kill()

func _auto_close():
	if isOpen:
		close_door()

func remote_interactive():
	if isOpen:
		close_door()
	else:
		open_door()

func is_door_open() -> bool:
	return isOpen

func is_door_locked() -> bool:
	return isLocked
