package utilities;

import haxe.Json;
#if DISCORD_ALLOWED
import cpp.ConstCharStar;
import cpp.RawConstPointer;
import flixel.util.FlxSignal;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;

using cpp.RawPointer;
using cpp.Function;

/**
 * Class for handling Discord RPC
 */
class DiscordClient {
	/**
	 * Whether the client is currently running
	 */
	public static var active(default, null):Bool = false;

	/**
	 * The default Discord RPC ID
	 */
	public static var defaultID(default, never):String = "864980501004812369";

	/**
	 * The current Discord RPC ID
	 */
	public static var ID(default, set):String = defaultID;

	/**
	 * The current Discord RPC
	 */
	public static var presence(default, never):DiscordRichPresence = new DiscordRichPresence();

	/**
	 * Signal for when the Discord RPC gives an error.
	 */
	public static var onError(default, never):FlxTypedSignal<(Int, String) -> Void> = new FlxTypedSignal<(Int, String) -> Void>();

	/**
	 * Signal for when the Discord RPC disconnects.
	 */
	public static var onDisconnect(default, never):FlxTypedSignal<(Int, ConstCharStar) -> Void> = new FlxTypedSignal<(Int, ConstCharStar) -> Void>();

	/**
	 * Signal for when the Discord RPC is ready.
	 */
	public static var onReady(default, never):FlxTypedSignal<RawConstPointer<DiscordUser>->Void> = new FlxTypedSignal<RawConstPointer<DiscordUser>->Void>();

	
	private static var discordThread(default, null):Thread = null;

	/**
	 * Starts the Discord RPC
	 */
	public static function startup() {
		if(active){
			return;
		}
		final handlers:DiscordEventHandlers = new DiscordEventHandlers();

		handlers.ready = _onReady.fromStaticFunction();
		handlers.disconnected = _onDisconnect.fromStaticFunction();
		handlers.errored = _onError.fromStaticFunction();
		Discord.Initialize(ID, handlers.addressOf(), false, null);

		active = true;

		if (discordThread == null) {
			discordThread = Thread.create(() -> {
				while (true) {
					#if DISCORD_DISABLE_IO_THREAD
					Discord.UpdateConnection();
					#end

					Discord.RunCallbacks();

					Sys.sleep(1);
				}
			});
		}
	}

	/**
	 * Shutsdown the Discord RPC.
	 */
	public static inline function shutdown() {
		if(!active){
			return;
		}
		trace("Discord: Shutting down...");
		Discord.Shutdown();
		active = false;
		trace("Discord: Shut down.");
	}

	private static function _onReady(request:RawConstPointer<DiscordUser>) {
		final username:String = request[0].username;
		final globalName:String = request[0].username;
		final discriminator:Int = Std.parseInt(request[0].discriminator);

		if (discriminator != 0)
			trace('Discord: Connected to user ${username}#${discriminator} ($globalName)');
		else
			trace('Discord: Connected to user @${username} ($globalName)');

		active = true;		

		onReady.dispatch(request);
	}

	public static function changePresence(details:String = "", ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float,
			largeImageKey:String = "icon", largeImageText:String = "Leather Engine") {
		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;

		if (endTimestamp > 0) {
			endTimestamp = startTimestamp + endTimestamp;
		}

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = largeImageKey;
		presence.largeImageText = largeImageText;
		presence.smallImageKey = smallImageKey;
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();
	}

	public static inline function updatePresence() {
		if(!active) {
			return;
		}
		Discord.UpdatePresence(presence.addressOf());
	}

	public static function loadModPresence():Bool {
		var jsonPath:String = 'mods/${Options.getData("curMod")}/discord.json';
		if (FileSystem.exists(jsonPath)) {
			var discordData:DiscordData = cast Json.parse(File.getContent(jsonPath));
			ID = discordData.ID;
			changePresence("", null, null, null, null, discordData.key, discordData.text);
			return true;
		} else {
			ID = defaultID;
			changePresence();
		}
		return false;
	}

	private static inline function _onDisconnect(errorCode:Int, message:ConstCharStar):Void {
		trace('Discord: Disconnected ($errorCode:$message)', WARNING);
		onDisconnect.dispatch(errorCode, message);
	}

	private static inline function _onError(errorCode:Int, message:ConstCharStar):Void {
		trace('Discord: Error ($errorCode:$message)', ERROR);
		onError.dispatch(errorCode, message);
	}

	@:noCompletion
	static inline function set_ID(newID:String):String {
		if (ID == newID) {
			return ID;
		}
		ID = newID;
		shutdown();
		startup();
		updatePresence();

		return newID;
	}
}

typedef DiscordData = {
	var ID:String;
	var key:String;
	var text:String;
}
#end
