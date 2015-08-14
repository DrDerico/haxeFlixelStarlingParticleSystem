package com.drderico.flixel;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.helpers.FlxRange;

/**
 * This is a simple particle class that extends the default behavior
 * of FlxSprite to have slightly more specialized behavior
 * common to many game scenarios.  You can override and extend this class
 * just like you would FlxSprite. While FlxEmitter
 * used to work with just any old sprite, it now requires a
 * FlxExtendedParticle based class.
 *
 * Extended by DrDerico		Jan 22, 2015
 * Added:
	 * support for radial and tangential acceleration
	 * type of emmiter - GRAVITY or RADIAL
	 * radial functionality
*/
class FlxExtendedParticle extends FlxSprite implements IFlxExtendedParticle
{
	/**
	 * How long this particle lives before it disappears. Set to 0 to never kill() the particle automatically.
	 * NOTE: this is a maximum, not a minimum; the object could get recycled before its lifespan is up.
	 */
	public var lifespan:Float = 0;
	/**
	 * How long this particle has lived so far.
	 */
	public var age(default, null):Float = 0;
	/**
	 * What percentage progress this particle has made of its total life. Essentially just (age / lifespan) on a scale from 0 to 1.
	 */
	public var percent(default, null):Float = 0;
	/**
	 * Whether or not the hitbox should be updated each frame when scaling.
	 */
	public var autoUpdateHitbox:Bool = false;
	/**
	 * The range of values for velocity over this particle's lifespan.
	 */
	public var velocityRange:FlxRange<FlxPoint>;
	/**
	 * The range of values for angularVelocity over this particle's lifespan.
	 */
	public var angularVelocityRange:FlxRange<Float>;
	/**
	 * The range of values for scale over this particle's lifespan.
	 */
	public var scaleRange:FlxRange<FlxPoint>;
	/**
	 * The range of values for alpha over this particle's lifespan.
	 */
	public var alphaRange:FlxRange<Float>;
	/**
	 * The range of values for color over this particle's lifespan.
	 */
	public var colorRange:FlxRange<FlxColor>;
	/**
	 * The range of values for drag over this particle's lifespan.
	 */
	public var dragRange:FlxRange<FlxPoint>;
	/**
	 * The range of values for acceleration over this particle's lifespan.
	 */
	public var accelerationRange:FlxRange<FlxPoint>;
	/**
	 * The range of values for elasticity over this particle's lifespan.
	 */
	public var elasticityRange:FlxRange<Float>;

	/**
	 * The amount of change from the previous frame.
	 */
	private var _delta:Float = 0;

	// Vars for radial and tangential acceleration calculations
	private var _distanceX:Float = 0;
	private var _distanceY:Float = 0;
	private var _distanceScalar:Float = 0;
	private var _radialX:Float = 0;
	private var _radialY:Float = 0;
	private var _tangentialX:Float = 0;
	private var _tangentialY:Float = 0;
	private var _prevTangentialX:Float = 0;

	public var emitRadiusRange:FlxRange<Float>;
	public var emitRotationRange:FlxRange<Float>;

	public var emitRotation:Float = 0;
	public var emitRadius:Float = 0;
	public var startPosition:FlxPoint;

	public var radialAcceleration:Float=0;
	public var tangentialAcceleration:Float=0;
	/**
	 * Instantiate a new particle. Like FlxSprite, all meaningful creation
	 * happens during loadGraphic() or makeGraphic() or whatever.
	 */
	@:keep
	public function new()
	{
		super();

		velocityRange = new FlxRange<FlxPoint>(FlxPoint.get(), FlxPoint.get());
		angularVelocityRange = new FlxRange<Float>(0);
		scaleRange = new FlxRange<FlxPoint>(FlxPoint.get(1,1), FlxPoint.get(1,1));
		alphaRange = new FlxRange<Float>(1, 1);
		colorRange = new FlxRange<FlxColor>(FlxColor.WHITE);
		dragRange = new FlxRange<FlxPoint>(FlxPoint.get(), FlxPoint.get());
		accelerationRange = new FlxRange<FlxPoint>(FlxPoint.get(), FlxPoint.get());
		elasticityRange = new FlxRange<Float>(0);
		emitRadiusRange = new FlxRange<Float>(0);
		emitRotationRange = new FlxRange<Float>(0);
		startPosition = FlxPoint.get();

		exists = false;
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		FlxDestroyUtil.put(velocityRange.start);
		FlxDestroyUtil.put(velocityRange.end);
		FlxDestroyUtil.put(scaleRange.start);
		FlxDestroyUtil.put(scaleRange.end);
		FlxDestroyUtil.put(dragRange.start);
		FlxDestroyUtil.put(dragRange.end);
		FlxDestroyUtil.put(accelerationRange.start);
		FlxDestroyUtil.put(accelerationRange.end);
		FlxDestroyUtil.put(startPosition);

		velocityRange = null;
		angularVelocityRange = null;
		scaleRange = null;
		alphaRange = null;
		colorRange = null;
		dragRange = null;
		accelerationRange = null;
		elasticityRange = null;
		emitRadiusRange = null;
		emitRotationRange = null;
		startPosition = null;

		super.destroy();
	}

	/**
	 * The particle's main update logic. Basically updates properties if alive, based on ranged properties.
	 */
	override public function update(elapsed:Float):Void
	{
		if (age < lifespan)
		{
			age += elapsed;
		}

		if (age >= lifespan && lifespan != 0)
		{
			kill();
		}
		else
		{
			_delta = elapsed / lifespan;
			percent = age / lifespan;

			if (velocityRange.active)
			{
				velocity.x += (velocityRange.end.x - velocityRange.start.x) * _delta;
				velocity.y += (velocityRange.end.y - velocityRange.start.y) * _delta;
			}

			if (angularVelocityRange.active)
			{
				angularVelocity += (angularVelocityRange.end - angularVelocityRange.start) * _delta;
			}

			if (scaleRange.active)
			{
				scale.x += (scaleRange.end.x - scaleRange.start.x) * _delta;
				scale.y += (scaleRange.end.y - scaleRange.start.y) * _delta;
				if (autoUpdateHitbox) updateHitbox();
			}

			if (alphaRange.active)
			{
				alpha += (alphaRange.end - alphaRange.start) * _delta;
			}

			if (colorRange.active)
			{
				color = FlxColor.interpolate(colorRange.start, colorRange.end, percent);
			}

			if (dragRange.active)
			{
				drag.x += (dragRange.end.x - dragRange.start.x) * _delta;
				drag.y += (dragRange.end.y - dragRange.start.y) * _delta;
			}

			if (accelerationRange.active)
			{
				acceleration.x += (accelerationRange.end.x - accelerationRange.start.x) * _delta;
				acceleration.y += (accelerationRange.end.y - accelerationRange.start.y) * _delta;
			}

			if (radialAcceleration != 0 || tangentialAcceleration != 0)
			{
				_distanceX = x - startPosition.x;
				_distanceY = y - startPosition.y;
				_distanceScalar = FlxMath.vectorLength(_distanceX, _distanceY);
				if (_distanceScalar < 0.01) _distanceScalar = 0.01;

               _radialX = _tangentialX = _distanceX / _distanceScalar;
               _radialY = _tangentialY = _distanceY / _distanceScalar;

				if (radialAcceleration != 0)
				{
					_radialX *= radialAcceleration;
					_radialY *= radialAcceleration;
				}

				if (tangentialAcceleration != 0)
				{
					_prevTangentialX = _tangentialX;
					_tangentialX = -_tangentialY * tangentialAcceleration;
					_tangentialY = _prevTangentialX * tangentialAcceleration;
				}
				velocity.x += (_radialX + _tangentialX) * elapsed;
				velocity.y += (_radialY + _tangentialY) * elapsed;
			}

			if (elasticityRange.active)
			{
				elasticity += (elasticityRange.end - elasticityRange.start) * _delta;
			}

			if (emitRotationRange.active)
			{
				emitRotation += emitRotationRange.end * elapsed;
			}

			if (emitRadiusRange.active)
			{
                emitRadius   += (emitRadiusRange.end - emitRadiusRange.start) * _delta;
                x = startPosition.x - Math.cos(emitRotation) * emitRadius;
                y = startPosition.y - Math.sin(emitRotation) * emitRadius;
			}
		}

		super.update(elapsed);
	}

	override public function reset(X:Float, Y:Float):Void
	{
		super.reset(X, Y);
		age = 0;
		visible = true;
	}

	/**
	 * Triggered whenever this object is launched by a FlxEmitter.
	 * You can override this to add custom behavior like a sound or AI or something.
	 */
	public function onEmit():Void {}
}

interface IFlxExtendedParticle extends IFlxSprite
{
	public var lifespan:Float;
	public var age(default, null):Float;
	public var percent(default, null):Float;
	public var autoUpdateHitbox:Bool;
	public var velocityRange:FlxRange<FlxPoint>;
	public var angularVelocityRange:FlxRange<Float>;
	public var scaleRange:FlxRange<FlxPoint>;
	public var alphaRange:FlxRange<Float>;
	public var colorRange:FlxRange<FlxColor>;
	public var dragRange:FlxRange<FlxPoint>;
	public var accelerationRange:FlxRange<FlxPoint>;
	public var elasticityRange:FlxRange<Float>;
	public var emitRadiusRange:FlxRange<Float>;
	public var emitRotationRange:FlxRange<Float>;
	public var emitRotation:Float;
	public var emitRadius:Float;
	public var startPosition:FlxPoint;
	public var radialAcceleration:Float;
	public var tangentialAcceleration:Float;

	public function onEmit():Void;
}