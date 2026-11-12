extends Node
## Система повреждений, перенесённая из Casualties: Unknown (Assembly-CSharp.dll:
## Body / Limb / LimbCondition / Tourniquet / SplintLimb / Painkillers / Moodle / WoundView).
## 7 конечностей, у каждой: кожа, мышцы, кровотечение, боль, перелом, вывих, инфекция, отсечение.
## Тело: объём крови (литры), пульс, сознание, шок, адреналин, фибрилляция, сепсис.
## Лечение: бинт (останавливает кровь), аптечка (бинтует всё + дезинфекция), шина, турникет, обезболивающее.

signal bled(amount: float)          # сколько крови вытекло за кадр — для луж и звука капель
signal heart_pulse(rate: float)     # удар сердца — синхронизирует рост луж
signal expired(cause: String)       # смерть от кровопотери / сердца / сепсиса
signal fainted()                    # потеря сознания
signal collapsed()                  # боль > 99: тело падает (ragdoll из CU)

class Limb extends RefCounted:
	var id: String = ""
	var name: String = ""
	var skin: float = 100.0        # здоровье кожи/мягких тканей
	var muscle: float = 100.0      # мышцы
	var bleed: float = 0.0         # скорость кровотечения (л/мин)
	var pain: float = 0.0         # 0..100 итоговая боль конечности (считается в tick)
	var acute: float = 0.0        # острая боль от свежего удара, спадает со временем
	var dislocated: bool = false
	var broken: bool = false
	var splinted: bool = false
	var infected: bool = false
	var infection: float = 0.0    # 0..1, выше 1 — сепсис
	var dismembered: bool = false
	var tourniquet: bool = false   # перетянут — не кровит ниже жгута
	var bandaged: bool = false
	var is_vital: bool = false
	var is_head: bool = false
	var is_leg: bool = false
	var is_arm: bool = false

	func condition() -> String:
		var parts: Array = []
		if dismembered:
			return "ОТСЕЧЕНА"
		if broken:
			parts.append("ПЕРЕЛОМ" + (" (ШИНА)" if splinted else ""))
		if dislocated:
			parts.append("ВЫВИХ")
		if bleed > 0.05 and not tourniquet:
			parts.append("КРОВИТ")
		if infected:
			parts.append("ИНФЕКЦИЯ %d%%" % int(infection * 100))
		if skin < 40:
			parts.append("РАНЫ")
		return " ".join(parts) if not parts.is_empty() else "ЦЕЛА"

	func short() -> String:
		if dismembered:
			return "—"
		return "%d/%d" % [int(skin), int(muscle)]

const LIMB_ORDER := ["head", "torso_up", "torso_down", "arm_l", "arm_r", "leg_l", "leg_r"]
const LIMB_NAMES := {
	"head": "ГОЛОВА", "torso_up": "ГРУДЬ", "torso_down": "ЖИВОТ",
	"arm_l": "ЛЕВАЯ РУКА", "arm_r": "ПРАВАЯ РУКА",
	"leg_l": "ЛЕВАЯ НОГА", "leg_r": "ПРАВАЯ НОГА",
}

var limbs: Dictionary = {}
var blood_volume: float = 5.0      # литров
var max_blood: float = 5.0
var heart_rate: float = 72.0
var consciousness: float = 1.0
var painkiller: float = 0.0       # обезболивающее в крови
var adrenaline: float = 0.0       # 0..100, падает на 1.7/с (CU: adrenaline)
var cur_adrenaline: float = 0.0   # тянется к adrenaline со скоростью 5/с (CU: curAdrenaline)
var pain_shock: float = 0.0       # 0..1, при 0.66 — потеря сознания от боли
var resilience: float = 10.0      # навык стойкости (RES), растёт от перенесённой боли
var res_xp: float = 0.0
var happiness: float = 0.0        # -100..100, настроение
var trauma: float = 0.0           # 0..100, психотравма
var resp_rate: float = 16.0       # частота дыхания
var _collapse_cd: float = 0.0
var shock: float = 0.0
var fibrillation: float = 0.0     # 0..1, 1 = остановка сердца
var sepsis: float = 0.0
var dead: bool = false
var death_cause: String = ""
var is_girl: bool = false
var _faint_done: bool = false
var _pulse_t: float = 0.0
var _regen_t: float = 0.0

func _init(girl: bool = false) -> void:
	is_girl = girl
	for id in LIMB_ORDER:
		var l := Limb.new()
		l.id = id
		l.name = str(LIMB_NAMES[id])
		l.is_head = id == "head"
		l.is_vital = id in ["head", "torso_up", "torso_down"]
		l.is_leg = id.begins_with("leg")
		l.is_arm = id.begins_with("arm")
		limbs[id] = l

func limb(id: String) -> Limb:
	return limbs.get(id) as Limb

## Основной урон. Типы: cut (порез — кровь), blunt (удар — перелом/вывих), pierce (прокол), bullet.
func damage(id: String, amount: float, type: String = "cut") -> void:
	if dead:
		return
	var l: Limb = limb(id)
	if l == null or l.dismembered:
		return
	var soften: float = 1.0 - painkiller * 0.3
	l.skin = maxf(0.0, l.skin - amount * 1.1 * soften)
	l.muscle = maxf(0.0, l.muscle - amount * 0.6 * soften)
	l.acute = minf(100.0, l.acute + amount * (1.6 if l.is_head else 1.0))
	l.pain = minf(100.0, l.pain + amount * (1.6 if l.is_head else 1.0))
	adrenaline = minf(100.0, adrenaline + amount * 0.9)
	match type:
		"cut":
			l.bleed += amount * 0.011
		"pierce":
			l.bleed += amount * 0.02
			l.infection = maxf(l.infection, 0.05)
		"bullet":
			l.bleed += amount * 0.03
			l.infection = maxf(l.infection, 0.08)
		"blunt":
			if l.skin < 55 and randf() < 0.5 and not l.broken:
				l.broken = true
			elif l.skin < 70 and randf() < 0.35:
				l.dislocated = true
	if l.is_head and l.skin <= 0:
		_expire("head")
	if l.is_vital and l.skin <= 0 and l.muscle <= 0:
		_expire("trauma")

## Отсечение конечности — фонтан и мгновенная большая потеря крови.
func dismember(id: String) -> void:
	var l: Limb = limb(id)
	if l == null or l.dismembered or l.is_vital:
		return
	l.dismembered = true
	l.bleed = 0.45
	l.skin = 0.0
	l.muscle = 0.0
	l.pain = 100.0
	l.splinted = false
	l.acute = 100.0
	blood_volume -= 0.35

## Перерезанное горло: лавина крови, быстрая смерть.
func throat_cut() -> void:
	var h: Limb = limb("head")
	h.skin = 0.0
	h.bleed = 0.9
	h.pain = 100.0
	h.acute = 100.0
	shock = 1.0
	consciousness = 0.4

## Лечение.
func bandage(id: String) -> void:
	var l: Limb = limb(id)
	if l == null:
		return
	l.bleed = 0.0
	l.bandaged = true
	l.acute = maxf(0.0, l.acute - 15.0)

func heal_all() -> void:
	for id in LIMB_ORDER:
		var l: Limb = limb(id)
		if l.dismembered:
			continue
		l.bleed = 0.0
		l.bandaged = true
		l.skin = minf(100.0, l.skin + 35.0)
		l.muscle = minf(100.0, l.muscle + 25.0)
		l.infected = false
		l.infection = 0.0
		l.acute = maxf(0.0, l.acute - 40.0)
	sepsis = 0.0

func splint(id: String) -> void:
	var l: Limb = limb(id)
	if l != null:
		l.splinted = true
		l.acute = maxf(0.0, l.acute - 20.0)

func tourniquet(id: String) -> void:
	var l: Limb = limb(id)
	if l != null and not l.is_vital:
		l.tourniquet = true
		l.acute = minf(100.0, l.acute + 10.0)

func painkill(amount: float = 1.0) -> void:
	painkiller = minf(1.0, painkiller + amount)
	for id in LIMB_ORDER:
		var l: Limb = limb(id)
		l.acute = maxf(0.0, l.acute - 30.0 * amount)

## Сводные значения.
func total_bleed() -> float:
	var t := 0.0
	for id in LIMB_ORDER:
		var l: Limb = limb(id)
		if l.dismembered and l.tourniquet:
			continue
		if l.tourniquet and not l.is_vital:
			continue
		t += l.bleed
	return t

## Боль конечности (CU: limb pain): острая боль + постоянная от состояния тканей.
func _limb_chronic(l: Limb) -> float:
	if l.dismembered:
		return 70.0 if not l.tourniquet else 55.0
	var c := (100.0 - l.skin) * 0.3 + (100.0 - l.muscle) * 0.25
	if l.broken:
		c += 22.0 if l.splinted else 48.0
	if l.dislocated:
		c += 32.0
	c += l.infection * 25.0
	if l.tourniquet:
		c += 15.0
	if l.bandaged:
		c *= 0.8
	return c

func highest_limb_pain() -> float:
	var m := 0.0
	for id in LIMB_ORDER:
		m = maxf(m, (limb(id) as Limb).pain)
	return m

## Общая боль (CU: TotalPain = (HighestLimbPain - 0.5*curAdrenaline) * (1 - 0.025*(RES-10))).
## Обезболивающее дополнительно глушит до 45 единиц. Может быть выше 100 при низкой стойкости.
func total_pain() -> float:
	var tp := (highest_limb_pain() - 0.5 * cur_adrenaline) * (1.0 - 0.025 * (resilience - 10.0))
	tp -= painkiller * 45.0
	return clampf(tp, 0.0, 150.0)

## Совместимость со старым кодом.
func average_pain() -> float:
	return total_pain()

## Сила конечности (CU: Limb Force). 1 = норма. Падает от боли, адреналин компенсирует.
func limb_force(id: String) -> float:
	var l: Limb = limb(id)
	if l == null or l.dismembered:
		return 0.0
	var red := maxf(0.7 * l.pain - 0.5 * cur_adrenaline, total_pain() * 0.9 - 0.5 * cur_adrenaline)
	return clampf(1.0 - red / 100.0, 0.15, 1.0)

## Дрожь рук от боли (CU: hand shake в мини-играх). 0..1, стойкость уменьшает.
func hand_shake() -> float:
	return clampf(total_pain() / 100.0 * (1.0 - (resilience - 10.0) * 0.06), 0.0, 1.0)

## Итоговое настроение с учётом боли (CU: 10% боли вычитается из настроения).
func mood() -> float:
	return clampf(happiness - total_pain() * 0.1 - trauma * 0.3, -100.0, 100.0)

func walk_mult() -> float:
	var m := 1.0
	for id in ["leg_l", "leg_r"]:
		var l: Limb = limb(id)
		if l.dismembered:
			m *= 0.35
		elif l.broken:
			m *= 0.55
		elif l.dislocated:
			m *= 0.8
	# CU: «Агония — движение нарушено», сильная боль замедляет
	var tp := total_pain()
	if tp > 80.0:
		m *= 0.55
	elif tp > 55.0:
		m *= 0.8
	m *= lerpf(0.6, 1.0, clampf(consciousness / 0.7, 0.0, 1.0))
	return m

func arm_ok() -> bool:
	return not ((limb("arm_r") as Limb).dismembered or (limb("arm_l") as Limb).dismembered)

## Состояния (moodles из CU). Каждое: {id, icon, name, desc, lvl 1..4, good}.
## good = положительное (квадратная рамка), иначе круглая.
func _md(id: String, icon: String, nm: String, desc: String, lvl: int, good: bool = false) -> Dictionary:
	return {"id": id, "icon": icon, "name": nm, "desc": desc, "lvl": lvl, "good": good}

func moodle_list() -> Array:
	if dead:
		return []
	var out: Array = []
	# боль (CU: Discomfort / Pain / Severe pain / Agony)
	var tp := total_pain()
	if tp > 80.0:
		out.append(_md("pain", "pain", "АГОНИЯ", "Невыносимая боль. Движения нарушены. Настроение быстро падает.", 4))
	elif tp > 55.0:
		out.append(_md("pain", "pain", "СИЛЬНАЯ БОЛЬ", "Разум затуманен болью, ты в полусознании. Настроение падает.", 3))
	elif tp > 30.0:
		out.append(_md("pain", "pain", "БОЛЬ", "Болит ощутимо. Настроение медленно портится.", 2))
	elif tp > 10.0:
		out.append(_md("pain", "pain", "ДИСКОМФОРТ", "Лёгкая боль.", 1))
	if pain_shock > 0.3:
		out.append(_md("shock", "shock", "БОЛЕВОЙ ШОК", "Шок от агонии. Ещё немного, и ты потеряешь сознание.", 4))
	# кровотечение
	var tb := total_bleed()
	if tb > 0.35:
		out.append(_md("bleed", "drop", "КРОВОИЗЛИЯНИЕ", "Кровь хлещет. Перевяжи рану немедленно.", 4))
	elif tb > 0.18:
		out.append(_md("bleed", "drop", "СИЛЬНОЕ КРОВОТЕЧЕНИЕ", "Кровь идёт быстро. Нужен бинт.", 3))
	elif tb > 0.08:
		out.append(_md("bleed", "drop", "КРОВОТЕЧЕНИЕ", "Рана кровит.", 2))
	elif tb > 0.02:
		out.append(_md("bleed", "drop", "ЛЁГКОЕ КРОВОТЕЧЕНИЕ", "Немного сочится кровь.", 1))
	# кровопотеря
	var frac := blood_volume / max_blood
	if frac < 0.45:
		out.append(_md("blood", "drop_low", "КРИТИЧЕСКАЯ КРОВОПОТЕРЯ", "Сердце не справляется. Смерть близко.", 4))
	elif frac < 0.6:
		out.append(_md("blood", "drop_low", "ТЯЖЁЛАЯ КРОВОПОТЕРЯ", "Холодно, темнеет в глазах.", 3))
	elif frac < 0.75:
		out.append(_md("blood", "drop_low", "КРОВОПОТЕРЯ", "Слабость и головокружение.", 2))
	elif frac < 0.9:
		out.append(_md("blood", "drop_low", "ЛЁГКАЯ КРОВОПОТЕРЯ", "Потеряно немного крови.", 1))
	# сердце
	if fibrillation > 0.05:
		out.append(_md("heart", "heart", "ФИБРИЛЛЯЦИЯ", "Сердце сбивается с ритма. Без крови оно остановится.", 4))
	elif heart_rate > 140.0:
		out.append(_md("heart", "heart", "ТАХИКАРДИЯ", "Пульс %d. Сердце колотится." % int(heart_rate), 3))
	elif heart_rate > 110.0:
		out.append(_md("heart", "heart", "УЧАЩЁННЫЙ ПУЛЬС", "Пульс %d." % int(heart_rate), 2))
	# сознание
	if consciousness < 0.35:
		out.append(_md("con", "eye", "НА ГРАНИ", "Ты вот-вот отключишься.", 4))
	elif consciousness < 0.6:
		out.append(_md("con", "eye", "ПОЛУОБМОРОК", "Всё плывёт.", 3))
	elif consciousness < 0.85:
		out.append(_md("con", "eye", "ПОМУТНЕНИЕ", "Мысли путаются.", 2))
	# переломы / вывихи / отсечение
	var nb := 0
	var nb_free := 0
	var nd := 0
	var lost := ""
	for id in LIMB_ORDER:
		var l: Limb = limb(id)
		if l.dismembered:
			lost = l.name
		if l.broken:
			nb += 1
			if not l.splinted:
				nb_free += 1
		if l.dislocated:
			nd += 1
	if lost != "":
		out.append(_md("lost", "bone", "ПОТЕРЯ КОНЕЧНОСТИ", lost + " отсутствует.", 4))
	if nb > 0:
		out.append(_md("frac", "bone_broken", "ПЕРЕЛОМ", ("Наложи шину (бинт)." if nb_free > 0 else "Кость зафиксирована шиной."), 3 if nb_free > 0 else 2))
	if nd > 0:
		out.append(_md("disl", "bone", "ВЫВИХ", "Сустав выбит. Конечность работает хуже.", 2))
	# инфекция / сепсис
	var inf := 0.0
	for id in LIMB_ORDER:
		inf = maxf(inf, (limb(id) as Limb).infection)
	if sepsis > 0.0:
		out.append(_md("inf", "germ", "СЕПСИС", "Инфекция в крови. Нужна аптечка.", 4))
	elif inf > 0.6:
		out.append(_md("inf", "germ", "СИЛЬНАЯ ИНФЕКЦИЯ", "Рана гноится, жар.", 3))
	elif inf > 0.3:
		out.append(_md("inf", "germ", "ИНФЕКЦИЯ", "Рана воспалена.", 2))
	elif inf > 0.1:
		out.append(_md("inf", "germ", "ЗАРАЖЕНИЕ", "В рану попала грязь.", 1))
	# психика (CU: Scared / Traumatized / Shell shocked; mood)
	if trauma > 80.0:
		out.append(_md("trauma", "storm", "КОНТУЗИЯ", "Ужас. Беспомощность. Ни слова не выдавить.", 4))
	elif trauma > 45.0:
		out.append(_md("trauma", "storm", "ТРАВМИРОВАН", "Перед глазами всплывает пережитое. Хочется выбраться любой ценой.", 3))
	elif trauma > 25.0:
		out.append(_md("trauma", "storm", "НАПУГАН", "Руки дрожат. Не хочется пережить это снова.", 2))
	var md := mood()
	if md <= -75.0:
		out.append(_md("mood", "face_sad", "ОТЧАЯНИЕ", "Каково это — знать, что не выберешься?", 4))
	elif md < -50.0:
		out.append(_md("mood", "face_sad", "ДЕПРЕССИЯ", "Ничего не хочется.", 3))
	elif md < -30.0:
		out.append(_md("mood", "face_sad", "МРАЧНОСТЬ", "Всё совсем не радует.", 2))
	elif md < -10.0:
		out.append(_md("mood", "face_sad", "ПОДАВЛЕН", "Начинаешь осознавать, куда попал.", 1))
	elif md > 10.0:
		out.append(_md("mood", "face_happy", "ДОВОЛЕН", "Держишься.", 1, true))
	# положительные
	if adrenaline > 20.0:
		out.append(_md("adr", "bolt", "АДРЕНАЛИН", "Боль притуплена. Ты настороже.", 2, true))
	if painkiller > 0.1:
		out.append(_md("pk", "pill", "ОБЕЗБОЛИВАЮЩЕЕ", "Боль заглушена лекарством.", 2, true))
	var band := false
	for id in LIMB_ORDER:
		if (limb(id) as Limb).bandaged:
			band = true
	if band:
		out.append(_md("band", "cross", "ПЕРЕВЯЗАН", "Раны перевязаны, заживают быстрее.", 1, true))
	return out

## Старый формат для совместимости: [имя, сила, тревога].
func moodles() -> Array:
	var out: Array = []
	for m in moodle_list():
		out.append([m["name"], float(m["lvl"]) / 4.0, int(m["lvl"]) >= 3])
	return out

## Текстовый осмотр ран (порт WoundView).
func report() -> String:
	var lines: Array = []
	lines.append("КРОВЬ: %.1f/%.1f л   ПУЛЬС: %d   СОЗНАНИЕ: %d%%" % [blood_volume, max_blood, int(heart_rate), int(consciousness * 100)])
	lines.append("БОЛЬ: %d   ШОК: %d%%   АДРЕНАЛИН: %d   СТОЙКОСТЬ: %.1f" % [int(total_pain()), int(pain_shock * 100), int(cur_adrenaline), resilience])
	if dead:
		lines.append("ТЫ МЁРТВ.")
		return "\n".join(lines)
	for id in LIMB_ORDER:
		var l: Limb = limb(id)
		var tag := l.condition()
		lines.append("%s: %s  боль %d %s" % [l.name, l.short(), int(l.pain), ("[" + tag + "]") if tag != "ЦЕЛА" else ""])
	return "\n".join(lines)

## Симуляция кровообращения и боли (порт Body.HandleCirculation + Pain из CU, упрощённо).
func tick(delta: float) -> void:
	if dead:
		return
	var tb := total_bleed()
	blood_volume = maxf(0.0, blood_volume - tb * delta / 60.0)
	if tb > 0.001:
		bled.emit(tb * delta / 60.0)
	# адреналин: adrenaline падает на 1.7/с, curAdrenaline тянется к нему со скоростью 5/с
	adrenaline = maxf(0.0, adrenaline - 1.7 * delta)
	cur_adrenaline = move_toward(cur_adrenaline, adrenaline, 5.0 * delta)
	painkiller = maxf(0.0, painkiller - delta * 0.012)
	# боль конечностей: острая спадает, постоянная — от состояния тканей
	for id in LIMB_ORDER:
		var l: Limb = limb(id)
		l.acute = maxf(0.0, l.acute - delta * (1.2 + l.acute * 0.02))
		l.pain = clampf(_limb_chronic(l) + l.acute, 0.0, 100.0)
	var tp := total_pain()
	# болевой шок: >75 копится на 3.33%/с, ниже — спадает
	if tp > 75.0:
		pain_shock = minf(1.0, pain_shock + 0.0333 * delta)
	else:
		pain_shock = maxf(0.0, pain_shock - 0.0333 * delta)
	# падение от боли (ragdoll) при >99
	_collapse_cd = maxf(0.0, _collapse_cd - delta)
	if tp > 99.0 and _collapse_cd <= 0.0:
		_collapse_cd = 10.0
		collapsed.emit()
	# пульс: компенсация кровопотери + боль + адреналин (до +55)
	var frac := blood_volume / max_blood
	heart_rate = 72.0 + (1.0 - frac) * 75.0 + tp * 0.6 + minf(cur_adrenaline * 0.55, 55.0)
	resp_rate = 16.0 + tp * 0.0625 + adrenaline / 5.0
	if fibrillation > 0.0:
		heart_rate = lerpf(30.0, 8.0, fibrillation)
	# фибрилляция при тяжёлой кровопотере
	if frac < 0.42:
		fibrillation = minf(1.0, fibrillation + delta * (0.55 - frac) * 0.9)
	if fibrillation >= 1.0:
		_expire("heart")
		return
	# сознание: кровопотеря и шок; боль ограничивает максимум (CU: 150 - TotalPain)
	var cap := clampf((150.0 - tp) / 100.0, 0.0, 1.0)
	var target := clampf(minf(frac * 1.15 - shock * 0.3, cap), 0.0, 1.0)
	if pain_shock >= 0.66:
		target = 0.0
	if target < consciousness:
		consciousness = maxf(target, consciousness - delta * (0.6 if pain_shock >= 0.66 else 0.25))
	else:
		consciousness = minf(target, consciousness + delta * 0.05)
	if consciousness < 0.3 and not _faint_done:
		_faint_done = true
		pain_shock = 0.0
		fainted.emit()
	shock = maxf(0.0, shock - delta * 0.05)
	# психика: боль >50 травмирует и портит настроение, ниже — травма проходит
	if tp > 50.0:
		trauma = minf(100.0, trauma + 0.0034 * tp * delta)
		happiness = maxf(-100.0, happiness - 0.001 * tp * delta)
	else:
		trauma = maxf(0.0, trauma - delta / 35.0)
		happiness = move_toward(happiness, 0.0, delta * 0.02)
	# стойкость: опыт = 1.25% боли в секунду
	res_xp += 0.0125 * tp * delta
	resilience = minf(20.0, 10.0 + res_xp / 400.0)
	# инфекция растёт в ранах, бинт и антисептик замедляют
	for id in LIMB_ORDER:
		var l: Limb = limb(id)
		if l.infected and not l.dismembered:
			var speed := 0.006 * delta * (1.0 if not l.bandaged else 0.35)
			l.infection += speed
			if l.infection > 1.0:
				sepsis = minf(1.0, sepsis + delta * 0.02)
		elif l.infection > 0.0 and not l.bandaged and l.skin < 80.0:
			# открытая грязная рана воспаляется
			if l.infection > 0.04:
				l.infected = true
	if sepsis >= 1.0:
		_expire("sepsis")
		return
	# медленная регенерация целых тканей
	_regen_t += delta
	if _regen_t > 30.0:
		_regen_t = 0.0
		for id in LIMB_ORDER:
			var l: Limb = limb(id)
			if l.dismembered or l.bleed > 0.02:
				continue
			l.skin = minf(100.0, l.skin + (1.5 if l.bandaged else 0.5))
			l.muscle = minf(100.0, l.muscle + (0.8 if l.bandaged else 0.3))
	# смерть от полной кровопотери
	if blood_volume <= 0.35:
		_expire("bloodloss")
	# пульс для звука и луж
	_pulse_t -= delta
	if _pulse_t <= 0.0 and not dead:
		_pulse_t = 60.0 / maxf(heart_rate, 1.0)
		heart_pulse.emit(heart_rate)

func _expire(cause: String) -> void:
	if dead:
		return
	dead = true
	death_cause = cause
	expired.emit(cause)
