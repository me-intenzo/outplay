class_name GameManager
extends Control

const CARD_SCENE := preload("res://scenes/card.tscn")

var selected_card: CardData = null

var player_1 := PlayerState.new()
var player_2 := PlayerState.new()

var deck := Deck.new()

var card_played := false

@onready var player_hand: HBoxContainer = $PlayerHand
@onready var play_button: Button = $PlayButton


func _ready() -> void:
	print("OUTPLAY starting...")

	deck.shuffle()

	deal_starting_hands()

	print_hand("Player 1", player_1.hand)
	print_hand("Player 2", player_2.hand)

	print("Cards remaining in tie-break deck: ", deck.cards.size())

	play_button.pressed.connect(_on_play_button_pressed)
	display_player_hand()


func deal_starting_hands() -> void:
	for i in range(5):
		player_1.hand.append(deck.draw())
		player_2.hand.append(deck.draw())


func print_hand(player_name: String, hand: Array[CardData]) -> void:
	var values: Array[int] = []

	for card in hand:
		values.append(card.value)

	print(player_name, ": ", values)


func display_player_hand() -> void:
	for card in player_1.hand:
		var card_view := CARD_SCENE.instantiate() as CardView

		player_hand.add_child(card_view)

		card_view.setup(card)

		card_view.card_selected.connect(_on_card_selected)


func _on_card_selected(card: CardData) -> void:
	if card_played:
		return

	selected_card = card

	print("Selected card: ", card.value)


func _on_play_button_pressed() -> void:
	if selected_card == null:
		print("No card selected!")
		return

	if card_played:
		return

	card_played = true

	print("PLAYED CARD: ", selected_card.value)

	play_button.disabled = true
