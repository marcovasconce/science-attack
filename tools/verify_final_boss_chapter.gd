extends SceneTree
const Chapters = preload("res://scripts/chapter_catalog.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func settle() -> void:
	for i in 5: await process_frame
func run() -> void:
	change_scene_to_file("res://scenes/main_menu.tscn")
	await settle()
	var menu = current_scene
	check(Chapters.KING_CHAPTER in menu.chapter_ids,"Final boss appears in main chapter menu")
	var debug = root.get_node("DebugPhases")
	var popup: PopupMenu
	for child in debug.row.get_children():
		if child is MenuButton: popup = child.get_popup()
	check(popup != null and popup.get_item_index(Chapters.KING_CHAPTER) >= 0,"Final boss appears in in-game phase selector")
	check(Chapters.valid(31) and Chapters.path_for(31).ends_with("hive_stage.tscn"),"New chapter resolves to final phase")
	set_meta("local_coop",true)
	check(Chapters.open(self,31) == OK,"Chapter opens successfully")
	await settle()
	var hive = current_scene
	hive.set_process(false)
	hive.set_physics_process(false)
	hive.king.set_physics_process(false)
	for p in hive.players: p.set_physics_process(false)
	check(hive.beat == hive.Beat.KING and hive.king.state != hive.king.State.DORMANT,"Chapter begins directly in active king fight")
	check(not hive.controls_locked and not hive.transitioning,"No elevator or workshop wait")
	check(hive.clean_sample and hive.arsenal_claimed and hive.bubble_puzzle.solved,"Workshop and antidote prerequisites prepared")
	for p in hive.players:
		check(p.weapon_upgraded and p.equipped_weapon != "none" and p.hp == p.max_hp and p.energy == 100,"Players have upgraded equipment and full combat resources")
		check(p.position.x > hive.KING_WEST and p.position.x < hive.room_right,"Players spawn within final arena")
	check(not hive.players[1].ai_controlled,"Co-op selection is preserved")
	check(hive.open_limit == hive.room_right and hive.progress_barrier.collision_layer == 0,"No old sector barrier traps the party")
	check(has_meta(hive.BOSS_CHECKPOINT) and not has_meta("hive_king_chapter"),"Retry checkpoint is saved and entry flag consumed")
	hive.restart_with_current_team()
	await settle()
	hive = current_scene
	hive.set_process(false)
	hive.set_physics_process(false)
	check(hive.beat == hive.Beat.KING and hive.arsenal_claimed,"Retry stays at final boss with upgrades")
	check(Chapters.open(self,30) == OK,"Workshop chapter still works")
	await settle()
	hive = current_scene
	hive.set_process(false)
	hive.set_physics_process(false)
	check(hive.beat == hive.Beat.WORKSHOP and not hive.arsenal_claimed,"Returning to workshop clears final boss shortcut")
	check(not has_meta("hive_king_checkpoint") and not has_meta("hive_king_chapter"),"Switching chapters clears boss-only state")
	if failures.is_empty(): print("PASS: final boss chapter in both menus; direct active battle; upgraded weapons, health, energy, antidote; co-op; boss retry; clean workshop return")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

