extends RichTextLabel

signal typing_finished
signal auto_hide_complete
signal interaction_required  # Emitted when force_interaction is true and typing finished

@export var characters_per_second: float = 30.0  # Typing speed
@export var default_delay_ms: float = 50.0  # Default delay between characters

var current_text: String = ""
var display_text: String = ""
var current_index: int = 0
var is_typing: bool = false
var typing_timer: float = 0.0
var pause_timer: float = 0.0
var current_subtitle_data: SubtitleData = null
var auto_hide_timer_started: bool = false
var waiting_for_interaction: bool = false
var auto_hide_timer: SceneTreeTimer = null  # Track the auto-hide timer

func _ready() -> void:
	visible_characters = 0
	bbcode_enabled = true  # Enable BBCode rendering

func _input(event: InputEvent) -> void:
	# Handle interaction for force_interaction mode
	if waiting_for_interaction and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		auto_hide_complete.emit()
		waiting_for_interaction = false
		return
	
	# Handle skipping typing animation
	if is_typing and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		# Check if skipping is allowed
		if current_subtitle_data and current_subtitle_data.require_finished_text:
			return  # Don't allow skipping
		skip_typing()

func display_subtitle(subtitle: String, custom_speed: float = -1.0, shake_rate: float = 20.0, shake_level: float = 5.0) -> void:
	"""Display a subtitle with typing effect. Supports <delay_ms> tags for pauses."""
	# Cancel any existing auto-hide timer
	_cancel_auto_hide_timer()
	
	current_text = subtitle
	display_text = _parse_text(subtitle, shake_rate, shake_level)
	text = display_text
	current_index = 0
	is_typing = true
	visible_characters = 0
	pause_timer = 0.0
	auto_hide_timer_started = false
	waiting_for_interaction = false
	typing_timer = 0.0
	
	# Use custom speed if provided
	if custom_speed > 0.0:
		characters_per_second = custom_speed

func display_subtitle_resource(subtitle_data: SubtitleData) -> void:
	"""Display a subtitle from a SubtitleData resource."""
	if not subtitle_data:
		return
	
	# Check if current subtitle can be interrupted
	if current_subtitle_data and not current_subtitle_data.allow_interruption and is_typing:
		print("Subtitle interruption blocked - current subtitle does not allow interruption")
		return
	
	# Cancel any existing auto-hide timer before starting new subtitle
	_cancel_auto_hide_timer()
	
	current_subtitle_data = subtitle_data
	var text_to_display = subtitle_data.get_display_text()
	display_subtitle(text_to_display, subtitle_data.characters_per_second, subtitle_data.shake_rate, subtitle_data.shake_level)

func _parse_text(raw_text: String, shake_rate: float = 20.0, shake_level: float = 5.0) -> String:
	"""Convert custom tags to BBCode and remove delay tags."""
	var parsed = raw_text
	
	# Remove delay tags (e.g., <100>)
	var delay_regex = RegEx.new()
	delay_regex.compile("<\\d+>")
	parsed = delay_regex.sub(parsed, "", true)
	
	# Convert text formatting tags to BBCode (these are already BBCode compatible, just pass through)
	# Bold: <b>text</b> -> [b]text[/b]
	parsed = parsed.replace("<b>", "[b]")
	parsed = parsed.replace("</b>", "[/b]")
	
	# Italic: <i>text</i> -> [i]text[/i]
	parsed = parsed.replace("<i>", "[i]")
	parsed = parsed.replace("</i>", "[/i]")
	
	# Underline: <u>text</u> -> [u]text[/u]
	parsed = parsed.replace("<u>", "[u]")
	parsed = parsed.replace("</u>", "[/u]")
	
	# Strikethrough: <s>text</s> -> [s]text[/s]
	parsed = parsed.replace("<s>", "[s]")
	parsed = parsed.replace("</s>", "[/s]")
	
	# Shake: <shake>text</shake> -> [shake rate=X level=Y]text[/shake]
	parsed = parsed.replace("<shake>", "[shake rate=" + str(shake_rate) + " level=" + str(shake_level) + "]")
	parsed = parsed.replace("</shake>", "[/shake]")
	
	# Convert color tags to BBCode
	var color_map = {
		"red": "ff0000",
		"blue": "0000ff",
		"green": "00ff00",
		"yellow": "ffff00",
		"orange": "ff8800",
		"purple": "8800ff",
		"white": "ffffff",
		"black": "000000",
		"gray": "808080",
		"grey": "808080",
		"pink": "ff00ff",
		"cyan": "00ffff"
	}
	
	# Replace <color>text</color> with [color=#hex]text[/color]
	for color_name in color_map.keys():
		var hex_code = color_map[color_name]
		# Opening tag
		parsed = parsed.replace("<" + color_name + ">", "[color=#" + hex_code + "]")
		# Closing tag
		parsed = parsed.replace("</" + color_name + ">", "[/color]")
	
	return parsed

func _process(delta: float) -> void:
	if not is_typing:
		return
	
	# Pause typing if game is paused
	if get_tree().paused and not Player.is_reading:
		return
	
	# Handle pause/delay
	if pause_timer > 0.0:
		pause_timer -= delta * 1000.0  # Convert to milliseconds
		return
	
	# Calculate typing progress
	typing_timer += delta
	var delay_between_chars = 1.0 / characters_per_second
	
	# Check if enough time has passed to show next character
	while typing_timer >= delay_between_chars and current_index < current_text.length():
		typing_timer -= delay_between_chars
		
		# Check if we hit a delay tag
		if current_text[current_index] == '<':
			var delay_match = _extract_delay_tag(current_index)
			if delay_match > 0:
				pause_timer = delay_match
				# Skip past the delay tag
				var _end_pos = current_text.find('>', current_index)
				current_index = _end_pos + 1
				return
			
			# Skip color tags
			var end_pos = current_text.find('>', current_index)
			if end_pos != -1:
				var tag_content = current_text.substr(current_index + 1, end_pos - current_index - 1)
				var formatting_tags = ["b", "i", "u", "s", "/b", "/i", "/u", "/s", "shake", "/shake"]
				var color_names = ["red", "blue", "green", "yellow", "orange", "purple", "white", "black", "gray", "grey", "pink", "cyan"]
				
				# Check for formatting tags, closing color tags, or color tags
				if tag_content in formatting_tags or tag_content in color_names or (tag_content.begins_with("/") and tag_content.substr(1) in color_names):
					current_index = end_pos + 1
					continue
		
		current_index += 1
	
	# Update visible characters
	var visible_chars = _count_visible_chars(current_index)
	visible_characters = visible_chars
	
	# Check if typing is complete
	if current_index >= current_text.length():
		is_typing = false
		visible_characters = -1  # Show all text
		
		if not auto_hide_timer_started:
			auto_hide_timer_started = true
			typing_finished.emit()
			
			# Handle force_interaction mode
			if current_subtitle_data and current_subtitle_data.force_interaction:
				waiting_for_interaction = true
				interaction_required.emit()
			# Handle auto-hide
			elif current_subtitle_data and current_subtitle_data.auto_hide:
				_start_auto_hide_timer(current_subtitle_data.auto_hide_delay_ms / 1000.0)

func _start_auto_hide_timer(delay: float) -> void:
	"""Start a new auto-hide timer."""
	_cancel_auto_hide_timer()  # Cancel any existing timer first
	
	auto_hide_timer = get_tree().create_timer(delay)
	auto_hide_timer.timeout.connect(_on_auto_hide_timer_timeout)

func _cancel_auto_hide_timer() -> void:
	"""Cancel the current auto-hide timer if it exists."""
	if auto_hide_timer:
		# Disconnect the signal if still connected
		if auto_hide_timer.timeout.is_connected(_on_auto_hide_timer_timeout):
			auto_hide_timer.timeout.disconnect(_on_auto_hide_timer_timeout)
		auto_hide_timer = null

func _on_auto_hide_timer_timeout() -> void:
	"""Called when auto-hide timer completes."""
	auto_hide_complete.emit()
	auto_hide_timer = null

func _extract_delay_tag(start_pos: int) -> float:
	"""Extract delay value from <delay_ms> tag. Returns 0 if not a valid delay tag."""
	var end_pos = current_text.find('>', start_pos)
	if end_pos == -1:
		return 0.0
	
	var tag_content = current_text.substr(start_pos + 1, end_pos - start_pos - 1)
	if tag_content.is_valid_int():
		return float(tag_content)
	
	return 0.0

func _count_visible_chars(index_in_original: int) -> int:
	"""Count how many visible characters (excluding delay tags and formatting tags) up to the given index."""
	var count = 0
	var i = 0
	var formatting_tags = ["b", "i", "u", "s", "/b", "/i", "/u", "/s", "shake", "/shake"]
	var color_names = ["red", "blue", "green", "yellow", "orange", "purple", "white", "black", "gray", "grey", "pink", "cyan"]
	
	while i < index_in_original and i < current_text.length():
		if current_text[i] == '<':
			var end_pos = current_text.find('>', i)
			if end_pos != -1:
				var tag_content = current_text.substr(i + 1, end_pos - i - 1)
				
				# Check if it's a delay tag (numeric)
				if tag_content.is_valid_int():
					i = end_pos + 1
					continue
				
				# Check if it's a formatting tag
				if tag_content in formatting_tags:
					i = end_pos + 1
					continue
				
				# Check if it's a closing color tag (starts with /)
				if tag_content.begins_with("/") and tag_content.substr(1) in color_names:
					i = end_pos + 1
					continue
				
				# Check if it's an opening color tag
				if tag_content in color_names:
					i = end_pos + 1
					continue
		
		count += 1
		i += 1
	return count

func skip_typing() -> void:
	"""Instantly show all text."""
	if is_typing:
		is_typing = false
		visible_characters = -1  # Show all
		current_index = current_text.length()
		
		if not auto_hide_timer_started:
			auto_hide_timer_started = true
			typing_finished.emit()
		
		# If force_interaction is enabled, wait for input
		if current_subtitle_data and current_subtitle_data.force_interaction:
			waiting_for_interaction = true
			interaction_required.emit()
		# Handle auto-hide after skipping
		elif current_subtitle_data and current_subtitle_data.auto_hide:
			_start_auto_hide_timer(current_subtitle_data.auto_hide_delay_ms / 1000.0)

func clear_subtitle() -> void:
	"""Clear the subtitle."""
	_cancel_auto_hide_timer()  # Cancel timer when clearing
	text = ""
	is_typing = false
	current_index = 0
	visible_characters = 0
	auto_hide_timer_started = false
	current_subtitle_data = null
	waiting_for_interaction = false
