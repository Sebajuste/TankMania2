extends Node

const Res_directory = "res://"
const Settings_Path = Res_directory + "Settings.cfg"

# 0 : File didn't open
# 1 : File open
enum {LOAD_ERROR_COULDNT_OPEN, LOAD_SUCCESS}

var Settings = {
	"Display": 
	{
		"HEIGHT" : 900,
		"WIDTH" :1600,
		"FullScreen":false,
		"Vsync":true,
		"Antialiasing":true
	},
	"AUDIO":
	{
		"MUTE" : false,
		"MUSIC": 100,
		"GENERAL":100,
		"SOUND_EFFECTS":100
	}
}

var _config = ConfigFile.new()

func update_Settings(height, width, fullscreen, vsync, antialiasing, audio, mute):
	Settings.Display.HEIGHT = height
	Settings.Display.WIDTH = width
	Settings.Display.FullScreen = fullscreen
	Settings.Display.Vsync = vsync
	Settings.Display.Antialiasing = antialiasing
	Settings.AUDIO.GENERAL = audio.x
	Settings.AUDIO.MUSIC = audio.y
	Settings.AUDIO.SOUND_EFFECTS = audio.z
	Settings.AUDIO.MUTE = mute
	#Saving the file than applying it
	_save_Settings()
	_apply_Settings()




func _ready():
	#Check if settings.ini exist if not create a new one with the default Settings
	if _load_Settings() == LOAD_ERROR_COULDNT_OPEN :
		_save_Settings()
	_apply_Settings()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _load_Settings():
	# Check for error if true exist the function else parse the file and load the config settings into Settings
	var error = _config.load(Settings_Path)
	if error != OK:
		print("Error loading the settings. Error code: %s" % error)
		return LOAD_ERROR_COULDNT_OPEN
	for section in Settings.keys():
		for key in Settings[section]:
			var value = _config.get_value(section, key)
			if value != null:
				Settings[section][key] = value
	return LOAD_SUCCESS


func _save_Settings():
	for section in Settings.keys():
		for key in Settings[section]:
			_config.set_value(section, key, Settings[section][key])
	_config.save(Settings_Path)
	

func _apply_Settings():
	# Check out the documentation about :
	# OS class : http://docs.godotengine.org/en/3.0/classes/class_os.html
	# Engine class : http://docs.godotengine.org/en/3.0/classes/class_engine.html
	# for this case i only use OS to change the resolution,fullscreen and Vsync 
	OS.window_size = Vector2(Settings.Display.WIDTH,Settings.Display.HEIGHT)
	OS.window_fullscreen = Settings.Display.FullScreen
	OS.vsync_enabled = Settings.Display.Vsync
	
	get_viewport().msaa = Viewport.MSAA_4X
	
