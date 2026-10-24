## ActionBar
## Bottom-right thumb zone: one large Attack button and four skill buttons in a
## fan, each with cooldown overlay and SP cost. Emits intents; never resolves
## anything itself. Reads cooldown/SP state from CombatSystem every frame.
extends Control

signal intent_requested(intent: Intent)

const ATTACK_SIZE := 104.0
const SKILL_SIZE := 72.0
## Skill button top-left offsets inside this control (fan around the attack button).
const SKILL_SLOTS: Array[Vector2] = [Vector2(96, 184), Vector2(104, 100), Vector2(150, 30), Vector2(224, 4)]

var _attack: Button
var _skill_buttons: Array[SkillButton] = []
var _player: Node = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.player_spawned.connect(_on_player_spawned)
	_attack = SkillButton.new()
	_attack.size = Vector2(ATTACK_SIZE, ATTACK_SIZE)
	_attack.position = Vector2(size.x - ATTACK_SIZE, size.y - ATTACK_SIZE)
	_attack.text = "ATK"
	_attack.button_down.connect(func() -> void: intent_requested.emit(Intent.basic_attack(null)))
	add_child(_attack)
	if GameRules.instance and GameRules.instance.player:
		_on_player_spawned(GameRules.instance.player)


func _on_player_spawned(player: Node) -> void:
	_player = player
	for b in _skill_buttons:
		b.queue_free()
	_skill_buttons.clear()
	if not player.has_method("get_skills"):
		return
	var skills: Array = player.get_skills()
	for i in mini(skills.size(), SKILL_SLOTS.size()):
		var sd: SkillDef = skills[i]
		if sd == null:
			continue
		var b := SkillButton.new()
		b.skill = sd
		b.size = Vector2(SKILL_SIZE, SKILL_SIZE)
		b.position = SKILL_SLOTS[i]
		b.button_down.connect(func() -> void: intent_requested.emit(Intent.use_skill(sd.id, null)))
		add_child(b)
		_skill_buttons.append(b)


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or GameRules.instance == null:
		return
	var combat: CombatSystem = GameRules.instance.combat
	var sp: int = _player.stats.sp
	for b in _skill_buttons:
		var left := combat.get_cooldown_remaining(_player, b.skill.id)
		b.cooldown_left = left
		b.cooldown_fraction = clampf(left / maxf(b.skill.cooldown, 0.01), 0.0, 1.0)
		b.affordable = sp >= b.skill.sp_cost
