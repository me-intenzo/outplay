class_name CardView
extends TextureButton

signal card_selected(card: CardData)

var card_data: CardData
var selected := false


func setup(data: CardData) -> void:
	card_data = data
	texture_normal = get_card_texture(data.displayed_value)
	custom_minimum_size = Vector2(128, 128)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func get_card_texture(value: int) -> Texture2D:
	if value == 1:
		return load("res://assets/cards/card_assassin.png")

	if value == 9:
		return load("res://assets/cards/card_king.png")
	print("REFRESH CARD: ", card_data.true_value, " -> ", card_data.displayed_value)
	return load("res://assets/cards/card_%d.png" % value)


func _pressed() -> void:
	if card_data == null:
		return

	selected = !selected

	if selected:
		position.y -= 20
	else:
		position.y += 20
	card_selected.emit(card_data)
	
func matches_card(card: CardData) -> bool:
	return card_data == card
	
func setup_hidden(data: CardData) -> void:
	card_data = data
	texture_normal = load("res://assets/cards/card_back.png")
	custom_minimum_size = Vector2(128, 128)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func refresh_visual() -> void:
	if card_data == null:
		return

	texture_normal = get_card_texture(card_data.displayed_value)
