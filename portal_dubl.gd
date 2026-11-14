extends Node
class_name PortalMeshProvider

enum MeshCollectMode {
	ALL_CHILDREN,
	BY_OWNER,
	CUSTOM_ROOT,
}

@export var collect_mode: MeshCollectMode = MeshCollectMode.ALL_CHILDREN:
	set(v):
		collect_mode = v
		notify_property_list_changed()
		_refresh_cache_if_ready()

@export var custom_root: Node3D = null:
	set(v):
		custom_root = v
		_refresh_cache_if_ready()

@export var recursive: bool = true:
	set(v):
		recursive = v
		_refresh_cache_if_ready()

@export var exclude_paths: Array[NodePath] = []

@export var portal_clip_material: ShaderMaterial

@export var auto_apply_material: bool = true

var _cached_meshes: Array[MeshInstance3D] = []
var _cache_built: bool = false

var _exclude_resolved: Array[MeshInstance3D] = []


func _ready() -> void:
	_resolve_excludes()
	_rebuild_cache()
	if auto_apply_material:
		apply_clip_material()


func get_teleportable_meshes() -> Array[MeshInstance3D]:
	if not _cache_built:
		_rebuild_cache()
	return _cached_meshes


func refresh_teleportable_meshes() -> Array[MeshInstance3D]:
	_resolve_excludes()
	_rebuild_cache()
	return _cached_meshes


func _rebuild_cache() -> void:
	_cached_meshes = _collect_meshes()
	_cache_built = true


func _collect_meshes() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []

	match collect_mode:
		MeshCollectMode.ALL_CHILDREN:
			if recursive:
				_collect_recursive(self, result)
			else:
				_collect_direct_children(self, result)

		MeshCollectMode.BY_OWNER:
			var root := _find_owner_root()
			if root == null:
				push_warning("%s: не удалось определить owner-корень, использую self." % name)
				if recursive:
					_collect_recursive(self, result)
				else:
					_collect_direct_children(self, result)
			else:
				_collect_by_owner(root, result)

		MeshCollectMode.CUSTOM_ROOT:
			if custom_root == null:
				push_warning("%s: custom_root не задан, использую self." % name)
				if recursive:
					_collect_recursive(self, result)
				else:
					_collect_direct_children(self, result)
			elif recursive:
				_collect_recursive(custom_root, result)
			else:
				_collect_direct_children(custom_root, result)

	return result


func _resolve_excludes() -> void:
	_exclude_resolved.clear()
	for p in exclude_paths:
		if p.is_empty():
			continue
		var n := get_node_or_null(p)
		if n is MeshInstance3D:
			_exclude_resolved.append(n)
		else:
			push_warning("%s: exclude path '%s' не найден или не MeshInstance3D" % [name, p])


func _is_excluded(mi: MeshInstance3D) -> bool:
	return mi in _exclude_resolved


func _collect_by_owner(root: Node, out: Array[MeshInstance3D]) -> void:
	if root is MeshInstance3D and not _is_excluded(root as MeshInstance3D):
		out.append(root as MeshInstance3D)

	if recursive:
		_walk_owner(root, root, out)
	else:
		for child in root.get_children():
			if child.owner == root and child is MeshInstance3D:
				var mi := child as MeshInstance3D
				if not _is_excluded(mi):
					out.append(mi)


func _walk_owner(node: Node, owner_root: Node, out: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child.owner == owner_root and child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if not _is_excluded(mi):
				out.append(mi)
		_walk_owner(child, owner_root, out)


func _find_owner_root() -> Node:
	return owner if owner != null else self

func _collect_direct_children(node: Node, out: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if not _is_excluded(mi):
				out.append(mi)


func _collect_recursive(node: Node, out: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if not _is_excluded(mi):
				out.append(mi)
		_collect_recursive(child, out)


func _refresh_cache_if_ready() -> void:
	if is_node_ready():
		_resolve_excludes()
		_rebuild_cache()


func apply_clip_material() -> void:
	if portal_clip_material == null:
		return
	for mi in _cached_meshes:
		if not is_instance_valid(mi):
			continue
		mi.material_override = portal_clip_material.duplicate()


func get_cached_meshes() -> Array[MeshInstance3D]:
	return _cached_meshes.duplicate()


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	return props