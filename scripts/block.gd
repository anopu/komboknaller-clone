extends Node2D

@export var color:String
@export var isChecked:bool = false


func move(target):
	var tween: Tween = create_tween()
	tween.tween_property(self,"position",target, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
