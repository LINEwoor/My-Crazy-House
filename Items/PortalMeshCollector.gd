extends Node
class_name PortalMeshCollector

@export var custom_owner: Node3D

func get_teleportable_meshes() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	var root: Node = custom_owner if custom_owner != null else owner
	if root == null:
		root = self
	_collect(root, result)
	return result

func _collect(node: Node, result: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child)
		_collect(child, result)