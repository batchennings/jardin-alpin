package aze.motion.specials 
{
	import aze.motion.EazeTween;
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	
	/**
	 * Tint tweening as a special property
	 * @author Philippe / http://philippe.elsass.me
	 */
	public class PropertyTint extends EazeSpecial
	{
		static public function register():void
		{
			EazeTween.specialProperties.tint = PropertyTint;
		}
		
		private var start:ColorTransform;
		private var tvalue:ColorTransform;
		private var delta:ColorTransform;
		
		function PropertyTint(target:Object, property:*, value:*, next:EazeSpecial)
		{
			super(target, property, value, next);
			var disp:DisplayObject = DisplayObject(target);
			
			if (value === null) tvalue = new ColorTransform();
			else 
			{
				var mix:Number = 1;
				var amix:Number = 0;
				var color:uint;
				if (value is Array) 
				{
					var a:Array = value as Array;
					if (a.length > 1) mix = a[1];
					if (a.length > 2) amix = a[2];
					else amix = 1 - mix;
					color = a[0];
				}
				else color = value;
				
				tvalue = new ColorTransform();
				tvalue.redMultiplier = amix;
				tvalue.greenMultiplier = amix;
				tvalue.blueMultiplier = amix;
				tvalue.redOffset = mix * ((color >> 16) & 0xff);
				tvalue.greenOffset = mix * ((color >> 8) & 0xff);
				tvalue.blueOffset = mix * (color & 0xff);
			}
		}
		
		override public function init(reverse:Boolean):void 
		{
			var disp:DisplayObject = DisplayObject(target);
			
			if (reverse) { start = tvalue; tvalue = disp.transform.colorTransform; }
			else { start = disp.transform.colorTransform; }
			
			delta = new ColorTransform(
				tvalue.redMultiplier - start.redMultiplier,
				tvalue.greenMultiplier - start.greenMultiplier,
				tvalue.blueMultiplier - start.blueMultiplier,
				0,
				tvalue.redOffset - start.redOffset,
				tvalue.greenOffset - start.greenOffset,
				tvalue.blueOffset - start.blueOffset
			);
			tvalue = null;
			
			if (reverse) update(0, false);
		}
		
		override public function update(ke:Number, isComplete:Boolean):void
		{
			var disp:DisplayObject = DisplayObject(target);
			var t:ColorTransform = disp.transform.colorTransform;
			
			t.redMultiplier = start.redMultiplier + delta.redMultiplier * ke;
			t.greenMultiplier = start.greenMultiplier + delta.greenMultiplier * ke;
			t.blueMultiplier = start.blueMultiplier + delta.blueMultiplier * ke;
			t.redOffset = start.redOffset + delta.redOffset * ke;
			t.greenOffset = start.greenOffset + delta.greenOffset * ke;
			t.blueOffset = start.blueOffset + delta.blueOffset * ke;
			
			disp.transform.colorTransform = t;
		}
		
		override public function dispose():void
		{
			start = delta = null;
			tvalue = null;
			super.dispose();
		}
	}

}