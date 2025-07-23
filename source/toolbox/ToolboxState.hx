package toolbox;

import toolbox.util.NewModState;
import ui.Option;
import states.PlayState;
import states.OptionsMenu;

class ToolboxState extends OptionsMenu {
	#if MODDING_ALLOWED override inline function addModOptions() {}#end
	override function create() {
		pages = [
			"Categories" => [
				#if MODDING_ALLOWED
				new GameStateOption("New Mod", NewModState, "Create a new mod"),
				#end
				new PageOption("Tools", "Tools", " Show tools like character creator and chart editor."),
				new PageOption("Documentation", "Documentation", "View the documentation")
			],
			"Tools" => [
				new PageOption("Back", "Categories", "Go back to the main menu."),
				new GameStateOption("Charter", ChartingState, "Open the chart editor."),
				new CharacterCreatorOption("Character Creator", () -> new CharacterCreator("dad", "stage"), "Open the character creator."),
				new GameStateOption("Stage Editor", () -> new StageMakingState("stage"), "Open the stage editor."),
				#if MODCHARTING_TOOLS
				new GameStateOption("Modchart Editor", modcharting.ModchartEditorState, "Open the modchart editor.")
				#end
			],
			"Documentation" => [
				new PageOption("Back", "Categories", "Go back to the main menu"),
				new OpenUrlOption("Wiki", "Wiki", "https://github.com/Leather128/LeatherEngine/wiki", "View the Wiki."),
				new OpenUrlOption("HScript Api", "HScript Api", "https://github.com/Vortex2Oblivion/LeatherEngine/wiki/HScript-api-documentation-(WIP)",
					"View the HScript API."),
				new OpenUrlOption("Lua Api", "Lua Api", "https://github.com/Vortex2Oblivion/LeatherEngine-Extended-Support/wiki/Lua-api-documentation-(WIP)",
					"View the Lua API."),
				new OpenUrlOption("Classes List", "Classes List", "https://vortex2oblivion.github.io/LeatherEngine/", "View the classes list."),
				new OpenUrlOption("Polymod Docs", "Polymod Docs", "https://polymod.io/docs/", "View the Polymod docs.")
			]
		];
		if (PlayState.instance == null) {
			pages["Tools"][4] = null;
			pages["Tools"][1] = null;
		}

		super.create();
	}
}
