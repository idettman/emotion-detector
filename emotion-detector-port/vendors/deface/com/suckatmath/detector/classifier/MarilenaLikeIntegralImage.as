package com.suckatmath.detector.classifier 
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	
	
	/**
	 * ...
	 * @author srs
	 */
	public class MarilenaLikeIntegralImage implements IntegralImage
	{
		public  var bd    :BitmapData;
		public  var _ii   :Vector.<Number>;	// IntegralImage
		public  var _ii2  :Vector.<Number>;	// IntegralImage of squared pixels
		public  var iiw   :int;
		public  var iih   :int;

		private var padded:BitmapData
		private var paddedPoint:Point

		private static  var bwmat:Array = [0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		.2989, .587, .114, 0, 0,
		0, 0, 0, 0, 0];

		private static  var bwfilter:ColorMatrixFilter = new ColorMatrixFilter(bwmat);
		
		
		public function MarilenaLikeIntegralImage(b:BitmapData) 
		{
			this.bitmapData = b;
		}

		public function set bitmapData(b:BitmapData):void{
			bd = b;
			var bwidth:int = bd.width;
			var bheight:int = bd.height;
			//padded = new BitmapData(bwidth,bheight, false, 0x00000000 );
			//paddedPoint = new Point();
			update();
		}
		
		public function update():void {
			//padded.applyFilter(bd, bd.rect, paddedPoint, bwfilter);
			//var ba:Vector.<uint> = padded.getVector(bd.rect);
			var ba:Vector.<uint> = bd.getVector(bd.rect);
			

			if ( (bd.width + 1) != iiw || (bd.height + 1) != iih ) {
				var pixelCount:int = (bd.width + 1) * (bd.height + 1);
				_ii  = new Vector.<Number>(pixelCount, true);
				_ii2 = new Vector.<Number>(pixelCount, true);
			}
			
			// build IntegralImages
			// IntegralImage is 1 size larger than image
			// all 0 for the 1st row,column
			iiw = bd.width +1;
			iih = bd.height+1;
			var singleII  :Number = 0;
			var singleII2 :Number = 0;
			for( var j:int=0; j<iih; j++ ){
				for( var i:int=0; i<iiw; i++ ){
					if( i==0 || j==0 ){
						//_ii.push(0);
						//_ii2.push(0);
						_ii[  j*iiw+i ] = 0;
						_ii2[ j*iiw+i ] = 0;
						continue;
					}
					var pix:uint = (ba[((bd.width*(j-1))+(i-1))] >>> 16 ) & 0xff;//bd.getPixel(i-1,j-1)>>16;
					singleII  = _ii[iiw*(j-1)+i]  + _ii[iiw*j+i-1]  + pix     - _ii[iiw*(j-1)+i-1];
					singleII2 = _ii2[iiw*(j-1)+i] + _ii2[iiw*j+i-1] + pix*pix - _ii2[iiw*(j-1)+i-1];
					//_ii.push(singleII);
					//_ii2.push(singleII2);
					_ii[  j*iiw+i ] = singleII;
					_ii2[ j*iiw+i ] = singleII2;
				}
			}
			
		}

		public function getRectSum(r:Rectangle):Number {
			var x:int = r.x;
			var y:int = r.y;
			var w:int = r.width;
			var h:int = r.height;
			
			var y_iiw   :Number = y     * iiw;
			var yh_iiw  :Number = (y+h) * iiw;
			return _ii[y_iiw  + x    ] +
				   _ii[yh_iiw + x + w] -
				   _ii[yh_iiw + x    ] -
				   _ii[y_iiw  + x + w];
		}

		// sum of squared pixel
		public function getRectSqSum(r:Rectangle):Number{
			var x:int = r.x;
			var y:int = r.y;
			var w:int = r.width;
			var h:int = r.height;
			
			var y_iiw   :Number = y     * iiw;
			var yh_iiw  :Number = (y+h) * iiw;
			return _ii2[y_iiw  + x    ] +
				   _ii2[yh_iiw + x + w] -
				   _ii2[yh_iiw + x    ] -
				   _ii2[y_iiw  + x + w];
		}

		public function getII(x:int,y:int):Number{
			return _ii[y*iiw+x];
		}

		public function getII2(x:int,y:int):Number{
			return _ii2[y*iiw+x];
		}

		public function getWidth():int{
			return bd.width;
		}

		public function getHeight():int{
			return bd.height;
		}
		
	}
	
}