extends Node

var player : Player
var player_camera : Camera3D

enum InputContext {
	GAMEPLAY,
	MENU,
	INVENTORY,
	VALVE,
	LOCKED,
}

const _CONTEXT_RULES := {
	InputContext.GAMEPLAY:  {"paused": false, "mouse": Input.MOUSE_MODE_CAPTURED, "player_frozen": false},
	InputContext.MENU:      {"paused": true,  "mouse": Input.MOUSE_MODE_VISIBLE,  "player_frozen": true},
	InputContext.INVENTORY: {"paused": false, "mouse": Input.MOUSE_MODE_VISIBLE,  "player_frozen": true},
	InputContext.VALVE:     {"paused": false, "mouse": Input.MOUSE_MODE_CAPTURED, "player_frozen": true},
	InputContext.LOCKED:    {"paused": false, "mouse": Input.MOUSE_MODE_CAPTURED,  "player_frozen": true},
	}

var _context_stack : Array[InputContext] = [InputContext.GAMEPLAY]


func _ready() -> void:
	_apply_context()


func push_context(ctx: InputContext) -> void:
	_context_stack.append(ctx)
	_apply_context()


func pop_context() -> void:
	if _context_stack.size() <= 1:
		return
	_context_stack.pop_back()
	_apply_context()


func remove_context(ctx: InputContext) -> void:
	for i in range(_context_stack.size() - 1, 0, -1):
		if _context_stack[i] == ctx:
			_context_stack.remove_at(i)
			_apply_context()
			return


func current_context() -> InputContext:
	return _context_stack.back()


func is_gameplay_active() -> bool:
	return current_context() == InputContext.GAMEPLAY


func is_player_frozen() -> bool:
	return _CONTEXT_RULES[current_context()].player_frozen


func _apply_context() -> void:
	var rules : Dictionary = _CONTEXT_RULES[current_context()]
	get_tree().paused = rules.paused
	Input.mouse_mode = rules.mouse