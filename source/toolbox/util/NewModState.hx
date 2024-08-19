
package toolbox.util;

#if sys
import sys.io.File;
import openfl.display.BitmapData;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.text.FlxText;
import openfl.utils.Assets;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUICheckBox;
import sys.FileSystem;
import haxe.Json;
import states.ModsMenu;
import lime.ui.FileDialogType;
import flixel.ui.FlxButton;
import flixel.FlxG;
#if DISCORD_ALLOWED
import utilities.Discord.DiscordClient;
#end
import states.MusicBeatState;
import flixel.addons.ui.FlxUIInputText;
import lime.ui.FileDialog;
import lime.app.Application;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.FlxCamera;


class NewModState extends MusicBeatState{

    var bg:FlxSprite;

    var modNameText:FlxText;
    var modName:FlxUIInputText;

    var UI_box:FlxUITabMenu;

    var modIconText:FlxText;
    var modIcon:FlxSprite = new FlxSprite().loadGraphic(Paths.image('template mod'));
    var browseButton:FlxButton;
    var modIconPath:String = Paths.image('template mod');

    var descriptionText:FlxText;
    var description:FlxUIInputText;

    var authorText:FlxText;
    var author:FlxUIInputText;

    var modVersionText:FlxText;
    var modVersion:FlxUIInputText;

    var checkAutoEnable:FlxUICheckBox;
    var checkHideModSwitch:FlxUICheckBox;

    var rpc_idText:FlxText;
    var rpc_id:FlxUIInputText;

    var createButton:FlxButton;

    var camHUD:FlxCamera;
    var UI_boxPopup:FlxUITabMenu;
    var popupBg:FlxSprite;
    var close:FlxButton;

    final dirs:Array<String> = [
        "_append",
        "data",
        "fonts",
        "images",
        "music",
        "shaders",
        "shared",
        "songs",
        "sounds",
        "stages",
        "videos"
    ];

    override function create(){
        super.create();
        #if DISCORD_ALLOWED
		DiscordClient.changePresence("Creating A New Mod", null, null, true);
		#end
        bg = new FlxSprite();
        if(Options.getData("menuBGs")){
            bg.loadGraphic(Paths.image(Assets.exists('ui skins/${Options.getData("uiSkin")}/backgrounds/menuCharter') ? 'ui skins/${Options.getData("uiSkin")}/backgrounds/menuCharter' : 'ui skins/default/backgrounds/menuCharter'));
            bg.screenCenter();
            add(bg);
        }

        camHUD = new FlxCamera();
        FlxG.cameras.add(camHUD, false); // false so it's not a default camera
        camHUD.bgColor.alpha = 0;
        camHUD.alpha = 0;

        UI_box = new FlxUITabMenu(null, [{name: "New Mod", label: 'New Mod'},], true);

		UI_box.resize(640, 480);
        UI_box.screenCenter();
		add(UI_box);

        var tab_Group_mod = new FlxUI(null, UI_box);
		tab_Group_mod.name = "New Mod";

        UI_box.addGroup(tab_Group_mod);
		UI_box.scrollFactor.set();

        modName = new FlxUIInputText(400, 250);
        add(modName);

        modNameText = new FlxText();
        modNameText.x = modName.x;
        modNameText.y = modName.y - 30;
        modNameText.alignment = FlxTextAlign.CENTER;
        modNameText.size = 16;
        modNameText.text = "Mod Name";
        add(modNameText);

        
        modIconText = new FlxText();
        modIconText.x = modName.x;
        modIconText.y = modNameText.y + 70;
        modIconText.alignment = FlxTextAlign.CENTER;
        modIconText.size = 16;
        modIconText.text = "Mod Icon";
        add(modIconText);

        browseButton = new FlxButton(modIconText.x + 100, modIconText.y, "Browse", function() {
            var open:FileDialog = new FileDialog();
            open.onSelect.add(function(path) {
                modIcon.loadGraphic(BitmapData.fromFile(path));
                modIcon.setGraphicSize(160, 160);
                modIcon.updateHitbox();
                modIconPath = path;
			});
            open.browse(FileDialogType.OPEN, null, null, "Choose an icon.");
        });
        add(browseButton);

        modIcon.x = modNameText.x;
        modIcon.y = modNameText.y + 100;
        add(modIcon);

        description = new FlxUIInputText(modName.x + 300, modName.y);
        add(description);

        descriptionText = new FlxText();
        descriptionText.x = description.x;
        descriptionText.y = description.y - 30;
        descriptionText.alignment = FlxTextAlign.CENTER;
        descriptionText.size = 16;
        descriptionText.text = "Description";
        add(descriptionText);

        author = new FlxUIInputText(description.x , description.y + 45);
        add(author);

        authorText = new FlxText();
        authorText.x = author.x;
        authorText.y = author.y - 30;
        authorText.alignment = FlxTextAlign.CENTER;
        authorText.size = 16;
        authorText.text = "Author";
        add(authorText);


        modVersion = new FlxUIInputText(authorText.x , authorText.y + 120);
        modVersion.text = "1.0.0";
        add(modVersion);

        modVersionText = new FlxText();
        modVersionText.x = modVersion.x;
        modVersionText.y = modVersion.y - 45;
        modVersionText.alignment = FlxTextAlign.CENTER;
        modVersionText.size = 16;
        modVersionText.text = "Mod Version\n(Must follow *.*.*)";
        add(modVersionText);

        rpc_id = new FlxUIInputText(description.x, modName.y + 300);
        add(rpc_id);

        rpc_idText = new FlxText();
        rpc_idText.x = rpc_id.x;
        rpc_idText.y = rpc_id.y - 30;
        rpc_idText.alignment = FlxTextAlign.CENTER;
        rpc_idText.size = 16;
        rpc_idText.text = "Discord RPC ID (Optional)";
        add(rpc_idText);

        checkAutoEnable = new FlxUICheckBox(rpc_idText.x, modVersion.y + 60, null, null, "Auto Enable", 100);
        checkAutoEnable.checked = true;
        add(checkAutoEnable);

        checkHideModSwitch = new FlxUICheckBox(checkAutoEnable.x, checkAutoEnable.y + checkAutoEnable.height + 2, null, null, "Hide Mod Switch Menu", 100);
        add(checkHideModSwitch);
        
        createButton = new FlxButton(modIconText.x, modIconText.y + 250, "Create Mod", function() {
            if(modVersion.text.length == 0 || author.text.length == 0 || description.text.length == 0 || modName.text.length == 0)
                {
                    coolError("Please fill out all required fields!","Error!");
                    return;
                }
            if(FileSystem.exists('./mods/${modName.text}')){
                coolError("Mod already exists!","Error!");
                return;
            }
            FileSystem.createDirectory('./mods/${modName.text}');
            File.saveBytes('./mods/${modName.text}/_polymod_icon.png', File.getBytes(modIconPath));
            for (dir in dirs){
                FileSystem.createDirectory('./mods/${modName.text}/${dir}');
            }
            var data:String = Json.stringify({
                title: modName.text,
                rpcId: rpc_id.text.length > 0 ? rpc_id.text : "864980501004812369",
                rpcKey: "logo",
                rpcText: rpc_id.text.length > 0 ? modName.text : "Leather Engine",
                description: description.text,
                author: author.text,
                api_version: CoolUtil.getCurrentVersion().replace('v', ''),
                mod_version: modVersion.text,
                metadata: {
                    auto_enable: Std.string(checkAutoEnable.checked),
                    canBeSwitchedTo: Std.string(!checkHideModSwitch.checked)
                }
            }, null, "\t");
            File.saveContent('./mods/${modName.text}/_polymod_meta.json', data);
            trace("mod created");
            FlxTween.tween(camHUD, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut});
        });
        add(createButton);

        popupBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        popupBg.alpha = 0.5;
        popupBg.cameras = [camHUD];
        add(popupBg);

        UI_boxPopup = new FlxUITabMenu(null, [{name: "Mod Created", label: 'Mod Created'},], true);

		UI_boxPopup.resize(640 * 0.667, 480 * 0.667);
        UI_boxPopup.screenCenter();
        UI_boxPopup.cameras = [camHUD];
		add(UI_boxPopup);

        close = new FlxButton(0,0,"Close",function(){
            FlxG.switchState(() -> new ModsMenu());
        });
        close.scale.set(2,2);
        close.label.scale.set(2,2);
        close.updateHitbox();
        close.label.updateHitbox();
        close.screenCenter();
        close.cameras = [camHUD];
        add(close);

        addVirtualPad(NONE, B);
    }
    override function update(elapsed:Float){
        super.update(elapsed);
        if(virtualPad.buttonB.justPressed || FlxG.keys.anyJustPressed([ESCAPE])){
            FlxG.switchState(() -> new ToolboxPlaceholder());
        }
    }
    function coolError(message:Null<String> = null, title:Null<String> = null):Void {
		trace(title + " /// " + message, ERROR);

		var text:FlxText = new FlxText(0, 0, 1280, title + "\n\n" + message, 32);
		text.font = Paths.font("vcr.ttf");
		text.color = 0xFF6183;
		text.alignment = CENTER;
		text.borderSize = 1.5;
		text.borderStyle = OUTLINE;
		text.borderColor = FlxColor.BLACK;
		text.scrollFactor.set();

		FlxTween.tween(text, {alpha: 0, y: 64}, 4, {
			onComplete: function(_) {
				if (text != null && text.exists) {
					FlxG.state.remove(text);
					text.destroy();
				}
			},
			startDelay: 1
		});

		add(text);
	}
}
#end