class_name CardData
extends RefCounted

var true_value: int
var displayed_value: int


func _init(card_value: int) -> void:
	true_value = card_value
	displayed_value = card_value
