extends Node

enum PartsOfDay {DAWN, DAY, DUSK, NIGHT}

enum Biomes {FOREST, DESERT, ICE}

enum MenuActions {NONE, CREATE, LOAD, ARE_YOU_SURE, RESET_BINDS}
var current_menu_action = MenuActions.NONE
