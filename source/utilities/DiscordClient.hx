package utilities;

#if DISCORD_ALLOWED
import cpp.ConstCharStar;
import cpp.RawConstPointer;
import flixel.util.FlxSignal;
import haxe.Json;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;

using cpp.RawPointer;
using cpp.Function;

class DiscordClient {
	/**
	 * Whether the client has been started
	 */
	public static var started(default, null):Bool = false;

	/**
	 * Whether the client is currently running
	 */
	public static var active(default, null):Bool = false;

	/**
	 * The default application ID
	 */
	public static var defaultID(default, never):String = "864980501004812369";

	public static var ID(default, set):String = defaultID;

	public static var presence(default, null):DiscordRichPresence = new DiscordRichPresence();

	/**
	 * Signal for when the Discord RPC gives an error.
	 */
	public static var onError(default, null):FlxTypedSignal<(Int, String) -> Void> = new FlxTypedSignal<(Int, String) -> Void>();

	/**
	 * Signal for when the Discord RPC disconnects.
	 */
	public static var onDisconnect(default, null):FlxTypedSignal<(Int, ConstCharStar) -> Void> = new FlxTypedSignal<(Int, ConstCharStar) -> Void>();

	/**
	 * Signal for when the Discord RPC is ready.
	 */
	public static var onReady(default, null):FlxTypedSignal<RawConstPointer<DiscordUser>->Void> = new FlxTypedSignal<RawConstPointer<DiscordUser>->Void>();

	/**
	 * Starts the Discord RPC
	 */
	public static function startup() {
		final handlers:DiscordEventHandlers = new DiscordEventHandlers();

		handlers.ready = _onReady.fromStaticFunction();
		handlers.disconnected = _onDisconnect.fromStaticFunction();
		handlers.errored = _onError.fromStaticFunction();
		Discord.Initialize(ID, handlers.addressOf(), false, null);

		started = true;

		Thread.create(() -> {
			while (true) {
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end

				Discord.RunCallbacks();

				Sys.sleep(1);
			}
		});
	}

	/**
	 * Shutsdown the Discord RPC.
	 */
	public static inline function shutdown() {
		trace("Discord: Shutting down...");
		Discord.Shutdown();
		active = false;
		started = false;
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

		changePresence();

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
		Discord.UpdatePresence(presence.addressOf());
	}

	public static function loadModPresence():Bool {
		if (FileSystem.exists("mods/" + Options.getData("curMod") + "/discord.json")) {
			var discordData:DiscordData = cast Json.parse(File.getContent("mods/" + Options.getData("curMod") + "/discord.json"));
			ID = discordData.ID;
			changePresence("", null, null, null, null, discordData.key, discordData.text);
			trace("found mod presence");
			return true;
		}
		else{
			ID = defaultID;
			changePresence();
		}
		trace("didnt find mod presence");
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
		if (started) {
			@:bypassAccessor
			ID = newID;
			shutdown();
			startup();
			Discord.UpdatePresence(presence.addressOf());
		}
		return ID = newID;
	}
}

typedef DiscordData = {
	var ID:String;
	var key:String;
	var text:String;
}
#end
