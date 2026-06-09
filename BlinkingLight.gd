extends Light3D

@export var amp : float = 5
@export var freq : float = 3
@export var random_seed : bool = false
@export var seed_offset : float = 0
var time : float

func _ready() -> void:
	if random_seed:
		seed_offset = randi_range(1, 1000)

func _process(delta: float) -> void:
	time += delta
	light_energy = (sin(time * freq + seed_offset) + 1) * (amp / 2)
