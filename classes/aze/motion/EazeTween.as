/*
	Eaze is an Actionscript 3 tween library by Philippe Elsass
	Contact: philippe.elsass*gmail.com
	Website: http://code.google.com/p/eaze-tween/
	License: http://www.opensource.org/licenses/mit-license.php
*/
package aze.motion
{
	import aze.motion.easing.Quadratic;
	import aze.motion.specials.EazeSpecial;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	
	/**
	 * EazeTween tween object
	 * @author Philippe - http://philippe.elsass.me
	 */
	final public class EazeTween
	{
		//--- STATIC ----------------------------------------------------------
		
		/** Defines default easing method to use when no ease is specified */
		static public var defaultEasing:Function = Quadratic.easeOut;
		static public var defaultDuration:Object = { slow:1, normal:0.4, fast:0.2 };
		
		/** Registered plugins */ 
		static public const specialProperties:Dictionary = new Dictionary();
		specialProperties.alpha = true;
		specialProperties.alphaVisible = true;
		specialProperties.scale = true;
		
		static private const running:Dictionary = new Dictionary();
		static private const ticker:Shape = createTicker();
		static private var pauseTime:Number;
		static private var head:EazeTween;
		static private var tweenCount:int = 0;
		
		/**
		 * Stop immediately all running tweens
		 */
		static public function killAllTweens():void
		{
			for (var target:Object in running)
				killTweensOf(target);
		}
		
		/**
		 * Stop immediately all tweens associated with target
		 * @param	target
		 */
		static public function killTweensOf(target:Object):void
		{
			if (!target) return;
			
			var tween:EazeTween = running[target];
			var rprev:EazeTween;
			while (tween)
			{
				tween.isDead = true;
				tween.dispose();
				if (tween.rnext) { rprev = tween; tween = tween.rnext; rprev.rnext = null; }
				else tween = null;
			}
			delete running[target];
		}
		
		/**
		 * Temporarily stop all tweens
		 */
		static public function pauseAllTweens():void
		{
			if (ticker.hasEventListener(Event.ENTER_FRAME))
			{
				pauseTime = getTimer();
				ticker.removeEventListener(Event.ENTER_FRAME, tick);
			}
		}
		
		/**
		 * Reactivate tweens
		 */
		static public function resumeAllTweens():void
		{
			if (!ticker.hasEventListener(Event.ENTER_FRAME))
			{
				var delta:Number = getTimer() - pauseTime;
				var tween:EazeTween = head;
				while (tween)
				{
					tween.startTime += delta;
					tween.endTime += delta;
					tween = tween.next;
				}
				ticker.addEventListener(Event.ENTER_FRAME, tick);
			}
		}
		
		/// Setup enterframe event for update
		static private function createTicker():Shape
		{
			var sp:Shape = new Shape();
			sp.addEventListener(Event.ENTER_FRAME, tick);
			//setInterval(checkLeaks, 5000);
			return sp;
		}
		
		static private function checkLeaks():void
		{
			var targets:int = 0;
			var t:EazeTween;
			for (var target:Object in running)
			{
				//trace(target);
				targets++;
			}
			
			var tweens:int = 0.
			t = head;
			while (t) { tweens++; t = t.next; }
			trace("== check targets=", targets, "tweens=", tweens);
		}
		
		/// Enterframe handler for update
		static private function tick(e:Event):void 
		{
			if (head) updateTweens(getTimer());
		}
		
		/// Main update loop
		static private function updateTweens(time:int):void 
		{
			var complete:Array = [];
			var ct:int = 0;
			var t:EazeTween = head;
			var cpt:int = 0;
			
			while (t)
			{
				cpt++;
				var isComplete:Boolean;
				if (t.isDead) isComplete = true;
				else
				{
					isComplete = time >= t.endTime;
					var k:Number = isComplete ? 1.0 : (time - t.startTime) / t._duration;
					var ke:Number = t._ease(k || 0);
					var target:Object = t.target;
					
					// update
					var p:EazeProperty = t.properties;
					while (p)
					{
						target[p.name] = p.start + p.delta * ke;
						p = p.next;
					}
					
					if (t.slowTween)
					{
						if (t.autoVisible) target.visible = target.alpha > 0.001;
						if (t.specials)
						{
							var s:EazeSpecial = t.specials;
							while (s)
							{
								s.update(ke, isComplete);
								s = s.next;
							}
						}
			
						if (t._onStart != null)
						{
							t._onStart.apply(null, t._onStartArgs);
							t._onStart = null;
							t._onStartArgs = null;
						}
						
						if (t._onUpdate != null) 
							t._onUpdate.apply(null, t._onUpdateArgs);
					}
				}
				
				if (isComplete) // tween ends
				{
					var cd:CompleteData = new CompleteData(t._onComplete, t._onCompleteArgs, t._chain, t.endTime - time);
					t._chain = null;
					complete.unshift(cd);
					ct++;
					
					//trace("- " + t._id + "/" + t.target.name);
					
					// finalize
					t.isDead = true;
					t.detach();
					t.dispose();
					
					// remove from chain
					var dead:EazeTween = t;
					var prev:EazeTween = t.prev;
					t = dead.next; // next tween
					
					if (prev) { prev.next = t; if (t) t.prev = prev; }
					else { head = t; if (t) t.prev = null; }
					dead.prev = dead.next = null;
				}
				else t = t.next; // next tween
			}
			
			// honor completed tweens notifications & chaining
			if (ct)
			{
				for (var i:int = 0; i < ct; i++) complete[i].execute();				
				
				//var dump:String = "";
				//var tt:EazeTween = head;
				//while (tt) { dump += tt._id + "/" + tt.target.name + " > "; tt = tt.next; }
				//trace(dump);
			}
			
			tweenCount = cpt;
		}
		
		//--- INSTANCE --------------------------------------------------------
		
		//static private var id:int = 0;
		//private var _id:int = id++;
		
		private var prev:EazeTween;
		private var next:EazeTween;
		private var rnext:EazeTween;
		private var isDead:Boolean;
		
		private var target:Object;
		private var reversed:Boolean;
		private var killTweens:Boolean;
		private var autoStart:Boolean;
		private var _configured:Boolean;
		private var _started:Boolean;
		private var _inited:Boolean;
		private var duration:*;
		private var _duration:Number;
		private var _ease:Function;
		private var startTime:Number;
		private var endTime:Number;
		private var properties:EazeProperty;
		private var specials:EazeSpecial;
		private var autoVisible:Boolean;
		private var slowTween:Boolean;
		private var _chain:Array;
		
		private var _onStart:Function;
		private var _onStartArgs:Array;
		private var _onUpdate:Function;
		private var _onUpdateArgs:Array;
		private var _onComplete:Function;
		private var _onCompleteArgs:Array;
		
		/**
		 * Creates a tween instance
		 * @param	target
		 * @param	autoStart	Start tween immediately after .to / .from are called
		 */
		public function EazeTween(target:Object, autoStart:Boolean = true)
		{
			if (!target) throw new ArgumentError("EazeTween: target can not be null");
			
			this.target = target;
			this.autoStart = autoStart;
			_ease = defaultEasing;
		}
		
		/// Set tween parameters
		private function configure(duration:*, newState:Object = null, reversed:Boolean = false):void
		{
			_configured = true;
			this.reversed = reversed;
			this.duration = duration;
			
			// properties
			if (newState)
			for (var name:String in newState)
			{
				var value:* = newState[name];
				if (name in specialProperties)
				{
					if (name == "alpha") autoVisible = true;
					else if (name == "alphaVisible") { name = "alpha"; autoVisible = false; }
					else if (name == "scale")
					{
						configure(duration, { scaleX:value, scaleY:value }, reversed);
						continue;
					}
					else
					{
						specials = new specialProperties[name](target, name, value, specials);
						continue;
					}
				}
				if (value is Array && target[name] is Number)
				{
					if ("__bezier" in specialProperties)
						specials = new specialProperties["__bezier"](target, name, value, specials);
					continue;
				}
				properties = new EazeProperty(name, value, properties);
			}
			
			slowTween = autoVisible || specials != null;
		}
		
		/** 
		 * Start this tween if it was created with autoStart disabled
		 */
		public function start(killTargetTweens:Boolean = true, timeOffset:Number = 0):void
		{
			if (_started) return;
			if (!_inited) init();
			killTweens = killTargetTweens;
			
			// add to main tween chain
			startTime = getTimer() + timeOffset;
			_duration = (isNaN(duration) ? smartDuration(String(duration)) : Number(duration)) * 1000;
			endTime = startTime + _duration;
			
			// set values
			if (reversed || _duration == 0) update(startTime);
			if (autoVisible && _duration > 0) target.visible = true;
			
			_started = true;
			attach(killTweens);
		}
		
		/// Read target properties
		private function init():void
		{
			if (_inited) return;
			
			// configure properties
			var p:EazeProperty = properties;
			while (p) { p.init(target, reversed); p = p.next; }
			
			var s:EazeSpecial = specials;
			while (s) { s.init(reversed); s = s.next; }
			
			_inited = true;
		}
		
		/// Resolve non numeric durations
		private function smartDuration(duration:String):Number
		{
			if (duration in defaultDuration) return defaultDuration[duration];
			else if (duration == "auto")
			{
				// look for a special property willing to provide an optimal duration
				var s:EazeSpecial = specials;
				while (s)
				{
					if ("getPreferredDuration" in s) return s["getPreferredDuration"]();
					s = s.next;
				}
			}
			return defaultDuration.normal;
		}
		
		/**
		 * Set easing method
		 * @param	f Easing function(k:Number):Number
		 * @return	Tween reference
		 */
		public function easing(f:Function):EazeTween
		{
			_ease = f || defaultEasing;
			return this;
		}
		
		/**
		 * Add a filter animation (PropertyFilter must be activated)
		 * @param	classRef	Filter class (ex: BlurFilter or "blurFilter")
		 * @param	parameters
		 * @return	Tween reference
		 */
		public function filter(classRef:*, parameters:Object, removeWhenDone:Boolean = false):EazeTween
		{
			if (!parameters) parameters = { };
			if (removeWhenDone) parameters.remove = true;
			addSpecial(classRef, classRef, parameters);
			return this;
		}
		
		/**
		 * Add a colorTransform tween (PropertyTint must be activated)
		 * @param	tint		Color
		 * @param	colorize	Color offset ratio (0-1)
		 * @param	multiply	Existing color ratio (0-1+)
		 * @return	Tween reference
		 */
		public function tint(tint:uint, colorize:Number = 1, multiply:Number = NaN):EazeTween
		{
			if (isNaN(multiply)) multiply = 1 - colorize;
			addSpecial("tint", "tint", [tint, colorize, multiply]);
			return this;
		}
		
		/**
		 * Add a short-rotation tween (PropertyShortRotation must be activated)
		 * @param	name	Target member name (ie. "rotation")
		 * @param	value	Rotation value
		 * @param	useRadian	Use radians instead of degrees
		 * @return	Tween reference
		 */
		public function short(name:String, value:Number, useRadian:Boolean = false):EazeTween
		{
			addSpecial("__short", name, [value, useRadian]);
			return this;
		}
		
		/// apply or append a special property tween
		private function addSpecial(special:*, name:*, value:Object):void
		{
			if (special in specialProperties && target)
			{
				if (!_inited && autoStart)
				{
					// apply
					EazeSpecial(new specialProperties[special](target, name, value, null))
						.init(true);
				}
				else 
				{
					specials = new specialProperties[special](target, name, value, specials);
					if (_started) specials.init(reversed);
					slowTween = true;
				}
			}
		}
		
		/**
		 * Set callback on tween startup
		 * @param	handler
		 * @param	...args
		 * @return	Tween reference
		 */
		public function onStart(handler:Function, ...args):EazeTween
		{
			_onStart = handler;
			_onStartArgs = args;
			slowTween = !autoVisible || specials != null || _onUpdate != null || _onStart != null;
			return this;
		}
		
		/**
		 * Set callback on tween update
		 * @param	handler
		 * @param	...args
		 * @return	Tween reference
		 */
		public function onUpdate(handler:Function, ...args):EazeTween
		{
			_onUpdate = handler;
			_onUpdateArgs = args;
			slowTween = !autoVisible || specials != null || _onUpdate != null || _onStart != null;
			return this;
		}
		
		/**
		 * Set callback on tween end
		 * @param	handler
		 * @param	...args
		 * @return	Tween reference
		 */
		public function onComplete(handler:Function, ...args):EazeTween
		{
			_onComplete = handler;
			_onCompleteArgs = args;
			return this;
		}
		
		/**
		 * Stop tween immediately
		 * @param	setEndValues	Set final tween values to target
		 */
		public function kill(setEndValues:Boolean = false):void
		{
			if (isDead) return;
			
			if (setEndValues) 
			{
				_onUpdate = _onComplete = null;
				update(endTime);
			}
			else 
			{
				detach();
				dispose();
			}
			isDead = true;
		}
		
		/**
		 * Update tween values immediately
		 */
		public function updateNow():EazeTween
		{
			if (_started)
			{
				var t:Number = Math.max(startTime, getTimer());
				update(t);
			}
			else 
			{
				init()
				endTime = _duration = 1;
				update(0);
			}
			return this;
		}
		
		/// Update this tween alone
		private function update(time:Number):void
		{
			// make this tween the only tween to update 
			var prev:EazeTween = head;
			head = this;
			updateTweens(time);
			head = prev;
		}
		
		/// push tween in process chain and associate target/tween in running Dictionnary
		private function attach(killTweens:Boolean):void
		{
			var parallel:EazeTween = null;
			
			if (killTweens) killTweensOf(target);
			else parallel = running[target];
			
			if (parallel)
			{
				prev = parallel;
				next = parallel.next;
				if (next) next.prev = this;
				parallel.next = this;
				rnext = parallel;
			}
			else
			{
				if (head) head.prev = this;
				next = head;
				head = this;
			}
			
			//var dump:String = "+ ";
			//var tt:EazeTween = head;
			//while (tt) { dump += tt._id + "/" + tt.target.name + " > "; tt = tt.next; }
			//trace(dump);
			
			running[target] = this;			
		}
		
		/// delete target/tween association in running Dictionnary
		private function detach():void
		{
			if (target && _started)
			{
				var targetTweens:EazeTween = running[target];
				if (targetTweens == this) 
				{
					if (rnext) running[target] = rnext;
					else delete running[target];
				}
				else if (targetTweens)
				{
					var prev:EazeTween = targetTweens;
					targetTweens = targetTweens.rnext;
					while (targetTweens) 
					{
						if (targetTweens == this)
						{
							prev.rnext = rnext;
							break;
						}
						prev = targetTweens;
						targetTweens = targetTweens.rnext;
					}
				}
				rnext = null;
			}
		}
		
		/// Cleanup all references except main chaining
		private function dispose():void
		{
			if (_started) target = null;
			if (properties) { properties.dispose(); properties = null; }
			_ease = null;
			_onStart = null;
			_onStartArgs = null;
			_onComplete = null;
			_onCompleteArgs = null;
			if (_chain)
			{
				for each(var tween:EazeTween in _chain) tween.dispose();
				_chain = null;
			}
			if (slowTween)
			{
				if (specials) { specials.dispose(); specials = null; }
				autoVisible = false; 
				_onUpdate = null;
				_onUpdateArgs = null;
			}
		}
		
		/**
		 * Create a blank tween for delaying
		 * @param	duration	Seconds or "slow/normal/fast/auto"
		 * @return Tween object
		 */
		public function delay(duration:*, killTargetTweens:Boolean = true):EazeTween
		{
			if (_inited) return chain().delay(duration, killTargetTweens);
			configure(duration);
			if (autoStart) start(killTargetTweens);
			return this;
		}
		
		/**
		 * Immediately change target properties
		 * @param	target
		 * @param	newState
		 * @param	overwrite	"keep" or "overwrite" (default) existing tweens of target
		 */
		public function apply(newState:Object = null, killTargetTweens:Boolean = true):EazeTween
		{
			if (_inited) return chain().apply(newState, killTargetTweens);
			configure(0, newState);
			if (autoStart) start(killTargetTweens);
			return this;
		}
		
		/**
		 * Animate target from current state to provided new state
		 * @param	target
		 * @param	duration	Seconds or "slow/normal/fast/auto"
		 * @param	newState
		 * @param	overwrite	"keep" or "overwrite" (default) existing tweens of target
		 * @return Tween object
		 */
		public function to(duration:*, newState:Object = null, killTargetTweens:Boolean = true):EazeTween
		{
			if (_inited || _configured) return chain().to(duration, newState, killTargetTweens);
			configure(duration, newState);
			if (autoStart) start(killTargetTweens);
			return this;
		}
		
		/**
		 * Animate target from provided new state to current state
		 * @param	target
		 * @param	duration	Seconds or "slow/normal/fast/auto"
		 * @param	newState
		 * @param	overwrite	"keep" or "overwrite" (default) existing tweens of target
		 * @return Tween object
		 */
		public function from(duration:*, initialState:Object = null, killTargetTweens:Boolean = true):EazeTween
		{
			if (_inited || _configured) return chain().from(duration, initialState, killTargetTweens);
			configure(duration, initialState, true);
			if (autoStart) start(killTargetTweens);
			return this;
		}
		
		/**
		 * Play target MovieClip timeline
		 * @param	target
		 * @param	frame		Frame number or label (default: totalFrames)
		 * @param	overwrite	"keep" or "overwrite" (default) existing tweens of target
		 * @return	Tween object
		 */
		public function play(frame:* = 0, killTargetTweens:Boolean = true):EazeTween
		{
			if (_inited || _configured) return chain().play(frame, killTargetTweens);
			configure("auto", { frame:frame });
			if (autoStart) start(killTargetTweens);
			return this;
		}
		
		/**
		 * Chain another tween after current tween
		 * @param	otherTarget		Chain another target after the current tween ends
		 */
		public function chain(target:Object = null):EazeTween
		{
			var tween:EazeTween = new EazeTween(target || this.target, false);
			if (!_chain) _chain = [];
			_chain.push(tween);
			return tween;
		}

	}

}

/**
 * Tweened propertie infos (chained list)
 */
final class EazeProperty
{
	public var name:String;
	public var start:Number;
	public var end:Number;
	public var delta:Number;
	public var next:EazeProperty;
	
	function EazeProperty(name:String, end:Number, next:EazeProperty)
	{
		this.name = name;
		this.end = end;
		this.next = next;
	}
	
	public function init(target:Object, reversed:Boolean):void
	{
		if (reversed)
		{
			start = end;
			end = target[name];
			target[name] = start;
		}
		else start = target[name];
		
		this.delta = end - start;
	}
	
	public function dispose():void
	{
		if (next) next.dispose();
		next = null;
	}
}

import aze.motion.EazeTween;

/**
 * Information to honor tween completion: complete event, chaining.
 */
final class CompleteData
{
	private var callback:Function;
	private var args:Array;
	private var chain:Array;
	private var diff:Number;
	
	function CompleteData(callback:Function, args:Array, chain:Array, diff:Number)
	{
		this.callback = callback;
		this.args = args;
		this.chain = chain;
		this.diff = diff;
	}
	
	public function execute():void
	{
		if (callback != null)
		{
			callback.apply(null, args);
			callback = null;
		}
		args = null;
		if (chain)
		{
			var len:int = chain.length;
			for (var i:int = 0; i < len; i++) 
				EazeTween(chain[i]).start(false, diff);
			chain = null;
		}
	}
}

