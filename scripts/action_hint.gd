extends HBoxContainer

@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label

@export var icon: Texture2D: 
	set(value):
		icon = value
		if icon_rect: icon_rect.texture = value
		
func set_text(text:String) -> void:
	label.text = text
	visible = text != ""
	
