package ui.logs;

import lime.app.Application;
import openfl.events.Event;
import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.BitmapData;

class Logs extends Sprite {
    public var logs:Array<String> = [];
    var bg:Bitmap;
    var logText:LogText;

    public static var instance:Logs = null;    

    public var texts:Map<PrintType, LogPrint> = [
		PrintType.LOG => new LogPrint("LOG", FlxColor.CYAN),
		PrintType.WARNING => new LogPrint("WARNING", FlxColor.YELLOW),
		PrintType.ERROR => new LogPrint("ERROR", FlxColor.RED),
		PrintType.DEBUG => new LogPrint("DEBUG", FlxColor.LIME),
	];

    public function new(){
        super();

        instance = this;

        bg = new Bitmap(new BitmapData(FlxG.width, FlxG.height, true, FlxColor.BLACK));
        bg.alpha = 0.5;
		addChild(bg);

        logText = new LogText(0, 60, {width: FlxG.width - 20, height: FlxG.height - 34}, "", 15, LEFT);
		addChild(logText);

        addEventListener(Event.ENTER_FRAME, onFrameUpdate);
        FlxG.stage.window.onResize.add(onStageResized);
    }

    private function onFrameUpdate(_):Void{
        if (FlxG.keys.justPressed.F3 && Options.getData("developer"))
            visible = !visible;
        else if (FlxG.keys.justPressed.F4 && Options.getData("developer")){
            logs = [];
            logText.text = '';
        }
    }
    private function onStageResized(w:Int, h:Int    ):Void{
		bg.width = Application.current.window.width;
		bg.height = Application.current.window.height;
		logText.height = Application.current.window.height - 94;
    }

    public static inline function log(message:Dynamic){
        if (Logs.instance != null)
            Logs.instance.addLog(message, PrintType.LOG);
    }

    public static inline function debug(message:Dynamic){
        if (Logs.instance != null)
            Logs.instance.addLog(message, PrintType.DEBUG);
    }

    public static inline function warn(message:Dynamic){
        if (Logs.instance != null)
            Logs.instance.addLog(message, PrintType.WARNING);
    }

    public static inline function error(message:Dynamic){
        if (Logs.instance != null)
            Logs.instance.addLog(message, PrintType.ERROR);
    }

    public function addLog(message:Dynamic, ?logType:PrintType){
        if (logText != null)
            {
                if (message == null)
                    return;
    
                var textt:String = "";
                var dataThing:String = Std.string(message);
    
                if (logs.length <= 0)
                    logText.text = "";
    
                var info:LogPrint = texts.get(logType);
    
                textt = (info != null ? info.text + " " : "") + dataThing;
                logs.push(textt);
    
                if (logs.length > 45)
                    logs.shift();
    
                var colorThese:Array<Dynamic> = []; //[start,end,color];
                var newText:String = "";
                for (i in 0...logs.length)
                {
                    var kys:Array<String> = [];
    
                    for (keys in texts)
                        kys.push(keys.text);
    
                    for (val in kys){
                        if (logs[i].startsWith(val)){
                            var formatData:LogPrint = texts.get(printTypeFromSting(val));
                            if (formatData!=null){
                                var colorFormat:Int = formatData.color;
                                var stringIndex:Array<Int> = [
                                    newText.length,
                                    newText.length+logs[i].length
                                ];
            
                                colorThese.push([stringIndex[0], stringIndex[1], colorFormat]);
                            }
                        }
                    }
    
                    newText += logs[i] + '\n';
                }
    
                logText.text = newText;
    
                for (i in colorThese) logText.setTextFormat(new LogTextFormat(i[2], 15), i[0], i[1]);
    
                logText.defaultTextFormat.align = LEFT;
                if (logText != null)
                    logText.scrollV = Std.int(logText.maxScrollV);
            }
    }

    public static function printTypeFromSting(s:String):PrintType{
        switch (s.toUpperCase()){
            case "DEBUG":   return PrintType.DEBUG;
            case "ERROR":   return PrintType.ERROR;
            case "WARNING": return PrintType.WARNING;
            default:        return PrintType.LOG;
        }
    }
}