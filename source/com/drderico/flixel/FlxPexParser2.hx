package com.drderico.flixel ;

import com.drderico.flixel.FlxTypedExtendedEmitter;
import flixel.effects.particles.FlxEmitter.FlxEmitterMode;
import flixel.effects.particles.FlxParticle;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import haxe.xml.Fast;
import haxe.xml.Parser;
import openfl.Assets;
import openfl.display.BlendMode;

/**
 * Parser for Starling/Sparrow particle files created with http://onebyonedesign.com/flash/particleeditor/
 * @author MrCdK
 *
 * Extended parser for Starling/Sparrow particle files created with http://onebyonedesign.com/flash/particleeditor/
	 * Works with extended version of FlxEmitter - FlxTypedExtendedEmitter
 * @author DrDerico
 */
class FlxPexParser2
{
	/**
	 * This function will parse a *.pex file and return a new emitter.
	 * There are some incompatibilities:
	 *  - Blend functions aren't supported. The default blend mode is ADD.
	 * @param	data			The data to be parsed. It has to be an ID to the assets file, a file embedded with @:file(), a string with the content of the file or a XML object.
	 * @param	particleGraphic	The particle graphic
	 * @param	emitter			(optional) A FlxExtendedEmitter. Most properties will be overwritten!
	 * @return	A new emitter
	 */
	public static function parse<T:FlxExtendedEmitter>(data:Dynamic, particleGraphic:FlxGraphicAsset, ?emitter:T):T
	{
		if (emitter == null)
		{
			emitter = cast new FlxExtendedEmitter();
		}

		var config:Fast = getFastNode(data);

		// Need to extract the particle graphic information
		var particle:FlxParticle = new FlxParticle();
		particle.loadGraphic(particleGraphic);

		var emitterType = Std.parseInt(config.node.emitterType.att.value);

		var maxParticles:Int = Std.parseInt(config.node.maxParticles.att.value);

		var lifespan = minMax("particleLifeSpan", "particleLifespanVariance", config);
		var speed = minMax("speed", config);

		var angle = minMax("angle", config);

		var startSize = minMax("startParticleSize", config);
		var finishSize = minMax("finishParticleSize", "FinishParticleSizeVariance", config);
		var rotationStart = minMax("rotationStart", config);
		var rotationEnd = minMax("rotationEnd", config);

		var radialAccel = minMax("radialAcceleration", "radialAccelVariance", config);
		var tangentialAccel = minMax("tangentialAcceleration", "tangentialAccelVariance", config);

		var sourcePositionVariance = xy("sourcePositionVariance", config);
		var gravity = xy("gravity", config);

		var emitMaxRadius = minMax("maxRadius", config);
		/*var emitMinRadius = { min:0.0, max:0.0 };
		try
		{*/
			var emitMinRadius = minMax("minRadius", config);
		/*} catch(msg:String)
		{
			emitMinRadius.min = value("minRadius", config);
		}*/

		var rotatePerSecond = minMax("rotatePerSecond", config);

		var startColors = color("startColor", config);
		var finishColors = color("finishColor", config);

		emitter.type = emitterType;
		emitter.launchMode = FlxEmitterMode.CIRCLE;
		emitter.loadParticles(particleGraphic, maxParticles);

		emitter.width = sourcePositionVariance.x == 0 ? 1 : sourcePositionVariance.x * 2;
		emitter.height = sourcePositionVariance.y == 0 ? 1 : sourcePositionVariance.y * 2;

		emitter.lifespan.set(lifespan.min, lifespan.max);

		if (emitterType == FlxExtendedEmitterType.GRAVITY)
		{
			emitter.acceleration.set(gravity.x, gravity.y);
			emitter.launchAngle.set(angle.min, angle.max);
			emitter.speed.start.set(speed.min, speed.max);
			emitter.speed.end.set(speed.min, speed.max);
			emitter.angle.set(rotationStart.min, rotationStart.max, rotationEnd.min, rotationEnd.max);
			emitter.radialAcceleration.set(radialAccel.min, radialAccel.max);
			emitter.tangentialAcceleration.set(tangentialAccel.min, tangentialAccel.max);
		}
		else if (emitterType == FlxExtendedEmitterType.RADIAL)
		{
			emitter.emitRadius.set(emitMaxRadius.min, emitMaxRadius.max, emitMinRadius.min, emitMinRadius.max);
			emitter.rotatePerSecond.set(FlxAngle.asRadians(rotatePerSecond.min), FlxAngle.asRadians(rotatePerSecond.max));
			emitter.emitRotation.set(FlxAngle.asRadians(angle.min), FlxAngle.asRadians(angle.max), FlxAngle.asRadians(angle.min), FlxAngle.asRadians(angle.max));
		}

		// Size
		var sizeValue = startSize.min / particle.frameWidth;
		sizeValue = (sizeValue < 0.1) ? 0.1 : sizeValue;
		emitter.scale.start.min.set(sizeValue, sizeValue);

		sizeValue = startSize.max / particle.frameWidth;
		sizeValue = (sizeValue < 0.1) ? 0.1 : sizeValue;
		emitter.scale.start.max.set(sizeValue, sizeValue);

		sizeValue = finishSize.min / particle.frameWidth;
		sizeValue = (sizeValue < 0.1) ? 0.1 : sizeValue;
		emitter.scale.end.min.set(sizeValue, sizeValue);

		sizeValue = finishSize.max / particle.frameWidth;
		sizeValue = (sizeValue < 0.1) ? 0.1 : sizeValue;
		emitter.scale.end.max.set(sizeValue, sizeValue);

		// Alpha, color

		emitter.alpha.set(startColors.minColor.alphaFloat, startColors.maxColor.alphaFloat, finishColors.minColor.alphaFloat, finishColors.maxColor.alphaFloat);
		emitter.color.set(startColors.minColor, startColors.maxColor, finishColors.minColor, finishColors.maxColor);

		emitter.blend = BlendMode.ADD;
		emitter.keepScaleRatio = true;
		return emitter;
	}

	private static function minMax(property:String, ?propertyVariance:String, config:Fast): { min:Float, max:Float }
	{
		if (propertyVariance == null)
		{
			propertyVariance = property + "Variance";
		}

		var node = config.node.resolve(property);
		var varianceNode = config.node.resolve(propertyVariance);

		var min = Std.parseFloat(node.att.value);
		var variance = Std.parseFloat(varianceNode.att.value);

		return
		{
			min: min - variance,
			max: min + variance
		};
	}

	private static function value(property:String, config:Fast): Float
	{
		var node = config.node.resolve(property);

		return Std.parseFloat(node.att.value);
	}

	private static function xy(property:String, config:Fast): { x:Float, y:Float }
	{
		var node = config.node.resolve(property);

		return
		{
			x: Std.parseFloat(node.att.x),
			y: Std.parseFloat(node.att.y)
		};
	}

	private static function color(property:String, config:Fast): { minColor:FlxColor, maxColor:FlxColor }
	{
		var node = config.node.resolve(property);
		var varianceNode = config.node.resolve(property + "Variance");

		var minR = Std.parseFloat(node.att.red);
		var minG = Std.parseFloat(node.att.green);
		var minB = Std.parseFloat(node.att.blue);
		var minA = Std.parseFloat(node.att.alpha);

		var varR = Std.parseFloat(varianceNode.att.red);
		var varG = Std.parseFloat(varianceNode.att.green);
		var varB = Std.parseFloat(varianceNode.att.blue);
		var varA = Std.parseFloat(varianceNode.att.alpha);

		return
		{
			minColor: FlxColor.fromRGBFloat(minR - varR, minG - varG, minB - varB, minA - varA),
			maxColor: FlxColor.fromRGBFloat(minR + varR, minG + varG, minB + varB, minA + varA)
		};
	}

	private static function getFastNode(data:Dynamic):Fast
	{
		var str:String = "";
		var firstElement:Xml = null;

		// data embedded with @:file
		if (Std.is(data, Class))
		{
			str = Type.createInstance(data, []);
		}
		// data is a XML object
		else if (Std.is(data, Xml))
		{
			firstElement = data.firstElement();
		}
		// data is an ID or the content
		else if (Std.is(data, String))
		{
			// is the pexFile an ID to an asset or the content of the file?
			if (Assets.exists(data))
			{
				str = Assets.getText(data);
			}
			else
			{
				str = data;
			}
		}
		else
		{
			throw 'Unknown input data format. It has to be an ID to the assets file, a file embedded with @:file(), a string with the content of the file or a XML object.';
		}

		// the data wasn't a XML object.
		if (firstElement == null)
		{
			firstElement = Parser.parse(str).firstElement();
		}

		if (firstElement == null || firstElement.nodeName != "particleEmitterConfig")
		{
			throw 'The input data is incorrect.';
		}

		return new Fast(firstElement);
	}

}
