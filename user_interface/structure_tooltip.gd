extends Control

@onready var name_label: Label = $TextureRect/NameLabel
@onready var description_label: Label = $TextureRect/DescriptionLabel

func _ready():
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
