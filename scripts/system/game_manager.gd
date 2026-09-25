class_name GameManager
extends Control

const CARD_SCENE := preload("res://scenes/card.tscn")

const POINTS_TO_WIN := 3
const NORMAL_ROUNDS := 5

var round_number := 1

var selected_card: CardData = null
var selected_card_disguised := false
var disguise_cost := 0
const MAX_ENERGY := 10
const CHALLENGE_COST := 3

var player_1 := PlayerState.new()
var player_2 := PlayerState.new()

var tie_break_active := false
var tie_break_round := 0
var deck := Deck.new()
var player_card_views: Array[CardView] = []

var card_played := false
var player_1_played: CardData = null
var player_2_played: CardData = null

@onready var player_hand: HBoxContainer = $PlayerHand
@onready var play_button: Button = $PlayButton
@onready var opponent_hand: HBoxContainer = $OpponentHand
@onready var player_2_play_button: Button = $Player2PlayButton

@onready var player_1_score_label: Label = $Player1Score
@onready var player_2_score_label: Label = $Player2Score
@onready var round_label: Label = $RoundLabel

@onready var disguise_button: Button = $DisguiseButton
@onready var disguise_panel: Panel = $DisguisePanel

@onready var disguise_buttons: Array[Button] = [
	$DisguisePanel/ButtonGrid/Button1,
	$DisguisePanel/ButtonGrid/Button2,
	$DisguisePanel/ButtonGrid/Button3,
	$DisguisePanel/ButtonGrid/Button4,
	$DisguisePanel/ButtonGrid/Button5,
	$DisguisePanel/ButtonGrid/Button6,
	$DisguisePanel/ButtonGrid/Button7,
	$DisguisePanel/ButtonGrid/Button8,
	$DisguisePanel/ButtonGrid/Button9
]
@onready var disguise_cancel_button: Button = $DisguisePanel/CancelButton

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
	update_ui()
	disguise_button.pressed.connect(_on_disguise_button_pressed)
	disguise_cancel_button.pressed.connect(_on_disguise_cancel_pressed)

	for i in range(disguise_buttons.size()):
		disguise_buttons[i].pressed.connect(
			_on_disguise_target_pressed.bind(i + 1)
		)

func deal_starting_hands() -> void:
	for i in range(5):
		player_1.hand.append(deck.draw())
		player_2.hand.append(deck.draw())


func print_hand(player_name: String, hand: Array[CardData]) -> void:
	var values: Array[int] = []

	for card in hand:
		values.append(card.true_value)

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

	print("Selected card: ", card.displayed_value)


func _on_play_button_pressed() -> void:
	if selected_card == null:
		print("No card selected!")
		return

	if card_played:
		return

	card_played = true
	player_1_played = selected_card

	print("PLAYER 1 PLAYED CARD: ", selected_card.displayed_value)

	play_button.disabled = true


func _on_player_2_play_button_pressed() -> void:
	if player_2_played != null:
		return

	if player_2.hand.is_empty():
		return

	player_2_played = player_2.hand[0]

	print("PLAYER 2 PLAYED: ", player_2_played.displayed_value)

	player_2_play_button.disabled = true

	resolve_round()
	
func resolve_round() -> void:
	if player_1_played == null:
		return

	if player_2_played == null:
		return

	print("----- ROUND RESULT -----")
	print("Player 1: ", player_1_played.displayed_value)
	print("Player 2: ", player_2_played.displayed_value)
	if card_beats(
		player_1_played.displayed_value,
		player_2_played.displayed_value
	):
		print("PLAYER 1 WINS ROUND!")
		player_1.score += 1
		print("SCORE: ", player_1.score, " : ", player_2.score)
		finish_round()
	elif card_beats(
		player_2_played.displayed_value,
		player_1_played.displayed_value
	):
		print("PLAYER 2 WINS ROUND!")
		player_2.score += 1
		print("SCORE: ", player_1.score, " : ", player_2.score)
		finish_round()
	else:
		print("TIE!")
		print("NO POINT")
		finish_round()

func finish_round() -> void:
	# Someone reached 3 points.
	if player_1.score >= POINTS_TO_WIN:
		end_game("PLAYER 1 WINS!")
		return

	if player_2.score >= POINTS_TO_WIN:
		end_game("PLAYER 2 WINS!")
		return

	remove_played_cards()

	# Five normal cards/rounds have now been completed.
	if round_number >= NORMAL_ROUNDS:
		finish_five_rounds()
		return

	round_number += 1

	print("----- ROUND ", round_number, " -----")

	reset_round_state()
	display_player_hand()
	update_ui()
	

func finish_five_rounds() -> void:
	print("----- FIVE ROUNDS COMPLETE -----")

	print("FINAL SCORE: ", player_1.score, " : ", player_2.score)

	if player_1.score > player_2.score:
		end_game("PLAYER 1 WINS!")

	elif player_2.score > player_1.score:
		end_game("PLAYER 2 WINS!")

	else:
		print("SCORE TIED!")

		start_tie_break()

func start_tie_break() -> void:
	tie_break_active = true
	tie_break_round = 0

	print("===== TIE-BREAK =====")

	play_tie_break()

func play_tie_break() -> void:
	tie_break_round += 1

	print("----- TIE-BREAK ", tie_break_round, " -----")

	if deck.cards.size() < 2:
		end_game("DRAW GAME")
		return

	var player_1_tie_card: CardData = deck.draw()
	var player_2_tie_card: CardData = deck.draw()

	print("P1 TIE-BREAK CARD: ", player_1_tie_card.true_value)
	print("P2 TIE-BREAK CARD: ", player_2_tie_card.true_value)

	if card_beats(
		player_1_tie_card.true_value,
		player_2_tie_card.true_value
	):
		print("PLAYER 1 WINS TIE-BREAK!")
		end_game("PLAYER 1 WINS!")

	elif card_beats(
		player_2_tie_card.true_value,
		player_1_tie_card.true_value
	):
		print("PLAYER 2 WINS TIE-BREAK!")
		end_game("PLAYER 2 WINS!")

	else:
		print("TIE AGAIN!")

		play_tie_break()
func end_game(result: String) -> void:
	print("========================")
	print("       GAME OVER")
	print(result)
	print("========================")

	play_button.disabled = true
	player_2_play_button.disabled = true

	tie_break_active = false
	
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

func update_ui() -> void:
	player_1_score_label.text = "PLAYER 1  |  SCORE: %d" % player_1.score
	player_2_score_label.text = "PLAYER 2  |  SCORE: %d" % player_2.score
	round_label.text = "ROUND %d" % round_number

func calculate_disguise_cost(current_value: int, target_value: int) -> int:
	var cost :int = abs(target_value - current_value)
	if target_value == 1 or target_value == 9:
		cost = max(cost, 2)
	return cost

func can_disguise(card: CardData) -> bool:
	if card.true_value == 9:
		return false

	return true
	
func can_disguise_to(card: CardData, target_value: int) -> bool:
	if card.true_value == 9:
		return false

	if target_value == card.true_value:
		return false

	var cost: int = calculate_disguise_cost(
		card.true_value,
		target_value
	)

	if player_1.energy < cost:
		return false

	return true

func test_disguise(card: CardData, target_value: int) -> void:
	if not can_disguise_to(card, target_value):
		print("Cannot disguise.")
		return

	disguise_cost = calculate_disguise_cost(
		card.true_value,
		target_value
	)

	player_1.energy -= disguise_cost

	card.displayed_value = target_value

	selected_card_disguised = true

	print("TRUE VALUE: ", card.true_value)
	print("DISPLAYED VALUE: ", card.displayed_value)
	print("DISGUISE COST: ", disguise_cost)
	print("ENERGY REMAINING: ", player_1.energy)



func _on_disguise_button_pressed() -> void:
	if selected_card == null:
		print("Select a card first.")
		return

	if not can_disguise(selected_card):
		print("This card cannot be disguised.")
		return

	update_disguise_menu()

	disguise_panel.visible = true
	
func update_disguise_menu() -> void:
	if selected_card == null:
		return

	for target_value in range(1, 10):
		var button: Button = disguise_buttons[target_value - 1]

		var allowed := can_disguise_to(
			selected_card,
			target_value
		)

		button.disabled = not allowed

		if allowed:
			var cost: int = calculate_disguise_cost(
				selected_card.true_value,
				target_value
			)

			button.text = "%d  (%dE)" % [target_value, cost]

		else:
			button.text = "%d  (X)" % target_value

func _on_disguise_target_pressed(target_value: int) -> void:
	if target_value < 1 or target_value > 9:
		return
	if selected_card == null:
		return

	if not can_disguise_to(selected_card, target_value):
		print("Cannot disguise to ", target_value)
		return

	disguise_cost = calculate_disguise_cost(
		selected_card.true_value,
		target_value
	)

	player_1.energy -= disguise_cost

	selected_card.displayed_value = target_value
	selected_card_disguised = true

	print("----- DISGUISE -----")
	print("TRUE VALUE: ", selected_card.true_value)
	print("DISPLAYED VALUE: ", selected_card.displayed_value)
	print("COST: ", disguise_cost)
	print("ENERGY: ", player_1.energy)

	disguise_panel.visible = false

	update_selected_card_visual()

func update_selected_card_visual() -> void:
	for card_view in player_card_views:
		if card_view.card_data == selected_card:
			card_view.refresh_visual()
			break
			

func _on_disguise_cancel_pressed() -> void:
	disguise_panel.visible = false
