extends Node2D

@onready var queue: Node2D = $Queue

const max_size: int = 5
const item_spacing: float = 18.0

signal finished_item(unit_scene: PackedScene)

func is_empty() -> bool:
	return queue.get_child_count() == 0

func size() -> int:
	return queue.get_child_count()

func add(item: BuildItem) -> bool:
	if queue.get_child_count() >= max_size:
		return false

	queue.add_child(item)
	item.finished.connect(finished)
	_reflow()

	if queue.get_child_count() == 1:
		item.start()

	return true

func remove(index: int) -> bool:
	if index < 0 or index >= queue.get_child_count():
		push_error("BuildQueue.remove: invalid index " + str(index))
		return false

	var child: Node = queue.get_child(index)
	queue.remove_child(child)
	child.queue_free()
	return true

func finished(unit_scene: PackedScene) -> void:
	if remove(0):
		finished_item.emit(unit_scene)
		_reflow()

		if queue.get_child_count() > 0:
			queue.get_child(0).start()

func _reflow() -> void:
	for i: int in queue.get_child_count():
		var child: Node2D = queue.get_child(i)
		child.position.x = i * item_spacing
