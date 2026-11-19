extends RefCounted
static func capture(arena) -> Array[Dictionary]:
	var party: Array[Dictionary] = []
	for p in arena.players:
		party.append({"weapon":p.equipped_weapon,"hp":p.hp,"max_hp":p.max_hp,"energy":p.energy,"healing_flasks":p.healing_flasks,"flask_heal_amount":p.flask_heal_amount,"ai_controlled":p.ai_controlled,"down":p.down,"pieces":arena.pieces,"clean_sample":arena.clean_sample})
	return party
static func restore(arena, entry_key: String) -> void:
	var tree: SceneTree = arena.get_tree()
	var party: Array = []
	if tree.has_meta("party_state"):
		party = tree.get_meta("party_state").duplicate(true)
		tree.remove_meta("party_state")
		tree.set_meta(entry_key,party.duplicate(true))
	elif tree.has_meta(entry_key): party = tree.get_meta(entry_key).duplicate(true)
	apply(arena, party)
	if not tree.has_meta(entry_key): tree.set_meta(entry_key, capture(arena))

static func apply(arena, party: Array) -> void:
	arena.pieces = maxi(0,int(party[0].get("pieces",0))) if not party.is_empty() else 0
	if not party.is_empty(): arena.clean_sample = bool(party[0].get("clean_sample", arena.clean_sample))
	for i in arena.players.size():
		var p = arena.players[i]
		var saved: Dictionary = party[i] if i < party.size() else {}
		p.max_hp = maxi(1,int(saved.get("max_hp",100)))
		p.hp = clampi(int(saved.get("hp",p.max_hp)),0,p.max_hp)
		if p.hp == 0 or bool(saved.get("down", false)):
			p.hp = p.max_hp
		p.down = false
		p.energy = clampf(float(saved.get("energy",100)),0,100)
		p.healing_flasks = maxi(0,int(saved.get("healing_flasks",5)))
		p.flask_heal_amount = maxi(1,int(saved.get("flask_heal_amount",25)))
		p.ai_controlled = bool(saved.get("ai_controlled",i == 1))
		if not p.equip_weapon(saved.get("weapon","brush" if i == 0 else "bubbles")):
			p.equip_weapon("brush" if i == 0 else "bubbles")
