/*
	The functions "maybe" needs to be added: isScreenKeyboardShown, messageboxShowMessageBox, clipboardHasText, clipboardGetText, clipboardSetText
	NOTE: THESE AT "SDLActivity"!!
 */

package android.utilities;

import lime.system.JNI;

class LeatherJNI #if (lime >= "8.0.0") implements JNISafety #end
{
	/** Represents an unknown screen orientation. */
	public static final SDL_ORIENTATION_UNKNOWN:Int = 0;

	/** Represents landscape screen orientation. */
	public static final SDL_ORIENTATION_LANDSCAPE:Int = 1;

	/** Represents flipped landscape screen orientation. */
	public static final SDL_ORIENTATION_LANDSCAPE_FLIPPED:Int = 2;

	/** Represents portrait screen orientation. */
	public static final SDL_ORIENTATION_PORTRAIT:Int = 3;

	/** Represents flipped portrait screen orientation. */
	public static final SDL_ORIENTATION_PORTRAIT_FLIPPED:Int = 4;

	/**
	 * Sets the screen orientation using JNI call.
	 *
	 * @param width The width of the screen.
	 * @param height The height of the screen.
	 * @param resizeable A boolean indicating if the screen is resizable.
	 * @param hint A string hint for the orientation.
	 * @return A dynamic result from the JNI call.
	 */
	public static inline function setOrientation(width:Int, height:Int, resizeable:Bool, hint:String):Dynamic
		return setOrientation_jni(width, height, resizeable, hint);

	/**
	 * Gets the current screen orientation as a string.
	 *
	 * @return A string representing the current screen orientation.
	 */
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
