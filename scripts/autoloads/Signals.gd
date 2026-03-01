extends Node

@warning_ignore("unused_signal")
signal player_health_changed(current_hp, max_hp)

@warning_ignore("unused_signal")
signal player_died

@warning_ignore("unused_signal")
signal block_destroyed(global_pos)

@warning_ignore("unused_signal")
signal boss_died(entity_id)

@warning_ignore("unused_signal")
signal play_world(world_name)

@warning_ignore("unused_signal")
signal select_world(world_name)

@warning_ignore("unused_signal")
signal delete_world(world_name)

@warning_ignore("unused_signal")
signal switch_to_section(section: String)

@warning_ignore("unused_signal")
signal equip_changed()
