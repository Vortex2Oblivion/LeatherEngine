extends Node


const quotes: Array[String] = [
	'Skill Issue', 
	'Shaggy was too strong',
	'You can now play as Luigi',
	'400 BPM',
	'522 BPM',
	'if (!working) crash();',
	'Space Breaker 2%',
	'Should have used a good engine',
	'Haha godot crash handler go brrr',
	'Top 10 null object reference',
	'if (usingLE) memoryLeak();',
	'https://github.com/what-is-a-git/FunkinGodot',
	'https://github.com/riconuts/fnf-troll-engine',
	'Forgor a ;',
	'Play Phighting',
	'Happy with your decisions that led you to this point?',
	'It\'s not too late, port your mod to something good!',
	'Hey,\natleast, it\'s not VSlice!',
	'Hey!\nDid you know, there are more than 6000 species of frogs?',
	'Maybe download more ram?',
	'In the name of Hades, Olympus, I accept this crash!',
	'You didn\'t try and chart 18k, did you?',
	'Guys help im running out of messages to put here',
	'If you are seeing this,\nDM @vortex5694 on Discord the word \'watermelon\'',
	'Hey! Did you know:\nHaxe is an open source high-level\nstrictly-typed programming language\nwith a fast optimizing cross-compiler.',
	'I wonder if it would have been funnier\nif this crash handler was written in pure C...',
	'Ignore the text below this. I\'m glad it crashed.',
	'So John Shedletsky here, if you guys dont know\nthis is the guy from Roblox Forsaken.',
	'OH MY GOD\nIT\'S DOOM SUCKER (from Forsaken)',
	'Leather Engine (Crashes Offline)',
	'Wow\n!\nthis\nmessage\nhas\nso\nmany\nlines\nha\nhaaa\nha\nhhaaa\nhaa\nhga\n\n\n\n\n\n\n\n\n\n\nha'
]

@onready var root: Control = %root
@onready var quote_label: Label = root.get_node('%quote_label')
@onready var dump_label: RichTextLabel = root.get_node('%dump_label')
@onready var background: ColorRect = root.get_node('%background')

var input_file: String


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	var tween := create_tween().set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(background, 'color:a', 0.25, 1.5)
	tween.tween_property(root, 'modulate:a', 1.0, 0.75)
	
	# Initial size is minimum size
	get_window().min_size = get_window().size
	
	var quote: String = quotes.pick_random()
	quote_label.text = '%s\nUnfortunately, Leather Engine has crashed.' % quote
	
	if randi_range(1, 1000) == 128:
		quote_label.text = quote_label.text.replace('Leather Engine', 'You\'re Mother')
	
	for argument in OS.get_cmdline_args():
		if argument.begins_with('--crash_path='):
			input_file = ProjectSettings.globalize_path(argument.split('=')[1])\
					.strip_edges().strip_escapes()
			
			if input_file.begins_with('"') and input_file.ends_with('"'):
				input_file = input_file.lstrip('"').rstrip('"')
			input_file.lstrip('./')
	
	if FileAccess.file_exists(input_file):
		dump_label.text = load_text()
	else:
		printerr(OS.get_cmdline_args())
		printerr('Couldn\'t find file at path "%s"!' % input_file)
		quote_label.text += '\n' + 'Couldn\'t find file at path "%s"!' % input_file


func _on_close_pressed() -> void:
	get_tree().quit()


func load_text() -> String:
	return FileAccess.get_file_as_string(input_file)


func _on_view_crash_dump_pressed() -> void:
	OS.shell_show_in_file_manager(input_file)


func _on_restart_pressed() -> void:
	match OS.get_name():
		'macOS':
			OS.execute('./LeatherEngine.app', [])
		'Linux':
			OS.execute('./LeatherEngine', [])
		'Windows':
			OS.execute('./LeatherEngine.exe', [])
		_:
			print('Uhh.... farf....')
	get_tree().quit()
