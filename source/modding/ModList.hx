package modding;

#if MODDING_ALLOWED
import polymod.Polymod;

class ModList {
	public static var modList:Map<String, Bool> = new Map<String, Bool>();

	public static var modMetadatas:Map<String, ModMetadata> = new Map();

	/**
	 * Enables / disables a mod
	 * @param mod The mod to enable / disable
	 * @param enabled should the mod be enabled?
	 */
	public static function setModEnabled(mod:String, enabled:Bool):Void {
		modList.set(mod, enabled);
		Options.setData(modList, "modlist", "modlist");
	}

	/**
	 * Gets if a mod is enabled
	 * @param mod The mod to check
	 * @return If the mod is enabled or not.
	 */
	public static function getModEnabled(mod:String):Bool {
		if (!modList.exists(mod))
			setModEnabled(mod, modMetadatas.get(mod).metadata.get('auto_enable').toLowerCase() != 'false');

		return modList.get(mod);
	}

	/**
	 * Returns an ``Array`` of all active mods
	 * NOTE: Will prioritize the current selected mod over all other mods.
	 * @param modsToCheck 
	 * @return The array of mods
	 */
	public static function getActiveMods(modsToCheck:Array<String>):Array<String> {
		var activeMods:Array<String> = [];

		for (modName in modsToCheck) {
			if (getModEnabled(modName) && modName != Options.getData("curMod") && modName != "Friday Night Funkin'")
				activeMods.push(modName);
		}
		activeMods.push("Friday Night Funkin'");
		activeMods.push(Options.getData("curMod"));
		return activeMods;
	}

	/**
	 * Loads all mods.
	 */
	public static inline function load():Void {
		if (Options.getData("modlist", "modlist") != null && Options.getData("modlist", "modlist") != [])
			modList = Options.getData("modlist", "modlist");
	}
}
#end
