package modding.helpers;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * Helper class to fix text outlines on LUA scripts.
 * @author TheZoroForce240
 * @see https://github.com/TheZoroForce240/Voiid-Chronicles-V2-Source/blob/2a1b5d2b6309971db401f3fcbb6c1591615e65ea/source/modding/ModchartUtilities.hx#L3206
 */
class FlxTextFix extends FlxText
{
	override function regenGraphic()
	{
		if (textField == null || !_regen)
			return;

		var oldWidth:Int = FlxText.VERTICAL_GUTTER;
		var oldHeight:Int = FlxText.VERTICAL_GUTTER;

		if (graphic != null)
		{
			oldWidth = graphic.width;
			oldHeight = graphic.height;
		}

		var newWidth:Int = Math.ceil(textField.width) + FlxText.VERTICAL_GUTTER*2;
		// Account for gutter
		var newHeight:Int = Math.ceil(textField.textHeight) + FlxText.VERTICAL_GUTTER;

        newWidth += Math.ceil(borderSize*2);

		// prevent text height from shrinking on flash if text == ""
		if (textField.textHeight == 0)
		{
			newHeight = oldHeight;
		}

		if (oldWidth != newWidth || oldHeight != newHeight)
		{
			// Need to generate a new buffer to store the text graphic
			height = newHeight;
			var key:String = FlxG.bitmap.getUniqueKey("text");
			makeGraphic(newWidth, newHeight, FlxColor.TRANSPARENT, false, key);

			if (_hasBorderAlpha)
				_borderPixels = graphic.bitmap.clone();
            frameWidth = newWidth;
			frameHeight = newHeight;
			textField.width = width * 1.5;
			textField.height = height * 1.2;
			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = newWidth;
			_flashRect.height = newHeight;
		}
		else // Else just clear the old buffer before redrawing the text
		{
			graphic.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
			if (_hasBorderAlpha)
			{
				if (_borderPixels == null)
					_borderPixels = new BitmapData(frameWidth, frameHeight, true);
				else
					_borderPixels.fillRect(_flashRect, FlxColor.TRANSPARENT);
			}
		}

		if (textField != null && textField.text != null && textField.text.length > 0)
		{
			// Now that we've cleared a buffer, we need to actually render the text to it
			copyTextFormat(_defaultFormat, _formatAdjusted);

			_matrix.identity();
			
			_matrix.translate(borderSize*3, borderSize*2);
			applyBorderStyle();
			applyBorderTransparency();
			applyFormats(_formatAdjusted, false);

			
			drawTextFieldTo(graphic.bitmap);
		}

		_regen = false;
		resetFrame();
	}
}