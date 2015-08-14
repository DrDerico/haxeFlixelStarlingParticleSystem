package;

import com.drderico.flixel.FlxPexParser2;
import com.drderico.flixel.FlxTypedExtendedEmitter;
import flixel.*;
import flixel.effects.particles.FlxParticle;

class PlayState extends FlxState
{
	var emitter:FlxExtendedEmitter;

	override public function create():Void
	{
		FlxG.mouse.visible = false;

		emitter = FlxPexParser2.parse("assets/data/particle.pex", "assets/images/texture.png");
		emitter.x = FlxG.width / 2;
		emitter.y = FlxG.height / 2;
		emitter.start(false, 1 / (emitter.members.length / emitter.lifespan.max));
		for (s in emitter.members)
			s.antialiasing = true;
		add(emitter);
	}

	override public function update(elapsed:Float):Void
	{
		if (FlxG.mouse.pressed)
		{
			emitter.setPosition(FlxG.mouse.x, FlxG.mouse.y);
		}
		super.update(elapsed);
	}
}
