extends Node3D
## ПОДВАЛ — PS1 horror. Весь мир строится из low-poly мешей прямо в коде.

const LowPoly = preload("res://Scripts/LowPoly.gd")
const PS1Mat = preload("res://Scripts/PS1Mat.gd")
const PS1Tex = preload("res://Scripts/PS1Tex.gd")
const Humanoid = preload("res://Scripts/Humanoid.gd")
const Monster = preload("res://Scripts/Monster.gd")
const Rat = preload("res://Scripts/Rat.gd")
const Action = preload("res://Scripts/Action.gd")
const Imp = preload("res://Scripts/Imp.gd")
const ItemModels = preload("res://Scripts/ItemModels.gd")
const MONSTER_ENABLED := false  # true — вернуть монстра
const PlayerScript = preload("res://Scripts/Player.gd")
const TouchScript = preload("res://Scripts/TouchControls.gd")
const VIGNETTE = preload("res://Shaders/vignette.gdshader")
const MENU_BG = preload("res://Shaders/menu_bg.gdshader")
const MenuScene = preload("res://Scripts/MenuScene.gd")
const MCStyle = preload("res://Scripts/MCStyle.gd")
const Portrait = preload("res://Scripts/Portrait.gd")
const Blood = preload("res://Scripts/Blood.gd")
const BodyDamage = preload("res://Scripts/BodyDamage.gd")
const MoodleBar = preload("res://Scripts/MoodleBar.gd")
const Sfx = preload("res://Scripts/Sfx.gd")
const InvPanel = preload("res://Scripts/InvPanel.gd")
const Atmo = preload("res://Scripts/Atmo.gd")
const FAINT_SHADER = preload("res://Shaders/faint.gdshader")
const BAR_RATIO := 0.1  # единый параметр: высота каждой полосы = 10% высоты экрана

const CAM_OFFSET := Vector3(0.0, 6.0, 5.0)
const LAMP_ENERGY := 1.7

const USABLE := ["knife", "pistol", "syringe", "rope", "cuffs", "banana", "poison", "crowbar", "beartrap", "note",
	"bandage", "medkit", "water", "chocolate", "canned", "beans", "lighter", "flashlight", "lockpick", "sylphy", "tape"]
const THROW_HEAVY := ["crowbar", "pistol", "medkit", "canned", "beans", "beartrap", "water"]
const SPLASHES := ["Не смотри под пол!", "18+", "Ключ в ящике!", "Свет гаснет сам!", "Сильфи ждёт!", "Осторожно, банан!",
	"Нажми «Открыть»!", "PS1 навсегда!", "Тут кто-то есть!"]
const OPENABLE := ["table", "crate", "shelf", "barrel", "boiler", "bench", "fridge", "bed", "cabinet", "crate3", "table2", "door"]
const OPEN_TEXT := {
	"table": ["Грубый стол. В столешнице ящик.", "Ты выдвигаешь ящик стола."],
	"crate": ["Ящик у полки. Крышка прибита небрежно.", "Крышка с хрустом поддаётся."],
	"shelf": ["Полка с банками и склянками.", "Ты разгребаешь банки."],
	"barrel": ["Бочка. Внутри что-то глухо перекатывается.", "Ты снимаешь крышку бочки."],
	"boiler": ["Холодный котёл. За ним что-то висит.", "Створка котла со скрипом отходит."],
	"bench": ["Верстак: тиски, молоток, ящики.", "Ты выдвигаешь ящик верстака."],
	"fridge": ["Старый холодильник. Гудит.", "Дверца отходит с чавканьем."],
	"bed": ["Кровать с продавленным матрасом.", "Ты приподнимаешь матрас."],
	"cabinet": ["Металлический шкаф с замком.", "Ты берёшься за дверцу шкафа."],
	"crate3": ["Складской ящик, внутри солома.", "Ты разгребаешь солому."],
	"table2": ["Стол с ржавым хламом.", "Ты роешься в хламе."],
}
const ITEM_NAMES := {
	"key": "латунный ключ", "note": "записка", "knife": "нож", "pistol": "пистолет",
	"syringe": "шприц", "rope": "верёвка", "cuffs": "наручники", "banana": "банан",
	"poison": "яд", "crowbar": "ломик", "beartrap": "капкан",
	"bandage": "бинт", "medkit": "аптечка", "water": "вода", "chocolate": "шоколад", "canned": "консерва",
	"beans": "открытая консерва", "lighter": "зажигалка", "flashlight": "фонарик", "lockpick": "отмычка",
	"sylphy": "плюшевая Сильфи", "tape": "скотч",
}
const ITEM_DESC := {
	"key": "Латунный ключ от выхода.",
	"note": "Записка: ключ в ящике, свет гаснет сам.",
	"knife": "Короткий нож. Режет верёвки и консервы.",
	"pistol": "Старый пистолет. Патроны считаны.",
	"syringe": "Шприц с мутной жидкостью. Лучше не трогать.",
	"rope": "Крепкая верёвка. Вяжет и ставит ловушки.",
	"cuffs": "Стальные наручники. Холодные.",
	"banana": "Почти свежий банан. Откуда он здесь?",
	"poison": "Склянка с чёрной этикеткой. Не пить.",
	"crowbar": "Тяжёлый ломик. Вскроет замок.",
	"beartrap": "Капкан. Ставится на пол.",
	"bandage": "Чистый бинт. Лечит раны.",
	"medkit": "Аптечка с красным крестом.",
	"water": "Закрытая бутылка воды.",
	"chocolate": "Плитка шоколада.",
	"canned": "Консерва без этикетки. Нужен нож.",
	"beans": "Открытая банка фасоли.",
	"lighter": "Зажигалка. Даёт немного света.",
	"flashlight": "Фонарик. Батарейки живы.",
	"lockpick": "Набор отмычек.",
	"sylphy": "Плюшевая Сильфи с зелёной чёлкой.",
	"tape": "Серый скотч. Рот, руки, стул. Держит крепко.",
}
const NEON := {
	"key": Color(1.0, 0.95, 0.2), "note": Color(0.7, 1.0, 1.0), "knife": Color(0.2, 1.0, 1.0),
	"pistol": Color(1.0, 0.2, 0.9), "syringe": Color(0.3, 1.0, 0.35), "rope": Color(1.0, 0.6, 0.1),
	"cuffs": Color(0.3, 0.5, 1.0), "banana": Color(0.8, 1.0, 0.1), "poison": Color(0.75, 0.3, 1.0),
	"crowbar": Color(1.0, 0.25, 0.25), "beartrap": Color(1.0, 0.45, 0.0),
	"bandage": Color(1.0, 1.0, 1.0), "medkit": Color(1.0, 0.3, 0.3), "water": Color(0.4, 0.8, 1.0),
	"chocolate": Color(0.8, 0.5, 0.3), "canned": Color(0.9, 0.6, 0.2), "beans": Color(0.9, 0.6, 0.2),
	"lighter": Color(1.0, 0.7, 0.2), "flashlight": Color(1.0, 1.0, 0.6), "lockpick": Color(0.7, 0.9, 1.0),
	"sylphy": Color(0.4, 1.0, 0.6), "tape": Color(0.75, 0.8, 0.9),
}
const PICK_TEXT := {
	"key": "На дне ящика лежит старый латунный ключ. Он холодный на ощупь.\n[Получено: ключ]",
	"note": "Ты находишь записку: «Свет иногда гаснет сам. Не паникуй. Ключ оставлен в ящике. Не корми ЕГО после полуночи».\n[Получено: записка]",
	"knife": "Под запиской в столешницу воткнут нож. На лезвии засохла бурая корка.\n[Получено: нож]",
	"pistol": "В шкафу, на куске промасленной ткани, лежит пистолет. В магазине три патрона.\n[Получено: пистолет, патроны: 3]",
	"syringe": "В морозилке старого холодильника — шприц с мутной жидкостью. На этикетке: «СНОТВ... не трясти».\n[Получено: шприц]",
	"rope": "За котлом висит моток крепкой верёвки. Один конец перетёрт.\n[Получено: верёвка]",
	"cuffs": "К спинке кровати прикованы старые стальные наручники. Ты отщёлкиваешь их.\n[Получено: наручники]",
	"banana": "Среди пустых бочек, на дне, лежит банан. Почти свежий. Откуда он здесь?\n[Получено: банан]",
	"poison": "За банками стоит склянка с чёрной этикеткой: «ЯД. НЕ ПИТЬ. СЕРЬЁЗНО».\n[Получено: яд]",
	"crowbar": "На верстаке лежит тяжёлый ломик. Идеально, чтобы вскрыть что-нибудь. Или кого-нибудь.\n[Получено: ломик]",
	"bandage": "На дне бочки — рулон почти чистого бинта.\n[Получено: бинт]",
	"medkit": "В шкафу, под пистолетом, стоит потёртая аптечка с красным крестом.\n[Получено: аптечка]",
	"water": "На полке стоит бутылка воды. Закрыта. Это хорошо.\n[Получено: вода]",
	"chocolate": "В столе, под бумагами, завалялась плитка шоколада.\n[Получено: шоколад]",
	"canned": "В холодильнике, в самом углу, консервная банка без этикетки. Нечем открыть — найди нож или ломик.\n[Получено: консерва]",
	"lighter": "На столе лежит зажигалка. Искра с первого раза.\n[Получено: зажигалка]",
	"flashlight": "Под котлом лежит фонарик. Батарейки ещё живы.\n[Получено: фонарик]",
	"lockpick": "В ящике верстака — набор тонких отмычек.\n[Получено: отмычка]",
	"sylphy": "На кровати, прижатая к стене, сидит плюшевая Сильфи с зелёной чёлкой. Кто-то очень её любил.\n[Получено: плюшевая Сильфи]",
	"tape": "В хламе на столе — почти целый моток серого скотча.\n[Получено: скотч]",
}

var player
var girl
var monster
var girl_ropes: Node3D
var camera: Camera3D
var key_light: DirectionalLight3D
var lamp: OmniLight3D
var tv_light: OmniLight3D
var red_light: OmniLight3D
var touch

var mats: Dictionary = {}
var props: Dictionary = {}
var interactables: Array = []
var near_target: Dictionary = {}
var loot: Dictionary = {}
var traps: Array = []
var inv: Dictionary = {}

var game_started: bool = false
var ended: bool = false
var busy: bool = false
var girl_talked: bool = false
var girl_freed: bool = false
var girl_dead: bool = false
var girl_asleep: bool = false
var girl_cuffed: bool = false
var cabinet_open: bool = false
var poison_banana: bool = false
var poison_syringe: bool = false
var touch_enabled: bool = false
var shadows_on: bool = true

var hp: int = 100
var ammo: int = 0
var monster_on: bool = false
var rats: Array = []  # крысы (Rat.gd): мирные, пока их не тронуть
var action  # бой, камера в духе Hotline Miami, укрытия (Action.gd)
var _end_cam_on: bool = false
var _end_cam_pos: Vector3 = Vector3.ZERO
var _end_cam_look: Vector3 = Vector3.ZERO
var _cam_q: Quaternion = Quaternion(Vector3.RIGHT, deg_to_rad(-50.0))
var monster_dead: bool = false
var monster_hp: int = 6
var monster_stun: float = 0.0
var monster_cd: float = 0.0
var shake: float = 0.0
var _hold_token: int = 0
var _summoning: bool = false

var menu_panel: Control
var play_btn: Button
var title_label: Label
var hud_panel: Control
var hud_btns: Array = []
var hp_fill: ColorRect
var objective_label: Label
var inventory_label: Label
var prompt_label: Label
var toast_label: Label
var flash_rect: ColorRect
var fade_rect: ColorRect
var dialog_panel: PanelContainer
var dialog_label: Label
var dialog_buttons: HFlowContainer
var _dialog_tween: Tween
var _toast_tween: Tween
var sack: Node3D
var swingers: Array = []
var talk_cam: bool = false
var cage_open: bool = true
var _anims: Dictionary = {}
var vent_eyes: Node3D
var portrait  # окно с камерой девушки (Portrait.gd)
var _next_portrait: bool = false
var blood  # кровь (Blood.gd)
var pdmg: BodyDamage  # система повреждений игрока (Body/Limb из Casualties: Unknown)
var moodle_label: Label
var moodle_bar  # панель состояний внизу экрана (MoodleBar.gd)
var pain_rect: ColorRect  # красная пульсация от боли
var dim_rect: ColorRect   # затемнение при падении сознания
var _downed: float = 0.0  # лежит после болевого падения
var _pain_beat: float = 0.0
var _dying: bool = false
var _wear_t: float = 0.0
var _bleed_vis_t: float = 0.0
var _last_heart_vol: float = 0.0
var atmo  # живые детали подвала (Atmo.gd)
var inv_panel  # рюкзак (InvPanel.gd)
var held_item: String = ""
var girl_gagged: bool = false
var girl_taped: bool = false
var sound_on: bool = true
var shake_on: bool = true
var held_bar: PanelContainer
var held_label: Label
var _throwing: bool = false
var _temp_holding: bool = false
var _sfx_cache: Dictionary = {}
var _atk_cd: float = 0.0
var projectiles: Array = []
var thrown: Dictionary = {}
var thrown_n: int = 0
var pack_node: Node3D
var pack_widgets: Array = []
var settings_panel: Control
var open_btn: Button
var _bar_amount: float = 0.0
var faint_rect: ColorRect
var faint_mat: ShaderMaterial
var fp_cam: Camera3D
var _fainting: bool = false
var thud_player: AudioStreamPlayer
var drone_player: AudioStreamPlayer
var creak_player: AudioStreamPlayer
var _creak_t: float = 10.0
var dust: CPUParticles3D
var splash_label: Label
var flash_light: OmniLight3D
var lighter_light: OmniLight3D
var flashlight_on: bool = false
var cut_skip: bool = false
var in_cutscene: bool = false
var _key_cut_done: bool = false
var girl_has_sylphy: bool = false
var settings_btns: Dictionary = {}
var bars_top: ColorRect
var bars_bot: ColorRect
var caption_label: Label
var pixel_font: Font
var trust: int = 20
var girl_following: bool = true
var has_override: bool = false
var cam_focus: Vector3 = Vector3.ZERO
var cam_zoom: float = 1.0
var _intro_done: bool = false
var _emote_token: int = 0

var _flicker_timer: float = 2.0
var _blackout: float = 0.0
var _clock: float = 0.0

# ------------------------------------------------------------------ setup

func _ready() -> void:
	randomize()
	shadows_on = not OS.has_feature("mobile")
	touch_enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	_setup_input()
	_build_materials()
	_build_loot()
	blood = Blood.new()
	add_child(blood)
	blood.setup(mats)
	pdmg = BodyDamage.new()
	add_child(pdmg)
	pdmg.expired.connect(_on_pdmg_death)
	pdmg.fainted.connect(_on_pdmg_faint)
	pdmg.collapsed.connect(_on_pain_collapse)
	_build_world()
	_build_extras()
	_build_extras2()
	_build_side_rooms()
	_build_girl()
	_build_player()
	_build_monster()
	_build_rats()
	_build_camera()
	_build_ui()
	_build_faint_layer()
	_build_atmosphere()
	atmo = Atmo.new()
	add_child(atmo)
	atmo.setup(self, mats)
	action = Action.new()
	add_child(action)
	action.setup(self)
	get_viewport().size_changed.connect(func(): _set_bars(_bar_amount))
	_apply_shadows()
	_show_menu()

func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_F],
		"inventory": [KEY_Q, KEY_I, KEY_TAB],
		"open": [KEY_R, KEY_O],
		"use_held": [KEY_SPACE],
		"throw_held": [KEY_G],
		"holster": [KEY_X],
		"wounds": [KEY_T],
		"dodge": [KEY_SHIFT],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var axes := [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0],
		["move_up", JOY_AXIS_LEFT_Y, -1.0], ["move_down", JOY_AXIS_LEFT_Y, 1.0]]
	for a in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = a[1]
		jm.axis_value = a[2]
		InputMap.action_add_event(a[0], jm)
	var jb := InputEventJoypadButton.new()
	jb.button_index = JOY_BUTTON_A
	InputMap.action_add_event("interact", jb)
	var jx := InputEventJoypadButton.new()
	jx.button_index = JOY_BUTTON_X
	InputMap.action_add_event("inventory", jx)

func _build_materials() -> void:
	PS1Mat.reset()
	var t_brick := PS1Tex.make("brick", 3)
	var t_planks := PS1Tex.make("planks", 5)
	var t_tiles := PS1Tex.make("tiles", 7)
	var t_metal := PS1Tex.make("metal", 9)
	var t_conc := PS1Tex.make("concrete", 11)
	mats["wall"] = PS1Mat.make(Color(0.55, 0.53, 0.58), t_brick, 1.0)
	mats["wall_dark"] = PS1Mat.make(Color(0.38, 0.38, 0.45), t_brick, 1.0)
	mats["floor"] = PS1Mat.make(Color(0.5, 0.48, 0.48), t_tiles, 0.8)
	mats["wood"] = PS1Mat.make(Color(0.5, 0.36, 0.26), t_planks, 1.6)
	mats["wood_light"] = PS1Mat.make(Color(0.72, 0.55, 0.38), t_planks, 1.6)
	mats["metal"] = PS1Mat.make(Color(0.5, 0.56, 0.62), t_metal, 1.5)
	mats["metal_light"] = PS1Mat.make(Color(0.72, 0.76, 0.8), t_metal, 1.5)
	mats["rust"] = PS1Mat.make(Color(0.6, 0.38, 0.26), t_metal, 1.5)
	mats["concrete"] = PS1Mat.make(Color(0.5, 0.5, 0.52), t_conc, 2.0)
	mats["stain"] = PS1Mat.make(Color(0.22, 0.2, 0.25))
	mats["blood"] = PS1Mat.make(Color(0.36, 0.015, 0.02))
	mats["blood_wet"] = PS1Mat.make(Color(0.55, 0.03, 0.04), null, 1.0, 0.12)
	mats["blood_dark"] = PS1Mat.make(Color(0.12, 0.006, 0.01))
	mats["tape"] = PS1Mat.make(Color(0.6, 0.62, 0.66))
	mats["glass"] = PS1Mat.make(Color(0.35, 0.55, 0.4))
	mats["paper"] = PS1Mat.make(Color(0.85, 0.8, 0.65))
	mats["lamp"] = PS1Mat.make(Color(1.0, 0.82, 0.45), null, 1.0, 1.6)
	mats["exit_glow"] = PS1Mat.make(Color(0.9, 0.2, 0.15), null, 1.0, 0.9)
	mats["red_lamp"] = PS1Mat.make(Color(1.0, 0.1, 0.08), null, 1.0, 1.4)
	mats["tv"] = PS1Mat.make(Color(0.6, 0.8, 0.9), null, 1.0, 1.3)
	mats["black"] = PS1Mat.make(Color(0.04, 0.04, 0.05))
	mats["mattress"] = PS1Mat.make(Color(0.62, 0.6, 0.5), t_conc, 1.5)
	mats["carpet"] = PS1Mat.make(Color(0.36, 0.1, 0.12), t_conc, 2.0)
	mats["sack"] = PS1Mat.make(Color(0.46, 0.4, 0.3), t_conc, 1.0)
	mats["banana"] = PS1Mat.make(Color(0.95, 0.82, 0.18))
	mats["skin"] = PS1Mat.make(Color(0.82, 0.62, 0.52))
	mats["cloth_p"] = PS1Mat.make(Color(0.62, 0.16, 0.16))
	mats["pants_p"] = PS1Mat.make(Color(0.2, 0.22, 0.32))
	mats["hair_p"] = PS1Mat.make(Color(0.12, 0.09, 0.07))
	mats["cloth_g"] = PS1Mat.make(Color(0.13, 0.13, 0.16))
	mats["pants_g"] = PS1Mat.make(Color(0.14, 0.14, 0.17))
	mats["trim"] = PS1Mat.make(Color(0.72, 0.72, 0.76))
	mats["hair_g"] = PS1Mat.make(Color(0.66, 0.64, 0.68))
	mats["skin_g"] = PS1Mat.make(Color(0.78, 0.71, 0.72))
	mats["white"] = PS1Mat.make(Color(0.95, 0.95, 0.92))
	mats["it_green"] = PS1Mat.make(Color(0.3, 0.75, 0.4))
	mats["it_cyan"] = PS1Mat.make(Color(0.3, 0.7, 0.85))
	mats["lips"] = PS1Mat.make(Color(0.65, 0.2, 0.22))
	mats["tear"] = PS1Mat.make(Color(0.7, 0.85, 1.0), null, 1.0, 0.4)
	mats["bruise"] = PS1Mat.make(Color(0.45, 0.3, 0.42))
	# имп (игрок) и рюкзак
	mats["imp_skin"] = PS1Mat.make(Color(0.1, 0.09, 0.16))
	mats["imp_pale"] = PS1Mat.make(Color(0.78, 0.82, 0.85), null, 1.0, 0.15)
	mats["imp_ear"] = PS1Mat.make(Color(0.28, 0.16, 0.24))
	mats["imp_eye"] = PS1Mat.make(Color(1.0, 1.0, 0.9), null, 1.0, 0.8)
	mats["imp_iris"] = PS1Mat.make(Color(0.8, 1.0, 0.1), null, 1.0, 1.0)
	mats["imp_pupil"] = PS1Mat.make(Color(0, 0, 0))
	mats["imp_teeth"] = PS1Mat.make(Color(1.0, 0.95, 0.4), null, 1.0, 0.5)
	mats["imp_glow"] = PS1Mat.make(Color(0.3, 0.8, 1.0), null, 1.0, 0.8)
	mats["it_dark"] = PS1Mat.make(Color(0.2, 0.17, 0.2), t_conc, 2.0)
	mats["it_red"] = PS1Mat.make(Color(0.5, 0.07, 0.1), t_conc, 2.0)
	mats["it_metal"] = PS1Mat.make(Color(0.42, 0.4, 0.45), t_metal, 2.0)
	mats["it_rope"] = PS1Mat.make(Color(0.45, 0.28, 0.27), t_conc, 2.0)
	mats["it_yellow"] = PS1Mat.make(Color(0.85, 0.68, 0.2), t_conc, 2.0)
	mats["it_brass"] = PS1Mat.make(Color(0.75, 0.58, 0.2), t_metal, 2.0)
	mats["pack"] = PS1Mat.make(Color(0.22, 0.17, 0.2), t_conc, 2.0)
	mats["pack_dark"] = PS1Mat.make(Color(0.12, 0.09, 0.11), t_conc, 2.0)
	mats["neon"] = PS1Mat.make(Color(0.2, 1.0, 0.9), null, 1.0, 1.2)
	# монстр
	mats["mon_skin"] = PS1Mat.make(Color(0.07, 0.07, 0.1))
	mats["mon_pale"] = PS1Mat.make(Color(0.55, 0.78, 0.85), null, 1.0, 0.25)
	mats["mon_eye"] = PS1Mat.make(Color(1.0, 1.0, 0.95), null, 1.0, 0.7)
	mats["mon_iris"] = PS1Mat.make(Color(0.85, 1.0, 0.1), null, 1.0, 0.9)
	mats["mon_pupil"] = PS1Mat.make(Color(0.0, 0.0, 0.0))
	mats["mon_teeth"] = PS1Mat.make(Color(0.95, 0.9, 0.55), null, 1.0, 0.2)
	mats["mon_tongue"] = PS1Mat.make(Color(0.7, 0.1, 0.12))
	mats["mon_hair"] = PS1Mat.make(Color(0.02, 0.02, 0.025))

func _build_loot() -> void:
	loot = {
		"table": {"items": ["note", "knife", "lighter"], "empty": "Только пыль."},
		"crate": {"items": ["key"], "empty": "Пусто."},
		"shelf": {"items": ["poison", "water"], "empty": "Банки и ржавчина."},
		"barrel": {"items": ["banana", "bandage"], "empty": "Гулкая пустота."},
		"boiler": {"items": ["rope", "flashlight"], "empty": "Холодный котёл."},
		"bench": {"items": ["crowbar", "lockpick"], "empty": "Тиски, молоток. Больше ничего."},
		"fridge": {"items": ["syringe", "canned"], "empty": "Лёд и запах."},
		"bed": {"items": ["cuffs", "sylphy"], "empty": "Старый матрас."},
		"cabinet": {"items": ["pistol", "medkit"], "locked": true, "empty": "Пусто."},
		"crate3": {"items": ["beartrap"], "empty": "Солома и гвозди."},
		"table2": {"items": ["chocolate", "tape"], "empty": "Ржавый хлам."},
	}

# ------------------------------------------------------------------ world helpers

func _solid(node_name: String, pos: Vector3, size: Vector3, mat: Material, show_mesh: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	add_child(body)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	if show_mesh:
		var bm := BoxMesh.new()
		bm.size = size
		_mesh(body, bm, mat, Vector3.ZERO)
	return body

func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func _boxm(size: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = size
	return bm

func _interactable(id: String, pos: Vector3, reach: float = 1.7) -> void:
	interactables.append({"id": id, "pos": pos, "reach": reach})

func _make_knife_prop() -> Node3D:
	var k: Node3D = ItemModels.make("knife", mats)
	k.scale = Vector3.ONE * 1.6
	return k

func _make_pistol_prop() -> Node3D:
	var p: Node3D = ItemModels.make("pistol", mats)
	p.scale = Vector3.ONE * 1.8
	return p

# ------------------------------------------------------------------ world

func _build_world() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.01, 0.011, 0.016)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.34, 0.37, 0.48)
	e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color(0.045, 0.052, 0.068)
	e.fog_density = 0.042
	we.environment = e
	add_child(we)

	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-60, -20, 0)
	key_light.light_energy = 0.25
	key_light.light_color = Color(0.7, 0.75, 1.0)
	add_child(key_light)

	# Пол и стены (передняя сторона открыта для камеры, но закрыта невидимым коллайдером)
	_solid("Floor", Vector3(0, -0.25, 0), Vector3(12.8, 0.5, 10.8), mats["floor"])
	_solid("BackWall", Vector3(0, 1.8, -5.2), Vector3(12.8, 3.6, 0.4), mats["wall"])
	_solid("LeftWallB", Vector3(-6.2, 1.8, -3.05), Vector3(0.4, 3.6, 4.7), mats["wall_dark"])
	_solid("LeftWallF", Vector3(-6.2, 1.8, 3.05), Vector3(0.4, 3.6, 4.7), mats["wall_dark"])
	_solid("LeftLintel", Vector3(-6.2, 3.15, 0), Vector3(0.4, 0.9, 1.4), mats["wall_dark"])
	_solid("RightWallB", Vector3(6.2, 1.8, -2.6), Vector3(0.4, 3.6, 5.6), mats["wall_dark"])
	_solid("RightWallF", Vector3(6.2, 1.8, 3.5), Vector3(0.4, 3.6, 3.8), mats["wall_dark"])
	_solid("RightLintel", Vector3(6.2, 3.15, 0.9), Vector3(0.4, 0.9, 1.4), mats["wall_dark"])
	_solid("FrontInvisible", Vector3(0, 1.8, 5.2), Vector3(12.8, 3.6, 0.4), mats["wall"], false)
	_mesh(self, _boxm(Vector3(12.0, 0.25, 0.12)), mats["concrete"], Vector3(0, 0.125, 5.0))

	# Потолочные трубы
	_mesh(self, LowPoly.frustum(6, 0.1, 0.1, 12.0), mats["metal"], Vector3(0, 3.3, -4.85), Vector3(0, 0, 90))
	_mesh(self, LowPoly.frustum(6, 0.08, 0.08, 10.0), mats["rust"], Vector3(-5.85, 3.0, 0), Vector3(90, 0, 0))
	_mesh(self, LowPoly.frustum(6, 0.07, 0.07, 3.0), mats["rust"], Vector3(-5.85, 1.5, -2.5))

	# Лампа
	_mesh(self, _boxm(Vector3(0.02, 0.7, 0.02)), mats["black"], Vector3(0, 3.25, -0.2))
	_mesh(self, LowPoly.frustum(6, 0.3, 0.08, 0.2), mats["metal"], Vector3(0, 2.85, -0.2))
	_mesh(self, LowPoly.sphere(Vector3(0.07, 0.07, 0.07), 5, 3), mats["lamp"], Vector3(0, 2.72, -0.2))
	lamp = OmniLight3D.new()
	lamp.position = Vector3(0, 2.6, -0.2)
	lamp.light_color = Color(1.0, 0.75, 0.45)
	lamp.light_energy = LAMP_ENERGY
	lamp.omni_range = 10.0
	add_child(lamp)

	# Дверь выхода (задняя стена) + красный отсвет
	props["exit_door"] = _solid("ExitDoor", Vector3(0, 1.15, -4.93), Vector3(1.4, 2.3, 0.12), mats["wood"])
	_mesh(self, _boxm(Vector3(0.15, 2.5, 0.2)), mats["wood_light"], Vector3(-0.78, 1.25, -4.9))
	_mesh(self, _boxm(Vector3(0.15, 2.5, 0.2)), mats["wood_light"], Vector3(0.78, 1.25, -4.9))
	_mesh(self, _boxm(Vector3(1.7, 0.15, 0.2)), mats["wood_light"], Vector3(0, 2.45, -4.9))
	props["exit_panel"] = _mesh(self, _boxm(Vector3(1.0, 1.7, 0.04)), mats["wood_light"], Vector3(0, 1.15, -4.84))
	props["exit_knob"] = _mesh(self, LowPoly.sphere(Vector3(0.07, 0.07, 0.07), 5, 3), mats["lamp"], Vector3(0.5, 1.1, -4.78))
	_mesh(self, _boxm(Vector3(0.5, 0.12, 0.05)), mats["exit_glow"], Vector3(0, 2.7, -4.95))
	var door_glow := OmniLight3D.new()
	door_glow.position = Vector3(0, 2.3, -4.2)
	door_glow.light_color = Color(0.9, 0.62, 0.36)
	door_glow.light_energy = 0.3
	door_glow.omni_range = 4.0
	add_child(door_glow)
	_interactable("door", Vector3(0, 0, -4.6), 1.5)

	# Полка с банками
	var shelf := _solid("Shelf", Vector3(-4.3, 1.0, -4.3), Vector3(1.9, 2.0, 1.1), mats["wood"], false)
	_mesh(shelf, _boxm(Vector3(0.12, 2.0, 1.1)), mats["wood"], Vector3(-0.9, 0, 0))
	_mesh(shelf, _boxm(Vector3(0.12, 2.0, 1.1)), mats["wood"], Vector3(0.9, 0, 0))
	for y in [-0.85, -0.1, 0.65]:
		_mesh(shelf, _boxm(Vector3(1.8, 0.1, 1.1)), mats["wood_light"], Vector3(0, y, 0))
	var jar_i := 0
	for y in [-0.7, 0.05, 0.8]:
		for x in [-0.55, -0.1, 0.4]:
			jar_i += 1
			_mesh(shelf, LowPoly.frustum(7, 0.1, 0.1, 0.2 + 0.03 * (jar_i % 3)), mats["glass"] if jar_i % 2 == 0 else mats["rust"], Vector3(x, y + 0.15, 0.05))
	# череп на полке
	_mesh(shelf, LowPoly.sphere(Vector3(0.12, 0.13, 0.13), 6, 4), mats["white"], Vector3(0.7, 0.8, 0.15))
	_mesh(shelf, _boxm(Vector3(0.1, 0.05, 0.08)), mats["white"], Vector3(0.7, 0.7, 0.2))
	_interactable("shelf", Vector3(-4.3, 0, -3.5), 1.5)
	props["wob_shelf"] = shelf

	# Ящик с ключом и второй ящик
	var crate := _solid("OldCrate", Vector3(-3.9, 0.4, -2.2), Vector3(0.8, 0.8, 0.8), mats["wood_light"])
	_mesh(crate, _boxm(Vector3(0.84, 0.1, 0.84)), mats["wood"], Vector3(0, 0.3, 0))
	_mesh(crate, _boxm(Vector3(0.84, 0.1, 0.84)), mats["wood"], Vector3(0, -0.3, 0))
	_interactable("crate", Vector3(-3.9, 0, -2.2), 1.5)
	_add_lid(crate, 0.8, "crate")
	var crate2 := _solid("Crate2", Vector3(-5.1, 0.3, -3.4), Vector3(0.6, 0.6, 0.6), mats["wood"])
	crate2.rotation_degrees.y = 18.0

	# Стол, записка, кружка, нож, стул
	var table := _solid("Table", Vector3(1.2, 0.475, -2.0), Vector3(2.2, 0.95, 1.1), mats["wood"], false)
	_mesh(table, _boxm(Vector3(2.2, 0.12, 1.1)), mats["wood_light"], Vector3(0, 0.41, 0))
	for x in [-0.95, 0.95]:
		for z in [-0.4, 0.4]:
			_mesh(table, _boxm(Vector3(0.12, 0.84, 0.12)), mats["wood"], Vector3(x, -0.05, z))
	_mesh(table, _boxm(Vector3(0.35, 0.01, 0.25)), mats["paper"], Vector3(-0.4, 0.475, 0.1), Vector3(0, 20, 0))
	_mesh(table, LowPoly.frustum(6, 0.06, 0.05, 0.1), mats["rust"], Vector3(0.5, 0.52, -0.1))
	var knife_prop := _make_knife_prop()
	knife_prop.position = Vector3(0.1, 0.5, 0.0)
	knife_prop.rotation_degrees = Vector3(0, 35, 0)
	table.add_child(knife_prop)
	props["knife"] = knife_prop
	_interactable("table", Vector3(1.2, 0, -2.0), 2.1)
	var tdr := Node3D.new()
	tdr.position = Vector3(0.45, 0.3, 0.54)
	table.add_child(tdr)
	_mesh(tdr, _boxm(Vector3(0.8, 0.14, 0.05)), mats["wood_light"], Vector3.ZERO)
	_mesh(tdr, _boxm(Vector3(0.18, 0.04, 0.05)), mats["metal"], Vector3(0, 0, 0.04))
	props["drawer_table"] = tdr
	var chair := _solid("Chair", Vector3(2.9, 0.45, -1.3), Vector3(0.7, 0.9, 0.7), mats["wood"], false)
	_mesh(chair, _boxm(Vector3(0.6, 0.08, 0.6)), mats["wood"], Vector3(0, -0.05, 0))
	_mesh(chair, _boxm(Vector3(0.6, 0.55, 0.07)), mats["wood"], Vector3(0, 0.25, -0.28))
	for x in [-0.25, 0.25]:
		for z in [-0.25, 0.25]:
			_mesh(chair, _boxm(Vector3(0.06, 0.4, 0.06)), mats["wood"], Vector3(x, -0.25, z))

	# Металлический шкаф (дверца открывается, внутри пистолет)
	var cab := _solid("Cabinet", Vector3(4.6, 0.9, -4.3), Vector3(1.1, 1.8, 0.8), mats["metal"], false)
	_mesh(cab, _boxm(Vector3(1.1, 1.8, 0.7)), mats["black"], Vector3(0, 0, -0.05))
	var pistol_prop := _make_pistol_prop()
	pistol_prop.position = Vector3(4.6, 0.95, -4.2)
	pistol_prop.rotation_degrees = Vector3(0, 20, 0)
	pistol_prop.visible = false
	add_child(pistol_prop)
	props["pistol"] = pistol_prop
	var cab_door := _pivot3(Vector3(4.05, 0.9, -3.88))
	_mesh(cab_door, _boxm(Vector3(1.1, 1.8, 0.05)), mats["metal"], Vector3(0.55, 0, 0))
	_mesh(cab_door, _boxm(Vector3(0.04, 1.6, 0.02)), mats["black"], Vector3(0.55, 0, 0.03))
	_mesh(cab_door, _boxm(Vector3(0.06, 0.25, 0.06)), mats["lamp"], Vector3(0.9, 0, 0.05))
	props["cab_door"] = cab_door
	_interactable("cabinet", Vector3(4.6, 0, -3.5), 1.5)

	# Бочки
	var bi := 0
	for p in [Vector3(-1.2, 0.45, -4.4), Vector3(-0.4, 0.45, -4.45)]:
		var barrel := _solid("Barrel", p, Vector3(0.7, 0.9, 0.7), mats["rust"], false)
		_mesh(barrel, LowPoly.frustum(8, 0.36, 0.33, 0.9), mats["rust"], Vector3.ZERO)
		_mesh(barrel, LowPoly.frustum(8, 0.38, 0.38, 0.06), mats["metal"], Vector3(0, 0.15, 0))
		var blid := Node3D.new()
		blid.position = Vector3(0, 0.46, 0)
		barrel.add_child(blid)
		_mesh(blid, LowPoly.frustum(8, 0.35, 0.35, 0.04), mats["metal"], Vector3.ZERO)
		props["lid_barrel_%d" % bi] = blid
		bi += 1
	_interactable("barrel", Vector3(-0.8, 0, -4.2), 1.4)

	# Котёл
	var boiler := _solid("Boiler", Vector3(-5.0, 0.9, 2.6), Vector3(1.3, 1.8, 1.3), mats["metal"], false)
	_mesh(boiler, LowPoly.frustum(8, 0.65, 0.6, 1.8), mats["metal"], Vector3.ZERO)
	_mesh(boiler, LowPoly.frustum(6, 0.09, 0.09, 1.6), mats["rust"], Vector3(0.3, 1.6, 0))
	_mesh(boiler, LowPoly.frustum(6, 0.07, 0.07, 1.2), mats["rust"], Vector3(0.0, 0.6, 0.7), Vector3(90, 0, 0))
	_mesh(boiler, LowPoly.frustum(8, 0.14, 0.14, 0.04), mats["exit_glow"], Vector3(0.0, 0.2, 0.66), Vector3(90, 0, 0))
	_interactable("boiler", Vector3(-5.0, 0, 2.6), 1.9)
	props["wob_boiler"] = boiler

	# Мелкие детали: слив, пятна, обломки, ведро
	_mesh(self, _boxm(Vector3(0.8, 0.02, 0.8)), mats["metal"], Vector3(-1.6, 0.011, 1.6))
	for i in 4:
		_mesh(self, _boxm(Vector3(0.7, 0.025, 0.04)), mats["black"], Vector3(-1.6, 0.025, 1.3 + i * 0.2))
	_mesh(self, _boxm(Vector3(1.6, 0.012, 1.0)), mats["stain"], Vector3(1.6, 0.007, 2.8), Vector3(0, 20, 0))
	_mesh(self, _boxm(Vector3(1.0, 0.012, 0.7)), mats["stain"], Vector3(-2.4, 0.007, 0.6), Vector3(0, -35, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for p in [Vector3(-2.8, 0.06, 0.4), Vector3(4.0, 0.05, 3.2), Vector3(-4.4, 0.05, 2.0), Vector3(2.2, 0.05, -0.2)]:
		_mesh(self, LowPoly.sphere(Vector3(0.18, 0.1, 0.14), 5, 3), mats["concrete"], p, Vector3(0, rng.randf_range(0, 90), 0))
	_rigid_cyl(Vector3(4.6, 0.16, 2.4), 0.17, 0.32, mats["rust"], 2.0, true)

func _pivot3(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	return n

## Дополнительные предметы интерьера: кровать, верстак, холодильник, телевизор, цепи, вентиляция...
func _build_extras() -> void:
	# Ковёр под столом
	_mesh(self, _boxm(Vector3(2.8, 0.015, 2.0)), mats["carpet"], Vector3(1.2, 0.01, -2.0))
	# Кровать с ремнями
	var bed := _solid("Bed", Vector3(5.0, 0.28, -1.9), Vector3(1.1, 0.56, 2.1), mats["wood"], false)
	props["mattress"] = _mesh(bed, _boxm(Vector3(1.0, 0.2, 2.0)), mats["mattress"], Vector3(0, 0.12, 0))
	_mesh(bed, _boxm(Vector3(0.6, 0.12, 0.4)), mats["paper"], Vector3(0, 0.28, -0.75))
	_mesh(bed, _boxm(Vector3(0.5, 0.012, 0.8)), mats["blood"], Vector3(0.05, 0.225, 0.3), Vector3(0, 15, 0))
	for x in [-0.5, 0.5]:
		for z in [-1.0, 1.0]:
			_mesh(bed, _boxm(Vector3(0.08, 0.34, 0.08)), mats["wood"], Vector3(x, -0.12, z))
	for z in [-0.4, 0.2, 0.8]:
		_mesh(bed, _boxm(Vector3(1.04, 0.025, 0.08)), mats["black"], Vector3(0, 0.235, z))
	_mesh(bed, LowPoly.frustum(6, 0.06, 0.06, 0.02), mats["metal"], Vector3(0.4, 0.26, -0.95), Vector3(90, 0, 0))
	_interactable("bed", Vector3(4.6, 0, -1.9), 1.7)
	# Верстак
	var bench := _solid("Bench", Vector3(-5.55, 0.45, -1.7), Vector3(0.8, 0.9, 1.8), mats["wood"], false)
	_mesh(bench, _boxm(Vector3(0.8, 0.08, 1.8)), mats["wood_light"], Vector3(0, 0.41, 0))
	for z in [-0.8, 0.8]:
		for x in [-0.32, 0.32]:
			_mesh(bench, _boxm(Vector3(0.08, 0.82, 0.08)), mats["wood"], Vector3(x, -0.04, z))
	_mesh(bench, _boxm(Vector3(0.2, 0.14, 0.2)), mats["metal"], Vector3(0.1, 0.52, -0.6))
	_mesh(bench, _boxm(Vector3(0.05, 0.04, 0.3)), mats["metal"], Vector3(-0.1, 0.47, 0.1), Vector3(0, 25, 0))
	_mesh(bench, _boxm(Vector3(0.1, 0.1, 0.05)), mats["metal"], Vector3(-0.1, 0.5, 0.25), Vector3(0, 25, 0))
	_mesh(bench, LowPoly.frustum(7, 0.13, 0.11, 0.26), mats["rust"], Vector3(0.0, 0.58, 0.65))
	_mesh(bench, _boxm(Vector3(0.3, 0.012, 0.3)), mats["blood"], Vector3(0.05, 0.455, 0.3))
	_interactable("bench", Vector3(-4.8, 0, -1.7), 1.7)
	var bdr := Node3D.new()
	bdr.position = Vector3(0.43, 0.3, -0.1)
	bench.add_child(bdr)
	_mesh(bdr, _boxm(Vector3(0.05, 0.12, 0.7)), mats["wood_light"], Vector3.ZERO)
	_mesh(bdr, _boxm(Vector3(0.05, 0.04, 0.2)), mats["metal"], Vector3(0.04, 0, 0))
	props["drawer_bench"] = bdr
	# Холодильник
	var fr := _solid("Fridge", Vector3(2.5, 1.0, -4.45), Vector3(0.95, 2.0, 0.8), mats["metal_light"], false)
	_mesh(fr, _boxm(Vector3(0.95, 2.0, 0.8)), mats["metal_light"], Vector3.ZERO)
	_mesh(fr, _boxm(Vector3(0.9, 0.03, 0.02)), mats["black"], Vector3(0, 0.3, 0.41))
	_mesh(fr, _boxm(Vector3(0.05, 0.5, 0.06)), mats["black"], Vector3(0.38, 0.65, 0.43))
	_mesh(fr, _boxm(Vector3(0.05, 0.4, 0.06)), mats["black"], Vector3(0.38, -0.2, 0.43))
	_mesh(fr, _boxm(Vector3(0.25, 0.01, 0.3)), mats["blood"], Vector3(-0.15, -0.99, 0.55))
	var fl := OmniLight3D.new()
	fl.position = Vector3(2.5, 1.6, -3.7)
	fl.light_color = Color(0.5, 0.8, 1.0)
	fl.light_energy = 0.35
	fl.omni_range = 3.0
	add_child(fl)
	_interactable("fridge", Vector3(2.5, 0, -3.7), 1.5)
	_mesh(fr, _boxm(Vector3(0.8, 1.8, 0.02)), mats["black"], Vector3(0, 0, 0.405))
	var fdoor := Node3D.new()
	fdoor.position = Vector3(-0.475, 0, 0.42)
	fr.add_child(fdoor)
	_mesh(fdoor, _boxm(Vector3(0.94, 1.98, 0.04)), mats["metal_light"], Vector3(0.47, 0, 0.02))
	_mesh(fdoor, _boxm(Vector3(0.05, 0.5, 0.06)), mats["black"], Vector3(0.85, 0.5, 0.06))
	_mesh(fdoor, _boxm(Vector3(0.05, 0.4, 0.06)), mats["black"], Vector3(0.85, -0.3, 0.06))
	props["fridge_door"] = fdoor
	# Телевизор на ящике
	var tvbox := _solid("TVBox", Vector3(2.4, 0.25, 3.9), Vector3(0.8, 0.5, 0.6), mats["wood"])
	_mesh(tvbox, _boxm(Vector3(0.72, 0.52, 0.5)), mats["black"], Vector3(0, 0.51, 0))
	_mesh(tvbox, _boxm(Vector3(0.54, 0.38, 0.02)), mats["tv"], Vector3(-0.04, 0.51, 0.26))
	_mesh(tvbox, _boxm(Vector3(0.015, 0.4, 0.015)), mats["black"], Vector3(0.1, 0.9, 0.0), Vector3(0, 0, 25))
	_mesh(tvbox, _boxm(Vector3(0.015, 0.4, 0.015)), mats["black"], Vector3(0.1, 0.9, 0.0), Vector3(0, 0, -25))
	tv_light = OmniLight3D.new()
	tv_light.position = Vector3(2.4, 1.1, 3.4)
	tv_light.light_color = Color(0.55, 0.85, 1.0)
	tv_light.light_energy = 0.5
	tv_light.omni_range = 3.5
	add_child(tv_light)
	_interactable("tv", Vector3(2.4, 0, 3.3), 1.5)
	# Цепи, крюки, мешок
	for x in [-2.3, -1.9, -1.5]:
		var ch := _swinger(Vector3(x, 3.6, 0.2 + (x + 2.3) * 0.3))
		_mesh(ch, _boxm(Vector3(0.03, 1.6, 0.03)), mats["metal"], Vector3(0, -0.8, 0))
		_mesh(ch, LowPoly.frustum(4, 0.01, 0.06, 0.18), mats["metal_light"], Vector3(0, -1.7, 0))
	sack = Node3D.new()
	sack.position = Vector3(-1.9, 2.5, 0.5)
	add_child(sack)
	_mesh(sack, LowPoly.sphere(Vector3(0.24, 0.4, 0.22), 6, 4), mats["sack"], Vector3(0, -0.4, 0))
	_mesh(sack, _boxm(Vector3(0.03, 0.4, 0.03)), mats["metal"], Vector3(0, 0.1, 0))
	_mesh(sack, _boxm(Vector3(0.1, 0.05, 0.02)), mats["blood"], Vector3(0.05, -0.6, 0.2))
	# Рисунок на стене
	_mesh(self, _boxm(Vector3(1.1, 0.8, 0.02)), mats["paper"], Vector3(-2.4, 1.9, -4.98))
	for x in [-0.17, 0.17]:
		_mesh(self, LowPoly.frustum(8, 0.12, 0.12, 0.02), mats["white"], Vector3(-2.4 + x, 2.0, -4.96), Vector3(90, 0, 0))
		_mesh(self, LowPoly.frustum(6, 0.04, 0.04, 0.03), mats["black"], Vector3(-2.4 + x, 2.0, -4.95), Vector3(90, 0, 0))
	_mesh(self, _boxm(Vector3(0.5, 0.05, 0.02)), mats["black"], Vector3(-2.4, 1.65, -4.96))
	for i in 6:
		_mesh(self, _boxm(Vector3(0.025, 0.1, 0.02)), mats["black"], Vector3(-2.6 + i * 0.08, 1.58, -4.96))
	_interactable("drawing", Vector3(-2.4, 0, -4.5), 1.4)
	# Вентиляция с глазами
	_mesh(self, _boxm(Vector3(0.9, 0.5, 0.06)), mats["black"], Vector3(2.6, 2.75, -4.98))
	for i in 4:
		_mesh(self, _boxm(Vector3(0.9, 0.04, 0.08)), mats["metal"], Vector3(2.6, 2.58 + i * 0.1, -4.94))
	vent_eyes = Node3D.new()
	vent_eyes.position = Vector3(2.6, 2.75, -4.93)
	add_child(vent_eyes)
	_mesh(vent_eyes, _boxm(Vector3(0.07, 0.05, 0.02)), mats["mon_iris"], Vector3(-0.12, 0, 0))
	_mesh(vent_eyes, _boxm(Vector3(0.07, 0.05, 0.02)), mats["mon_iris"], Vector3(0.12, 0, 0))
	vent_eyes.visible = false
	# Аварийная красная лампа
	_mesh(self, LowPoly.sphere(Vector3(0.1, 0.1, 0.1), 5, 3), mats["red_lamp"], Vector3(5.95, 2.6, -3.6))
	red_light = OmniLight3D.new()
	red_light.position = Vector3(5.6, 2.5, -3.6)
	red_light.light_color = Color(0.95, 0.3, 0.14)
	red_light.light_energy = 0.2
	red_light.omni_range = 4.5
	add_child(red_light)
	# Вентиль на трубе, трещины, кровавые следы, ржавая решётка
	_mesh(self, LowPoly.frustum(8, 0.14, 0.14, 0.03), mats["exit_glow"], Vector3(-5.95, 1.9, -2.5), Vector3(0, 0, 90))
	for c in [Vector3(-4.5, 1.8, -4.99), Vector3(3.6, 1.2, -4.99)]:
		_mesh(self, _boxm(Vector3(0.03, 0.9, 0.02)), mats["black"], c, Vector3(0, 0, 15))
	for p in [Vector3(3.0, 0.009, 1.6), Vector3(2.7, 0.009, 2.1), Vector3(2.2, 0.009, 2.5), Vector3(1.4, 0.009, 2.9), Vector3(0.6, 0.009, 3.2)]:
		_mesh(self, _boxm(Vector3(0.28, 0.01, 0.2)), mats["blood"], p, Vector3(0, randf_range(0, 90), 0))
	_mesh(self, _boxm(Vector3(0.9, 0.012, 0.6)), mats["blood"], Vector3(3.9, 0.009, 0.3), Vector3(0, 30, 0))
	_mesh(self, _boxm(Vector3(1.0, 0.02, 1.0)), mats["black"], Vector3(-3.0, 0.012, 3.3))
	for i in 5:
		_mesh(self, _boxm(Vector3(0.9, 0.025, 0.04)), mats["rust"], Vector3(-3.0, 0.026, 3.0 + i * 0.15))
	# Стопка коробок
	var bx := _solid("Boxes", Vector3(5.4, 0.3, 3.6), Vector3(0.9, 0.6, 0.9), mats["wood_light"])
	_mesh(bx, _boxm(Vector3(0.7, 0.5, 0.7)), mats["wood"], Vector3(0, 0.55, 0), Vector3(0, 22, 0))
	# Лестница-стремянка у стены
	for x in [-0.15, 0.15]:
		_mesh(self, _boxm(Vector3(0.04, 1.8, 0.04)), mats["wood"], Vector3(-5.0 + x, 0.9, -3.2), Vector3(-10, 0, 0))
	for i in 5:
		_mesh(self, _boxm(Vector3(0.34, 0.03, 0.03)), mats["wood"], Vector3(-5.0, 0.3 + i * 0.35, -3.2 - i * 0.05))

func _build_girl() -> void:
	var pos := Vector3(3.6, 0.0, 0.8)
	var chair := _solid("GirlChair", pos + Vector3(0, 0.45, 0), Vector3(0.7, 0.9, 0.7), mats["wood"], false)
	_mesh(chair, _boxm(Vector3(0.6, 0.07, 0.6)), mats["wood"], Vector3(0, -0.11, 0))
	_mesh(chair, _boxm(Vector3(0.6, 0.6, 0.07)), mats["wood"], Vector3(0, 0.22, -0.28))
	for x in [-0.25, 0.25]:
		for z in [-0.25, 0.25]:
			_mesh(chair, _boxm(Vector3(0.06, 0.34, 0.06)), mats["wood"], Vector3(x, -0.28, z))
	girl = _make_humanoid("cloth_g", "pants_g", "hair_g", true, "girl")
	girl.position = pos + Vector3(0, -0.15, 0.02)
	_add_girl_grime()
	girl.seated = true
	girl.tied = true
	girl.tremble = 1.0
	girl.set_emotion("fear")
	add_child(girl)
	girl_ropes = Node3D.new()
	girl.add_child(girl_ropes)
	_mesh(girl_ropes, _boxm(Vector3(0.46, 0.04, 0.34)), mats["wood_light"], Vector3(0, 0.95, 0))
	_mesh(girl_ropes, _boxm(Vector3(0.46, 0.04, 0.34)), mats["wood_light"], Vector3(0, 0.72, 0))
	_mesh(girl_ropes, _boxm(Vector3(0.04, 0.5, 0.34)), mats["wood_light"], Vector3(0.0, 0.84, 0.0))
	_interactable("girl", pos, 1.8)

## Потёки крови и грязь на коже девушки (по референсу модели).
func _add_girl_grime() -> void:
	var spots := [
		[girl.arm_l, Vector3(-0.01, -0.12, 0.05), Vector3(0.035, 0.16, 0.012)],
		[girl.arm_r, Vector3(0.01, -0.16, 0.05), Vector3(0.03, 0.2, 0.012)],
		[girl.hip_l, Vector3(0.02, -0.12, 0.07), Vector3(0.05, 0.2, 0.012)],
		[girl.hip_r, Vector3(-0.02, -0.18, 0.07), Vector3(0.04, 0.17, 0.012)],
		[girl.knee_l, Vector3(0.0, -0.1, 0.06), Vector3(0.045, 0.15, 0.012)],
		[girl.knee_r, Vector3(0.01, -0.14, 0.06), Vector3(0.035, 0.12, 0.012)],
	]
	for sp in spots:
		var n: Node3D = sp[0]
		if n == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = _boxm(sp[2])
		mi.material_override = mats["blood"]
		mi.position = sp[1]
		n.add_child(mi)

func _make_humanoid(cloth: String, pants: String, hair: String, long_hair: bool, style: String = "man"):
	var h = Humanoid.new()
	h.build({
		"skin": mats["skin_g"] if style == "girl" else mats["skin"],
		"cloth": mats[cloth], "pants": mats[pants], "hair": mats[hair], "black": mats["black"],
		"white": mats["white"], "blood": mats["blood"], "lips": mats["lips"], "tear": mats["tear"],
		"bruise": mats["bruise"], "trim": mats["trim"], "metal": mats["metal_light"], "wood": mats["wood"],
		"rope": mats["wood_light"], "glass": mats["glass"], "banana": mats["banana"], "tape": mats["tape"],
	}, long_hair, style)
	return h

func _build_player() -> void:
	player = PlayerScript.new()
	player.position = Vector3(0.0, 0.05, 2.8)
	add_child(player)
	player.setup(self, _make_imp())
	girl.look_node = player

func _make_imp():
	var im = Imp.new()
	im.build(mats)
	return im

func _build_monster() -> void:
	monster = Monster.new()
	add_child(monster)
	monster.build(mats)
	monster.position = Vector3(0, -50, 0)
	monster.visible = false
	monster.process_mode = Node.PROCESS_MODE_DISABLED

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 52.0
	camera.near = 0.1
	camera.far = 40.0
	camera.rotation_degrees = Vector3(-50, 0, 0)
	camera.position = _camera_target()
	add_child(camera)
	camera.make_current()

func _camera_target() -> Vector3:
	if has_override:
		return cam_focus + CAM_OFFSET * cam_zoom
	var p: Vector3 = player.global_position
	var cx := clampf(p.x, -2.5, 2.5) + (p.x - clampf(p.x, -5.5, 5.5))
	var focus := Vector3(cx, 0.0, clampf(p.z, -2.2, 1.0))
	if action != null:
		return focus + CAM_OFFSET * action.zoom + action.lead
	return focus + CAM_OFFSET

# ------------------------------------------------------------------ UI

func _panel_style(color: Color, border: Color = Color(0.35, 0.32, 0.31)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_border_width_all(2)
	s.border_color = border
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _btn_style(bg: Color, border: Color, shadow: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(2)
	s.border_color = border
	s.border_width_bottom = 4
	s.set_corner_radius_all(2)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.6)
		s.shadow_size = 4
		s.shadow_offset = Vector2(0, 2)
	return s

## kind: normal / danger / small
func _button(text_value: String, min_w: float = 220.0, kind: String = "normal") -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(min_w, 26 if kind == "small" else 32)
	b.add_theme_font_size_override("font_size", 12 if kind == "small" else 14)
	MCStyle.style_button(b, kind == "danger")
	return b

func _label(text_value: String, size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	return l

func _full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	_full_rect(root)
	ui.add_child(root)
	root.theme = _make_theme()

	var vig := ColorRect.new()
	_full_rect(vig)
	var vm := ShaderMaterial.new()
	vm.shader = VIGNETTE
	vig.material = vm
	root.add_child(vig)
	# эффекты боли и сознания (под интерфейсом)
	pain_rect = ColorRect.new()
	_full_rect(pain_rect)
	pain_rect.color = Color(0.55, 0.0, 0.0, 0.0)
	root.add_child(pain_rect)
	dim_rect = ColorRect.new()
	_full_rect(dim_rect)
	dim_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	root.add_child(dim_rect)

	# HUD
	hud_panel = PanelContainer.new()
	hud_panel.position = Vector2(26, 8)
	hud_panel.add_theme_stylebox_override("panel", MCStyle.hud_box())
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_panel)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 3)
	hud_panel.add_child(hv)
	var hud_title := _label("ЗАДАЧА", 9, Color(0.95, 0.75, 0.2))
	MCStyle.style_label(hud_title, Color(0.95, 0.75, 0.2))
	hv.add_child(hud_title)
	hud_title.visible = false
	objective_label = _label("", 11, Color(1.0, 1.0, 0.85))
	MCStyle.style_label(objective_label, Color(1.0, 1.0, 0.85))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(250, 0)
	inventory_label = _label("", 10, Color(0.6, 0.65, 0.7))
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_label.custom_minimum_size = Vector2(300, 0)
	moodle_label = _label("", 10, Color(0.9, 0.45, 0.4))
	MCStyle.style_label(moodle_label, Color(0.9, 0.45, 0.4))
	moodle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	moodle_label.custom_minimum_size = Vector2(250, 0)
	moodle_label.visible = false
	var hp_back := ColorRect.new()
	hp_back.custom_minimum_size = Vector2(150, 8)
	hp_back.color = Color(0.12, 0.02, 0.02)
	hp_fill = ColorRect.new()
	hp_fill.color = Color(0.8, 0.12, 0.1)
	hp_fill.size = Vector2(150, 8)
	hp_back.add_child(hp_fill)
	hv.add_child(objective_label)
	hv.add_child(hp_back)
	hp_back.visible = false
	hv.add_child(moodle_label)
	hv.add_child(inventory_label)
	objective_label.visible = false
	inventory_label.visible = false

	# Панель состояний (moodles) внизу экрана, как в Casualties: Unknown
	moodle_bar = MoodleBar.new()
	moodle_bar.visible = false
	root.add_child(moodle_bar)

	# Рюкзак (3D) и кнопка меню в углу
	_build_pack_widget(root)
	var menu_btn := _button("МЕНЮ", 76, "small")
	menu_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_btn.offset_left = -84
	menu_btn.offset_right = -8
	menu_btn.offset_top = 84
	menu_btn.offset_bottom = 112
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.pressed.connect(_on_back)
	root.add_child(menu_btn)
	hud_btns = pack_widgets.duplicate()
	hud_btns.append(menu_btn)

	# предмет в руках: подпись и кнопки (удобно и на телефоне)
	held_bar = PanelContainer.new()
	held_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	held_bar.offset_left = 10
	held_bar.offset_right = 10
	held_bar.offset_top = -12
	held_bar.offset_bottom = -12
	held_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	held_bar.add_theme_stylebox_override("panel", MCStyle.hud_box())
	held_bar.visible = false
	root.add_child(held_bar)
	var hv2 := VBoxContainer.new()
	hv2.add_theme_constant_override("separation", 4)
	held_bar.add_child(hv2)
	held_label = _label("", 11, Color(0.82, 0.86, 0.84))
	MCStyle.style_label(held_label, Color(0.82, 0.86, 0.84))
	hv2.add_child(held_label)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 4)
	hv2.add_child(hrow)
	var hb1 := _button("ПРИМЕНИТЬ", 86, "small")
	hb1.focus_mode = Control.FOCUS_NONE
	hb1.pressed.connect(_use_held)
	hrow.add_child(hb1)
	var hb2 := _button("БРОСИТЬ", 70, "small")
	hb2.focus_mode = Control.FOCUS_NONE
	hb2.pressed.connect(_throw_held)
	hrow.add_child(hb2)
	var hb3 := _button("УБРАТЬ", 66, "small")
	hb3.focus_mode = Control.FOCUS_NONE
	hb3.pressed.connect(_unequip)
	hrow.add_child(hb3)

	# Подсказка действия и тосты
	prompt_label = _label("", 15, Color(0.95, 0.9, 0.78))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_label.offset_top = -64
	prompt_label.offset_bottom = -40
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 5)
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(prompt_label)
	toast_label = _label("", 17, Color(1.0, 0.82, 0.7))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast_label.offset_top = 76
	toast_label.offset_bottom = 120
	toast_label.offset_left = 60
	toast_label.offset_right = -60
	toast_label.add_theme_color_override("font_outline_color", Color.BLACK)
	toast_label.add_theme_constant_override("outline_size", 6)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.modulate.a = 0.0
	root.add_child(toast_label)

	# Сенсорное управление
	touch = TouchScript.new()
	touch.action_pressed.connect(interact)
	touch.attack_pressed.connect(func(): if action != null: action.attack())
	touch.dodge_pressed.connect(func(): if action != null: action.dodge())
	root.add_child(touch)

	# Вспышки и затемнение
	flash_rect = ColorRect.new()
	_full_rect(flash_rect)
	flash_rect.modulate.a = 0.0
	root.add_child(flash_rect)
	fade_rect = ColorRect.new()
	_full_rect(fade_rect)
	fade_rect.color = Color(0.1, 0.0, 0.0, 1.0)
	fade_rect.modulate.a = 0.0
	root.add_child(fade_rect)
	bars_top = ColorRect.new()
	bars_top.color = Color.BLACK
	bars_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bars_top.offset_bottom = 0.0
	bars_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bars_top)
	bars_bot = ColorRect.new()
	bars_bot.color = Color.BLACK
	bars_bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bars_bot.offset_top = 0.0
	bars_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bars_bot)
	caption_label = _label("", 14, Color(0.95, 0.92, 0.85))
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption_label.offset_top = -26
	caption_label.offset_bottom = -4
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(caption_label)

	# Кнопка «ОТКРЫТЬ» (появляется рядом с тем, что можно открыть)
	open_btn = _button("ОТКРЫТЬ [R]", 112, "small")
	open_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	open_btn.offset_left = -124
	open_btn.offset_right = -12
	open_btn.offset_top = -166
	open_btn.offset_bottom = -138
	open_btn.focus_mode = Control.FOCUS_NONE
	open_btn.pressed.connect(open_action)
	open_btn.visible = false
	root.add_child(open_btn)

	# Главное меню в стиле Minecraft
	menu_panel = Control.new()
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu_panel)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bgm := ShaderMaterial.new()
	bgm.shader = MENU_BG
	bgm.set_shader_parameter("tex", MCStyle.stone_texture())
	bg.material = bgm
	bg.resized.connect(func(): bgm.set_shader_parameter("tiles", bg.size / 32.0))
	bg.visible = false  # запасной каменный фон; основной — 3D-поляна
	menu_panel.add_child(bg)
	menu_panel.add_child(MenuScene.new())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_panel.add_child(center)
	var mb := VBoxContainer.new()
	mb.add_theme_constant_override("separation", 8)
	center.add_child(mb)
	var title_holder := Control.new()
	title_holder.custom_minimum_size = Vector2(400, 84)
	mb.add_child(title_holder)
	title_label = _label("ПОДВАЛ", 52, Color(0.8, 0.8, 0.8))
	MCStyle.style_label(title_label, Color(0.8, 0.8, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_holder.add_child(title_label)
	splash_label = _label(SPLASHES[randi() % SPLASHES.size()], 13, Color(1.0, 1.0, 0.2))
	MCStyle.style_label(splash_label, Color(1.0, 1.0, 0.2))
	splash_label.position = Vector2(250, 56)
	splash_label.rotation_degrees = -14.0
	title_holder.add_child(splash_label)
	splash_label.resized.connect(func(): splash_label.pivot_offset = splash_label.size * 0.5)
	play_btn = _button("ИГРАТЬ", 220)
	play_btn.pressed.connect(_on_play)
	mb.add_child(play_btn)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	mb.add_child(row)
	var sb := _button("НАСТРОЙКИ", 106)
	sb.pressed.connect(_show_settings)
	row.add_child(sb)
	var qb := _button("ВЫХОД", 106)
	qb.pressed.connect(func(): get_tree().quit())
	row.add_child(qb)
	var ver := _label("ПОДВАЛ · PS1 Horror · обновление 15", 10, Color(0.75, 0.75, 0.75))
	MCStyle.style_label(ver, Color(0.75, 0.75, 0.75))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.offset_left = 8
	ver.offset_top = -20
	ver.offset_bottom = -4
	ver.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu_panel.add_child(ver)
	var warn := _label("18+ · жестокие сцены", 10, Color(0.9, 0.35, 0.35))
	MCStyle.style_label(warn, Color(0.9, 0.35, 0.35))
	warn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	warn.offset_left = -190
	warn.offset_right = -8
	warn.offset_top = -20
	warn.offset_bottom = -4
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	warn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu_panel.add_child(warn)

	_build_settings(root)

	# Диалог
	dialog_panel = PanelContainer.new()
	dialog_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_left = 24
	dialog_panel.offset_right = -24
	dialog_panel.offset_bottom = -10
	dialog_panel.offset_top = -20
	dialog_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialog_panel.add_theme_stylebox_override("panel", _dialog_style())
	root.add_child(dialog_panel)
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 12)
	dialog_panel.add_child(dh)
	# окно с камерой девушки (живой 3D-вид лица)
	portrait = Portrait.new()
	dh.add_child(portrait)
	portrait.setup(self)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 8)
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dh.add_child(dv)
	dialog_label = _label("", 14, Color(0.86, 0.88, 0.86))
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv.add_child(dialog_label)
	dialog_buttons = HFlowContainer.new()
	dialog_buttons.alignment = FlowContainer.ALIGNMENT_CENTER
	dialog_buttons.add_theme_constant_override("h_separation", 8)
	dialog_buttons.add_theme_constant_override("v_separation", 6)
	dv.add_child(dialog_buttons)
	dialog_panel.visible = false

	# рюкзак: сетка ячеек, вращающийся предмет, действия
	inv_panel = InvPanel.new()
	root.add_child(inv_panel)
	inv_panel.setup(self)
	inv_panel.use_pressed.connect(_on_inv_use)
	inv_panel.equip_pressed.connect(_on_inv_equip)
	inv_panel.drop_pressed.connect(_on_inv_throw)

# ------------------------------------------------------------------ dialogs / menu

func _dialog_style() -> StyleBox:
	var st := MCStyle.grunge_panel()
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	return st

var _bars_on: bool = false

func _is_danger(t: String) -> bool:
	for w in ["УДАР", "ВЫСТРЕЛ", "УБИТЬ", "ВОДУ", "ВКОЛОТЬ", "НА ДЕВУШКЕ", "НА МОНСТРЕ", "ЗАРЯДИТЬ", "ЗАЖАТЬ"]:
		if t.find(w) != -1:
			return true
	return false

## options: массив пар [текст кнопки, Callable или Callable() для простого закрытия]
func _dialog(text_value: String, options: Array = []) -> void:
	if options.is_empty():
		options = [["ПРОДОЛЖИТЬ", Callable()]]
	dialog_label.text = text_value
	dialog_label.visible_ratio = 0.0
	dialog_panel.visible = true
	talk_cam = _next_portrait
	if talk_cam:
		_face_each_other()
		portrait.present(girl)
	else:
		portrait.dismiss()
	_next_portrait = false
	dialog_panel.modulate.a = 0.0
	create_tween().tween_property(dialog_panel, "modulate:a", 1.0, 0.18)
	for c in dialog_buttons.get_children():
		dialog_buttons.remove_child(c)
		c.queue_free()
	var first: Button = null
	for opt in options:
		var cb: Callable = opt[1]
		var label_text := str(opt[0])
		var b := _button(label_text, 120.0, "danger" if _is_danger(label_text) else "normal")
		b.pressed.connect(func():
			_close_dialog()
			if cb.is_valid():
				cb.call())
		dialog_buttons.add_child(b)
		if first == null:
			first = b
	if first != null:
		first.grab_focus()
	if _dialog_tween != null:
		_dialog_tween.kill()
	_dialog_tween = create_tween()
	_dialog_tween.tween_property(dialog_label, "visible_ratio", 1.0, clampf(text_value.length() * 0.014, 0.2, 1.4))

func _close_dialog() -> void:
	dialog_panel.visible = false
	talk_cam = false
	portrait.dismiss()
	if _bars_on:
		_bars_on = false
		_bars(false)

func _girl_emotion() -> String:
	if girl_dead:
		return "dead"
	if girl_asleep:
		return "asleep"
	return str(girl.emotion)

## Диалог с портретом девушки (эмоция берётся из её текущего состояния).
func _gdialog(text_value: String, options: Array = []) -> void:
	_next_portrait = true
	_dialog(text_value, options)

var _menu_sound_done: bool = false

func _show_menu() -> void:
	menu_panel.visible = true
	if not _menu_sound_done:
		_menu_sound_done = true
		_sfx("power_on", -3.0)
	play_btn.text = "ПРОДОЛЖИТЬ" if game_started else "ИГРАТЬ"

func _on_play() -> void:
	game_started = true
	menu_panel.visible = false
	if not _intro_done:
		_intro_done = true
		_intro()

func _show_help() -> void:
	_dialog("WASD — ходьба. E — действие. Рюкзак — значок в углу.\nПредметы работают на цель рядом.", [["ПОНЯТНО", Callable()]])

func _show_settings() -> void:
	_refresh_settings()
	settings_panel.visible = true

func _toggle_touch() -> void:
	touch_enabled = not touch_enabled
	_show_settings()

func _toggle_snap() -> void:
	PS1Mat.set_snap(0.0 if PS1Mat.snap > 0.5 else 1.0)
	_show_settings()

func _toggle_shadows() -> void:
	shadows_on = not shadows_on
	_apply_shadows()
	_show_settings()

func _apply_shadows() -> void:
	lamp.shadow_enabled = shadows_on
	key_light.shadow_enabled = shadows_on

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()

func _unhandled_input(event: InputEvent) -> void:
	if in_cutscene and (event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel")):
		cut_skip = true
		return
	if action != null and action.on_input(event):
		return
	if event.is_action_pressed("ui_cancel"):
		_on_back()
	elif event.is_action_pressed("interact"):
		if dialog_panel.visible and dialog_buttons.get_child_count() == 1:
			(dialog_buttons.get_child(0) as Button).pressed.emit()
		else:
			interact()
	elif event.is_action_pressed("inventory"):
		if inv_panel.visible:
			inv_panel.close()
		else:
			_open_items()
	elif event.is_action_pressed("open"):
		open_action()
	elif event.is_action_pressed("use_held"):
		_use_held()
	elif event.is_action_pressed("throw_held"):
		_throw_held()
	elif event.is_action_pressed("holster"):
		_unequip()
	elif event.is_action_pressed("wounds"):
		if dialog_panel.visible:
			_close_dialog()
		else:
			_wound_menu()

func _on_back() -> void:
	if ended or busy:
		return
	if settings_panel.visible:
		settings_panel.visible = false
		return
	if inv_panel.visible:
		inv_panel.close()
		return
	if dialog_panel.visible:
		_close_dialog()
	elif menu_panel.visible:
		if game_started:
			menu_panel.visible = false
	elif game_started:
		_show_menu()

func input_locked() -> bool:
	return (not game_started) or menu_panel.visible or dialog_panel.visible or settings_panel.visible or inv_panel.visible or ended or busy

func touch_vector() -> Vector2:
	return touch.vec if touch != null else Vector2.ZERO

# ------------------------------------------------------------------ effects

func _flash(col: Color, dur: float = 0.6) -> void:
	flash_rect.color = col
	flash_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(flash_rect, "modulate:a", 0.0, dur)

func _toast(t: String, secs: float = 2.5) -> void:
	toast_label.text = t
	toast_label.modulate.a = 1.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(secs)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)

func _spat(t: float, c: Node3D, start: Vector3, vel: Vector3) -> void:
	c.position = Vector3(start.x + vel.x * t, maxf(0.015, start.y + vel.y * t - 4.9 * t * t), start.z + vel.z * t)

func _spatter(pos: Vector3, count: int = 10) -> void:
	blood.spatter(pos, count)
	_stain_girl_near(pos, float(count) / 16.0)

## Кровь рядом с девушкой пачкает её одежду.
func _stain_girl_near(pos: Vector3, amount: float) -> void:
	if girl == null:
		return
	var d: float = Vector2(pos.x - girl.global_position.x, pos.z - girl.global_position.z).length()
	if d < 1.3:
		girl.add_wear(0.03 * amount, clampf(0.35 * amount * (1.3 - d), 0.0, 0.5))

## Одежда девушки изнашивается: пока она связана и вырывается, при ходьбе по подвалу.
func _update_clothes(delta: float) -> void:
	if not game_started or menu_panel.visible or ended or girl == null or girl_dead:
		return
	_wear_t += delta
	if _wear_t < 10.0:
		return
	_wear_t = 0.0
	var w := 0.0
	if girl.tied or girl.cuffed or girl.taped:
		w += 0.006 * (1.0 + girl.tremble)
	if girl.move_amount > 0.1:
		w += 0.004
	if w > 0.0:
		girl.add_wear(w)

func _blood_pool(pos: Vector3, r: float) -> void:
	blood.pool(pos, r, 5.0)

## Жёсткая сцена: красная вспышка, тряска, пауза, потом текст.
func _scene(text_value: String, options: Array = [], col: Color = Color(0.3, 0.02, 0.03, 0.5), delay: float = 0.9) -> void:
	busy = true
	_flash(col, 1.0)
	shake = 0.7
	await get_tree().create_timer(delay).timeout
	busy = false
	_dialog(text_value, options)

## Нож как инструмент: достать -> взмах (разрезать) -> убрать. done вызывается в момент разреза.
func _knife_cut(done: Callable = Callable()) -> void:
	_hold_token += 1
	var tk := _hold_token
	var m = player.model
	m.show_held("knife")
	m.swing = 0.0
	var tw := create_tween()
	tw.tween_property(m, "aim", 1.0, 0.25)
	tw.tween_interval(0.1)
	tw.tween_property(m, "swing", 0.8, 0.12)
	tw.tween_callback(func():
		shake = 0.1
		if done.is_valid():
			done.call())
	tw.tween_property(m, "swing", -0.25, 0.1)
	tw.tween_property(m, "swing", 0.0, 0.1)
	tw.tween_interval(0.3)
	tw.tween_property(m, "aim", 0.0, 0.3)
	tw.tween_callback(func():
		if tk == _hold_token:
			m.show_held(held_item))

func _hold(id: String, secs: float = 1.2) -> void:
	_hold_token += 1
	var token := _hold_token
	player.model.show_held(id)
	player.model.aim = 1.0 if (id == "pistol" or id == "knife" or id == "crowbar") else 0.5
	await get_tree().create_timer(secs).timeout
	if token == _hold_token:
		_restore_held()

func _hurt_player(amount: int, cause: String) -> void:
	if ended:
		return
	# рывок-перекат даёт короткую неуязвимость к когтям и зубам
	if action != null and action.invuln > 0.0 and cause in ["monster", "rat"]:
		_toast("Увернулся.", 0.9)
		return
	# урон уходит в случайную конечность: рана, кровотечение, перелом (как в CU)
	var limb_id: String = ["torso_up", "torso_down", "arm_l", "arm_r", "leg_l", "leg_r"].pick_random()
	var dtype := "cut" if cause in ["monster", "knife", "trap", "rat"] else "blunt"
	pdmg.damage(limb_id, float(amount), dtype)
	_flash(Color(0.75, 0.0, 0.0, 0.6), 0.5)
	shake = 0.7
	_spatter(player.global_position + Vector3(0, 0.9, 0), 8)
	if pdmg.dead:
		hp = 0
		_die(pdmg.death_cause)
		return
	_hero_emote("hurt", 1.0)
	_toast("РАНА: %s   КРОВЬ: %.1f л" % [BodyDamage.LIMB_NAMES[limb_id], pdmg.blood_volume], 1.6)
	monster_stun = maxf(monster_stun, 0.9)
	if monster_on and not monster_dead:
		var away: Vector3 = player.global_position - monster.global_position
		away.y = 0.0
		if away.length() > 0.01:
			var np: Vector3 = player.global_position + away.normalized() * 1.0
			np.x = clampf(np.x, -5.5, 5.5)
			np.z = clampf(np.z, -4.4, 4.6)
			player.global_position = np

const DEATH_TEXT := {
	"monster": "Когти. Два немигающих глаза. Темнота.",
	"rat": "Мелкие зубы. Писк. Ты так и не встал.",
	"knife": "Рука дрогнула. Нож оказался у него.",
	"misfire": "Щелчок. Осечка.",
	"poison_self": "Горечь на языке. Банан был не для тебя.",
	"sedative": "Сон. Дыхание над ухом.",
	"self_pistol": "Один выстрел. Потом тишина.",
	"self_knife": "Тёплое льётся за воротник. Стало очень тихо.",
	"bloodloss": "Ватные ноги. Тёплая лужа. Сердце стучит всё тише.",
	"heart": "Сердце сбивается, ловит пустоту и молчит.",
	"sepsis": "Жар. Лихорадка. Тьма.",
	"trauma": "Тело не выдержало.",
	"head": "Мир померк.",
}

func _die(cause: String) -> void:
	if ended or _fainting:
		return
	if cause in ["poison_self", "sedative"]:
		_faint()
		return
	ended = true
	_dying = true
	_downed = 0.0
	var m = player.model
	var violent: bool = cause in ["monster", "knife", "misfire", "trauma", "head"]
	if violent:
		_flash(Color(0.8, 0.0, 0.0, 0.8), 1.0)
		shake = 0.9
		_spatter(player.global_position + Vector3(0, 0.9, 0), 10)
	else:
		_flash(Color(0.25, 0.0, 0.0, 0.45), 1.4)
		shake = 0.2
	m.set_emotion("hurt")
	m.show_held("")
	m.aim = 0.0
	m.tremor = 0.0
	m.dead_eyes = false
	m.collapse_side = -1.0 if randf() < 0.5 else 1.0
	m.collapse = maxf(m.collapse, 0.0)
	# камера медленно подъезжает к телу
	cam_focus = player.global_position
	has_override = true
	var cz := create_tween()
	cz.tween_property(self, "cam_zoom", 0.62, 3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 1) удар / пошатывание, 2) пытается устоять, 3) колени подгибаются,
	# 4) на коленях, 5) заваливается ничком, 6) короткий отскок, глаза закрываются
	var tw := create_tween()
	tw.tween_property(m, "collapse", 0.2, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "collapse", 0.1, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(m, "collapse", 0.5, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_sfx("thump", -9.0)
		shake = maxf(shake, 0.2))
	tw.tween_interval(0.55)
	tw.tween_property(m, "collapse", 1.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_sfx("thump", -2.0)
		shake = maxf(shake, 0.45))
	tw.tween_property(m, "collapse", 0.94, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "collapse", 1.0, 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): m.dead_eyes = true)
	if violent or pdmg.total_bleed() > 0.05 or cause == "bloodloss":
		tw.tween_callback(func(): _blood_pool(player.global_position + _facing_vec() * 0.45, 0.6))
	# сердце замедляется и затихает, экран гаснет
	_death_heartbeats()
	var tf := create_tween().set_parallel(true)
	tf.tween_property(pain_rect, "color:a", 0.0, 1.5)
	tf.tween_property(dim_rect, "color:a", 0.55, 2.4).set_delay(1.0)
	tf.tween_property(fade_rect, "modulate:a", 0.85, 2.0).set_delay(2.4)
	await get_tree().create_timer(3.6).timeout
	_dialog("ТЫ МЁРТВ\n" + DEATH_TEXT.get(cause, DEATH_TEXT["monster"]), [["ЗАНОВО", _restart]])

## Последние удары сердца: всё реже и тише.
func _death_heartbeats() -> void:
	var gaps := [0.55, 0.75, 1.0, 1.4]
	var vol := -4.0
	for g in gaps:
		_sfx("heartbeat", vol)
		vol -= 4.0
		await get_tree().create_timer(g).timeout

## Боль > 99 сбивает с ног (CU: ragdoll от боли). Через пару секунд встаёт.
func _on_pain_collapse() -> void:
	if ended or _fainting or busy or in_cutscene:
		return
	_downed = 2.8
	_toast("Боль сбивает с ног.", 1.8)
	shake = maxf(shake, 0.5)
	var m = player.model
	m.collapse_side = -1.0 if randf() < 0.5 else 1.0
	var tw := create_tween()
	tw.tween_property(m, "collapse", 0.5, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _sfx("thump", -6.0))
	tw.tween_property(m, "collapse", 0.78, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(1.5)
	tw.tween_property(m, "collapse", 0.45, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(m, "collapse", 0.0, 0.5).set_trans(Tween.TRANS_SINE)

## Красная пульсация в такт сердцу от боли, затемнение при падении сознания.
func _update_pain_fx(_delta: float) -> void:
	if pain_rect == null or _dying:
		return
	var tp := pdmg.total_pain()
	var ph := fmod(_clock * maxf(pdmg.heart_rate, 30.0) / 60.0, 1.0)
	var beat := exp(-ph * 6.0)
	pain_rect.color.a = clampf((tp - 25.0) / 110.0, 0.0, 0.55) * (0.3 + 0.35 * beat)
	var dim := clampf((0.85 - pdmg.consciousness) * 0.9, 0.0, 0.7)
	dim_rect.color.a = dim * (0.85 + 0.15 * sin(_clock * 1.3))

## Панель состояний внизу по центру; сдвигается, чтобы не наезжать на панель предмета.
func _update_moodle_bar(playing: bool) -> void:
	if moodle_bar == null:
		return
	var show: bool = playing and not ended and not inv_panel.visible and not settings_panel.visible and not in_cutscene and not dialog_panel.visible
	var list: Array = pdmg.moodle_list() if show else []
	moodle_bar.set_items(list)
	moodle_bar.visible = show and not list.is_empty()
	if not moodle_bar.visible:
		return
	var vs: Vector2 = (moodle_bar.get_parent() as Control).size
	var w: float = moodle_bar.size.x
	var x := (vs.x - w) * 0.5
	if held_bar.visible:
		x = maxf(x, held_bar.position.x + held_bar.size.x + 8.0)
	moodle_bar.position = Vector2(round(x), round(vs.y - MoodleBar.CELL - 6.0))

# ------------------------------------------------------------------ per-frame

func _process(delta: float) -> void:
	_clock += delta
	if action != null:
		action.tick(delta)
	_update_camera(delta)
	_update_swingers(delta)
	_update_lamp(delta)
	_update_ambience(delta)
	_update_damage(delta)
	_update_girl(delta)
	_update_clothes(delta)
	_update_projectiles(delta)
	_atk_cd = maxf(0.0, _atk_cd - delta)
	if not shake_on:
		shake = 0.0
	if title_label != null and menu_panel.visible:
		var j := 1.5 if randf() < 0.06 else 0.0
		title_label.position.x = randf_range(-j, j)
		title_label.modulate = Color(1, 1, 1, 0.92 + 0.08 * sin(_clock * 3.0))
		if splash_label != null:
			splash_label.scale = Vector2.ONE * (1.0 + 0.07 * sin(_clock * 6.0))
	var speaking: bool = dialog_panel.visible and talk_cam and not girl_dead and not girl_asleep
	girl.talking = speaking
	var locked := input_locked()
	touch.set_active(touch_enabled and not locked)
	var playing := game_started and not menu_panel.visible
	hud_panel.visible = playing
	for b in hud_btns:
		(b as Control).visible = playing and not dialog_panel.visible and not inv_panel.visible and not ended
	if held_item != "" and not _has(held_item):
		_unequip()
	held_bar.visible = playing and held_item != "" and not locked and not in_cutscene
	if held_bar.visible:
		var ht: String = "В РУКАХ: " + str(ITEM_NAMES.get(held_item, held_item)).to_upper()
		if held_item == "pistol":
			ht += "   ПАТРОНЫ: %d" % ammo
		if not touch_enabled:
			ht += "   [ПРОБЕЛ] применить  [G] бросить  [X] убрать"
		held_label.text = ht
	if hud_panel.visible:
		inventory_label.text = _inventory()
		hp_fill.size.x = 150.0 * clampf(pdmg.blood_volume / pdmg.max_blood, 0.0, 1.0)
		moodle_label.visible = false
	_update_moodle_bar(playing)
	if locked:
		near_target = {}
		prompt_label.text = ""
		open_btn.visible = false
		return
	near_target = _find_target()
	open_btn.visible = (not near_target.is_empty()) and _can_open(str(near_target["id"]))
	touch.highlight = not near_target.is_empty()
	if near_target.is_empty():
		prompt_label.text = ""
	else:
		var prefix := "" if touch_enabled else "[E] "
		prompt_label.text = prefix + _label_for(near_target["id"])
		if _can_open(str(near_target["id"])) and not touch_enabled:
			prompt_label.text += "    [R] ОТКРЫТЬ"

## Система повреждений (Body/Limb из Casualties: Unknown): тик симуляции,
## лужа растёт под кровоточащим игроком, сердце стучит при кровопотере.
func _update_damage(delta: float) -> void:
	if not game_started or menu_panel.visible or ended:
		if not _dying and pain_rect != null:
			pain_rect.color.a = 0.0
			dim_rect.color.a = 0.0
		return
	pdmg.tick(delta)
	if player != null:
		player.speed_mult = pdmg.walk_mult()
		_downed = maxf(0.0, _downed - delta)
		if _downed > 0.0:
			player.speed_mult = 0.0
		# дрожь рук от боли (CU: hand shake)
		player.model.tremor = pdmg.hand_shake()
	_update_pain_fx(delta)
	var tb := pdmg.total_bleed()
	if tb > 0.02:
		_bleed_vis_t += delta
		if _bleed_vis_t > 2.5:
			_bleed_vis_t = 0.0
			blood.pool(player.global_position, 0.1 + tb * 0.4, 6.0)
			_sfx("drip", -9.0)
	var frac := pdmg.blood_volume / pdmg.max_blood
	if frac < 0.8 and not pdmg.dead:
		_last_heart_vol -= delta
		if _last_heart_vol <= 0.0:
			_last_heart_vol = 0.7 + frac
			_sfx("heartbeat", lerpf(-16.0, -5.0, 1.0 - frac))

func _on_pdmg_death(cause: String) -> void:
	if ended or _fainting:
		return
	_die(cause)

func _on_pdmg_faint() -> void:
	if ended or _fainting:
		return
	_faint()

func _update_lamp(delta: float) -> void:
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = randf_range(2.5, 8.0)
		_blackout = randf_range(0.06, 0.4) if randf() < 0.55 else 0.0
	if _blackout > 0.0:
		_blackout -= delta
		lamp.light_energy = LAMP_ENERGY * randf_range(0.0, 0.2)
	else:
		lamp.light_energy = LAMP_ENERGY * (0.95 + 0.05 * sin(Time.get_ticks_msec() * 0.013))

func _update_ambience(_delta: float) -> void:
	_update_creaks(_delta)
	tv_light.light_energy = 0.35 + randf() * 0.35
	red_light.light_energy = 0.12 + 0.1 * sin(_clock * 3.0)
	pack_node.rotation.y = sin(_clock * 0.9) * 0.7
	sack.rotation.z = sin(_clock * 0.8) * 0.06
	sack.rotation.x = sin(_clock * 0.6 + 1.0) * 0.05
	vent_eyes.visible = (not monster_on) and sin(_clock * 0.55) > 0.93

func _update_girl(delta: float) -> void:
	if not girl_freed or not girl_following or ended or girl_dead or girl_asleep or busy:
		return
	var to: Vector3 = player.global_position - girl.position
	to.y = 0.0
	if to.length() > 1.5:
		var d := to.normalized()
		girl.position += d * (1.4 if (girl_cuffed or girl_taped) else 2.3) * delta
		girl.position.x = clampf(girl.position.x, -11.5, 11.5)
		girl.position.z = clampf(girl.position.z, -4.4, 4.6)
		girl.rotation.y = lerp_angle(girl.rotation.y, atan2(d.x, d.z), clampf(10.0 * delta, 0.0, 1.0))
		girl.move_amount = 1.0
	else:
		girl.move_amount = 0.0

func _build_rats() -> void:
	for p in [Vector3(-4.0, 0, -4.4), Vector3(3.5, 0, -4.5), Vector3(1.0, 0, 4.4)]:
		var r := Rat.new()
		add_child(r)
		r.build()
		r.position = p
		r.rotation.y = randf() * TAU
		r.set("_target", p)
		rats.append(r)

func _update_rats(delta: float) -> void:
	var frozen: bool = ended or not game_started or dialog_panel.visible or menu_panel.visible or busy
	var safe: bool = action != null and action.is_safe()
	for r in rats:
		if r.step(player.global_position, delta, frozen) and not safe:
			_sfx("squeak", -6.0)
			_hurt_player(6, "rat")
			if ended:
				return

## Разозлить крыс рядом с точкой (сородича ударили).
func _provoke_rats(at: Vector3, radius: float) -> void:
	for r in rats:
		if not r.dead and r.position.distance_to(Vector3(at.x, 0, at.z)) < radius:
			r.provoke()

func _hit_rat(r, dmg: int, dir: Vector3, force: float) -> void:
	_sfx("squeak", -4.0)
	blood.spatter(r.global_position + Vector3(0, 0.15, 0), 3, dir, 0.4)
	_provoke_rats(r.global_position, 3.0)
	if r.hit(dmg, dir, force):
		_toast("Крыса затихает.", 1.6)
	else:
		_toast("Крыса визжит и бросается на тебя.", 1.8)

func _physics_process(delta: float) -> void:
	_update_rats(delta)
	if not monster_on or monster_dead or ended or not game_started:
		return
	if dialog_panel.visible or menu_panel.visible or busy:
		monster.step(monster.global_position, 0.0, delta)
		return
	monster_stun = maxf(0.0, monster_stun - delta)
	monster_cd = maxf(0.0, monster_cd - delta)
	monster.stunned = monster_stun > 0.0
	var speed := 1.5
	if girl_dead:
		speed += 0.4
	if monster_hp <= 2:
		speed += 0.4
	var safe: bool = action != null and action.is_safe()
	var mtarget: Vector3 = player.global_position
	if safe:
		# герой спрятался: тварь кружит рядом, но не находит
		mtarget = player.global_position + Vector3(cos(_clock * 0.4), 0, sin(_clock * 0.4)) * 2.8
		speed *= 0.6
	monster.step(mtarget, speed, delta)
	for t in traps.duplicate():
		var tp: Vector3 = t["pos"]
		if monster.global_position.distance_to(tp) < 0.75:
			_trigger_trap(t)
			if monster_dead:
				return
	var d := Vector2(player.global_position.x - monster.global_position.x, player.global_position.z - monster.global_position.z).length()
	if d < 0.95 and monster_stun <= 0.0 and monster_cd <= 0.0 and not safe:
		monster_cd = 1.8
		_hurt_player(50, "monster")

func _find_target() -> Dictionary:
	if action != null and action.hiding != "":
		return {"id": "hide", "pos": player.global_position, "reach": 9.0}
	var best := {}
	var best_d := 99.0
	var p: Vector3 = player.global_position
	for it in interactables:
		var ip: Vector3 = it["pos"]
		if it["id"] == "girl":
			ip = Vector3(girl.position.x, 0.0, girl.position.z)
		var d := Vector2(p.x - ip.x, p.z - ip.z).length()
		if d < float(it["reach"]) and d < best_d:
			best_d = d
			best = it
	return best

func _label_for(id: String) -> String:
	if id.begins_with("thrown_"):
		if thrown.has(id):
			return "ПОДОБРАТЬ: " + _item_title(str((thrown[id] as Dictionary)["id"])).to_upper()
		return "ПОДОБРАТЬ"
	match id:
		"girl":
			if girl_dead:
				return "ТЕЛО"
			return "ДЕВУШКА"
		"door":
			return "ДВЕРЬ"
		"hide":
			return "УКРЫТИЕ"
		"cage":
			return "КЛЕТКА"
		"kennel":
			return "КОНУРА"
		"cabinet":
			return "ОТКРЫТЬ" if not cabinet_open else "ОСМОТРЕТЬ"
		"tv":
			return "ВКЛЮЧИТЬ"
		"bed":
			return "ОСМОТРЕТЬ КРОВАТЬ"
		"fridge":
			return "ОТКРЫТЬ ХОЛОДИЛЬНИК"
		"bench":
			return "ОСМОТРЕТЬ ВЕРСТАК"
		_:
			return "ОСМОТРЕТЬ"

func _objective() -> String:
	if monster_on and not monster_dead:
		return "ЦЕЛЬ: ВЫЖИТЬ. Оно охотится на тебя"
	if girl_dead:
		return "ЦЕЛЬ: выбраться из подвала"
	if girl_freed:
		return "ЦЕЛЬ: выйди через дверь вместе с ней"
	if _has("key"):
		return "ЦЕЛЬ: развяжи девушку или иди к двери"
	if girl_talked:
		return "ЦЕЛЬ: найди ключ (ящик у полки)"
	return "ЦЕЛЬ: осмотри подвал, поговори с девушкой"

func _item_title(id: String) -> String:
	var base: String = str(ITEM_NAMES.get(id, id)).to_upper()
	match id:
		"pistol":
			return "%s (%d)" % [base, ammo]
		"banana":
			return base + (" (ОТРАВЛЕН)" if poison_banana else "")
		"syringe":
			return base + (" (ЯД)" if poison_syringe else "")
	return base

func _inventory() -> String:
	var items: Array = []
	for id in ITEM_NAMES:
		if _has(id):
			items.append(_item_title(id).to_lower())
	return "ПРЕДМЕТЫ: " + (", ".join(items) if not items.is_empty() else "пусто")

func _has(id: String) -> bool:
	return inv.has(id)

# ------------------------------------------------------------------ gameplay: осмотр

func interact() -> void:
	if input_locked() or near_target.is_empty():
		return
	var id := str(near_target["id"])
	if id == "hide":
		action.hide_menu()
		return
	_face_target(near_target)
	match id:
		"girl":
			_talk_girl()
		"door":
			_use_door()
		"tv":
			_use_tv()
		"cage":
			_cage_menu()
		"kennel":
			_dialog("Тесная деревянная конура. Внутри обглоданная кость и клок шерсти. Если пригнуться, влезешь.", [["ЗАЛЕЗТЬ", func(): action.enter("kennel")], ["НАЗАД", Callable()]])
		"shackles":
			_dialog("Кандалы. Ржавые, но целые.", [["НАЗАД", Callable()]])
		"drawing":
			_dialog("Рисунок: огромные глаза, зубы. «ОН ЖИВЁТ ПОД ПОЛОМ».", [["НАЗАД", Callable()]])
		_:
			if id.begins_with("thrown_"):
				_pickup_thrown(id)
			elif loot.has(id):
				_look_container(id)

## Герой поворачивается к тому, с чем взаимодействует.
func _face_target(t: Dictionary) -> void:
	var ip: Vector3 = t.get("pos", player.global_position)
	if str(t.get("id", "")) == "girl":
		ip = girl.position
	var to: Vector3 = ip - player.global_position
	to.y = 0.0
	if to.length() < 0.2:
		return
	var want := atan2(to.x, to.z)
	var tw := create_tween()
	tw.tween_method(func(a: float):
		player.facing = a
		player.model.rotation.y = a, player.facing, player.facing + wrapf(want - player.facing, -PI, PI), 0.15)

func _can_open(id: String) -> bool:
	return id in OPENABLE and (id == "door" or loot.has(id))

## Команда «ОТКРЫТЬ» (клавиша R / кнопка на экране): сразу открывает то, что рядом.
func open_action() -> void:
	if input_locked() or near_target.is_empty():
		return
	var id := str(near_target["id"])
	if not _can_open(id):
		_toast("Тут нечего открывать.", 1.4)
		return
	if id == "door":
		_use_door()
		return
	_open_container(id)

func _look_container(id: String) -> void:
	var c: Dictionary = loot[id]
	var texts: Array = OPEN_TEXT.get(id, ["Что-то здесь есть.", "Ты открываешь."])
	if (c["items"] as Array).is_empty() and not c.get("locked", false):
		if id == "table":
			_dialog(str(c["empty"]) + " Под столом можно спрятаться.", [["ЗАЛЕЗТЬ ПОД СТОЛ", func(): action.enter("table")], ["НАЗАД", Callable()]])
		else:
			_dialog(str(c["empty"]), [["НАЗАД", Callable()]])
	else:
		var opts: Array = [["ОТКРЫТЬ", func(): _open_container(id)]]
		if id == "table":
			opts.append(["ЗАЛЕЗТЬ ПОД СТОЛ", func(): action.enter("table")])
		opts.append(["ОТОЙТИ", Callable()])
		_dialog(str(texts[0]), opts)

func _open_container(id: String) -> void:
	var texts: Array = OPEN_TEXT.get(id, ["", "Ты открываешь."])
	shake = 0.15
	_toast(str(texts[1]), 1.6)
	_open_anim(id)
	_search(id)

func _use_tv() -> void:
	shake = 0.5
	_flash(Color(0.8, 0.95, 1.0, 0.7), 0.4)
	_dialog("Помехи. На миг — лицо с огромными глазами.", [["ЖУТКО", Callable()]])

func _search(id: String) -> void:
	var c: Dictionary = loot[id]
	if c.get("locked", false):
		if _has("lockpick"):
			_dialog("Ржавый замок. Отмычка подойдёт — тихо и без шума.", [["ВСКРЫТЬ ОТМЫЧКОЙ", _open_cabinet], ["ПОТОМ", Callable()]])
		elif _has("crowbar"):
			_dialog("Ржавый замок. Ломик подойдёт.", [["ВЗЛОМАТЬ", _open_cabinet], ["ПОТОМ", Callable()]])
		else:
			_dialog("Заперто. Нужен рычаг или отмычка.", [["ОСТАВИТЬ", Callable()]])
		return
	var items: Array = c["items"]
	if items.is_empty():
		_dialog(str(c["empty"]), [["НАЗАД", Callable()]])
	else:
		var it: String = items.pop_front()
		_give(it)

func _give(id: String) -> void:
	inv[id] = true
	if id == "pistol":
		ammo = 3
		if props.has("pistol"):
			(props["pistol"] as Node3D).visible = false
	if id == "knife" and props.has("knife"):
		(props["knife"] as Node3D).visible = false
	_pickup_label(id)
	_bounce_pack()
	if action != null:
		action.stash_anim()
	_hero_emote("happy", 1.2)
	if id == "key":
		_schedule_monster(7.0)
		if not _key_cut_done:
			_key_cut_done = true
			_key_cutscene()

func _key_cutscene() -> void:
	await get_tree().create_timer(1.3).timeout
	if ended:
		return
	var beats: Array = [
		{"at": "player", "line": "Ключ. Холодный и тяжёлый. Он тот самый.", "secs": 2.4, "zoom": 0.42, "hero": "happy"},
	]
	if _girl_awake():
		beats.append({"at": "girl", "line": "Девушка смотрит на ключ. В её глазах — надежда.", "secs": 2.4, "zoom": 0.55})
	elif girl_dead:
		beats.append({"at": "girl", "line": "Она лежит неподвижно. Больше никто не ждёт этот ключ.", "secs": 2.4, "zoom": 0.55})
	else:
		beats.append({"at": "girl", "line": "Девушка спит. Она не видит ключ.", "secs": 2.2, "zoom": 0.55})
	beats.append({"at": "door", "line": "Дверь совсем рядом.", "secs": 1.8, "zoom": 0.7})
	await _run_cutscene(beats)

func _open_cabinet() -> void:
	if cabinet_open:
		return
	cabinet_open = true
	loot["cabinet"]["locked"] = false
	shake = 0.3
	var tw := create_tween()
	tw.tween_property(props["cab_door"], "rotation_degrees:y", -105.0, 0.5).set_trans(Tween.TRANS_BACK)
	(props["pistol"] as Node3D).visible = not _has("pistol")
	_dialog("Скрежет. Дверца поддаётся.", [["ЗАГЛЯНУТЬ", func(): _search("cabinet")]])

# ------------------------------------------------------------------ gameplay: рюкзак

func _inv_ids() -> Array:
	var ids: Array = []
	for id in USABLE:
		if _has(id):
			ids.append(id)
	return ids

## Рюкзак: открывает панель с ячейками (старый вызов с номером страницы больше не нужен).
func _open_items(_page: int = 0) -> void:
	if input_locked():
		return
	var ids := _inv_ids()
	if ids.is_empty():
		_dialog("Рюкзак пуст.", [["НАЗАД", Callable()]])
		return
	inv_panel.open(ids)

func _on_inv_use(id: String) -> void:
	inv_panel.close()
	_item_targets(id)

func _on_inv_equip(id: String) -> void:
	_equip(id)
	var ids := _inv_ids()
	if ids.is_empty():
		inv_panel.close()
	else:
		inv_panel.refresh(ids)

func _on_inv_throw(id: String) -> void:
	inv_panel.close()
	_throw_item(id)

func _girl_dist() -> float:
	return Vector2(player.global_position.x - girl.position.x, player.global_position.z - girl.position.z).length()

func _monster_dist() -> float:
	if not monster_on or monster_dead:
		return 999.0
	return Vector2(player.global_position.x - monster.global_position.x, player.global_position.z - monster.global_position.z).length()

func _cabinet_near() -> bool:
	return Vector2(player.global_position.x - 4.6, player.global_position.z + 3.7).length() < 2.2

func _item_targets(id: String) -> void:
	if id == "note":
		_dialog("«Ключ в ящике. Свет гаснет сам. Не корми ЕГО после полуночи.»", [["НАЗАД", _open_items]])
		return
	var opts: Array = []
	if _girl_dist() < 2.3 and not girl_dead and not (id in ["crowbar", "canned", "lockpick"]):
		opts.append(["НА ДЕВУШКЕ", func(): _use_on_girl(id)])
	var md := _monster_dist()
	if md < 2.4 or (id == "pistol" and md < 8.0):
		opts.append(["НА МОНСТРЕ", func(): _use_on_monster(id)])
	match id:
		"banana":
			opts.append(["СЪЕСТЬ", _eat_banana])
			opts.append(["БРОСИТЬ НА ПОЛ", func(): _place_trap("banana")])
		"rope":
			opts.append(["НАТЯНУТЬ ЛОВУШКУ", func(): _place_trap("rope")])
		"beartrap":
			opts.append(["ПОСТАВИТЬ КАПКАН", func(): _place_trap("beartrap")])
		"syringe":
			opts.append(["ВКОЛОТЬ СЕБЕ", _syringe_self])
		"poison":
			if _has("banana") and not poison_banana:
				opts.append(["ОТРАВИТЬ БАНАН", _poison_the_banana])
			if _has("syringe") and not poison_syringe:
				opts.append(["ЗАРЯДИТЬ ШПРИЦ", _poison_the_syringe])
		"crowbar":
			if _cabinet_near() and not cabinet_open:
				opts.append(["ВЗЛОМАТЬ ШКАФ", _open_cabinet])
		"knife":
			opts.append(["ДОСТАТЬ И УБРАТЬ", func(): _knife_cut()])
			opts.append(["НА СЕБЯ", func(): _self_confirm("knife")])
		"pistol":
			opts.append(["К ВИСКУ", func(): _self_confirm("pistol")])
		"lockpick":
			if _cabinet_near() and not cabinet_open:
				opts.append(["ВСКРЫТЬ ШКАФ", _open_cabinet])
		"bandage":
			opts.append(["ПЕРЕВЯЗАТЬ РАНЫ", _wound_menu])
		"medkit":
			opts.append(["ЛЕЧИТЬ РАНЫ", _wound_menu])
		"water":
			opts.append(["ВЫПИТЬ", func(): _consume("water", 5, "Холодная чистая вода.")])
		"chocolate":
			opts.append(["СЪЕСТЬ", func(): _consume("chocolate", 10, "Сладко. Почти по-человечески.")])
		"beans":
			opts.append(["СЪЕСТЬ", func(): _consume("beans", 15, "Холодная фасоль. Сойдёт.")])
		"canned":
			if _has("knife") or _has("crowbar"):
				opts.append(["ОТКРЫТЬ БАНКУ", _open_can])
			else:
				opts.append(["ПОПРОБОВАТЬ ОТКРЫТЬ", func(): _toast("Нечем. Нужен нож или ломик.", 2.0)])
		"lighter":
			opts.append(["ЗАЖЕЧЬ", func(): _light_up(15.0)])
		"flashlight":
			opts.append(["ВЫКЛЮЧИТЬ" if flashlight_on else "ВКЛЮЧИТЬ", _toggle_flashlight])
		"sylphy":
			opts.append(["ОБНЯТЬ СИЛЬФИ", _hug_sylphy])
	if opts.is_empty():
		_dialog("Не к чему применить.", [["НАЗАД", _open_items]])
		return
	opts.append(["НАЗАД", _open_items])
	_dialog("%s — что делаем?" % _item_title(id), opts)

## Сцена «на себя». Нож — медленная сцена с лезвием у горла, артериальным фонтаном,
## хрипом и лужей. Пистолет — быстро и в темноту.
func _self_confirm(id: String) -> void:
	var q := "Приставить ствол к виску?" if id == "pistol" else "Приставить нож к горлу?"
	_dialog(q, [["ДА", func(): _self_end(id)], ["НЕТ", _open_items]])

func _self_end(id: String) -> void:
	if ended or busy or _fainting:
		return
	if id == "pistol" and ammo <= 0:
		_sfx("click", -4.0)
		_toast("Щёлк. Патронов нет.", 1.8)
		return
	busy = true
	_hold_token += 1
	var m = player.model
	m.show_held(id)
	m.aim = 0.0
	if id == "pistol":
		await _self_pistol_scene(m)
	else:
		await _self_knife_scene(m)

func _self_pistol_scene(m) -> void:
	create_tween().tween_property(m, "to_head", 1.0, 0.7)
	_toast("Холодный металл. Тишина.", 1.4)
	await get_tree().create_timer(1.5).timeout
	busy = false
	ended = true
	ammo -= 1
	pdmg.damage("head", 200.0, "bullet")
	_sfx("shot", -1.0)
	_flash(Color(1, 1, 1, 0.9), 0.25)
	shake = 1.0
	# выходное отверстие: брызги назад от направления взгляда
	blood.spray(player.global_position + Vector3(0, 1.05, 0), -_facing_vec() + Vector3(0, 0.5, 0), 1.5)
	_spatter(player.global_position + Vector3(0, 1.0, 0), 10)
	blood.pool(player.global_position, 0.6, 5.0, 6, 0.7)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(m, "to_head", 0.0, 0.3)
	tw.tween_property(m, "rotation:x", -PI / 2.0, 0.45)
	tw.tween_property(m, "position:y", 0.14, 0.45)
	create_tween().tween_property(fade_rect, "modulate:a", 1.0, 1.4)
	await get_tree().create_timer(1.8).timeout
	_dialog("ТЫ МЁРТВ\n" + DEATH_TEXT.get("self_pistol", ""), [["ЗАНОВО", _restart]])

func _self_knife_scene(m) -> void:
	# лезвие поднимается к горлу, голова запрокидывается
	create_tween().tween_property(m, "to_throat", 1.0, 1.1)
	_toast("Лезвие упирается в горло. Пульс бьётся о сталь.", 2.0)
	await get_tree().create_timer(2.1).timeout
	# порез
	_sfx("slash", -4.0)
	_sfx("stab", -2.0)
	_flash(Color(0.45, 0.0, 0.0, 0.5), 0.35)
	shake = 0.6
	pdmg.throat_cut()
	# рана на шее модели
	blood.wound(m, Vector3(0, 0.92, 0.17), Vector2(0.1, 0.05), 3.0)
	var neck: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	var dir := _facing_vec()
	# артериальный фонтан пульсами + звук вытекающей крови
	_sfx("bloodflow", -2.0)
	_sfx("gurgle", -3.0)
	for i in 6:
		blood.spray(neck, dir + Vector3(0, 0.8, 0), 1.7)
		_sfx("heartbeat", -8.0)
		await get_tree().create_timer(0.85).timeout
	# хрип, тело оседает
	_sfx("rattle", -4.0)
	_sfx("thump", -1.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(m, "to_throat", 0.0, 0.3)
	tw.tween_property(m, "rotation:x", -PI / 2.0, 0.5)
	tw.tween_property(m, "position:y", 0.14, 0.5)
	# кровь продолжает капать из раны, лужа растёт толчками
	blood.stream(neck, 4.0, 0.3)
	blood.pool(player.global_position, 0.75, 5.0, 8, 0.9)
	create_tween().tween_property(fade_rect, "modulate:a", 1.0, 2.2)
	await get_tree().create_timer(2.6).timeout
	busy = false
	ended = true
	_dialog("ТЫ МЁРТВ\n" + DEATH_TEXT.get("self_knife", ""), [["ЗАНОВО", _restart]])

## Осмотр ран (порт WoundView из Casualties: Unknown): статус тела и лечение по конечностям.
func _wound_menu() -> void:
	if ended or not game_started or menu_panel.visible:
		return
	var opts: Array = []
	var shown := 0
	for id in BodyDamage.LIMB_ORDER:
		if shown >= 5:
			break
		var l = pdmg.limb(id)
		if l == null or l.dismembered:
			continue
		if l.bleed > 0.02 or l.skin < 99 or l.broken or l.dislocated or l.infected:
			var label: String = "%s [%s]" % [l.name, l.condition()]
			opts.append([label, func(): _limb_menu(id)])
			shown += 1
	if shown < 5 and _has("bandage"):
		opts.append(["ПЕРЕВЯЗАТЬ ХУДШУЮ РАНУ", _bandage_worst])
	if _has("medkit"):
		opts.append(["АПТЕЧКА: ЛЕЧИТЬ ВСЁ", _use_medkit_self])
	opts.append(["НАЗАД", Callable()])
	if opts.size() == 1:
		_dialog("Тело цело. Кровь: %.1f/%.1f л. Пульс %d." % [pdmg.blood_volume, pdmg.max_blood, int(pdmg.heart_rate)], [["ОК", Callable()]])
		return
	_dialog(pdmg.report(), opts)

func _limb_menu(id: String) -> void:
	var l = pdmg.limb(id)
	var opts: Array = []
	if l.bleed > 0.02 and not l.tourniquet:
		if _has("bandage"):
			opts.append(["ЗАБИНТОВАТЬ (ОСТАНОВИТЬ КРОВЬ)", func(): _bandage_limb(id)])
		else:
			opts.append(["НУЖЕН БИНТ", Callable()])
	if l.broken and not l.splinted and _has("bandage"):
		opts.append(["ШИНА (ПЛАСТЫРЬ)", func(): _splint_limb(id)])
	if l.infected and _has("medkit"):
		opts.append(["ПРОМЫТЬ АНТИСЕПТИКОМ", func(): _disinfect_limb(id)])
	opts.append(["НАЗАД", _wound_menu])
	_gdialog2("%s\n%s %s\nБоль: %d" % [l.name, l.short(), "[" + l.condition() + "]", int(l.pain)], opts)

## Диалог без портрета девушки (для своих действий).
func _gdialog2(text_value: String, options: Array = []) -> void:
	_dialog(text_value, options)

func _bandage_limb(id: String) -> void:
	if not _has("bandage"):
		_toast("Бинты кончились.", 1.5)
		return
	inv.erase("bandage")
	pdmg.bandage(id)
	_sfx("rip", -6.0)
	var l = pdmg.limb(id)
	_toast("%s перебинтована. Кровь остановлена." % l.name, 2.2)
	_wound_menu()

func _bandage_worst() -> void:
	var worst := ""
	var worst_bleed := 0.0
	for id in BodyDamage.LIMB_ORDER:
		var l = pdmg.limb(id)
		if l != null and l.bleed > worst_bleed:
			worst_bleed = l.bleed
			worst = id
	if worst.is_empty():
		_toast("Ничего не кровит.", 1.5)
		return
	_bandage_limb(worst)

func _splint_limb(id: String) -> void:
	if not _has("bandage"):
		return
	inv.erase("bandage")
	pdmg.splint(id)
	_sfx("rip", -6.0)
	_toast("Шина наложена. Стало легче.", 2.0)
	_wound_menu()

func _disinfect_limb(id: String) -> void:
	if not _has("medkit"):
		return
	var l = pdmg.limb(id)
	l.infected = false
	l.infection = 0.0
	_sfx("click", -8.0)
	_toast("Рана промыта. Инфекция отступает.", 2.0)
	_wound_menu()

func _use_medkit_self() -> void:
	if not _has("medkit"):
		return
	inv.erase("medkit")
	pdmg.heal_all()
	pdmg.painkill(0.6)
	_sfx("click", -8.0)
	_toast("Аптечка. Бинты, антисептик, таблетки от боли.", 2.5)
	_wound_menu()

func _eat_banana() -> void:
	inv.erase("banana")
	if poison_banana:
		poison_banana = false
		_hold("banana", 0.8)
		await get_tree().create_timer(0.6).timeout
		_spatter(player.global_position + Vector3(0, 1.0, 0), 6)
		_die("poison_self")
		return
	hp = mini(100, hp + 15)
	_toast("+15 HP", 1.5)
	_hold("banana", 1.0)

func _syringe_self() -> void:
	_dialog("Вколоть себе неизвестную жидкость?", [["ВКОЛОТЬ", _syringe_self_do], ["НЕТ", _open_items]])

func _syringe_self_do() -> void:
	inv.erase("syringe")
	_hold("syringe", 1.0)
	if poison_syringe:
		poison_syringe = false
		await get_tree().create_timer(0.5).timeout
		_die("poison_self")
		return
	busy = true
	_flash(Color(0, 0, 0, 1.0), 2.5)
	await get_tree().create_timer(1.6).timeout
	busy = false
	if monster_on and not monster_dead:
		_die("sedative")
	else:
		hp = maxi(1, hp - 20)
		_toast("Ты приходишь в себя. Тело ватное. Здоровье: %d. Хорошо, что рядом никого не было." % hp, 4.0)

func _poison_the_banana() -> void:
	inv.erase("poison")
	poison_banana = true
	_hold("poison", 1.0)
	_dialog("Банан отравлен. Самому не есть.", [["ПОНЯТНО", Callable()]])

func _poison_the_syringe() -> void:
	inv.erase("poison")
	poison_syringe = true
	_hold("syringe", 1.0)
	_dialog("Шприц заряжен ядом.", [["ПОНЯТНО", Callable()]])

func _place_trap(kind: String) -> void:
	var face := Vector3(sin(player.facing), 0.0, cos(player.facing))
	var p: Vector3 = player.global_position + face * 0.9
	p.x = clampf(p.x, -11.5, 11.5)
	p.z = clampf(p.z, -4.3, 4.5)
	p.y = 0.03
	var n := Node3D.new()
	n.position = p
	add_child(n)
	var poisoned := false
	if kind == "banana":
		inv.erase("banana")
		poisoned = poison_banana
		_mesh(n, _boxm(Vector3(0.28, 0.04, 0.1)), mats["banana"], Vector3.ZERO, Vector3(0, randf_range(0, 180), 0))
		_mesh(n, _boxm(Vector3(0.12, 0.03, 0.1)), mats["banana"], Vector3(0.1, 0.01, 0.05))
		if poisoned:
			_mesh(n, _boxm(Vector3(0.05, 0.02, 0.05)), mats["mon_iris"], Vector3(0, 0.03, 0))
	elif kind == "beartrap":
		inv.erase("beartrap")
		var bt: Node3D = ItemModels.make("beartrap", mats)
		bt.scale = Vector3.ONE * 2.2
		n.add_child(bt)
	else:
		inv.erase("rope")
		_mesh(n, _boxm(Vector3(1.0, 0.025, 0.04)), mats["wood_light"], Vector3.ZERO, Vector3(0, randf_range(0, 180), 0))
	traps.append({"kind": kind, "pos": p, "node": n, "poison": poisoned})
	if kind == "banana" and poison_banana:
		poison_banana = false
	_toast("Ловушка готова.", 2.0)
	_hold(kind, 0.8)

func _trigger_trap(t: Dictionary) -> void:
	traps.erase(t)
	if is_instance_valid(t["node"]):
		(t["node"] as Node3D).queue_free()
	if t["kind"] == "banana":
		if t["poison"]:
			monster_stun = 99.0
			_toast("Тварь жадно хватает банан и проглатывает его целиком...", 3.0)
			await get_tree().create_timer(2.0).timeout
			_kill_monster("Монстр хрипит, хватается за горло. Из пасти идёт чёрная пена. Громадные глаза выкатываются ещё сильнее, и он замирает. Банан был лучшим подарком.")
		else:
			monster_stun = 4.0
			_toast("Тварь наступила на банан и грохнулась на пол!", 2.5)
			shake = 0.4
	elif t["kind"] == "beartrap":
		monster_stun = 10.0
		_toast("Капкан защёлкнулся!", 2.5)
		shake = 0.5
	else:
		monster_stun = 6.0
		_toast("Тварь запуталась в верёвке и падает!", 2.5)
		shake = 0.4

# ------------------------------------------------------------------ gameplay: девушка

func _talk_girl() -> void:
	if girl_dead:
		_dialog("Она не дышит.", [["ОТОЙТИ", Callable()]])
		return
	if girl_asleep:
		_gdialog("Она спит. Дыхание ровное.", [["РЮКЗАК", _open_items], ["ОТОЙТИ", Callable()]])
		return
	if girl_gagged:
		girl.set_emotion("fear")
		_gdialog("Она мычит сквозь скотч и дёргается. Слов не разобрать.", [["СНЯТЬ СКОТЧ", _ungag_girl], ["РЮКЗАК", _open_items], ["ОТОЙТИ", Callable()]])
		return
	var opts: Array = []
	var txt := ""
	if girl_freed:
		txt = _girl_line()
		opts.append(["ПРИКАЗАТЬ", _order_menu])
		opts.append(["ОДЕЖДА", _outfit_menu])
	elif _has("key") or _has("knife"):
		girl.set_emotion("fear")
		txt = "«Развяжи меня. Пожалуйста.»"
		opts.append(["РАЗВЯЗАТЬ", _free_girl])
	elif girl_talked:
		girl.set_emotion("sad")
		txt = "«Ключ в ящике у полки. Быстрее.»"
	else:
		girl_talked = true
		girl.set_emotion("fear")
		txt = "«Помоги. Ключ в ящике у полки. И... здесь что-то живёт.»"
	_change_trust(2)
	opts.append(["РЮКЗАК", _open_items])
	opts.append(["УЙТИ", Callable()])
	_gdialog(txt, opts)

func _free_girl() -> void:
	if girl_freed or girl_dead:
		return
	girl_freed = true
	girl_ropes.visible = false
	girl.tied = false
	girl.seated = false
	girl.tremble = 0.0
	girl.droop = 0.0
	girl.position = Vector3(3.6, 0.0, 1.7)
	if girl_asleep:
		# спящая не встаёт и не смотрит: она просто остаётся лежать
		girl_following = false
		_lay_down(girl, false)
		await _run_cutscene([
			{"at": "girl", "line": "Верёвки падают на пол. Она не просыпается.", "secs": 2.2, "zoom": 0.5},
		])
		return
	girl_following = true
	_change_trust(20)
	girl.set_emotion("happy")
	await _run_cutscene([
		{"at": "girl", "line": "Верёвки падают на пол.", "secs": 1.8, "zoom": 0.5, "girl": "happy"},
		{"at": "both", "line": "Она свободна. Она смотрит на тебя.", "secs": 2.2, "zoom": 0.7, "hero": "happy"},
	])
	if girl_gagged:
		_gdialog("Она кивает и тянется к скотчу на губах.", [["СНЯТЬ СКОТЧ", _ungag_girl], ["ИДЁМ", Callable()]])
	else:
		_gdialog("«Спасибо.»", [["ИДЁМ", Callable()]])

func _lay_down(h: Node3D, bloody: bool) -> void:
	var gp: Vector3 = h.position
	var target := Vector3(gp.x + 0.8, 0.12, gp.z + 0.6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(h, "position", target, 0.6).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(h, "rotation:z", PI / 2.0, 0.6).set_trans(Tween.TRANS_QUAD)
	if bloody:
		blood.pool(Vector3(target.x - 0.4, 0.0, target.z), 0.9, 7.0)

func _use_on_girl(id: String) -> void:
	if girl_gagged and id in ["banana", "water", "chocolate", "beans", "poison"]:
		_gdialog("Рот заклеен скотчем. Сначала его нужно снять.", [["СНЯТЬ СКОТЧ", _ungag_girl], ["НАЗАД", Callable()]])
		return
	if girl_asleep and id in ["banana", "water", "chocolate", "beans", "poison", "sylphy", "bandage", "medkit", "lighter", "flashlight", "cuffs", "rope"]:
		_gdialog("Она без сознания и никак не отреагирует.", [["НАЗАД", Callable()]])
		return
	if girl_asleep and id in ["knife", "pistol", "syringe"]:
		match id:
			"knife":
				var oa: Array = []
				if not girl_freed:
					oa.append(["ПЕРЕРЕЗАТЬ ВЕРЁВКИ", func(): _knife_cut(_free_girl)])
				oa.append(["УДАРИТЬ НОЖОМ", func(): _kill_girl("knife")])
				oa.append(["УБРАТЬ", Callable()])
				_hold("knife", 1.5)
				_gdialog("Лезвие блестит в тусклом свете. Девушка без сознания и ничего не видит.", oa)
			"pistol":
				if ammo <= 0:
					_gdialog("Щёлк. Магазин пуст. Она не слышит.", [["УБРАТЬ", Callable()]])
				else:
					_hold("pistol", 1.5)
					_gdialog("Ствол у её лица. Девушка без сознания и не знает об этом.", [["ВЫСТРЕЛИТЬ", func(): _kill_girl("pistol")], ["ОПУСТИТЬ", Callable()]])
			"syringe":
				if poison_syringe:
					_hold("syringe", 1.5)
					_gdialog("Игла блестит. Она спит и не почувствует укола.", [["ВКОЛОТЬ ЯД", func(): _kill_girl("poison_syringe")], ["УБРАТЬ", Callable()]])
				else:
					_gdialog("Она уже спит.", [["НАЗАД", Callable()]])
		return
	match id:
		"tape":
			var ot: Array = []
			if girl_gagged:
				ot.append(["СНЯТЬ СКОТЧ СО РТА", _ungag_girl])
			else:
				ot.append(["ЗАКЛЕИТЬ РОТ", _gag_girl])
			if girl_freed and not girl_taped and not girl_cuffed:
				ot.append(["ЗАМОТАТЬ ЗАПЯСТЬЯ", _tape_wrists])
			elif girl_taped:
				ot.append(["СНЯТЬ СКОТЧ С РУК", _untape_wrists])
			ot.append(["УБРАТЬ", Callable()])
			_hold("tape", 1.2)
			_gdialog("Серый скотч. Ты отрываешь полоску, и она трещит на весь подвал.", ot)
		"knife":
			var o: Array = []
			if not girl_freed:
				o.append(["ПЕРЕРЕЗАТЬ ВЕРЁВКИ", func(): _knife_cut(_free_girl)])
			o.append(["УДАРИТЬ НОЖОМ", func(): _kill_girl("knife")])
			o.append(["УБРАТЬ", Callable()])
			girl.set_emotion("fear")
			_change_trust(-8)
			_hold("knife", 1.5)
			_gdialog("Лезвие блестит в тусклом свете. Девушка смотрит на нож и перестаёт дышать.", o)
		"pistol":
			if ammo <= 0:
				_gdialog("Щёлк. Магазин пуст. Девушка зажмуривается и всхлипывает.", [["УБРАТЬ", Callable()]])
			else:
				girl.set_emotion("fear")
				_change_trust(-10)
				_hold("pistol", 1.5)
				_gdialog("Ствол смотрит ей в лицо. " + ("Она мычит сквозь скотч и зажмуривается." if girl_gagged else "«Нет, нет, пожалуйста...» — шепчет она."), [["ВЫСТРЕЛИТЬ", func(): _kill_girl("pistol")], ["ОПУСТИТЬ", Callable()]])
		"syringe":
			if poison_syringe:
				_hold("syringe", 1.5)
				_gdialog("Игла блестит. Девушка не знает, что внутри. Зато ты знаешь.", [["ВКОЛОТЬ ЯД", func(): _kill_girl("poison_syringe")], ["УБРАТЬ", Callable()]])
			else:
				_hold("syringe", 1.5)
				_gdialog("Девушка косится на шприц: «Что там? Не надо...»", [["ВКОЛОТЬ", _sedate_girl], ["УБРАТЬ", Callable()]])
		"rope":
			if girl_freed:
				if Vector2(girl.position.x - 3.6, girl.position.z - 0.82).length() < 1.6:
					_gdialog("Она у стула.", [["СВЯЗАТЬ", _retie_girl], ["УБРАТЬ", Callable()]])
				else:
					_gdialog("Верёвку можно использовать только у стула.", [["НАЗАД", Callable()]])
			else:
				_gdialog("Она и так крепко связана.", [["НАЗАД", Callable()]])
		"cuffs":
			if not girl_freed:
				_gdialog("Её руки привязаны к стулу. Сначала освободи её.", [["НАЗАД", Callable()]])
			elif girl_cuffed:
				_gdialog("Наручники уже защёлкнуты.", [["НАЗАД", Callable()]])
			else:
				_gdialog("Ты показываешь наручники. " + ("Она качает головой и мычит." if girl_gagged else "«Нет... Я же иду за тобой. Зачем?»"), [["НАДЕТЬ НАРУЧНИКИ", _cuff_girl], ["УБРАТЬ", Callable()]])
		"banana":
			if poison_banana:
				_gdialog("Ты протягиваешь ей банан. Она голодна. Очень. Она не знает про склянку.", [["ДАТЬ БАНАН", func(): _kill_girl("poison_banana")], ["УБРАТЬ", Callable()]])
			else:
				_gdialog("Ты протягиваешь ей банан. «...Правда? Спасибо». Она дрожащими руками берёт его и ест.", [["ПОКОРМИТЬ", _feed_girl], ["УБРАТЬ", Callable()]])
		"poison":
			_hold("poison", 1.5)
			_gdialog("Ты открываешь склянку с чёрной этикеткой. Девушка хрипло просит воды.", [["ДАТЬ «ВОДУ»", func(): _kill_girl("poison")], ["УБРАТЬ", Callable()]])
		"bandage":
			_girl_gift("bandage", "Ты показываешь бинт. Она протягивает руку со ссадинами.", "ПЕРЕВЯЗАТЬ", 8, "Ты аккуратно перевязываешь ей запястье.")
		"medkit":
			_girl_gift("medkit", "Ты открываешь аптечку. Девушка смотрит на красный крест и кивает.", "ОБРАБОТАТЬ РАНЫ", 15, "Она морщится от йода, но терпит. И шепчет «спасибо».")
		"water":
			_girl_gift("water", "Ты протягиваешь бутылку воды. «Правда можно?..»", "НАПОИТЬ", 10, "Она жадно пьёт и вытирает губы.")
		"chocolate":
			_girl_gift("chocolate", "Ты протягиваешь шоколад. Она давно не ела.", "ДАТЬ ШОКОЛАД", 12, "Она ломает плитку пополам и отдаёт тебе половину.")
		"beans":
			_girl_gift("beans", "Ты протягиваешь открытую банку фасоли.", "ПОКОРМИТЬ", 10, "Она ест медленно, не сводя с тебя глаз.")
		"sylphy":
			_girl_gift("sylphy", "Ты протягиваешь плюшевую Сильфи. Глаза девушки расширяются.", "ОТДАТЬ СИЛЬФИ", 18, "Она прижимает Сильфи к груди. «Я думала, её больше нет...»")
		"lighter":
			_light_up(10.0)
			girl.set_emotion("neutral")
			_change_trust(3)
			_gdialog("Огонёк освещает её лицо. Она тянется к теплу и немного успокаивается.", [["ОК", Callable()]])
		"flashlight":
			_change_trust(-3)
			girl.set_emotion("fear")
			_gdialog("Ты светишь ей в лицо. Она щурится и отворачивается.", [["ПРОСТИ", Callable()]])
		_:
			_gdialog("Это ей не подойдёт.", [["НАЗАД", Callable()]])

func _girl_gift(id: String, text_value: String, btn: String, gain: int, result: String) -> void:
	var give := func():
		inv.erase(id)
		if id == "sylphy":
			girl_has_sylphy = true
		_change_trust(gain)
		girl.set_emotion("happy")
		_toast(result, 3.0)
	_gdialog(text_value, [[btn, give], ["УБРАТЬ", Callable()]])

func _heal(n: int) -> void:
	hp = mini(100, hp + n)
	_flash(Color(0.3, 1.0, 0.4, 0.25), 0.4)
	_hero_emote("happy", 1.0)

func _consume(id: String, n: int, text_value: String) -> void:
	inv.erase(id)
	_heal(n)
	_toast(text_value + "  HP %d" % hp, 2.5)

func _open_can() -> void:
	if not _has("canned"):
		return
	inv.erase("canned")
	inv["beans"] = true
	shake = 0.2
	if _has("knife"):
		_knife_cut()
	else:
		_hold("crowbar", 1.0)
	_toast("Щёлк! Банка открыта: фасоль в томате.", 2.5)
	_bounce_pack()

func _ensure_lights() -> void:
	if flash_light != null:
		return
	flash_light = OmniLight3D.new()
	flash_light.light_color = Color(1.0, 0.98, 0.85)
	flash_light.omni_range = 7.0
	flash_light.light_energy = 0.0
	flash_light.position = Vector3(0, 1.6, 0.6)
	player.add_child(flash_light)
	lighter_light = OmniLight3D.new()
	lighter_light.light_color = Color(1.0, 0.6, 0.25)
	lighter_light.omni_range = 4.0
	lighter_light.light_energy = 0.0
	lighter_light.position = Vector3(0, 1.1, 0.4)
	player.add_child(lighter_light)

func _toggle_flashlight() -> void:
	_ensure_lights()
	flashlight_on = not flashlight_on
	flash_light.light_energy = 1.8 if flashlight_on else 0.0
	_hold("flashlight", 1.0)
	_toast("Фонарик включён." if flashlight_on else "Фонарик выключен.", 1.6)

func _light_up(secs: float) -> void:
	_ensure_lights()
	_hold("lighter", 1.5)
	lighter_light.light_energy = 1.4
	var tw := create_tween()
	tw.tween_interval(secs)
	tw.tween_property(lighter_light, "light_energy", 0.0, 1.0)
	_toast("Огонёк дрожит. Тени отступили.", 2.0)

func _hug_sylphy() -> void:
	_hero_emote("happy", 2.0)
	_heal(5)
	_toast("Мягкая. Пахнет пылью и чем-то домашним.", 2.5)

func _feed_girl() -> void:
	inv.erase("banana")
	_change_trust(10)
	girl.set_emotion("happy")
	_toast("Она доела банан и слабо улыбнулась.", 3.0)

func _retie_girl() -> void:
	inv.erase("rope")
	_change_trust(-25)
	girl_freed = false
	girl_cuffed = false
	girl.cuffed = false
	girl_taped = false
	girl.taped = false
	girl_ropes.visible = true
	girl.tied = true
	girl.seated = true
	girl.tremble = 1.0
	girl.position = Vector3(3.6, -0.15, 0.82)
	girl.rotation.y = 0.0
	girl.set_emotion("fear")
	_gdialog("Ты обматываешь верёвкой запястья и лодыжки и усаживаешь её обратно на стул. Она плачет и не сопротивляется.", [["ОТОЙТИ", Callable()]])

func _cuff_girl() -> void:
	inv.erase("cuffs")
	_change_trust(-15)
	girl_cuffed = true
	girl.cuffed = true
	girl.set_emotion("fear")
	_gdialog("Щёлк. Стальные браслеты смыкаются на запястьях за спиной. Девушка идёт за тобой, но медленнее и тише.", [["ИДЁМ", Callable()]])

func _sedate_girl() -> void:
	inv.erase("syringe")
	_change_trust(-10)
	girl_asleep = true
	girl.tremble = 0.0
	girl.eyes_closed = true
	girl.set_emotion("sad")
	if girl_freed:
		_lay_down(girl, false)
	else:
		girl.droop = 0.8
	_gdialog("Игла входит в предплечье. Девушка вздрагивает, веки тяжелеют, голова падает на грудь. Она засыпает.", [["ОТОЙТИ", Callable()]])

func _kill_girl(method: String) -> void:
	if girl_dead:
		return
	var was_asleep: bool = girl_asleep
	var was_seated: bool = girl.seated
	girl_dead = true
	girl.tremble = 0.0
	girl.tied = false
	girl.cuffed = false
	girl.seated = false
	girl.eyes_closed = true
	girl.look_node = null
	girl.set_emotion("sad")
	girl_ropes.visible = false
	var gp: Vector3 = girl.position
	var txt := ""
	var spatter := true
	match method:
		"knife":
			inv["knife"] = true
			if was_asleep:
				txt = "Нож входит один раз, потом ещё. Она не просыпается и не кричит. Дыхание просто обрывается. Кровь стекает по платью и капает на пол."
			else:
				txt = "Нож входит один раз, потом ещё. Она вскрикивает и затихает. Кровь стекает по платью и капает на пол. Тишина давит на уши."
		"pistol":
			ammo -= 1
			if was_asleep:
				txt = "Выстрел оглушает подвал. Эхо гуляет под сводами. Она даже не вздрагивает. Пахнет порохом и железом."
			else:
				txt = "Выстрел оглушает подвал. Эхо гуляет под сводами. Она падает " + ("со стула" if was_seated else "на пол") + ". Пахнет порохом и железом."
		"poison_syringe":
			poison_syringe = false
			inv.erase("syringe")
			spatter = false
			if was_asleep:
				txt = "Игла входит в вену. Она вздрагивает во сне и обмякает. Ничего громкого. Просто тишина, которая не кончится."
			else:
				txt = "Игла входит в вену. Она дёргается, хрипит и обмякает. Ничего громкого. Просто тишина, которая не кончится."
		"poison_banana":
			poison_banana = false
			inv.erase("banana")
			spatter = false
			txt = "Она съедает банан. Через минуту хватается за горло, пытается что-то сказать. Глаза становятся стеклянными. Она заваливается набок."
		_:
			inv.erase("poison")
			spatter = false
			txt = "Она делает глоток и морщится. Потом хрипит. Потом всё. Стакан катится по полу."
	if spatter:
		var hit_dir: Vector3 = gp - player.global_position
		hit_dir.y = 0.0
		blood.spatter(gp + Vector3(0, 0.95, 0), 16, hit_dir, 1.0)
		blood.wound(girl.upper, Vector3(0.04, 0.85, 0.2), Vector2(0.13, 0.17), 5.0)
		girl.add_wear(0.1, 1.0)
		if method == "knife":
			# артериальный фонтан и медленное растекание лужи
			blood.spray(gp + Vector3(0, 1.0, 0), hit_dir + Vector3(0, 0.9, 0), 1.5)
			blood.stream(gp + Vector3(0, 0.5, 0.1), 5.0, 0.35)
			blood.pool(gp, 0.6, 5.0, 7, 1.0)
	girl.talking = false
	girl.set_gag(false)
	girl_gagged = false
	_lay_down(girl, spatter)
	_hold(method if method in ["knife", "pistol"] else "syringe", 1.2)
	_scene(txt + "\n\nПодвал замирает. Лампа гаснет на секунду. Становится очень тихо.", [["ПРОДОЛЖИТЬ", Callable()]])
	_schedule_monster(5.0)

# ------------------------------------------------------------------ gameplay: монстр

func _schedule_monster(delay: float) -> void:
	if not MONSTER_ENABLED:
		return
	if monster_on or monster_dead or _summoning:
		return
	_summoning = true
	await get_tree().create_timer(delay).timeout
	while dialog_panel.visible or busy or menu_panel.visible:
		await get_tree().create_timer(0.5).timeout
	if ended:
		return
	monster_on = true
	_blackout = 1.5
	shake = 0.5
	await get_tree().create_timer(1.4).timeout
	var spawns := [Vector3(-5.0, 0.05, 4.2), Vector3(5.2, 0.05, 4.2), Vector3(5.0, 0.05, 0.0), Vector3(-3.0, 0.05, -3.0)]
	var best: Vector3 = spawns[0]
	var best_d := 0.0
	for s in spawns:
		var d: float = (s as Vector3).distance_to(player.global_position)
		if d > best_d:
			best_d = d
			best = s
	monster.process_mode = Node.PROCESS_MODE_INHERIT
	monster.visible = true
	monster.global_position = best
	_flash(Color(0.6, 1.0, 0.3, 0.35), 0.8)
	_toast("Из темноты кто-то дышит. Скрежет когтей по бетону...", 4.0)

func _use_on_monster(id: String) -> void:
	var stunned := monster_stun > 0.0
	match id:
		"knife":
			_hold("knife", 1.0)
			if stunned:
				_damage_monster(3, "Нож входит глубоко, пока тварь беспомощна.")
			else:
				_damage_monster(2, "Ты полоснул тварь ножом.")
				if not monster_dead and randf() < 0.55:
					_hurt_player(40, "knife")
		"pistol":
			if ammo <= 0:
				_dialog("Щёлк. Магазин пуст. Тварь поворачивает голову на звук.", [["ЧЁРТ", Callable()]])
				return
			_hold("pistol", 1.2)
			ammo -= 1
			if randf() < 0.15:
				_toast("ОСЕЧКА!", 1.5)
				_hurt_player(50, "misfire")
				return
			_damage_monster(3, "Выстрел гремит под сводами. Тварь отшатывается.")
		"syringe":
			_hold("syringe", 1.0)
			if stunned or randf() < 0.6:
				if poison_syringe:
					poison_syringe = false
					inv.erase("syringe")
					_kill_monster("Игла входит в шею твари. Чёрная жидкость уходит в вену. Монстр дёргается, хрипит и валится на бок.")
				else:
					inv.erase("syringe")
					monster_stun = 9.0
					_toast("Тварь оседает на пол — снотворное действует!", 3.0)
			else:
				_toast("Промах! Тварь ударяет тебя.", 2.0)
				_hurt_player(50, "monster")
		"rope":
			if stunned:
				inv.erase("rope")
				monster_stun = 18.0
				_toast("Ты связал оглушённую тварь. Она ещё дёргается, но встать не может.", 3.5)
			else:
				_dialog("Тварь слишком быстра. Верёвку лучше расставить как ловушку.", [["НАЗАД", Callable()]])
		"cuffs":
			if stunned:
				inv.erase("cuffs")
				monster_stun = 25.0
				_toast("Щёлк. Наручники сомкнулись на когтистых лапах.", 3.5)
			else:
				_toast("Тварь не даётся! Когти полоснули по руке.", 2.5)
				_hurt_player(30, "monster")
		"banana":
			if poison_banana:
				poison_banana = false
				inv.erase("banana")
				monster_stun = 99.0
				_hold("banana", 1.0)
				_toast("Ты бросаешь банан. Тварь жадно хватает его...", 3.0)
				await get_tree().create_timer(2.0).timeout
				_kill_monster("Монстр хрипит, хватается за горло. Из пасти идёт чёрная пена. Громадные глаза выкатываются ещё сильнее, и он замирает.")
			else:
				inv.erase("banana")
				monster_stun = 3.5
				_hold("banana", 0.8)
				_toast("Банан попадает прямо в морду. Тварь растерянно замирает!", 3.0)
		"crowbar":
			_hold("crowbar", 1.0)
			_damage_monster(1, "Удар ломиком. Хруст кости.")
			monster_stun = maxf(monster_stun, 1.5)
		_:
			_dialog("Это против него бесполезно.", [["НАЗАД", Callable()]])

func _damage_monster(dmg: int, text_value: String) -> void:
	monster_hp -= dmg
	_spatter(monster.global_position + Vector3(0, 1.1, 0), 8)
	_flash(Color(0.4, 0.0, 0.0, 0.3), 0.3)
	shake = 0.4
	if monster_hp <= 0:
		_kill_monster(text_value + " Тварь корчится и затихает.")
	else:
		_toast(text_value, 2.5)
		monster_stun = maxf(monster_stun, 0.8)

func _kill_monster(text_value: String) -> void:
	if monster_dead:
		return
	monster_dead = true
	monster.dead = true
	monster.stunned = false
	monster.collision_layer = 0
	monster.collision_mask = 0
	var mp: Vector3 = monster.global_position
	_spatter(mp + Vector3(0, 1.0, 0), 14)
	_blood_pool(mp + Vector3(0, 0, 0.3), 1.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(monster, "rotation:z", PI / 2.0, 0.7).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(monster, "position:y", 0.32, 0.7)
	if girl_freed and not girl_dead and not girl_asleep:
		girl.set_emotion("happy")
	_scene(text_value + "\n\nХозяин подвала мёртв. Над подвалом повисла тишина, и впервые она не давит.", [["ВЫДОХНУТЬ", Callable()]], Color(0.2, 0.5, 0.1, 0.5))

# ------------------------------------------------------------------ gameplay: дверь и концовки

func _use_door() -> void:
	if _has("key"):
		_dialog("Ключ подходит. Выйти?", [["ОТКРЫТЬ", _ending], ["ПОЗЖЕ", Callable()]])
	else:
		_dialog("Заперто. Нужен ключ.", [["ЗАКРЫТЬ", Callable()]])

func _ending() -> void:
	if ended:
		return
	var line := "Ключ поворачивается. Дверь открывается."
	if girl_dead:
		line = "Ты уходишь один. Внизу очень тихо."
	elif girl_asleep:
		line = "Она остаётся лежать и спать."
	elif girl_freed:
		line = "Она идёт следом."
	var t := ""
	if girl_dead:
		t = "ПАЛАЧ\nТы уходишь один. Внизу тихо."
	elif girl_asleep:
		t = "СОН\nОна осталась спать внизу."
	elif girl_freed and (girl_cuffed or girl_taped):
		t = "ПОД КОНВОЕМ\nОна идёт молча, руки связаны."
	elif girl_freed and trust >= 60:
		t = "ВМЕСТЕ\nУтренний воздух. Она держится рядом." + ("\nВ руках у неё — плюшевая Сильфи." if girl_has_sylphy else "")
	elif girl_freed:
		t = "ПОБЕГ\nНа лестнице она вырывается и убегает."
	else:
		t = "В ОДИНОЧКУ\nТы выходишь. Внизу кто-то зовёт тебя."
	ended = true
	in_cutscene = true
	_unequip()
	_bars(true)
	var p = player
	var m = p.model
	p.scripted = true
	p.velocity = Vector3.ZERO
	var follow: bool = girl_freed and girl_following and not girl_dead and not girl_asleep
	# камера остаётся в комнате и смотрит на дверь
	_end_cam_pos = Vector3(-0.4, 2.35, -0.7)
	_end_cam_look = Vector3(0.0, 1.05, -5.4)
	_end_cam_on = true
	_open_doorway()
	# 1. подходит к двери
	await _walk(p, Vector3(0.05, 0.0, -4.25), 1.9, follow)
	_turn_to(PI)
	await get_tree().create_timer(0.35).timeout
	# 2. ключ в замке: рука вперёд, щелчок
	var tw := create_tween()
	tw.tween_property(m, "punch_l", 0.75, 0.25).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_sfx("click", -4.0)
	_caption("Ключ входит в замок. Щелчок.", 1.6)
	await get_tree().create_timer(0.45).timeout
	_sfx("click", -6.0)
	tw = create_tween()
	tw.tween_property(m, "punch_l", 0.0, 0.25)
	await get_tree().create_timer(0.3).timeout
	# 3. дверь открывается, снаружи бьёт холодный утренний свет
	_swing_exit_door()
	await get_tree().create_timer(1.3).timeout
	_caption(line, 2.6)
	await get_tree().create_timer(0.6).timeout
	# 4. выходит и поднимается по лестнице, камера остаётся внутри
	if follow:
		_girl_walk_out()
	await _walk(p, Vector3(0.0, 0.0, -5.6), 1.4, false)
	await _walk(p, Vector3(0.0, 0.0, -9.3), 1.25, false, true)
	p.visible = false
	await get_tree().create_timer(1.6 if follow else 0.9).timeout
	# 5. экран медленно гаснет, финальный текст
	_final_screen(t)

## Герой идёт к точке (шагом, с анимацией ходьбы). climb — подъём по ступеням.
func _walk(p, dest: Vector3, spd: float, girl_follow: bool, climb: bool = false) -> void:
	var m = p.model
	var from: Vector3 = p.global_position
	var flat := Vector3(dest.x - from.x, 0.0, dest.z - from.z)
	if flat.length() < 0.05:
		return
	_turn_to(atan2(flat.x, flat.z))
	m.move_amount = 0.75
	var secs := flat.length() / spd
	var target := Vector3(dest.x, from.y, dest.z)
	if climb:
		target.y = from.y + flat.length() * 0.62
	var tw := create_tween()
	tw.tween_property(p, "global_position", target, secs)
	if girl_follow:
		tw.parallel().tween_method(func(_v: float): _girl_trail(p.global_position), 0.0, 1.0, secs)
	await tw.finished
	m.move_amount = 0.0
	if girl_follow:
		girl.move_amount = 0.0

func _turn_to(a: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float):
		player.facing = v
		player.model.rotation.y = v, player.facing, player.facing + wrapf(a - player.facing, -PI, PI), 0.2)

## Девушка держится в метре позади героя.
func _girl_trail(lead_pos: Vector3) -> void:
	var to: Vector3 = lead_pos - girl.position
	to.y = 0.0
	if to.length() > 1.1:
		var d := to.normalized()
		girl.position += d * (to.length() - 1.1)
		girl.rotation.y = atan2(d.x, d.z)
		girl.move_amount = 1.0
	else:
		girl.move_amount = 0.0

func _girl_walk_out() -> void:
	await get_tree().create_timer(0.9).timeout
	var path := [Vector3(0.1, girl.position.y, -4.3), Vector3(0.0, girl.position.y, -5.6), Vector3(0.0, girl.position.y + 2.3, -9.3)]
	for pt in path:
		var to: Vector3 = pt - girl.position
		var flat := Vector3(to.x, 0, to.z)
		if flat.length() < 0.05:
			continue
		girl.rotation.y = atan2(flat.x, flat.z)
		girl.move_amount = 1.0
		var tw := create_tween()
		tw.tween_property(girl, "position", pt, flat.length() / 1.3)
		await tw.finished
	girl.move_amount = 0.0

## Пробивает в задней стене проём и строит за ним лестницу наверх, к утреннему свету.
func _open_doorway() -> void:
	var wall := get_node_or_null("BackWall") as Node3D
	if wall != null:
		for c in wall.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).visible = false
			elif c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
		_mesh(self, _boxm(Vector3(5.7, 3.6, 0.4)), mats["wall"], Vector3(-3.55, 1.8, -5.2))
		_mesh(self, _boxm(Vector3(5.7, 3.6, 0.4)), mats["wall"], Vector3(3.55, 1.8, -5.2))
		_mesh(self, _boxm(Vector3(1.4, 1.3, 0.4)), mats["wall"], Vector3(0.0, 2.95, -5.2))
	# лестничный пролёт: стены, ступени, потолок
	var stair := Node3D.new()
	stair.name = "ExitStairs"
	add_child(stair)
	_mesh(stair, _boxm(Vector3(0.3, 6.0, 4.4)), mats["wall_dark"], Vector3(-0.85, 2.0, -7.4))
	_mesh(stair, _boxm(Vector3(0.3, 6.0, 4.4)), mats["wall_dark"], Vector3(0.85, 2.0, -7.4))
	_mesh(stair, _boxm(Vector3(1.4, 0.5, 0.8)), mats["floor"], Vector3(0.0, -0.25, -5.6))
	for i in 10:
		var z := -6.0 - i * 0.3
		var y := 0.09 + i * 0.186
		_mesh(stair, _boxm(Vector3(1.4, y * 2.0, 0.3)), mats["wood"] if i % 2 == 0 else mats["wood_light"], Vector3(0.0, 0.0, z))
	_mesh(stair, _boxm(Vector3(1.4, 0.3, 4.4)), mats["wall_dark"], Vector3(0.0, 4.2, -7.6))
	# свет сверху: светящийся проём и холодный рассветный свет, падающий вниз
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(0.85, 0.92, 1.0)
	_mesh(stair, _boxm(Vector3(1.4, 2.6, 0.05)), glow, Vector3(0.0, 2.4, -9.6))
	var sun := OmniLight3D.new()
	sun.light_color = Color(0.75, 0.85, 1.0)
	sun.light_energy = 0.0
	sun.omni_range = 9.0
	sun.position = Vector3(0.0, 3.0, -8.8)
	stair.add_child(sun)
	props["exit_sun"] = sun
	var spill := SpotLight3D.new()
	spill.light_color = Color(0.8, 0.88, 1.0)
	spill.light_energy = 0.0
	spill.spot_range = 9.0
	spill.spot_angle = 32.0
	spill.position = Vector3(0.0, 2.4, -5.6)
	spill.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	spill.shadow_enabled = true
	stair.add_child(spill)
	props["exit_spill"] = spill

## Дверь распахивается на петлях, свет заливает пол подвала.
func _swing_exit_door() -> void:
	var door := props.get("exit_door") as StaticBody3D
	if door != null:
		for c in door.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).visible = false
			elif c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
	for k in ["exit_panel", "exit_knob"]:
		if props.has(k):
			(props[k] as Node3D).visible = false
	var hinge := Node3D.new()
	hinge.position = Vector3(-0.7, 1.15, -4.93)
	add_child(hinge)
	_mesh(hinge, _boxm(Vector3(1.4, 2.3, 0.12)), mats["wood"], Vector3(0.7, 0, 0))
	_mesh(hinge, _boxm(Vector3(1.0, 1.7, 0.04)), mats["wood_light"], Vector3(0.7, 0, 0.09))
	_mesh(hinge, LowPoly.sphere(Vector3(0.07, 0.07, 0.07), 5, 3), mats["lamp"], Vector3(1.2, -0.05, 0.15))
	_sfx("rattle", -6.0)
	if creak_player != null:
		creak_player.play()
	shake = maxf(shake, 0.15)
	var tw := create_tween()
	tw.tween_property(hinge, "rotation_degrees:y", 12.0, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.25)
	tw.tween_property(hinge, "rotation_degrees:y", 108.0, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var lt := create_tween().set_parallel(true)
	if props.has("exit_sun"):
		lt.tween_property(props["exit_sun"], "light_energy", 2.2, 1.8).set_delay(0.3)
	if props.has("exit_spill"):
		lt.tween_property(props["exit_spill"], "light_energy", 3.0, 1.8).set_delay(0.4)

## Затемнение и финальный текст поверх всего.
func _final_screen(t: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(black)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.modulate.a = 0.0
	layer.add_child(box)
	var parts := t.split("\n", false, 1)
	var title := _label(parts[0], 28, Color(0.95, 0.9, 0.82))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	if parts.size() > 1:
		var body := _label(parts[1], 13, Color(0.75, 0.72, 0.68))
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(body)
	var bc := CenterContainer.new()
	box.add_child(bc)
	var btn := _button("В МЕНЮ", 160.0)
	btn.pressed.connect(_restart)
	btn.modulate.a = 0.0
	bc.add_child(btn)
	_bars(false)
	var tw := create_tween()
	tw.tween_property(black, "color:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.6)
	tw.tween_property(box, "modulate:a", 1.0, 1.6)
	tw.tween_interval(1.0)
	tw.tween_property(btn, "modulate:a", 1.0, 0.6)
	tw.tween_callback(func(): btn.grab_focus())

func _restart() -> void:
	get_tree().reload_current_scene()

# ------------------------------------------------------------------ новое: подбор, эмоции, рюкзак, катсцены

func _pickup_label(id: String) -> void:
	var col: Color = NEON.get(id, Color(1, 1, 1))
	var l := Label3D.new()
	l.text = "+ " + str(ITEM_NAMES.get(id, id)).to_upper()
	if pixel_font != null:
		l.font = pixel_font
	l.font_size = 36
	l.pixel_size = 0.008
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.shaded = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.modulate = col
	l.outline_modulate = col.darkened(0.75)
	l.outline_size = 12
	l.position = Vector3(0, 2.1, 0)
	player.add_child(l)
	var mdl: Node3D = ItemModels.make(id, mats)
	mdl.scale = Vector3.ONE * 2.0
	mdl.position = Vector3(0, 1.3, 0)
	player.add_child(mdl)
	var glow := OmniLight3D.new()
	glow.light_color = col
	glow.light_energy = 1.6
	glow.omni_range = 3.0
	glow.position = Vector3(0, 1.0, 0.3)
	player.add_child(glow)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", 2.7, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(1.4)
	tw.tween_property(glow, "light_energy", 0.0, 1.2)
	tw.tween_property(mdl, "rotation:y", TAU * 2.0, 1.8)
	tw.tween_property(mdl, "position:y", 1.9, 1.8)
	tw.chain().tween_callback(func():
		l.queue_free()
		mdl.queue_free()
		glow.queue_free())

func _hero_emote(e: String, secs: float = 1.2) -> void:
	_emote_token += 1
	var tk := _emote_token
	player.model.set_emotion(e)
	await get_tree().create_timer(secs).timeout
	if tk == _emote_token and is_instance_valid(player):
		player.model.set_emotion("neutral")

func _bounce_pack() -> void:
	if pack_node == null:
		return
	var tw := create_tween()
	tw.tween_property(pack_node, "scale", Vector3.ONE * 1.4, 0.1)
	tw.tween_property(pack_node, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BOUNCE)

func _build_pack_widget(root: Control) -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	svc.offset_left = -84
	svc.offset_right = -8
	svc.offset_top = 4
	svc.offset_bottom = 80
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(svc)
	var sv := SubViewport.new()
	sv.size = Vector2i(76, 76)
	sv.transparent_bg = true
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.8)
	env.ambient_light_energy = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	sv.add_child(we)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.15, 2.6)
	cam.fov = 40
	sv.add_child(cam)
	var dl := DirectionalLight3D.new()
	dl.rotation_degrees = Vector3(-30, 30, 0)
	dl.light_energy = 1.2
	sv.add_child(dl)
	pack_node = Node3D.new()
	sv.add_child(pack_node)
	_mesh(pack_node, _boxm(Vector3(0.9, 0.75, 0.55)), mats["pack"], Vector3(0, -0.2, 0))
	_mesh(pack_node, _boxm(Vector3(0.96, 0.42, 0.62)), mats["pack"], Vector3(0, 0.38, -0.02), Vector3(-8, 0, 0))
	_mesh(pack_node, _boxm(Vector3(0.7, 0.4, 0.16)), mats["pack_dark"], Vector3(0, -0.32, 0.36))
	_mesh(pack_node, _boxm(Vector3(0.14, 0.62, 0.05)), mats["it_red"], Vector3(0, 0.12, 0.34))
	_mesh(pack_node, _boxm(Vector3(0.2, 0.1, 0.06)), mats["it_metal"], Vector3(0, 0.22, 0.37))
	_mesh(pack_node, _boxm(Vector3(0.05, 0.3, 0.03)), mats["it_red"], Vector3(-0.2, 0.42, 0.33), Vector3(0, 0, 20))
	_mesh(pack_node, _boxm(Vector3(0.22, 0.05, 0.03)), mats["it_red"], Vector3(-0.2, 0.44, 0.33), Vector3(0, 0, 20))
	_mesh(pack_node, _boxm(Vector3(0.08, 0.28, 0.1)), mats["it_red"], Vector3(-0.12, 0.7, 0.0), Vector3(0, 0, 18))
	_mesh(pack_node, _boxm(Vector3(0.08, 0.28, 0.1)), mats["it_red"], Vector3(0.12, 0.7, 0.0), Vector3(0, 0, -18))
	_mesh(pack_node, _boxm(Vector3(0.3, 0.07, 0.1)), mats["it_red"], Vector3(0, 0.84, 0.0))
	_mesh(pack_node, _boxm(Vector3(0.1, 0.8, 0.05)), mats["it_red"], Vector3(0.52, -0.1, 0.0), Vector3(0, 0, -6))
	_mesh(pack_node, _boxm(Vector3(0.1, 0.8, 0.05)), mats["it_red"], Vector3(-0.52, -0.1, 0.0), Vector3(0, 0, 6))
	pack_node.position.y = -0.15
	pack_widgets.append(svc)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -84
	b.offset_right = -8
	b.offset_top = 4
	b.offset_bottom = 80
	b.pressed.connect(_open_items)
	root.add_child(b)
	pack_widgets.append(b)

func _bars(on: bool) -> void:
	var tw := create_tween()
	tw.tween_method(_set_bars, _bar_amount, 1.0 if on else 0.0, 0.4)
	if not on:
		caption_label.text = ""

## Обе полосы считаются от одной высоты, поэтому всегда равны и симметричны. Субтитры центрируются в нижней полосе.
func _set_bars(a: float) -> void:
	_bar_amount = a
	var full: float = get_viewport().get_visible_rect().size.y * BAR_RATIO
	var h := full * a
	bars_top.offset_top = 0.0
	bars_top.offset_bottom = h
	bars_bot.offset_bottom = 0.0
	bars_bot.offset_top = -h
	caption_label.offset_top = -full
	caption_label.offset_bottom = 0.0
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _caption(t: String, secs: float) -> void:
	caption_label.text = t
	caption_label.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(caption_label, "visible_ratio", 1.0, clampf(t.length() * 0.04, 0.3, 2.0))
	await get_tree().create_timer(secs).timeout

func _cut(focus: Vector3, line: String, secs: float = 2.4, zoom: float = 0.6) -> void:
	cam_focus = focus
	cam_zoom = zoom
	has_override = true
	await _caption(line, secs)

func _intro() -> void:
	fade_rect.modulate.a = 1.0
	create_tween().tween_property(fade_rect, "modulate:a", 0.0, 1.4)
	await _run_cutscene([
		{"at": "girl", "line": "Подвал. Холодно. Кто-то тихо плачет.", "secs": 2.6, "zoom": 0.6, "girl": "sad"},
		{"at": "player", "line": "Ты очнулся здесь. Голова гудит.", "secs": 2.4, "zoom": 0.42, "hero": "hurt"},
		{"at": "door", "line": "Дверь заперта. Ключ спрятан где-то рядом.", "secs": 2.4, "zoom": 0.7},
		{"at": "player", "line": "Нужно найти ключ.", "secs": 2.0, "zoom": 0.5, "hero": "neutral"},
	])

## Положение камеры для катсцены: "player" / "girl" / "both" / "door" или Vector3.
func _focus_of(at) -> Vector3:
	if at is Vector3:
		return at
	match str(at):
		"player":
			return Vector3(player.global_position.x, 0.7, player.global_position.z)
		"girl":
			return Vector3(girl.global_position.x, 0.7, girl.global_position.z)
		"both":
			var a: Vector3 = player.global_position
			var b: Vector3 = girl.global_position
			return Vector3((a.x + b.x) * 0.5, 0.7, (a.z + b.z) * 0.5)
		"door":
			return Vector3(0.0, 0.8, -4.2)
	return Vector3.ZERO

func _cut_wait(secs: float) -> void:
	var t := 0.0
	while t < secs and not cut_skip:
		await get_tree().process_frame
		t += get_process_delta_time()

## beats: массив словарей {at, line, secs, zoom, hero, girl}. Любая кнопка действия пропускает сцену.
func _run_cutscene(beats: Array) -> void:
	busy = true
	in_cutscene = true
	cut_skip = false
	var girl_emo := str(girl.emotion)
	_bars(true)
	await _cut_wait(0.45)
	for b in beats:
		if cut_skip:
			break
		cam_focus = _focus_of(b.get("at", "player"))
		cam_zoom = float(b.get("zoom", 0.6))
		has_override = true
		if b.has("hero"):
			player.model.set_emotion(str(b["hero"]))
		if b.has("girl") and _girl_awake():
			girl.set_emotion(str(b["girl"]))
		caption_label.text = str(b.get("line", ""))
		caption_label.visible_ratio = 0.0
		var tw := create_tween()
		tw.tween_property(caption_label, "visible_ratio", 1.0, clampf(caption_label.text.length() * 0.035, 0.3, 1.8))
		await _cut_wait(float(b.get("secs", 2.2)))
	has_override = false
	cam_zoom = 1.0
	player.model.set_emotion("neutral")
	if _girl_awake() and not girl_freed:
		girl.set_emotion(girl_emo)
	_bars(false)
	await _cut_wait(0.4)
	in_cutscene = false
	cut_skip = false
	busy = false

func _make_theme() -> Theme:
	var th := Theme.new()
	if ResourceLoader.exists("res://Fonts/pixel.ttf"):
		pixel_font = load("res://Fonts/pixel.ttf")
	else:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Press Start 2P", "Minecraft", "Silkscreen", "DejaVu Sans Mono", "monospace"])
		sf.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		sf.hinting = TextServer.HINTING_NORMAL
		sf.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		pixel_font = sf
	th.default_font = pixel_font
	th.default_font_size = 12
	return th

func _change_trust(d: int) -> void:
	trust = clampi(trust + d, 0, 100)
	if girl_dead or girl_asleep or not girl_freed:
		return
	if girl_cuffed or trust < 25:
		girl.set_emotion("fear")
	elif trust >= 60:
		girl.set_emotion("happy")
	else:
		girl.set_emotion("sad")

func _girl_line() -> String:
	if girl_cuffed:
		return "«Сними это.»"
	if trust < 30:
		return "«Не подходи близко.»"
	if trust < 60:
		return "«Я иду за тобой. Пока.»"
	return "«Спасибо. Идём.»"

## Гардероб девушки: по 3 наряда на странице, чтобы кнопки помещались на экране.
## Нижнее бельё появляется только при доверии 40+.
func _outfit_menu(page: int = 0) -> void:
	var ids: Array = []
	for id in Humanoid.OUTFIT_ORDER:
		if id == "underwear" and trust < 40:
			continue
		ids.append(id)
	var per := 3
	var start := page * per
	var opts: Array = []
	for i in range(start, mini(start + per, ids.size())):
		var oid: String = ids[i]
		var label: String = Humanoid.OUTFITS[oid]["label"]
		if oid == girl.outfit:
			label += " ✓"
		opts.append([label, func(): _set_girl_outfit(oid)])
	if start + per < ids.size():
		opts.append(["ДАЛЕЕ", func(): _outfit_menu(page + 1)])
	else:
		opts.append(["НАЗАД", _talk_girl])
	var cur: String = Humanoid.OUTFITS[girl.outfit]["label"].to_lower()
	var cond := _wear_text()
	if cond != "" and page == 0:
		opts.insert(opts.size() - 1, ["ПРИВЕСТИ В ПОРЯДОК", _repair_menu])
	_gdialog("Во что её одеть? Сейчас: %s%s." % [cur, cond], opts)

func _wear_text() -> String:
	var w: float = girl.get_wear()
	var b: float = girl.get_stain()
	var parts: Array = []
	if w >= 0.7:
		parts.append("порвана")
	elif w >= 0.4:
		parts.append("потрёпана")
	elif w >= 0.15:
		parts.append("грязная")
	if b >= 0.2:
		parts.append("в крови")
	if parts.is_empty():
		return ""
	return " (" + ", ".join(parts) + ", износ %d%%)" % int(w * 100)

## Починка: вода отстирывает кровь и грязь, скотч латает прорехи.
func _repair_menu() -> void:
	var opts: Array = []
	if _has("water"):
		opts.append(["ОТСТИРАТЬ (ВОДА)", func():
			inv.erase("water")
			girl.repair(0.15, true)
			girl.set_emotion("happy")
			_change_trust(2)
			_gdialog("Холодная вода, немного усилий. Пятна почти сошли.%s" % _wear_text(), [["ОК", Callable()]])])
	if _has("tape"):
		opts.append(["ЗАЛАТАТЬ (СКОТЧ)", func():
			girl.repair(0.35, false)
			_change_trust(1)
			_gdialog("Прорехи заклеены скотчем изнутри. Держится.%s" % _wear_text(), [["ОК", Callable()]])])
	opts.append(["НАЗАД", func(): _outfit_menu(0)])
	if opts.size() == 1:
		_gdialog("Нечем. Нужна вода, чтобы отстирать, или скотч, чтобы залатать.", opts)
	else:
		_gdialog("Одежда: %s.%s" % [Humanoid.OUTFITS[girl.outfit]["label"].to_lower(), _wear_text()], opts)

const OUTFIT_LINES := {
	"cloak": "«Мой старый плащ. Ладно.»",
	"dress": "«Платье? Оно лёгкое. Спасибо.»",
	"sweater": "«Тёплый свитер. Наконец-то не мёрзну.»",
	"pajamas": "«Пижама... Как дома.»",
	"jacket": "«Красная куртка. Мне нравится.»",
	"underwear": "«Совсем снять?.. Ладно. Только не смотри так.»",
}

func _set_girl_outfit(id: String) -> void:
	girl.set_outfit(id)
	if id == "underwear":
		girl.set_emotion("sad")
		girl.tremble = 0.4
		_change_trust(1)
	else:
		girl.set_emotion("happy")
		girl.tremble = 0.0
		_change_trust(3)
	_gdialog(str(OUTFIT_LINES.get(id, "«Спасибо.»")), [["ОК", Callable()]])

func _order_menu() -> void:
	_gdialog("Что ей приказать?", [
		["ЗА МНОЙ", func(): _order("follow")],
		["ЖДАТЬ", func(): _order("wait")],
		["САДИСЬ", func(): _order("sit")],
		["НАЗАД", Callable()],
	])

func _order(kind: String) -> void:
	var chance := clampf(0.3 + float(trust) / 120.0, 0.1, 0.95)
	if girl_cuffed:
		chance -= 0.15
	if randf() > chance:
		_change_trust(-2)
		_gdialog("Она отворачивается.", [["ОК", Callable()]])
		return
	match kind:
		"follow":
			girl_following = true
			girl.seated = false
			girl.position.y = 0.0
		"wait":
			girl_following = false
		"sit":
			girl_following = false
			girl.seated = true
			girl.position.y = -0.33
	_gdialog("Она кивает.", [["ОК", Callable()]])

func _rigid(pos: Vector3, size: Vector3, mat: Material, mass: float) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.position = pos
	rb.mass = mass
	rb.linear_damp = 3.0
	rb.angular_damp = 6.0
	rb.axis_lock_angular_x = true
	rb.axis_lock_angular_z = true
	var pm := PhysicsMaterial.new()
	pm.friction = 0.8
	pm.bounce = 0.2
	rb.physics_material_override = pm
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	rb.add_child(cs)
	_mesh(rb, _boxm(size), mat, Vector3.ZERO)
	rb.add_to_group("movables")
	add_child(rb)
	return rb

func _build_extras2() -> void:
	# Кандалы на стене
	for z in [1.9, 2.5]:
		_mesh(self, LowPoly.frustum(8, 0.1, 0.1, 0.04), mats["metal"], Vector3(5.95, 1.6, z), Vector3(0, 0, 90))
		_mesh(self, _boxm(Vector3(0.03, 0.5, 0.03)), mats["metal"], Vector3(5.9, 1.3, z))
		_mesh(self, LowPoly.frustum(8, 0.08, 0.08, 0.04), mats["metal"], Vector3(5.9, 1.05, z), Vector3(0, 0, 90))
	_interactable("shackles", Vector3(5.2, 0, 2.2), 1.5)
	# Подвижные предметы
	_rigid(Vector3(-0.9, 0.17, -1.5), Vector3(0.34, 0.34, 0.34), mats["rust"], 3.0)
	_rigid(Vector3(3.9, 0.2, -3.2), Vector3(0.4, 0.4, 0.4), mats["wood_light"], 4.0)
	_rigid(Vector3(-3.9, 0.15, 3.9), Vector3(0.3, 0.3, 0.3), mats["wood"], 2.0)
	_rigid(Vector3(1.6, 0.12, 1.2), Vector3(0.5, 0.24, 0.3), mats["metal"], 2.5)

func _build_settings(root: Control) -> void:
	settings_panel = Control.new()
	_full_rect(settings_panel)
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_panel.visible = false
	root.add_child(settings_panel)
	var dim := ColorRect.new()
	_full_rect(dim)
	dim.color = Color(0.0, 0.005, 0.012, 0.78)
	settings_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_panel.add_child(center)
	var pc := PanelContainer.new()
	var st := MCStyle.grunge_panel()
	st.content_margin_left = 22
	st.content_margin_right = 22
	st.content_margin_top = 16
	st.content_margin_bottom = 16
	pc.add_theme_stylebox_override("panel", st)
	center.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	var title := _label("НАСТРОЙКИ", 20, Color(0.82, 0.85, 0.84))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	v.add_child(HSeparator.new())
	for row in [["touch", "Сенсор"], ["snap", "Дрожание"], ["shadows", "Тени"], ["sound", "Звук"], ["shake", "Тряска"]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 24)
		var l := _label(row[1], 14, Color(0.8, 0.83, 0.82))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var tb := _button("", 80, "small")
		var key: String = row[0]
		tb.pressed.connect(func(): _toggle_setting(key))
		h.add_child(tb)
		settings_btns[key] = tb
		v.add_child(h)
	var close := _button("ГОТОВО", 220)
	close.pressed.connect(func():
		settings_panel.visible = false)
	v.add_child(close)

func _toggle_setting(key: String) -> void:
	match key:
		"touch":
			touch_enabled = not touch_enabled
		"snap":
			PS1Mat.set_snap(0.0 if PS1Mat.snap > 0.5 else 1.0)
		"shadows":
			shadows_on = not shadows_on
			_apply_shadows()
		"sound":
			sound_on = not sound_on
			AudioServer.set_bus_mute(0, not sound_on)
		"shake":
			shake_on = not shake_on
	_refresh_settings()

func _refresh_settings() -> void:
	var vals := {"touch": touch_enabled, "snap": PS1Mat.snap > 0.5, "shadows": shadows_on, "sound": sound_on, "shake": shake_on}
	for k in settings_btns:
		var b: Button = settings_btns[k]
		var on: bool = vals[k]
		b.text = "ВКЛ" if on else "ВЫКЛ"
		b.add_theme_color_override("font_color", Color(0.66, 0.88, 0.72) if on else Color(0.6, 0.62, 0.66))
		b.add_theme_color_override("font_hover_color", Color(0.78, 0.96, 0.82) if on else Color(0.78, 0.8, 0.84))

func _room_lamp(pos: Vector3) -> void:
	_mesh(self, _boxm(Vector3(0.02, 0.6, 0.02)), mats["black"], pos + Vector3(0, 0.3, 0))
	_mesh(self, LowPoly.sphere(Vector3(0.08, 0.08, 0.08), 5, 3), mats["lamp"], pos)
	var l := OmniLight3D.new()
	l.position = pos - Vector3(0, 0.2, 0)
	l.light_color = Color(1.0, 0.78, 0.5)
	l.light_energy = 1.3
	l.omni_range = 7.0
	add_child(l)

func _crate_at(pos: Vector3, size: float, rot: float = 0.0) -> StaticBody3D:
	var c := _solid("Crate", pos, Vector3(size, size, size), mats["wood_light"])
	c.rotation_degrees.y = rot
	_mesh(c, _boxm(Vector3(size + 0.02, size * 0.14, size + 0.02)), mats["wood"], Vector3(0, size * 0.36, 0))
	_mesh(c, _boxm(Vector3(size + 0.02, size * 0.14, size + 0.02)), mats["wood"], Vector3(0, -size * 0.36, 0))
	return c

## Две боковые комнаты по карте: склад слева и комната с цепями справа.
func _build_side_rooms() -> void:
	# --- левая: склад
	_solid("FloorL", Vector3(-9.5, -0.25, 0), Vector3(6.6, 0.5, 7.4), mats["floor"])
	_solid("FarWallL", Vector3(-12.8, 1.8, 0), Vector3(0.4, 3.6, 8.0), mats["wall"])
	_solid("BackWallL", Vector3(-9.5, 1.8, -3.8), Vector3(6.6, 3.6, 0.4), mats["wall"])
	_solid("FrontWallL", Vector3(-9.5, 1.8, 3.8), Vector3(6.6, 3.6, 0.4), mats["wall"], false)
	_room_lamp(Vector3(-9.5, 2.8, -0.5))
	_crate_at(Vector3(-11.9, 0.4, -2.8), 0.8, 8.0)
	_crate_at(Vector3(-11.9, 1.2, -2.8), 0.8, -10.0)
	_crate_at(Vector3(-11.0, 0.4, -3.1), 0.8, 0.0)
	_crate_at(Vector3(-11.95, 0.4, -1.8), 0.8, 12.0)
	_crate_at(Vector3(-8.3, 0.35, -3.2), 0.7, 20.0)
	var c3 := _crate_at(Vector3(-9.4, 0.4, -3.1), 0.8, 0.0)
	_interactable("crate3", Vector3(-9.4, 0, -2.3), 1.5)
	_add_lid(c3, 0.8, "crate3")
	_crate_at(Vector3(-11.9, 0.4, 2.8), 0.8, 5.0)
	_crate_at(Vector3(-11.0, 0.4, 3.0), 0.7, -15.0)
	_crate_at(Vector3(-11.9, 1.15, 2.8), 0.6, 30.0)
	# лестница у дальней стены
	for z in [-0.35, 0.35]:
		_mesh(self, _boxm(Vector3(0.05, 2.6, 0.05)), mats["wood"], Vector3(-12.55, 1.3, z), Vector3(0, 0, 6))
	for i in 7:
		_mesh(self, _boxm(Vector3(0.04, 0.04, 0.8)), mats["wood"], Vector3(-12.55 + i * 0.015, 0.3 + i * 0.35, 0.0))
	# дверь на задней стене
	_mesh(self, _boxm(Vector3(1.1, 2.2, 0.1)), mats["wood"], Vector3(-6.9, 1.1, -3.55))
	_mesh(self, LowPoly.sphere(Vector3(0.05, 0.05, 0.05), 5, 3), mats["lamp"], Vector3(-6.5, 1.1, -3.48))
	# подвижные вещи
	_rigid(Vector3(-8.0, 0.2, 1.5), Vector3(0.4, 0.4, 0.4), mats["wood_light"], 4.0)
	_rigid(Vector3(-9.2, 0.15, 2.2), Vector3(0.3, 0.3, 0.3), mats["rust"], 2.5)
	# --- правая: комната с цепями
	_solid("FloorR", Vector3(9.5, -0.25, 0), Vector3(6.6, 0.5, 7.4), mats["floor"])
	_solid("FarWallR", Vector3(12.8, 1.8, 0), Vector3(0.4, 3.6, 8.0), mats["wall"])
	_solid("BackWallR", Vector3(9.5, 1.8, -3.8), Vector3(6.6, 3.6, 0.4), mats["wall"])
	_solid("FrontWallR", Vector3(9.5, 1.8, 3.8), Vector3(6.6, 3.6, 0.4), mats["wall"], false)
	_room_lamp(Vector3(9.5, 2.8, -0.5))
	# деревянное кресло с подлокотниками
	var ch := _solid("ArmChair", Vector3(10.0, 0.45, 0.0), Vector3(0.9, 0.9, 0.9), mats["wood"], false)
	_mesh(ch, _boxm(Vector3(0.7, 0.1, 0.7)), mats["wood"], Vector3(0, -0.05, 0))
	_mesh(ch, _boxm(Vector3(0.7, 0.9, 0.1)), mats["wood"], Vector3(0.0, 0.2, -0.32))
	_mesh(ch, _boxm(Vector3(0.08, 0.08, 0.7)), mats["wood_light"], Vector3(-0.38, 0.2, 0.0))
	_mesh(ch, _boxm(Vector3(0.08, 0.08, 0.7)), mats["wood_light"], Vector3(0.38, 0.2, 0.0))
	_mesh(self, _boxm(Vector3(1.6, 0.012, 1.4)), mats["blood"], Vector3(10.0, 0.009, 0.5), Vector3(0, 12, 0))
	# цепи у задней стены
	for x in [8.0, 9.0, 10.0, 11.0, 12.0]:
		var ch2 := _swinger(Vector3(x, 3.6, -3.55))
		_mesh(ch2, _boxm(Vector3(0.03, 2.0, 0.03)), mats["metal"], Vector3(0, -1.0, 0))
		_mesh(ch2, LowPoly.frustum(4, 0.01, 0.05, 0.16), mats["metal_light"], Vector3(0, -2.1, 0))
	# стол с хламом
	var tb := _solid("Table2", Vector3(11.9, 0.45, -2.3), Vector3(0.8, 0.9, 1.6), mats["wood"], false)
	_mesh(tb, _boxm(Vector3(0.8, 0.1, 1.6)), mats["wood_light"], Vector3(0, 0.4, 0))
	_mesh(tb, _boxm(Vector3(0.5, 0.03, 0.08)), mats["it_metal"], Vector3(0.0, 0.46, -0.3), Vector3(0, 20, 0))
	_mesh(tb, _boxm(Vector3(0.3, 0.012, 0.3)), mats["blood"], Vector3(0.0, 0.455, 0.3))
	_interactable("table2", Vector3(11.1, 0, -2.3), 1.5)
	props["wob_table2"] = tb
	_rigid(Vector3(7.6, 0.15, 1.0), Vector3(0.34, 0.3, 0.34), mats["rust"], 2.5)
	_rigid(Vector3(8.3, 0.15, 2.6), Vector3(0.4, 0.3, 0.4), mats["wood"], 3.0)
	_build_cages()
	_build_physics_props()


# ------------------------------------------------------------------ потеря сознания (без ран и крови)

func _build_faint_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	faint_rect = ColorRect.new()
	faint_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	faint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faint_mat = ShaderMaterial.new()
	faint_mat.shader = FAINT_SHADER
	faint_mat.set_shader_parameter("amount", 0.0)
	faint_rect.material = faint_mat
	faint_rect.visible = false
	layer.add_child(faint_rect)
	fp_cam = Camera3D.new()
	fp_cam.fov = 70.0
	fp_cam.near = 0.05
	add_child(fp_cam)
	thud_player = AudioStreamPlayer.new()
	thud_player.stream = _make_thud()
	thud_player.volume_db = -4.0
	add_child(thud_player)

func _set_faint(a: float) -> void:
	faint_mat.set_shader_parameter("amount", a)

## Ближайшая цель взгляда: плюшевая Сильфи в рюкзаке/у девушки или сама девушка рядом.
func _faint_target():
	if not girl_dead and _girl_dist() < 2.6:
		return girl.global_position + Vector3(0, 0.8, 0)
	return null

## Камера не должна уходить сквозь стены, мебель и персонажей: луч от тела к глазам.
func _safe_eye(from: Vector3, to: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return to
	return (hit["position"] as Vector3).lerp(from, 0.15)

func _faint() -> void:
	if _fainting:
		return
	_fainting = true
	busy = true
	var target = _faint_target()
	var body: Vector3 = player.global_position
	faint_rect.visible = true
	if target != null:
		# вид от первого лица: поворот к ней, размытие и затемнение
		var eye := _safe_eye(body + Vector3(0, 0.7, 0), body + Vector3(0, 1.25, 0))
		fp_cam.global_position = eye
		var fwd := Vector3(sin(player.facing), 0, cos(player.facing))
		fp_cam.look_at(eye + fwd, Vector3.UP)
		fp_cam.make_current()
		player.model.visible = false
		var q0 := fp_cam.global_transform.basis.get_rotation_quaternion()
		fp_cam.look_at(target, Vector3.UP)
		var q1 := fp_cam.global_transform.basis.get_rotation_quaternion()
		fp_cam.global_transform.basis = Basis(q0)
		var tw := create_tween()
		tw.tween_method(func(t: float): fp_cam.global_transform.basis = Basis(q0.slerp(q1, t)), 0.0, 1.0, 1.3)
		tw.tween_method(_set_faint, 0.0, 1.0, 2.0)
		await tw.finished
		fp_cam.global_position = _safe_eye(eye, eye + Vector3(0, -0.8, 0))
	else:
		# короткий вариант: затемнение из текущего ракурса
		var tw2 := create_tween()
		tw2.tween_method(_set_faint, 0.0, 1.0, 1.2)
		await tw2.finished
	thud_player.play()
	shake = 0.6
	await get_tree().create_timer(1.2).timeout
	# пробуждение: сознание возвращается, немного крови восстанавливается
	pdmg.blood_volume = maxf(pdmg.blood_volume, 3.0)
	pdmg.consciousness = 0.75
	pdmg._faint_done = false
	hp = 40
	monster_stun = 2.0
	player.model.visible = true
	player.model.set_emotion("hurt")
	camera.make_current()
	var tw3 := create_tween()
	tw3.tween_method(_set_faint, 1.0, 0.0, 2.0)
	await tw3.finished
	faint_rect.visible = false
	_toast("Ты приходишь в себя. Кровь: %.1f л" % pdmg.blood_volume, 3.0)
	_hero_emote("neutral", 1.5)
	busy = false
	_fainting = false

# ------------------------------------------------------------------ звук и атмосфера

func _make_wav(data: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	return w

func _make_thud() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.5)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := float(i) / rate
		d[i] = (sin(TAU * 55.0 * t) * 0.8 + randf_range(-0.3, 0.3) * exp(-t * 30.0)) * exp(-t * 9.0)
	return _make_wav(d, rate, false)

func _make_drone() -> AudioStreamWAV:
	var rate := 22050
	var n := rate * 4
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := float(i) / rate
		d[i] = sin(TAU * 50.0 * t) * 0.25 + sin(TAU * 75.0 * t) * 0.12 + sin(TAU * 0.5 * t) * 0.05 * sin(TAU * 110.0 * t)
	return _make_wav(d, rate, true)

func _make_creak() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.8)
	var d := PackedFloat32Array()
	d.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / rate
		ph += TAU * (180.0 + 90.0 * sin(t * 9.0) - 60.0 * t) / rate
		d[i] = (sin(ph) * 0.35 + randf_range(-0.12, 0.12)) * sin(PI * t / 0.8)
	return _make_wav(d, rate, false)

func _build_atmosphere() -> void:
	# звук
	drone_player = AudioStreamPlayer.new()
	drone_player.stream = _make_drone()
	drone_player.volume_db = -20.0
	add_child(drone_player)
	drone_player.play()
	creak_player = AudioStreamPlayer.new()
	creak_player.stream = _make_creak()
	creak_player.volume_db = -14.0
	add_child(creak_player)
	# пыль в луче лампы
	dust = CPUParticles3D.new()
	dust.amount = 70
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(6.0, 1.6, 4.5)
	dust.position = Vector3(0, 1.8, -0.3)
	dust.direction = Vector3(0.2, -0.1, 0.1)
	dust.spread = 180.0
	dust.initial_velocity_min = 0.02
	dust.initial_velocity_max = 0.12
	dust.gravity = Vector3(0, -0.01, 0)
	var qm := QuadMesh.new()
	qm.size = Vector2(0.025, 0.025)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(0.85, 0.8, 0.7, 0.35)
	qm.material = dm
	dust.mesh = qm
	add_child(dust)
	# потёртости и пятна грязи на полу
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0.0, 0.0, 0.0, 0.28)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 22:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(rng.randf_range(0.3, 1.1), 0.004, rng.randf_range(0.2, 0.8))
		mi.mesh = bm
		mi.material_override = sm
		mi.position = Vector3(rng.randf_range(-5.0, 5.0), 0.012, rng.randf_range(-4.0, 4.0))
		mi.rotation_degrees.y = rng.randf_range(0.0, 180.0)
		add_child(mi)

func _update_creaks(delta: float) -> void:
	_creak_t -= delta
	if _creak_t <= 0.0 and game_started:
		_creak_t = randf_range(9.0, 22.0)
		creak_player.pitch_scale = randf_range(0.7, 1.3)
		creak_player.play()


# ------------------------------------------------------------------ камера разговора

func _update_camera(delta: float) -> void:
	var want_pos: Vector3 = _camera_target()
	var want_q := Quaternion(Vector3.RIGHT, deg_to_rad(-50.0))
	var want_fov := 52.0
	if _end_cam_on:
		want_pos = _end_cam_pos
		want_q = Quaternion(Basis.looking_at(_end_cam_look - _end_cam_pos, Vector3.UP))
		want_fov = 50.0
	elif talk_cam and girl != null and player != null:
		var shot: Array = _talk_shot()
		var from: Vector3 = shot[0]
		var to: Vector3 = shot[1]
		want_pos = from
		want_q = Quaternion(Basis.looking_at(to - from, Vector3.UP))
		want_fov = 44.0
	var k := 1.0 - exp(-5.0 * delta)
	var cam_pos := camera.position.lerp(want_pos, k)
	if shake > 0.0:
		cam_pos += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 0.25
		shake = maxf(0.0, shake - delta * 1.5)
	var roll := 0.0
	if action != null:
		cam_pos += action.kick_offset()
		if not talk_cam and not _end_cam_on:
			roll = action.roll
	camera.position = cam_pos
	_cam_q = _cam_q.slerp(want_q, k)
	camera.basis = Basis(_cam_q) * Basis(Vector3(0, 0, 1), roll)
	camera.fov = lerpf(camera.fov, want_fov, k)

## Общий план разговора: камера сбоку на уровне голов, в кадре и игрок, и девушка.
func _talk_shot() -> Array:
	var p: Vector3 = player.global_position
	var g: Vector3 = girl.global_position
	var mid := (p + g) * 0.5
	var d := g - p
	d.y = 0.0
	if d.length() < 0.05:
		d = Vector3(1, 0, 0)
	d = d.normalized()
	var side := Vector3(-d.z, 0.0, d.x)
	# камера со стороны открытого переднего края, чтобы стена не закрывала кадр
	if side.z < -0.2 or (absf(side.z) <= 0.2 and side.x * mid.x > 0.0):
		side = -side
	var dist := clampf(p.distance_to(g) * 0.5 + 1.9, 2.3, 3.1)
	var pos := mid + side * dist + Vector3(0, 1.3, 0)
	var look := mid + Vector3(0, 0.95, 0)
	return [pos, look]

func _face_each_other() -> void:
	var d: Vector3 = girl.global_position - player.global_position
	d.y = 0.0
	if d.length() < 0.05:
		return
	player.facing = atan2(d.x, d.z)
	player.model.rotation.y = player.facing
	if not girl.seated:
		girl.rotation.y = atan2(-d.x, -d.z)

# ------------------------------------------------------------------ анимации предметов и физика

func _swinger(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	swingers.append({"n": n, "ang": Vector2.ZERO, "vel": Vector2.ZERO, "ph": randf() * 6.28})
	return n

## Подвешенные цепи качаются сами и отталкиваются, если пройти рядом.
func _update_swingers(delta: float) -> void:
	if player == null:
		return
	var pp: Vector3 = player.global_position
	var moving: bool = player.velocity.length() > 0.3
	for s in swingers:
		var n: Node3D = s["n"]
		var ang: Vector2 = s["ang"]
		var vel: Vector2 = s["vel"]
		var dv := Vector2(pp.x - n.position.x, pp.z - n.position.z)
		var dl := dv.length()
		if moving and dl < 0.9 and dl > 0.001:
			var push := dv / dl * (1.0 - dl / 0.9)
			vel.x -= push.x * 4.0 * delta * 6.0
			vel.y += push.y * 4.0 * delta * 6.0
		vel.x += sin(_clock * 0.7 + float(s["ph"])) * 0.03 * delta
		vel -= ang * 14.0 * delta
		vel *= maxf(0.0, 1.0 - 0.9 * delta)
		ang += vel * delta
		ang = ang.clamp(Vector2(-0.8, -0.8), Vector2(0.8, 0.8))
		s["ang"] = ang
		s["vel"] = vel
		n.rotation.z = ang.x
		n.rotation.x = ang.y

func _kill_anim(n: Node) -> void:
	if _anims.has(n):
		var t = _anims[n]
		if t != null and (t as Tween).is_valid():
			(t as Tween).kill()
		_anims.erase(n)

func _swing(node, axis: String, deg: float, hold: float = 1.5) -> void:
	var n := node as Node3D
	if n == null:
		return
	var prop := "rotation_degrees:" + axis
	_kill_anim(n)
	var tw := create_tween()
	_anims[n] = tw
	tw.tween_property(n, prop, deg, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(n, prop, 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _slide(node, axis: String, amt: float, hold: float = 1.4) -> void:
	var n := node as Node3D
	if n == null:
		return
	if not n.has_meta("home"):
		n.set_meta("home", n.position)
	var home: Vector3 = n.get_meta("home")
	var out := home
	match axis:
		"x":
			out.x += amt
		"y":
			out.y += amt
		_:
			out.z += amt
	_kill_anim(n)
	var tw := create_tween()
	_anims[n] = tw
	tw.tween_property(n, "position", out, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(n, "position", home, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _lift(node) -> void:
	var n := node as Node3D
	if n == null:
		return
	if not n.has_meta("home"):
		n.set_meta("home", n.position)
	var home: Vector3 = n.get_meta("home")
	_kill_anim(n)
	var tw := create_tween()
	_anims[n] = tw
	tw.tween_property(n, "position", home + Vector3(0, 0.1, 0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(n, "rotation_degrees:z", 7.0, 0.25)
	tw.tween_interval(1.0)
	tw.tween_property(n, "position", home, 0.3)
	tw.parallel().tween_property(n, "rotation_degrees:z", 0.0, 0.3)

func _wobble(node) -> void:
	var n := node as Node3D
	if n == null:
		return
	_kill_anim(n)
	var tw := create_tween()
	_anims[n] = tw
	for i in 5:
		var a := (3.0 - float(i) * 0.6) * (1.0 if i % 2 == 0 else -1.0)
		tw.tween_property(n, "rotation_degrees:z", a, 0.05)
	tw.tween_property(n, "rotation_degrees:z", 0.0, 0.06)

## Крышка бочки подпрыгивает и падает на пол рядом.
func _lid_drop(node) -> void:
	var n := node as Node3D
	if n == null or n.has_meta("dropped"):
		return
	n.set_meta("dropped", true)
	var tw := create_tween()
	tw.tween_property(n, "position", n.position + Vector3(0.12, 0.35, 0.0), 0.15).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(n, "rotation_degrees:z", -40.0, 0.15)
	tw.tween_property(n, "position", Vector3(0.62, -0.43, 0.1), 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(n, "rotation_degrees:z", 0.0, 0.4)

func _add_lid(body: Node3D, size: float, id: String) -> void:
	var lid := Node3D.new()
	lid.position = Vector3(0, size * 0.5, -size * 0.5 - 0.01)
	body.add_child(lid)
	_mesh(lid, _boxm(Vector3(size + 0.04, 0.06, size + 0.04)), mats["wood"], Vector3(0, 0.03, size * 0.5 + 0.01))
	_mesh(lid, _boxm(Vector3(0.1, 0.02, size)), mats["wood_light"], Vector3(0, 0.07, size * 0.5 + 0.01))
	props["lid_" + id] = lid

func _open_anim(id: String) -> void:
	var at := Vector3.ZERO
	for it in interactables:
		if it["id"] == id:
			at = it["pos"]
	match id:
		"crate", "crate3":
			_swing(props.get("lid_" + id), "x", -80.0, 1.5)
		"barrel":
			_lid_drop(props.get("lid_barrel_0"))
			_lid_drop(props.get("lid_barrel_1"))
		"fridge":
			_swing(props.get("fridge_door"), "y", -100.0, 1.6)
		"table":
			_slide(props.get("drawer_table"), "z", 0.38, 1.5)
		"bench":
			_slide(props.get("drawer_bench"), "x", 0.34, 1.5)
		"bed":
			_lift(props.get("mattress"))
		"shelf":
			_wobble(props.get("wob_shelf"))
		"boiler":
			_wobble(props.get("wob_boiler"))
		"table2":
			_wobble(props.get("wob_table2"))
	_bump_nearby(at, 1.9, 0.8)

## Лёгкие предметы рядом подпрыгивают, когда что-то открывают или роются в хламе.
func _bump_nearby(pos: Vector3, radius: float = 2.0, power: float = 1.0) -> void:
	for n in get_tree().get_nodes_in_group("movables"):
		var rb := n as RigidBody3D
		if rb == null:
			continue
		var d: Vector3 = rb.global_position - pos
		d.y = 0.0
		if d.length() < radius:
			rb.sleeping = false
			rb.apply_central_impulse(Vector3(randf_range(-0.6, 0.6), 1.6, randf_range(-0.6, 0.6)) * rb.mass * power)
			rb.apply_torque_impulse(Vector3(0, randf_range(-1.0, 1.0), 0) * rb.mass * 0.2)

func _rigid_cyl(pos: Vector3, radius: float, height: float, mat: Material, mass: float, lock_tilt: bool = true) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.position = pos
	rb.mass = mass
	rb.linear_damp = 2.5
	rb.angular_damp = 4.0
	if lock_tilt:
		rb.axis_lock_angular_x = true
		rb.axis_lock_angular_z = true
	var pm := PhysicsMaterial.new()
	pm.friction = 0.7
	pm.bounce = 0.25
	rb.physics_material_override = pm
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	rb.add_child(cs)
	_mesh(rb, LowPoly.frustum(8, radius, radius, height), mat, Vector3.ZERO)
	rb.add_to_group("movables")
	add_child(rb)
	return rb

func _build_physics_props() -> void:
	# башенка из банок: падает, если задеть
	for y in [0.065, 0.195, 0.325]:
		_rigid_cyl(Vector3(-1.25, y, 2.5), 0.07, 0.13, mats["metal_light"], 0.4, false)
	# бутылки на правом столе-хламе
	for p in [Vector3(8.0, 0.14, -1.0), Vector3(8.35, 0.14, -1.25)]:
		_rigid_cyl(p, 0.06, 0.28, mats["glass"], 0.5, false)
	# бочонки, которые можно толкать
	_rigid_cyl(Vector3(-8.7, 0.4, 1.0), 0.33, 0.8, mats["rust"], 9.0, true)
	_rigid_cyl(Vector3(5.0, 0.3, 1.6), 0.25, 0.6, mats["wood"], 5.0, true)

# ------------------------------------------------------------------ клетки в пыточной (правая комната)

func _toggle_cage(from_inside: bool = false) -> void:
	var door := props.get("cage_door") as Node3D
	if door == null:
		return
	cage_open = not cage_open
	shake = 0.12
	_kill_anim(door)
	var tw := create_tween()
	_anims[door] = tw
	tw.tween_property(door, "rotation_degrees:y", 82.0 if cage_open else 0.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_sfx("rattle", -8.0)
	if from_inside:
		_toast("Дверца открыта." if cage_open else "Ты закрываешь дверцу изнутри. Задвижка лязгает.", 1.8)
		return
	if cage_open:
		_dialog("Дверца со скрипом распахивается. Внутри кости и царапины на прутьях.", [["НАЗАД", Callable()]])
	else:
		_dialog("Ты захлопываешь дверцу. Лязг гулко катится по комнате.", [["НАЗАД", Callable()]])

## Клетка снаружи: открыть / закрыть дверцу или забраться внутрь самому.
func _cage_menu() -> void:
	var opts: Array = [["ЗАКРЫТЬ ДВЕРЦУ" if cage_open else "ОТКРЫТЬ ДВЕРЦУ", func(): _toggle_cage()]]
	if cage_open:
		opts.append(["ЗАЛЕЗТЬ ВНУТРЬ", func(): action.enter("cage")])
	opts.append(["НАЗАД", Callable()])
	_dialog("Ржавая клетка. Внутри хватит места, чтобы спрятаться. Задвижка есть и изнутри.", opts)

func _build_cages() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# --- большая железная клетка с приоткрытой дверцей
	var cage := _solid("Cage", Vector3(11.3, 0.8, 1.2), Vector3(1.5, 1.6, 1.3), mats["metal"], false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_mesh(cage, _boxm(Vector3(0.09, 1.64, 0.09)), mats["metal"], Vector3(sx * 0.72, 0, sz * 0.62))
	for i in 8:
		var m: Material = mats["rust"] if i % 3 == 1 else mats["metal"]
		_mesh(cage, _boxm(Vector3(0.04, 1.6, 0.04)), m, Vector3(-0.6 + i * 0.17, 0, -0.62))
	for i in 6:
		var z := -0.5 + i * 0.2
		var ml: Material = mats["rust"] if i % 2 == 0 else mats["metal"]
		if i == 2:
			_mesh(cage, _boxm(Vector3(0.04, 1.6, 0.04)), ml, Vector3(-0.62, 0, z), Vector3(0, 0, -14))
		else:
			_mesh(cage, _boxm(Vector3(0.04, 1.6, 0.04)), ml, Vector3(-0.72, 0, z))
		if i == 3:
			_mesh(cage, _boxm(Vector3(0.04, 0.35, 0.04)), mats["rust"], Vector3(0.72, 0.62, z))
			_mesh(cage, _boxm(Vector3(0.04, 0.3, 0.04)), mats["rust"], Vector3(0.72, -0.63, z))
		else:
			_mesh(cage, _boxm(Vector3(0.04, 1.6, 0.04)), ml, Vector3(0.72, 0, z))
	for i in 4:
		var mf: Material = mats["rust"] if i == 1 else mats["metal"]
		_mesh(cage, _boxm(Vector3(0.04, 1.6, 0.04)), mf, Vector3(-0.6 + i * 0.17, 0, 0.62))
	# рамы: пол сплошной, крыша из реек, чтобы сверху было видно внутрь
	_mesh(cage, _boxm(Vector3(1.5, 0.06, 1.3)), mats["rust"], Vector3(0, -0.77, 0))
	for i in 3:
		_mesh(cage, _boxm(Vector3(1.5, 0.03, 0.04)), mats["rust"], Vector3(0, 0.79, -0.3 + i * 0.3))
	_mesh(cage, _boxm(Vector3(1.5, 0.06, 0.06)), mats["metal"], Vector3(0, 0.79, 0.62))
	_mesh(cage, _boxm(Vector3(1.5, 0.06, 0.06)), mats["metal"], Vector3(0, 0.79, -0.62))
	# дверца на петлях справа
	var door := Node3D.new()
	door.position = Vector3(0.72, 0, 0.62)
	door.rotation_degrees.y = 38.0
	cage.add_child(door)
	for i in 4:
		var md: Material = mats["rust"] if i == 2 else mats["metal"]
		_mesh(door, _boxm(Vector3(0.04, 1.5, 0.04)), md, Vector3(-0.14 - i * 0.16, 0, 0))
	_mesh(door, _boxm(Vector3(0.66, 0.06, 0.05)), mats["rust"], Vector3(-0.35, 0.72, 0))
	_mesh(door, _boxm(Vector3(0.66, 0.06, 0.05)), mats["rust"], Vector3(-0.35, -0.72, 0))
	_mesh(door, _boxm(Vector3(0.06, 1.5, 0.06)), mats["metal"], Vector3(-0.66, 0, 0))
	_mesh(door, _boxm(Vector3(0.1, 0.14, 0.06)), mats["lamp"], Vector3(-0.66, 0.0, 0.06))
	props["cage_door"] = door
	# внутри: матрас, одеяло, миска, кости, череп, кровь, засечки на стене, цепь с кандалой, ведро
	_mesh(cage, _boxm(Vector3(0.62, 0.1, 0.5)), mats["mattress"], Vector3(0.25, -0.69, -0.2), Vector3(0, 8, 0))
	_mesh(cage, _boxm(Vector3(0.42, 0.04, 0.36)), mats["sack"], Vector3(0.3, -0.62, -0.18), Vector3(0, -10, 6))
	_mesh(cage, LowPoly.frustum(7, 0.07, 0.1, 0.06), mats["metal_light"], Vector3(-0.45, -0.71, 0.3))
	_mesh(cage, _boxm(Vector3(0.22, 0.03, 0.03)), mats["white"], Vector3(-0.3, -0.73, -0.35), Vector3(0, 35, 0))
	_mesh(cage, _boxm(Vector3(0.18, 0.03, 0.03)), mats["white"], Vector3(-0.15, -0.73, -0.28), Vector3(0, -20, 0))
	_mesh(cage, LowPoly.sphere(Vector3(0.09, 0.08, 0.1), 6, 4), mats["white"], Vector3(-0.5, -0.69, -0.4))
	_mesh(cage, _boxm(Vector3(0.5, 0.012, 0.4)), mats["blood"], Vector3(-0.1, -0.745, 0.1), Vector3(0, 25, 0))
	_mesh(cage, _boxm(Vector3(0.3, 0.012, 0.25)), mats["blood"], Vector3(-0.45, -0.745, -0.1))
	for g in [0.1, -0.2]:
		for i in 4:
			_mesh(cage, _boxm(Vector3(0.015, 0.2, 0.01)), mats["black"], Vector3(0.2 + i * 0.06, g, -0.58))
		_mesh(cage, _boxm(Vector3(0.3, 0.015, 0.01)), mats["black"], Vector3(0.29, g, -0.575), Vector3(0, 0, 20))
	_mesh(cage, _boxm(Vector3(0.08, 0.1, 0.01)), mats["blood"], Vector3(-0.4, 0.3, -0.58))
	_mesh(cage, _boxm(Vector3(0.08, 0.1, 0.01)), mats["blood"], Vector3(-0.28, 0.25, -0.58))
	_mesh(cage, LowPoly.frustum(6, 0.05, 0.05, 0.03), mats["metal"], Vector3(-0.65, -0.68, -0.55), Vector3(90, 0, 0))
	for i in 3:
		_mesh(cage, _boxm(Vector3(0.05, 0.015, 0.03)), mats["metal"], Vector3(-0.6 + i * 0.1, -0.73, -0.5 + i * 0.05), Vector3(0, 20 * i, 0))
	_mesh(cage, LowPoly.frustum(7, 0.09, 0.12, 0.2), mats["rust"], Vector3(0.5, -0.64, 0.4))
	_interactable("cage", Vector3(11.3, 0, 2.4), 1.3)
	# солома и кровь у клетки
	for i in 9:
		_mesh(self, _boxm(Vector3(0.16, 0.012, 0.03)), mats["sack"], Vector3(rng.randf_range(9.9, 12.2), 0.012, rng.randf_range(2.1, 2.8)), Vector3(0, rng.randf_range(0, 180), 0))
	_mesh(self, _boxm(Vector3(0.8, 0.012, 0.6)), mats["blood"], Vector3(11.0, 0.009, 2.5), Vector3(0, 25, 0))
	# --- маленькая деревянная клетка-конура рядом
	var ken := _solid("Kennel", Vector3(9.2, 0.35, 1.5), Vector3(0.95, 0.7, 0.7), mats["wood"], false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_mesh(ken, _boxm(Vector3(0.07, 0.7, 0.07)), mats["wood"], Vector3(sx * 0.44, 0, sz * 0.31))
	_mesh(ken, _boxm(Vector3(0.95, 0.05, 0.7)), mats["wood_light"], Vector3(0, -0.33, 0))
	for i in 4:
		_mesh(ken, _boxm(Vector3(1.0, 0.05, 0.12)), mats["wood"], Vector3(0, 0.34, -0.27 + i * 0.18))
	for i in 7:
		if i == 3:
			continue
		_mesh(ken, _boxm(Vector3(0.05, 0.62, 0.04)), mats["wood_light"], Vector3(-0.36 + i * 0.12, 0, 0.32))
	for i in 5:
		_mesh(ken, _boxm(Vector3(0.95, 0.12, 0.03)), mats["wood"], Vector3(0, -0.24 + i * 0.14, -0.33))
	_mesh(ken, _boxm(Vector3(0.45, 0.04, 0.35)), mats["sack"], Vector3(0.05, -0.29, 0.0), Vector3(0, 15, 0))
	_mesh(ken, _boxm(Vector3(0.2, 0.03, 0.03)), mats["white"], Vector3(-0.2, -0.27, 0.1), Vector3(0, 40, 0))
	_interactable("kennel", Vector3(9.2, 0, 2.4), 1.2)


# ------------------------------------------------------------------ предметы в руках, бой, броски, скотч

func _girl_awake() -> bool:
	return not girl_dead and not girl_asleep

func _facing_vec() -> Vector3:
	return Vector3(sin(player.facing), 0.0, cos(player.facing))

func _sfx(id: String, vol: float = 0.0) -> void:
	if not sound_on:
		return
	if not _sfx_cache.has(id):
		_sfx_cache[id] = Sfx.make(id)
	var p := AudioStreamPlayer.new()
	p.stream = _sfx_cache[id]
	p.volume_db = vol
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _equip(id: String) -> void:
	if not _has(id):
		return
	if held_item == id:
		_unequip()
		return
	if not player.model.held.has(id):
		_toast("Это не удержать в руке.", 1.8)
		return
	held_item = id
	_hold_token += 1
	player.model.aim = 0.0
	if action != null:
		action.draw_anim(func(): if held_item == id: player.model.show_held(id))
	else:
		player.model.show_held(id)
	_sfx("click", -12.0)
	_toast("В руках: " + str(ITEM_NAMES.get(id, id)), 1.6)

func _unequip() -> void:
	if held_item == "":
		return
	held_item = ""
	_hold_token += 1
	player.model.show_held("")
	player.model.aim = 0.0

func _restore_held() -> void:
	player.model.show_held(held_item)
	player.model.aim = 0.0

## Пробел: применить предмет из рук. Оружие у девушки — только через выбор в диалоге, чтобы не убить случайно.
func _use_held() -> void:
	if input_locked() or _throwing or in_cutscene:
		return
	if held_item == "":
		if action != null:
			action.punch()
		return
	var id := held_item
	if not _has(id):
		_unequip()
		return
	var fighting: bool = monster_on and not monster_dead and _monster_dist() < 7.0
	var near_girl: bool = _girl_dist() < 2.3 and not girl_dead
	match id:
		"knife", "crowbar", "pistol":
			if near_girl and not fighting:
				_item_targets(id)
				return
			if id == "pistol":
				_shoot()
			else:
				_melee(id)
		"flashlight":
			_toggle_flashlight()
		"lighter":
			_light_up(15.0)
		_:
			_item_targets(id)

func _melee(id: String) -> void:
	if _atk_cd > 0.0:
		return
	var heavy: bool = id == "crowbar"
	var step: int = action.next_combo() if action != null else 1
	var fin: bool = step == 3
	# серия: два быстрых удара и тяжёлый третий с выпадом
	_atk_cd = (0.9 if heavy else 0.5) * (1.25 if fin else 0.7) / maxf(pdmg.limb_force("arm_r"), 0.35)
	var m = player.model
	_sfx("whoosh" if (heavy or fin) else "slash", -6.0)
	_hold_token += 1
	var tw := create_tween()
	if step == 2:
		# обратный удар: рука идёт сверху вниз наискось
		tw.tween_property(m, "swing", 1.1, 0.07 if not heavy else 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "swing", -0.9, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	elif fin:
		tw.tween_property(m, "swing", -1.0, 0.22 if heavy else 0.14).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func(): if action != null: action.lunge(0.12))
		tw.tween_property(m, "swing", 1.25, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(m, "swing", -0.6, 0.2 if heavy else 0.08)
		tw.tween_property(m, "swing", 1.0, 0.1)
	tw.tween_callback(func(): _melee_hit(id, fin))
	tw.tween_interval(0.08)
	tw.tween_property(m, "swing", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _melee_hit(id: String, fin: bool = false) -> void:
	var heavy: bool = id == "crowbar"
	var bonus := 1 if fin else 0
	var f := _facing_vec()
	var origin: Vector3 = player.global_position
	var reach := 1.9 if heavy else 1.6
	shake = maxf(shake, 0.3 if heavy else 0.12)
	if monster_on and not monster_dead:
		var to: Vector3 = monster.global_position - origin
		to.y = 0.0
		if to.length() < reach and (to.length() < 0.4 or f.dot(to.normalized()) > 0.25):
			_sfx("hit", -4.0)
			if action != null:
				action.on_hit(f, 1.6 if (heavy or fin) else 1.0)
			if heavy:
				monster_stun = maxf(monster_stun, 1.4)
				_damage_monster(2 + bonus, "Ломик с хрустом бьёт по рёбрам.")
			else:
				if fin:
					monster_stun = maxf(monster_stun, 0.8)
				_damage_monster(1 + bonus, "Нож вспарывает шкуру." if not fin else "Удар с разворота вгоняет нож по рукоять.")
			blood.spatter(monster.global_position + Vector3(0, 1.1, 0), 6, f, 0.8)
			return
	for r in rats:
		if r.dead:
			continue
		var rt: Vector3 = r.global_position - origin
		rt.y = 0.0
		if rt.length() < reach * 0.85 and (rt.length() < 0.35 or f.dot(rt.normalized()) > 0.3):
			_sfx("hit", -6.0)
			if action != null:
				action.on_hit(f, 1.2 if (heavy or fin) else 0.7)
			_hit_rat(r, (2 if heavy else 1) + bonus, f, 3.5 if heavy else 2.0)
			return
	_bump_nearby(origin + f * 1.1, 1.0, 1.4 if heavy else 0.8)

func _shoot() -> void:
	if _atk_cd > 0.0:
		return
	if ammo <= 0:
		_atk_cd = 0.4
		_sfx("click", -4.0)
		_toast("Щёлк. Патронов нет.", 1.6)
		return
	_atk_cd = 0.6
	ammo -= 1
	_sfx("shot", -2.0)
	shake = maxf(shake, 0.45)
	player.model.kick = 1.0
	var f := _facing_vec()
	# боль трясёт руки — пуля уходит в сторону
	f = f.rotated(Vector3.UP, randf_range(-1.0, 1.0) * pdmg.hand_shake() * 0.35)
	var from: Vector3 = player.global_position + Vector3(0.0, 1.0, 0.0) + f * 0.4
	_muzzle_flash(from + f * 0.3)
	var q := PhysicsRayQueryParameters3D.create(from, from + f * 14.0)
	q.exclude = [player.get_rid()]
	var res: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	var wall_d := 14.0
	var wall_pos: Vector3 = from + f * 14.0
	if not res.is_empty():
		wall_pos = res["position"]
		wall_d = from.distance_to(wall_pos)
	if action != null:
		action.shot_fx(from, wall_pos, f)
	# пуля рядом с девушкой: она не умирает, но пугается
	if not girl_dead:
		var gv: Vector3 = Vector3(girl.global_position.x, from.y, girl.global_position.z) - from
		var gp := gv.dot(f)
		if gp > 0.0 and gp < wall_d and (gv - f * gp).length() < 0.5:
			if girl_asleep:
				_toast("Пуля проходит рядом. Она не просыпается.", 2.2)
			else:
				_change_trust(-25)
				girl.set_emotion("fear")
				_toast("Пуля свистит у самой её головы. Она кричит.", 2.4)
	if monster_on and not monster_dead:
		var mv: Vector3 = Vector3(monster.global_position.x, from.y, monster.global_position.z) - from
		var mp := mv.dot(f)
		if mp > 0.0 and mp < wall_d + 0.9 and (mv - f * mp).length() < 0.75:
			monster_stun = maxf(monster_stun, 1.2)
			blood.spatter(monster.global_position + Vector3(0, 1.1, 0), 7, f, 1.2)
			_damage_monster(2, "Выстрел попадает в тварь.")
			return
	var best = null
	var best_d := wall_d
	for r in rats:
		if r.dead:
			continue
		var rv: Vector3 = Vector3(r.global_position.x, from.y, r.global_position.z) - from
		var rp := rv.dot(f)
		if rp > 0.0 and rp < best_d and (rv - f * rp).length() < 0.35:
			best = r
			best_d = rp
	if best != null:
		_hit_rat(best, 3, f, 4.0)
		return
	_bump_nearby(wall_pos, 1.2, 1.2)

func _muzzle_flash(pos: Vector3) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.45)
	l.light_energy = 3.0
	l.omni_range = 5.0
	l.position = pos
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 0.0, 0.1)
	tw.tween_callback(l.queue_free)

func _throw_held() -> void:
	if held_item != "":
		_throw_item(held_item)

func _throw_item(id: String) -> void:
	if input_locked() or _throwing or in_cutscene or not _has(id):
		return
	_throwing = true
	var m = player.model
	m.show_held(id)
	m.throw_t = 0.0
	var tw := create_tween()
	tw.tween_interval(0.28)
	tw.tween_property(m, "throw_t", 0.7, 0.1)
	tw.tween_callback(func(): _launch_item(id))
	tw.tween_property(m, "throw_t", 1.0, 0.06)
	tw.tween_interval(0.22)
	tw.tween_callback(_finish_throw)

func _finish_throw() -> void:
	player.model.throw_t = -1.0
	_throwing = false
	_restore_held()

func _launch_item(id: String) -> void:
	if not _has(id):
		return
	var f := _facing_vec()
	var node: Node3D = ItemModels.make(id, mats)
	node.position = player.global_position + Vector3(0.0, 1.0, 0.0) + f * 0.5
	add_child(node)
	inv.erase(id)
	if held_item == id:
		held_item = ""
	if id == "flashlight" and flashlight_on:
		_toggle_flashlight()
	var heavy: bool = id in THROW_HEAVY
	var speed := 6.5 if heavy else 8.5
	projectiles.append({"node": node, "id": id, "vel": f * speed + Vector3(0.0, 2.4, 0.0),
		"spin": Vector3(randf_range(-9.0, 9.0), randf_range(-9.0, 9.0), randf_range(-9.0, 9.0)),
		"bounces": 0, "age": 0.0, "girl_hit": false})
	_sfx("whoosh", -8.0)

func _update_projectiles(delta: float) -> void:
	for pr in projectiles.duplicate():
		var n: Node3D = pr["node"]
		if not is_instance_valid(n):
			projectiles.erase(pr)
			continue
		var vel: Vector3 = pr["vel"]
		pr["age"] = float(pr["age"]) + delta
		vel.y -= 14.0 * delta
		var from: Vector3 = n.position
		var to: Vector3 = from + vel * delta
		var settle := false
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.exclude = [player.get_rid()]
		var res: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
		if not res.is_empty():
			var nrm: Vector3 = res["normal"]
			to = (res["position"] as Vector3) + nrm * 0.04
			if res["collider"] == monster and monster_on and not monster_dead:
				_projectile_hits_monster(str(pr["id"]))
			vel = vel.bounce(nrm) * 0.38
			pr["bounces"] = int(pr["bounces"]) + 1
			_sfx("hit", -14.0)
			if nrm.y > 0.6 and vel.length() < 1.6:
				settle = true
		if to.y < 0.04:
			to.y = 0.04
			vel = Vector3(vel.x * 0.5, absf(vel.y) * 0.3, vel.z * 0.5)
			pr["bounces"] = int(pr["bounces"]) + 1
			if vel.length() < 1.3:
				settle = true
		if not girl_dead and not bool(pr["girl_hit"]):
			var gp: Vector3 = girl.global_position
			if Vector2(to.x - gp.x, to.z - gp.z).length() < 0.4 and to.y > 0.1 and to.y < 1.6:
				pr["girl_hit"] = true
				_projectile_hits_girl()
				vel = Vector3(-vel.x, 1.2, -vel.z) * 0.3
		pr["vel"] = vel
		n.position = to
		var spin: Vector3 = pr["spin"]
		n.rotation += spin * delta * clampf(vel.length() / 8.0, 0.0, 1.0)
		if settle or int(pr["bounces"]) >= 4 or float(pr["age"]) > 5.0:
			_land_item(pr)

func _projectile_hits_monster(id: String) -> void:
	var dmg := 2 if (id in THROW_HEAVY or id == "knife") else 1
	monster_stun = maxf(monster_stun, 1.0 if id in THROW_HEAVY else 0.5)
	_damage_monster(dmg, "Брошенный предмет бьёт тварь.")

func _projectile_hits_girl() -> void:
	_sfx("hit", -6.0)
	if girl_asleep:
		_toast("Предмет падает рядом с ней. Она не шевелится.", 2.0)
		return
	_change_trust(-12)
	girl.set_emotion("fear")
	_toast("Предмет попадает в неё. Она вскрикивает.", 2.2)

func _land_item(pr: Dictionary) -> void:
	projectiles.erase(pr)
	var n: Node3D = pr["node"]
	var id: String = str(pr["id"])
	var p: Vector3 = n.position
	_bump_nearby(p, 1.4, 0.6)
	if id == "poison":
		_sfx("glass", -4.0)
		n.queue_free()
		_toast("Склянка разбивается. Чёрная лужа растекается по полу.", 2.4)
		return
	n.position = Vector3(p.x, 0.05, p.z)
	n.rotation = Vector3(0.0, n.rotation.y, 0.0)
	_sfx("thump", -10.0)
	thrown_n += 1
	var tid := "thrown_%d" % thrown_n
	thrown[tid] = {"id": id, "node": n}
	_interactable(tid, Vector3(p.x, 0.0, p.z), 1.25)

func _pickup_thrown(tid: String) -> void:
	if not thrown.has(tid):
		return
	var d: Dictionary = thrown[tid]
	var id: String = str(d["id"])
	inv[id] = true
	var n: Node3D = d["node"]
	if is_instance_valid(n):
		n.queue_free()
	thrown.erase(tid)
	for it in interactables.duplicate():
		if str(it["id"]) == tid:
			interactables.erase(it)
	_sfx("click", -10.0)
	_toast("Подобрано: " + _item_title(id), 1.6)

# --- скотч

func _gag_girl() -> void:
	girl_gagged = true
	girl.set_gag(true)
	_sfx("rip", -4.0)
	if _girl_awake():
		girl.set_emotion("fear")
		_change_trust(-12)
		_gdialog("Ты прижимаешь липкую ленту к её губам. Она мотает головой и мычит. Слов больше нет.", [["ОТОЙТИ", Callable()]])
	else:
		_gdialog("Ты заклеиваешь ей рот. Она не реагирует.", [["ОТОЙТИ", Callable()]])

func _ungag_girl() -> void:
	girl_gagged = false
	girl.set_gag(false)
	_sfx("rip", -6.0)
	if _girl_awake():
		girl.set_emotion("sad")
		_change_trust(3)
		_gdialog("Ты осторожно отлепляешь скотч. Она жадно глотает воздух и отворачивается.", [["ОТОЙТИ", Callable()]])
	else:
		_gdialog("Скотч снят.", [["ОТОЙТИ", Callable()]])

func _tape_wrists() -> void:
	girl_taped = true
	girl.taped = true
	_sfx("rip", -4.0)
	if _girl_awake():
		girl.set_emotion("fear")
		_change_trust(-15)
		_gdialog("Несколько витков скотча на запястьях. Она идёт за тобой, но медленнее и тише.", [["ИДЁМ", Callable()]])
	else:
		_gdialog("Запястья замотаны скотчем.", [["ОТОЙТИ", Callable()]])

func _untape_wrists() -> void:
	girl_taped = false
	girl.taped = false
	_sfx("rip", -6.0)
	if _girl_awake():
		girl.set_emotion("neutral")
		_change_trust(5)
		_gdialog("Ты разрезаешь и снимаешь скотч с запястий. Она растирает красные следы.", [["ИДЁМ", Callable()]])
	else:
		_gdialog("Скотч с рук снят.", [["ОТОЙТИ", Callable()]])
