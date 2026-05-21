extends PanelContainer

signal master_vol_changed(value: float)
signal music_vol_changed(value: float)
signal sfx_vol_changed(value: float)
signal bg_opacity_changed(value: float)
signal bg_speed_changed(value: float)

func _on_master_slider_value_changed(value: float) -> void:
	master_vol_changed.emit(value)


func _on_music_slider_value_changed(value: float) -> void:
	music_vol_changed.emit(value)


func _on_sfx_slider_value_changed(value: float) -> void:
	sfx_vol_changed.emit(value)


func _on_bg_opacity_slider_value_changed(value: float) -> void:
	bg_opacity_changed.emit(value)


func _on_bg_speed_slider_value_changed(value: float) -> void:
	bg_speed_changed.emit(value)
