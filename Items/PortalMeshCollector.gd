extends Node
class_name PortalMeshCollector

func get_teleportable_meshes() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	
	for child in get_children():
		if child is MeshInstance3D:
			result.append(child)
		
		if child.get_child_count() > 0:
			for subchild in child.get_children():
				if subchild is MeshInstance3D:
					result.append(subchild)
	
	return result
