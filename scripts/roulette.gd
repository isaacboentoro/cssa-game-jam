extends Node

signal state_changed(new_state)
signal bets_updated
signal spin_result(number:int, color:String)
signal round_ended(result:String, payout:int)
signal table_toggled(opened_by: String)


enum State {BETTING, SPINNING, ROUND_OVER}

var opened_by := ""
func toggle_table(player_id: String) -> void:
	if opened_by == "":
		opened_by = player_id
	elif opened_by == player_id:
		opened_by = ""
	else:
		return
	table_toggled.emit(opened_by)
	
