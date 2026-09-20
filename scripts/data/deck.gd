class_name Deck
extends RefCounted


var cards: Array[CardData] = []


func _init() -> void:
	reset()


func reset() -> void:
	cards.clear()

	for value in range(1, 10):
		cards.append(CardData.new(value))
		cards.append(CardData.new(value))


func shuffle() -> void:
	cards.shuffle()


func draw() -> CardData:
	if cards.is_empty():
		return null

	return cards.pop_back()
