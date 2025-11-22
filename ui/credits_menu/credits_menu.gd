extends Control

@onready var credits_return_button: Button = %CreditsReturnButton
@onready var next_button: Button = %NextButton

@onready var credits_vbox1 = $CreditsVBox1
@onready var credits_vbox2 = $CreditsVBox2
@onready var credits_vbox3 = $CreditsVBox3

@onready var t20 = $T20
@onready var next_credits_vbox1 = $NextCreditsVBox1

var current_page: int = 1
var on_close: Callable

func _ready() -> void:
	credits_return_button.pressed.connect(on_credits_return_button_pressed)
	next_button.pressed.connect(on_next_button_pressed)
	
	# Initialize - show page 1, hide page 2
	show_page_1()

func on_next_button_pressed() -> void:
	current_page = 2
	
	# Hide page 1
	credits_vbox1.hide()
	credits_vbox2.hide()
	credits_vbox3.hide()
	next_button.hide()
	
	# Show page 2
	#t20.show()
	next_credits_vbox1.show()

func show_page_1() -> void:
	current_page = 1
	
	# Show page 1
	credits_vbox1.show()
	credits_vbox2.show()
	credits_vbox3.show()
	next_button.show()
	
	# Hide page 2
	#t20.hide()
	next_credits_vbox1.hide()

func on_credits_return_button_pressed() -> void:
	if current_page == 2:
		# Go back to page 1
		show_page_1()
	else:
		# Return to main menu
		if on_close.is_valid():
			on_close.call()
