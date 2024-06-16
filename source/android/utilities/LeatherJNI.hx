/*
	The functions "maybe" needs to be added: isScreenKeyboardShown, messageboxShowMessageBox, clipboardHasText, clipboardGetText, clipboardSetText
	NOTE: THESE AT "SDLActivity"!!
 */

package android.utilities;

#if android
import lime.system.JNI;

class LeatherJNI #if (lime >= "8.0.0") implements JNISafety #end
{
	public static final SDL_ORIENTATION_UNKNOWN:Int = 0;
	public static final SDL_ORIENTATION_LANDSCAPE:Int = 1;
	public static final SDL_ORIENTATION_LANDSCAPE_FLIPPED:Int = 2;
	public static final SDL_ORIENTATION_PORTRAIT:Int = 3;
	public static final SDL_ORIENTATION_PORTRAIT_FLIPPED:Int = 4;

	public static inline function setOrientation(width:Int, height:Int, resizeable:Bool, hint:String):Dynamic
		return setOrientation_jni(width, height, resizeable, hint);

	public static inline function getCurrentOrientationAsString():String {
		return switch (getCurrentOrientation_jni()) {
			case SDL_ORIENTATION_PORTRAIT: "Portrait";
			case SDL_ORIENTATION_LANDSCAPE: "LandscapeRight";
			case SDL_ORIENTATION_PORTRAIT_FLIPPED: "PortraitUpsideDown";
			case SDL_ORIENTATION_LANDSCAPE_FLIPPED: "LandscapeLeft";
			default: "Unknown";
		}
	}

	@:noCompletion private static var setOrientation_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'setOrientation',
		'(IIZLjava/lang/String;)V');

	@:noCompletion private static var getCurrentOrientation_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'getCurrentOrientation', '()I');
}
#end
