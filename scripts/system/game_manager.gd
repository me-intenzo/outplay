class_name GameManager
extends Control

const CARD_SCENE := preload("res://scenes/card.tscn")

const POINTS_TO_WIN := 3

var round_number := 1

var selected_card: CardData = null

var player_1 := PlayerState.new()
var player_2 := PlayerState.new()

var deck := Deck.new()
var player_card_views: Array[CardView] = []

var card_played := false
var player_1_played: CardData = null
var player_2_played: CardData = null

@onready var player_hand: HBoxContainer = $PlayerHand
@onready var play_button: Button = $PlayButton
@onready var opponent_hand: HBoxContainer = $OpponentHand
@onready var player_2_play_button: Button = $Player2PlayButton


func _ready() -> void:
	print("OUTPLAY starting...")

	deck.shuffle()

	deal_starting_hands()

	print_hand("Player 1", player_1.hand)
	print_hand("Player 2", player_2.hand)

	print("Cards remaining in tie-break deck: ", deck.cards.size())

	player_2_play_button.pressed.connect(_on_player_2_play_button_pressed)
	play_button.pressed.connect(_on_play_button_pressed)
	display_player_hand()
	display_opponent_hand()


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
	for card_view in player_card_views:
		card_view.queue_free()
	player_card_views.clear()
	
	for card in player_1.hand:
		var card_view := CARD_SCENE.instantiate() as CardView
		player_hand.add_child(card_view)

		card_view.setup(card)

		card_view.card_selected.connect(_on_card_selected)

		player_card_views.append(card_view)

func display_opponent_hand() -> void:
	for card in player_2.hand:
		var card_view := CARD_SCENE.instantiate() as CardView
		opponent_hand.add_child(card_view)
		card_view.setup_hidden(card)

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
	player_1_played = selected_card

	print("PLAYER 1 PLAYED CARD: ", selected_card.value)

	play_button.disabled = true


func _on_player_2_play_button_pressed() -> void:
	if player_2_played != null:
		return
	if player_2.hand.is_empty():
		return

	player_2_played = player_2.hand[0]

	print("PLAYER 2 PLAYED: ", player_2_played.value)

	player_2_play_button.disabled = true

	resolve_round()
	
func resolve_round() -> void:
	if player_1_played == null:
		return

	if player_2_played == null:
		return

	print("----- ROUND RESULT -----")

	print("Player 1: ", player_1_played.value)
	print("Player 2: ", player_2_played.value)

	if card_beats(player_1_played.value, player_2_played.value):
		print("PLAYER 1 WINS!")
		player_1.score += 1

		print("Player 1 score: ", player_1.score)
		print("Player 2 score: ", player_2.score)

		finish_round()

	elif card_beats(player_2_played.value, player_1_played.value):
		print("PLAYER 2 WINS!")
		player_2.score += 1

		print("Player 1 score: ", player_1.score)
		print("Player 2 score: ", player_2.score)

		finish_round()

	else:
		print("TIE!")

		# Tie-break system comes later.
		print("Tie-break system not implemented yet.")
	
	
func finish_round() -> void:
	if player_1.score >= POINTS_TO_WIN:
		print("PLAYER 1 WINS THE MATCH!")
		return

	if player_2.score >= POINTS_TO_WIN:
		print("PLAYER 2 WINS THE MATCH!")
		return

	remove_played_cards()

	round_number += 1

	print("----- ROUND ", round_number, " -----")

	reset_round_state()

	display_player_hand()
	
func card_beats(attacker: int, defender: int) -> bool:
	# Assassin beats King.
	if attacker == 1 and defender == 9:
		return true

	# King does not beat Assassin.
	if attacker == 9 and defender == 1:
		return false

	return attacker > defender

func remove_played_cards() -> void:
	player_1.hand.erase(player_1_played)
	player_2.hand.erase(player_2_played)

	print("Player 1 cards remaining: ", player_1.hand.size())
	print("Player 2 cards remaining: ", player_2.hand.size())
	
func reset_round_state() -> void:
	selected_card = null
	
	player_1_played = null
	player_2_played = null
	
	card_played = false
	
	play_button.disabled = false
	player_2_play_button.disabled = false
