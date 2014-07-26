package com.suckatmath.tracker 
{
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Classic mean-shift tracker
	 * @author srs
	 */
	public class MeanShiftTracker extends EventDispatcher
	{
		
		//last location
		public var lastPoint:Point;
		
		//last bounds
		private var lpRect:Rectangle;
		
		//bitmapdata to track in
		private var bmd:BitmapData;
		
		//rgb histogram model of tracked region
		private var modelHisto:Vector.<Vector.<Vector.<Number>>>;
		
		//rgb histogram model of candidate region
		private var candidateHisto:Vector.<Vector.<Vector.<Number>>>;

		//constant for helping calculate epanechnikov kernel
		private static const TwoOverPI:Number = 2.0 / Math.PI;
		
		private var round:Function = Math.round; //for performance reasons, use local copy of round
		
		private var maxiter:int;
		
		public function MeanShiftTracker(bd:BitmapData = null, trect:Rectangle = null, maxit:int = 20) 
		{
			setBitmapData(bd);
			if (trect != null) {
				setTrackTarget(trect);
			}
			maxiter = maxit;
			modelHisto = new Vector.<Vector.<Vector.<Number>>>(16);
			for (var i:int = 0; i < modelHisto.length; i++) {
				modelHisto[i] = new Vector.<Vector.<Number>>(16);
				for (var j: int = 0; j < modelHisto[i].length; j++) {
					modelHisto[i][j] = new Vector.<Number>(16);
				}
			}
			
		}
		
		/*
		 * update position, and return new position
		 * 
		 * @return Point representing new location of tracked object
		 */
		public function update():Point {
			var i:int;
			var halfw:int = lpRect.width / 2;
			var halfh:int = lpRect.height / 2;
			var weight:Number;
			var r:int, g:int, b:int;
			var xsum:Number;
			var ysum:Number;
			var cpix:uint;
			var px:Vector.<uint>;
			var newx:Number;
			var newy:Number;
			var weightsum:Number;
			var origin:Point = new Point();
			var q:int;
            for (q = 0; q < maxiter; q++){ //max iterations.
				xsum = 0;
				ysum = 0;
				weightsum = 0;
				px = bmd.getVector(lpRect);
				i = 0;
				for (var n:int = -halfh; i < lpRect.height; i++, n++) {
					for (var j:int = 0, m:int = -halfw; j < lpRect.width; j++, m++) {
						cpix = px[i*lpRect.width +j];
						r = (cpix >> 20) & 0xf;
						g = (cpix >> 12) & 0xf;
						b = (cpix >> 4) & 0xf;
						weight = (modelHisto[r][g][b]);
						weightsum += weight;
						xsum += m * weight;
						ysum += n * weight;
					}
				}
				//prevent error if NO pixels match model.
				if (weightsum == 0) {
					continue;
				}
				newx = xsum  / weightsum;
				newy = ysum  / weightsum;
				lastPoint.x += round(newx);
				lastPoint.y += round(newy);
				//prevent going outside the boundaries
				if (lastPoint.x < halfw) {
					lastPoint.x = halfw;
				}else if (lastPoint.x > bmd.width - halfw) {
					lastPoint.x = bmd.width - halfw;
				}
				if (lastPoint.y < halfh) {
					lastPoint.y = halfh;
				}else if (lastPoint.y > bmd.height - halfh) {
					lastPoint.y = bmd.height - halfh;
				}
				lpRect.x = lastPoint.x - halfw;
				lpRect.y = lastPoint.y - halfh;
				if (newx*newx + newy*newy < 1) { //new position is less than 1 pixel from old
					break;
				}
				
			}	
			if (q >= maxiter) {
				dispatchEvent(new TrackerEvent(TrackerEvent.LOST));
			}
			//todo: use bhattarcharyya coefficient
			return lastPoint;
		}
		
		public function setTrackTarget(rect:Rectangle):void {
			lpRect = rect.clone();
			if (lpRect.width % 2 != 0) {
				lpRect.width--;
			}
			if (lpRect.height % 2 != 0) {
				lpRect.height--;
			}
			lastPoint = new Point(lpRect.x + lpRect.width / 2, lpRect.y + lpRect.height / 2);
			getHisto(bmd, lpRect, modelHisto);
		}
		
		public function setBitmapData(bd:BitmapData):void {
			this.bmd = bd;
		}
		
		private function getHisto(bd:BitmapData, rect:Rectangle, targetHisto:Vector.<Vector.<Vector.<Number>>>):void {
			var i:int, j:int, k:int;
			for (i = 0; i < 16; i++) {
				for (j = 0; j < 16; j++) {
					for (k = 0; k < 16; k++) {
						targetHisto[i][j][k] = 0;
					}
				}
			}
			var ba:Vector.<uint> = bd.getVector(rect);
			var r:int, g:int, b:int;
			var px:uint;
			var m:Number, n:Number;
			var stepY:Number = 1.0 / (rect.height);
			var stepX:Number = 1.0 / (rect.width);
			
			for (i = 0, m = -0.5; i < rect.height; i++, m+=stepY) {
				for (j = 0, n = -0.5; j < rect.width; j++, n+=stepX) {
					px = ba[i * rect.width + j];
					r = (px >> 20) & 0xf;
					g = (px >> 12) & 0xf;
					b = (px >>  4) & 0xf;
					targetHisto[r][g][b]+= epanechnikov(n,m);
				}
			}
		}

		/**
		 * epanechnikov kernel is simply a way of weighting pixels further from the center less, on the assumption that central 
		 * pixels are more likely to be important (less likely to be background).
		 * 
		 * */
		private function epanechnikov(xnorm:Number, ynorm:Number):Number {
			return TwoOverPI * (1 - (xnorm * xnorm + ynorm * ynorm));
			
		}
	}
	
}