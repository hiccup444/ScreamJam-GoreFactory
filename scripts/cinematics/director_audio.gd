extends AudioStreamPlayer3D

@export var cinematic: AnimationPlayer

const MALE_GETTING_UNALIVED = preload("uid://q5ehfi77626q")
const MALE_GUTTERAL_SCREAM = preload("uid://cpgy3vouqga1e")
const MALE_SHOCKED_YELL = preload("uid://bjg8wb4p2gt4r")
const MALE_SHOCKED_YELL_2 = preload("uid://bk2eaaq2dhmdl")
const MALE_STILL_ALIVE_AFTER_SLICED_APART = preload("uid://dxfplsqtu8g88")

func play_director_screaming() -> void:
	AudioManager.play_3d(self, MALE_GUTTERAL_SCREAM)

func play_director_shocked_1() -> void:
	AudioManager.play_3d(self, MALE_SHOCKED_YELL)

func play_director_shocked_2() -> void:
	AudioManager.play_3d(self, MALE_SHOCKED_YELL_2)
