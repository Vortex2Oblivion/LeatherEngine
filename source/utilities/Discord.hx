package utilities;

#if DISCORD_ALLOWED
import Sys.sleep;
import discord_rpc.DiscordRpc;
import flixel.FlxG;
import openfl.Assets;
import haxe.Json;


using StringTools;
typedef DiscordStuffs = {
	var values:Array<DiscordStuff>;
}

typedef DiscordStuff = {
	var id:String;
	var key:String;
	var text:String;
}

class DiscordClient
{

	public static var discordData:DiscordStuffs;

	public static var started:Bool = false;

	public static var active:Bool = false;



	inline public function new()
	{	
		discordData = Json.parse(Assets.getText(Paths.json("discord")));
		startLmao();
	}

	public static function startLmao()
	{
		if (discordData == null) {
			return;
		}
		
		for (value in discordData.values) {
			var idStuff = value.id;
			trace("Discord Client starting...");
			DiscordRpc.start({
				clientID: idStuff,
				onReady: onReady,
				onError: onError,
				onDisconnected: onDisconnected
			});
		}


		trace("Discord Client started.");

		active = true;

		while (active)
		{
			DiscordRpc.process();
			sleep(2);
		}

		if (active)
			DiscordRpc.shutdown();

		active = false;
	}

	public static function shutdown()
	{
		DiscordRpc.shutdown();

		active = false;
	}

	static function onReady()
	{
		// should be a bigger issue maybe but whatevs
		if (discordData == null) {
			return;
		}

		for (value in discordData.values) {
			var keyLol = value.key;
			var textLol = value.text;
			DiscordRpc.presence({
				details: "In the Menus",
				state: null,
				largeImageKey: keyLol,
				largeImageText: textLol
			});
		}
	}

	static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});

		started = true;
		trace("Discord Client initialized");
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
	{
		if (discordData == null) {
			return;
		}

		var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}
		for (value in discordData.values) {
			var keyLol = value.key;
			var textLol = value.text;
			DiscordRpc.presence({
				details: details,
				state: state,
				largeImageKey: keyLol,
				largeImageText: textLol,
				smallImageKey: smallImageKey,
				// Obtained times are in milliseconds so they are divided so Discord can use it
				startTimestamp: Std.int(startTimestamp / 1000),
				endTimestamp: Std.int(endTimestamp / 1000)
			});
	
		}
		// trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}
}
#end
