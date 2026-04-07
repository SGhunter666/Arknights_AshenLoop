class_name ShopManager
extends RefCounted

func can_afford(price: int) -> bool:
	return RunManager.gold >= price

func buy_card(card_id: String, price: int) -> bool:
	if not can_afford(price):
		return false
	RunManager.add_gold(-price)
	RunManager.add_card(card_id)
	return true

func buy_module(module_id: String, price: int) -> bool:
	if not can_afford(price):
		return false
	RunManager.add_gold(-price)
	RunManager.add_module(module_id)
	return true

func buy_charm(charm_id: String, price: int) -> bool:
	if not can_afford(price):
		return false
	RunManager.add_gold(-price)
	RunManager.add_charm(charm_id)
	return true

