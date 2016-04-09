package sdg;

import kha.Scheduler;
import kha.System;
import kha.math.Vector2;
import sdg.math.Point;
import sdg.math.Rectangle;

@:allow(sdg.Engine)
class Sdg
{
	public static var dt(default, null):Float = 0;
    	
	public static var windowWidth(default, null):Int;
    public static var halfWinWidth(default, null):Int;
	public static var windowHeight(default, null):Int;
    public static var halfWinHeight(default, null):Int;
    
    public static var gameWidth(default, null):Int;
    public static var halfGameWidth(default, null):Int;
	public static var gameHeight(default, null):Int;
    public static var halfGameHeight(default, null):Int;
    
	public static var screen:Screen;
	public static var gameScale:Float = 1;
    
    /** Convert a radian value into a degree value. */
	public static var DEG(get, never):Float;
	private static inline function get_DEG(): Float { return -180 / Math.PI; }
    
    /** Convert a degree value into a radian value. */
	public static var RAD(get, never):Float;
	private static inline function get_RAD(): Float { return Math.PI / -180; }
    
    /**
	 * Flash equivalent: int.MIN_VALUE
	 */
	public static inline var INT_MIN_VALUE = -2147483648;

	/**
	 * Flash equivalent: int.MAX_VALUE
	 */
	public static inline var INT_MAX_VALUE = 2147483647;
	
	static var timeTasks:Array<Int>;
    
    // Global objects used for rendering, collision, etc.
    @:dox(hide) public static var object:Object;
    @:dox(hide) public static var point:Point = new Point();
    @:dox(hide) public static var point2:Vector2 = new Vector2();
    @:dox(hide) public static var rect:Rectangle = new Rectangle();    
	
	public static function addTimeTask(task: Void -> Void, start: Float, period: Float = 0, duration: Float = 0):Int
	{
		if (timeTasks == null)
			timeTasks = new Array<Int>();
		
		timeTasks.push(Scheduler.addTimeTask(task, start, period, duration));
		
		return timeTasks[timeTasks.length - 1];
	}
	
	public static function removeTimeTasks(id:Int):Void
	{
		if (timeTasks != null)
		{
			timeTasks.remove(id);
			Scheduler.removeTimeTask(id);
		}
	}
	
	/**
	 * Empties an array of its' contents
	 * @param array filled array
	 */
	public static inline function clear(array:Array<Dynamic>)
	{
		#if (cpp || php)
		array.splice(0, array.length);
		#else
		untyped array.length = 0;
		#end
	}
	
	/**
	 * Binary insertion sort
	 * @param list     A list to insert into
	 * @param key      The key to insert
	 * @param compare  A comparison function to determine sort order
	 */
	public static function insertSortedKey<T>(list:Array<T>, key:T, compare:T->T->Int):Void
	{
		var result:Int = 0,
			mid:Int = 0,
			min:Int = 0,
			max:Int = list.length - 1;
			
		while (max >= min)
		{
			mid = min + Std.int((max - min) / 2);
			result = compare(list[mid], key);
			if (result > 0) max = mid - 1;
			else if (result < 0) min = mid + 1;
			else return;
		}

		list.insert(result > 0 ? mid : mid + 1, key);
	}
    
    /**
	 * Find the distance between two points.
	 * @param	x1		The first x-position.
	 * @param	y1		The first y-position.
	 * @param	x2		The second x-position.
	 * @param	y2		The second y-position.
	 * @return	The distance.
	 */
	public static inline function distance(x1:Float, y1:Float, x2:Float = 0, y2:Float = 0):Float
	{
		return Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
	}
    
    /**
	 * Find the distance between two rectangles. Will return 0 if the rectangles overlap.
	 * @param	x1		The x-position of the first rect.
	 * @param	y1		The y-position of the first rect.
	 * @param	w1		The width of the first rect.
	 * @param	h1		The height of the first rect.
	 * @param	x2		The x-position of the second rect.
	 * @param	y2		The y-position of the second rect.
	 * @param	w2		The width of the second rect.
	 * @param	h2		The height of the second rect.
	 * @return	The distance.
	 */
	public static function distanceRects(x1:Float, y1:Float, w1:Float, h1:Float, x2:Float, y2:Float, w2:Float, h2:Float):Float
	{
		if (x1 < x2 + w2 && x2 < x1 + w1)
		{
			if (y1 < y2 + h2 && y2 < y1 + h1) return 0;
			if (y1 > y2) return y1 - (y2 + h2);
			return y2 - (y1 + h1);
		}
		if (y1 < y2 + h2 && y2 < y1 + h1)
		{
			if (x1 > x2) return x1 - (x2 + w2);
			return x2 - (x1 + w1);
		}
		if (x1 > x2)
		{
			if (y1 > y2) return distance(x1, y1, (x2 + w2), (y2 + h2));
			return distance(x1, y1 + h1, x2 + w2, y2);
		}
		if (y1 > y2) return distance(x1 + w1, y1, x2, y2 + h2);
		return distance(x1 + w1, y1 + h1, x2, y2);
	}
    
    /**
	 * Find the distance between a point and a rectangle. Returns 0 if the point is within the rectangle.
	 * @param	px		The x-position of the point.
	 * @param	py		The y-position of the point.
	 * @param	rx		The x-position of the rect.
	 * @param	ry		The y-position of the rect.
	 * @param	rw		The width of the rect.
	 * @param	rh		The height of the rect.
	 * @return	The distance.
	 */
	public static function distanceRectPoint(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Float
	{
		if (px >= rx && px <= rx + rw)
		{
			if (py >= ry && py <= ry + rh) return 0;
			if (py > ry) return py - (ry + rh);
			return ry - py;
		}
		if (py >= ry && py <= ry + rh)
		{
			if (px > rx) return px - (rx + rw);
			return rx - px;
		}
		if (px > rx)
		{
			if (py > ry) return distance(px, py, rx + rw, ry + rh);
			return distance(px, py, rx + rw, ry);
		}
		if (py > ry) return distance(px, py, rx, ry + rh);
		return distance(px, py, rx, ry);
	}
    
    /**
	 * Clamps the value within the minimum and maximum values.
	 * @param	value		The Float to evaluate.
	 * @param	min			The minimum range.
	 * @param	max			The maximum range.
	 * @return	The clamped value.
	 */
	public static function clamp(value:Float, min:Float, max:Float):Float
	{
		if (max > min)
		{
			if (value < min) return min;
			else if (value > max) return max;
			else return value;
		}
		else
		{
			// Min/max swapped
			if (value < max) return max;
			else if (value > min) return min;
			else return value;
		}
	}
    
    
}