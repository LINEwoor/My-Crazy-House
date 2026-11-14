extends Node3D

@export var player_node: Node3D
@export var head_node: Node3D
@export var max_radius: float = 0.05
@export var smoothness: float = 8.0

# Флаги блокировки осей
@export var block_x: bool = false
@export var block_y: bool = false

# Порог "мёртвой зоны" (в локальных единицах направления)
@export var deadzone: float = 0.2
@export var max_distance : float = 15

@onready var center_position: Vector3 = position

func _ready() -> void:
	if not player_node:
		player_node = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if not player_node or not head_node:
		return
	
	var lenght = global_position.distance_to(player_node.global_position)
	
	if lenght > max_distance:
		return
	
	# 1. Направление от головы к игроку
	var to_player: Vector3 = player_node.global_position - head_node.global_position

	# 2. Переводим в локальное пространство РОДИТЕЛЯ картины
	var parent_basis: Basis = get_parent().global_transform.basis
	var local_dir: Vector3 = parent_basis.inverse() * to_player

	# 3. Блокировка осей в направлении
	if block_x:
		local_dir.x = 0.0
	if block_y:
		local_dir.y = 0.0

	# 4. Нормализуем направление (чтобы порог и радиус были в одних единицах)
	var local_dir_norm: Vector3 = local_dir.normalized()

	# 5. Берём X и Y
	var local_offset: Vector2 = Vector2(local_dir_norm.x, local_dir_norm.y)

	# 6. Применяем мёртвую зону
	local_offset = apply_deadzone(local_offset, deadzone)

	# 7. Ограничиваем по кругу
	if local_offset.length() > max_radius:
		local_offset = local_offset.normalized() * max_radius

	# 8. Целевая позиция
	var target_position: Vector3 = center_position + Vector3(local_offset.x, local_offset.y, 0)

	# 9. Плавное движение
	position = position.lerp(target_position, smoothness * delta)


# Функция мёртвой зоны: если длина вектора меньше порога — обнуляем,
# иначе "вычитаем" порог из длины, чтобы движение начиналось плавно с края зоны
func apply_deadzone(offset: Vector2, zone: float) -> Vector2:
	var length: float = offset.length()
	if length <= zone:
		return Vector2.ZERO
	# Вычитаем порог из длины, сохраняя направление
	var new_length: float = length - zone
	return offset.normalized() * new_length