package sdg.graphics.particles;

import kha.Color;
import kha.Scheduler;
import kha.Shaders;
import kha.graphics2.Graphics;
import kha.graphics4.BlendingFactor;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import sdg.graphics.particles.util.MathHelper;
import sdg.graphics.particles.util.ParticleColor;
import sdg.graphics.particles.util.ParticleVector;
import sdg.atlas.Region;

class ParticleSystem extends Graphic 
{
    public static inline var EMITTER_TYPE_GRAVITY : Int = 0;
    public static inline var EMITTER_TYPE_RADIAL : Int = 1;

    public static inline var POSITION_TYPE_FREE : Int = 0;
    public static inline var POSITION_TYPE_RELATIVE : Int = 1;
    public static inline var POSITION_TYPE_GROUPED : Int = 2;

    public var emitterType : Int;
    public var maxParticles : Int;
    public var positionType : Int;
    public var duration : Float;
    public var gravity : ParticleVector;
    public var particleLifespan : Float;
    public var particleLifespanVariance : Float;
    public var speed : Float;
    public var speedVariance : Float;
    public var sourcePosition : ParticleVector;
    public var sourcePositionVariance : ParticleVector;
    //public var angle : Float;
    public var angleVariance : Float;
    public var startParticleSize : Float;
    public var startParticleSizeVariance : Float;
    public var finishParticleSize : Float;
    public var finishParticleSizeVariance : Float;
    public var startColor : ParticleColor;
    public var startColorVariance : ParticleColor;
    public var finishColor : ParticleColor;
    public var finishColorVariance : ParticleColor;
    public var minRadius : Float;
    public var minRadiusVariance : Float;
    public var maxRadius : Float;
    public var maxRadiusVariance : Float;
    public var rotationStart : Float;
    public var rotationStartVariance : Float;
    public var rotationEnd : Float;
    public var rotationEndVariance : Float;
    public var radialAcceleration : Float;
    public var radialAccelerationVariance : Float;
    public var tangentialAcceleration : Float;
    public var tangentialAccelerationVariance : Float;
    public var rotatePerSecond : Float;
    public var rotatePerSecondVariance : Float;
    public var blendFuncSource : BlendingFactor;
    public var blendFuncDestination : BlendingFactor;
	public var region : Region;
    public var active : Bool;
    public var restart : Bool;
    public var particleScaleX : Float;
    public var particleScaleY : Float;
    public var particleScaleSize : Float;
    public var yCoordMultiplier : Float;
    public var emissionFreq : Float;

    private var prevTime : Float;
    private var emitCounter : Float;
    private var elapsedTime : Float;

    public var particleList : Array<Particle>;
    public var particleCount : Int;
	
	var shaderPipeline:PipelineState;	
	
	// temp variables used in the render
	var particle:Particle;
	var scale:Float;
	//var rotation:Float;

    public function new() : Void 
	{
		super();
		
        active = false;
        restart = false;
        particleScaleX = 1.0;
        particleScaleY = 1.0;
        particleScaleSize = 1.0;
        emissionFreq = 0.0;		
    }

    public function __initialize() : Void 
	{
		initShaders();

        prevTime = -1.0;
        emitCounter = 0.0;
        elapsedTime = 0.0;

        if (emissionFreq <= 0.0) 
		{
            var emissionRate : Float = maxParticles / Math.max(0.0001, particleLifespan);

            if (emissionRate > 0.0) 
			{
                emissionFreq = 1.0 / emissionRate;
            }
        }

        particleList = new Array<Particle>();
        particleCount = 0;

        for (i in 0 ... maxParticles) 		
            particleList[i] = new Particle();        
    }
	
	function initShaders():Void
	{
		if (shaderPipeline != null) 
			return;
			
		shaderPipeline = new PipelineState();
		shaderPipeline.fragmentShader = Shaders.particles_frag;
		shaderPipeline.vertexShader = Shaders.painter_image_vert;
		
		var structure = new VertexStructure();
		structure.add('vertexPosition', VertexData.Float3);
		structure.add('texPosition', VertexData.Float2);
		structure.add('vertexColor', VertexData.Float4);
		shaderPipeline.inputLayout = [structure];
		
		shaderPipeline.blendSource = blendFuncSource;
		shaderPipeline.blendDestination = blendFuncDestination;
		
		shaderPipeline.alphaBlendSource = BlendingFactor.Undefined;
		shaderPipeline.alphaBlendDestination = BlendingFactor.Undefined;
		
		shaderPipeline.compile();
	}
	
    override public function update():Void
	{
        var currentTime = Scheduler.time(); //Timer.stamp();

        if (prevTime < 0.0) 
		{
            prevTime = currentTime;
            return;
        }

        var dt = currentTime - prevTime;

        if (dt < 0.0001) 		
            return;        

        prevTime = currentTime;

        if (active && emissionFreq > 0.0) 
		{
            emitCounter += dt;

            while (particleCount < maxParticles && emitCounter > emissionFreq) 
			{
                initParticle(particleList[particleCount]);
                particleCount++;
                emitCounter -= emissionFreq;
            }

            if (emitCounter > emissionFreq) 
			{
                emitCounter = (emitCounter % emissionFreq);
            }

            elapsedTime += dt;

            if (duration >= 0.0 && duration < elapsedTime) 
			{
                stop();
            }
        }
		
		// TODO: check this variable
        var updated = false;

        if (particleCount > 0) 		
            updated = true;        

        var index = 0;

        while (index < particleCount) 
		{
            var particle = particleList[index];

            if (particle.update(this, dt)) 
			{
                index++;
            } 
			else 
			{
                if (index != particleCount - 1) 
				{
                    var tmp = particleList[index];
                    particleList[index] = particleList[particleCount - 1];
                    particleList[particleCount - 1] = tmp;
                }

                particleCount--;
            }
        }

        if (particleCount > 0) 		
            updated = true;        
		else if (restart) 		
            active = true;        

        //return updated;
    }

    private function initParticle(p : Particle) : Void 
	{
        // Common
        p.timeToLive = Math.max(0.0001, particleLifespan + particleLifespanVariance * MathHelper.rnd1to1());

        p.startPos.x = sourcePosition.x / particleScaleX;
        p.startPos.y = sourcePosition.y / particleScaleY;

        p.color = {
            r: MathHelper.clamp(startColor.r + startColorVariance.r * MathHelper.rnd1to1()),
            g: MathHelper.clamp(startColor.g + startColorVariance.g * MathHelper.rnd1to1()),
            b: MathHelper.clamp(startColor.b + startColorVariance.b * MathHelper.rnd1to1()),
            a: MathHelper.clamp(startColor.a + startColorVariance.a * MathHelper.rnd1to1()),
        };

        p.colorDelta = {
            r: (MathHelper.clamp(finishColor.r + finishColorVariance.r * MathHelper.rnd1to1()) - p.color.r) / p.timeToLive,
            g: (MathHelper.clamp(finishColor.g + finishColorVariance.g * MathHelper.rnd1to1()) - p.color.g) / p.timeToLive,
            b: (MathHelper.clamp(finishColor.b + finishColorVariance.b * MathHelper.rnd1to1()) - p.color.b) / p.timeToLive,
            a: (MathHelper.clamp(finishColor.a + finishColorVariance.a * MathHelper.rnd1to1()) - p.color.a) / p.timeToLive,
        };

        p.particleSize = Math.max(0.0, startParticleSize + startParticleSizeVariance * MathHelper.rnd1to1());

        p.particleSizeDelta = (Math.max(
            0.0,
            finishParticleSize + finishParticleSizeVariance * MathHelper.rnd1to1()) - p.particleSize
        ) / p.timeToLive;

        p.rotation = rotationStart + rotationStartVariance * MathHelper.rnd1to1();
        p.rotationDelta = (rotationEnd + rotationEndVariance * MathHelper.rnd1to1() - p.rotation) / p.timeToLive;

        var computedAngle = angle + angleVariance * MathHelper.rnd1to1();

        // For gravity emitter type
        var directionSpeed = speed + speedVariance * MathHelper.rnd1to1();

        p.position.x = p.startPos.x + sourcePositionVariance.x * MathHelper.rnd1to1();
        p.position.y = p.startPos.y + sourcePositionVariance.y * MathHelper.rnd1to1();
        p.direction.x = Math.cos(computedAngle) * directionSpeed;
        p.direction.y = Math.sin(computedAngle) * directionSpeed;
        p.radialAcceleration = radialAcceleration + radialAccelerationVariance * MathHelper.rnd1to1();
        p.tangentialAcceleration = tangentialAcceleration + tangentialAccelerationVariance * MathHelper.rnd1to1();

        // For radial emitter type
        p.angle = computedAngle;
        p.angleDelta = (rotatePerSecond + rotatePerSecondVariance * MathHelper.rnd1to1()) / p.timeToLive;
        p.radius = maxRadius + maxRadiusVariance * MathHelper.rnd1to1();
        p.radiusDelta = (minRadius + minRadiusVariance * MathHelper.rnd1to1() - p.radius) / p.timeToLive;
    }
	
	public function emit():Void
	{
		sourcePosition.x = x;
		sourcePosition.y = y;
		active = true;
	}

    public function emitAtPosition(?sourcePositionX : Null<Float>, ?sourcePositionY : Null<Float>) : Void 
	{
        if (sourcePositionX != null) 		
            sourcePosition.x = sourcePositionX;        

        if (sourcePositionY != null) 		
            sourcePosition.y = sourcePositionY;        

        active = true;
    }

    public function stop() : Void 
	{
        active = false;
        elapsedTime = 0.0;
        emitCounter = 0.0;
    }

    public function reset() : Void 
	{
        stop();

        for (i in 0 ... particleCount) 		
            particleList[i].timeToLive = 0.0;        
    }
	
	override public function render(g:Graphics, objectX:Float, objectY:Float, cameraX:Float, cameraY:Float):Void 
	{
		if (!visible)
			return;
			
		//if (angle != 0)
		//	g.pushRotation(angle, object.x + x + pivot.x - cameraX, object.y + y + pivot.y - cameraY);
			
		if (alpha != 1) 
			g.pushOpacity(alpha);
			
		g.pipeline = shaderPipeline;
			
		for (i in 0 ... particleCount)
		{
			particle = particleList[i];			
			scale = particle.particleSize / region.w * particleScaleSize;			
			//rotation = particle.rotation * 180.0 / Math.PI + 90.0;			
			g.color = Color.fromFloats(particle.color.r, particle.color.g, particle.color.b, particle.color.a);
			
			g.drawScaledSubImage(region.image, region.sx, region.sy, region.w, region.h,
							 objectX + (particle.position.x * particleScaleX) - ((region.w * scale) * 0.5) - (!object.fixed.x ? cameraX : 0), 
							 objectY + (particle.position.y * particleScaleY) - ((region.h * scale) * 0.5) - (!object.fixed.y ? cameraY : 0), 
							 region.w * scale, region.h * scale);
		}
			
		g.pipeline = null;
		
		if (alpha != 1)
			g.popOpacity();
			
		//if (angle != 0)		
		//	g.popTransformation();
	}	
}
