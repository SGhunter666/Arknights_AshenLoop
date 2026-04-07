class_name RelicManager
extends RefCounted

static func has_relic(relic_id: String) -> bool:
	return RunManager.modules.has(relic_id) or RunManager.charms.has(relic_id)

static func active_relics() -> Array[String]:
	var result: Array[String] = []
	for module_id in RunManager.modules:
		result.append(module_id)
	for charm_id in RunManager.charms:
		result.append(charm_id)
	return result

