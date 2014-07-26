package com.suckatmath.tracker 
{
	import flash.events.Event;
	
	/**
	 * TrackerEvent is so far just a placeholder.  Plain events with type "LOST" would work too, but I like type-checking
	 * @author srs
	 */
	public class TrackerEvent extends Event
	{
		
		public static const LOST:String = "LOST";
		
		public function TrackerEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(type, bubbles, cancelable);
		}
		
	}
	
}