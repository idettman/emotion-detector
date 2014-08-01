package
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;


	public class MosseFilter
	{

		private var _filter:Array, _top:Array, _bottom:Array;
		private var _fft:FFT;
		private var _w:int, _h:int;
		private var _im_part:Vector.<Number>;
		private var _arrlen:int;
		private var _image_array:Vector.<Number>;
		private var peak:Number = 0.0;
		private var updateable:Boolean = false;
		private var params:Object;
		private var psr_prev:Number;
		private var peak_prev:Number;


		public function MosseFilter (params:Object = null)
		{
			this.psr_prev = undefined;
			this.peak_prev = undefined;

			if (!params) this.params = {};
			else this.params = params;

			if (this.params.psrThreshold === undefined) this.params.psrThreshold = 10;
			if (this.params.eta === undefined) this.params.eta = 0.10;
			if (this.params.convertToGrayscale === undefined) this.params.convertToGrayscale = true;
		}

		public function load (filter:Object)
		{
			// initialize filter width and height
			_w = filter.width;
			_h = filter.height;
			_arrlen = _w * _h;
			_filter = [filter.real, filter.imag];
			// handling top and bottom when they're not present
			if (filter.top && filter.bottom) {
				updateable = true;
				_top = [filter.top.real, filter.top.imag];
				_bottom = [filter.bottom.real, filter.bottom.imag];
			}

			// initialize fft to given width
			_fft = new FFT();
			_fft.init(int(filter.width));

			// set up temporary variables
			_im_part = new Vector.<Number>(_arrlen);
			_im_part.fixed = true;

			_image_array = new Vector.<Number>(_arrlen);
			_image_array.fixed = true;

			bitmapData = new BitmapData(_w, _h, false);
			imgData = new Rectangle(0, 0, _w, _h);
		}

		// not in-place// fft function
		function fft (array:Vector.<Number>):Array
		{
			var cn:Vector.<Number> = new Vector.<Number>(_arrlen);
			for (var i:int = 0; i < _arrlen; i++) {
				cn[i] = 0.0;
			}

			_fft.fft2d(array, cn);
			return [array, cn];
		}

		// fft function
		function fft_inplace (array:Vector.<Number>):Array
		{
			// in-place

			for (var i:int = 0; i < _arrlen; i++) {
				_im_part[i] = 0.0;
			}

			_fft.fft2d(array, _im_part);
			return [array, _im_part];
		}

		function ifft (rn, cn):Array
		{
			// in-place
			_fft.ifft2d(rn, cn);
			return rn;
		}

		// peak to sidelobe ratio function (optional)
		function psr (array:Array):Number
		{
			// proper
			var sum:Number = 0;
			var max:Number = 0;
			var maxpos:Array = [];
			var sdo:Number = 0;
			var val:Number;
			for (var x:int = 0; x < _w; x++) {
				for (var y:int = 0; y < _h; y++) {
					val = Number(array[(y * _w) + x]);
					sum += val;
					sdo += (val * val);
					if (max < val) {
						max = val;
						maxpos = [x, y];
					}
				}
			}

			// subtract values around peak
			for (var x:int = -5; x < 6; x++) {
				for (var y:int = -5; y < 6; y++) {
					if (Math.sqrt(x * x + y * y) < 5) {
						val = Number(array[((maxpos[1] + y) * _w) + (maxpos[0] + x)]);
						sdo -= (val * val);
						sum -= val;
					}
				}
			}

			var mean:Number = sum / array.length;
			var sd:Number = Math.sqrt((sdo / array.length) - (mean * mean));

			// get mean/variance of output around peak
			var psr:Number = (max - mean) / sd;
			return psr;
		}


		private var bitmapData:BitmapData;
		private var rect:Rectangle = new Rectangle();
		private var matrix:Matrix = new Matrix();
		private var imgData:Rectangle;

		function track (input:BitmapData, left:Number, top:Number, width:Number, height:Number, updateFilter:Boolean, gaussianPrior:Array = null, calcPSR:Boolean = false):Array
		{
			// finds position of filter in input image

			// scale selection according to original source image
			var sourceX:int = Math.round(left);
			var sourceY:int = Math.round(top);
			var sourceW:int = Math.round(width);
			var sourceH:int = Math.round(height);
			var scaleX:Number = _w / sourceW;
			var scaleY:Number = _h / sourceH;

			matrix.identity();
			matrix.scale(scaleX, scaleY);
			rect.setTo(sourceX, sourceY, sourceW, sourceH);
			bitmapData.draw(input, matrix, null, null, rect);

			var id:Vector.<uint> = input.getVector(imgData);
			var pixelValue:uint;
			var red:uint;
			var green:uint;
			var blue:uint;

			if (params.convertToGrayscale) {
				// convert to grayscale

				for (var i:int = 0; i < _arrlen; i++) {
					pixelValue = id[i];
					red = pixelValue >> 16 & 0xff;
					green = pixelValue >> 8 & 0xff;
					blue = pixelValue & 0xff;

					_image_array[i] = red * 0.3;
					_image_array[i] += green * 0.59;
					_image_array[i] += blue * 0.11;
				}
			} else {
				// use only one channel
				for (var i:int = 0; i < _arrlen; i++) {
					red = id[i] >> 16 & 0xff;
					_image_array[i] = red;
				}
			}

			// preprocess
			var prepImage:Vector.<Number> = preprocess(_image_array);
			prepImage = cosine_window(prepImage);

			// filter
			var res:Array = this.fft_inplace(prepImage);
			// elementwise multiplication with filter
			var nures:Array = complex_mult(res, _filter);
			// do inverse 2d fft
			var filtered:Array = this.ifft(nures[0], nures[1]);

			// find max and min
			var max:Number = 0;
			var min:Number = 0;
			var maxpos:Array = [];

			//method using centered gaussian prior
			if (gaussianPrior) {
				var prior, dx, dy;
				var variance = 128;
				for (var x:int = 0; x < _w; x++) {
					for (var y:int = 0; y < _h; y++) {
						dx = x - _w / 2;
						dy = y - _h / 2;
						prior = Math.exp(-0.5 * ((dx * dx) + (dy * dy)) / variance)
						if ((filtered[(y * _w) + x] * prior) > max) {
							max = filtered[(y * _w) + x] * prior;
							maxpos = [x, y];
						}
						if (filtered[(y * _w) + x] < min) {
							min = filtered[(y * _w) + x];
						}
					}
				}
			} else {
				for (var x:int = 0; x < _w; x++) {
					for (var y:int = 0; y < _h; y++) {
						if (filtered[(y * _w) + x] > max) {
							max = filtered[(y * _w) + x];
							maxpos = [x, y];
						}
						if (filtered[(y * _w) + x] < min) {
							min = filtered[(y * _w) + x];
						}
					}
				}
			}
			this.peak_prev = max;

			if (calcPSR) {
				this.psr_prev = this.psr(filtered);
			}

			if (updateFilter) {
				if (!updateable) {
					//console.log("The loaded filter does not support updating. Ignoring parameter 'updateFilter'.");
				} else {
					var psr:Number;

					if (calcPSR) {
						psr = this.psr_prev;
					} else {
						psr = this.psr(filtered);
					}

					if (psr > params.psrThreshold) {
						// create target
						var target:Vector.<Number> = new Vector.<Number>(_w * _h);
						var nux:Number = Number(maxpos[0]);
						var nuy:Number = Number(maxpos[1]);

						for (var x:int = 0; x < _w; x++) {
							for (var y:int = 0; y < _h; y++) {
								target[(y * _w) + x] = Math.exp(-(((x - nux) * (x - nux)) + ((y - nuy) * (y - nuy))) / (2 * 2));
							}
						}

						// create filter
						var res_conj:Array = complex_conj(res);
						var fuTop:Array = complex_mult(this.fft(target), res_conj);
						var fuBottom:Array = complex_mult(res, res_conj);

						// add up
						var eta:Number = Number(params.eta);
						for (var i:int = 0; i < _arrlen; i++) {
							_top[0][i] = eta * Number(fuTop[0][i]) + (1 - eta) * Number(_top[0][i]);
							_top[1][i] = eta * Number(fuTop[1][i]) + (1 - eta) * Number(_top[1][i]);
							_bottom[0][i] = eta * Number(fuBottom[0][i]) + (1 - eta) * Number(_bottom[0][i]);
							_bottom[1][i] = eta * Number(fuBottom[1][i]) + (1 - eta) * Number(_bottom[1][i]);
						}

						_filter = complex_div(_top, _bottom);
					}
				}
			}
			maxpos[0] = Number(maxpos[0]) * (width / _w);
			maxpos[1] = Number(maxpos[1]) * (width / _h);

			// check if output is strong enough
			// if not, return false?
			if (max < 0) {
				return null;
			} else {
				return maxpos;
			}
		}

		function preprocess (array:Vector.<Number>):Vector.<Number>
		{
			// in-place

			// log adjusting
			for (var i:int = 0; i < _arrlen; i++) {
				array[i] = Math.log(array[i] + 1);
			}

			// normalize to mean 0 and norm 1
			var mean:int = 0;
			for (var i:int = 0; i < _arrlen; i++) {
				mean += array[i];
			}
			mean /= _arrlen;

			for (var i:int = 0; i < _arrlen; i++) {
				array[i] -= mean;
			}
			var norm:Number = 0.0;
			for (var i:int = 0; i < _arrlen; i++) {
				norm += (array[i] * array[i]);
			}
			norm = Math.sqrt(norm);
			for (var i:int = 0; i < _arrlen; i++) {
				array[i] /= norm;
			}

			return array;
		}

		function cosine_window (array:Vector.<Number>):Vector.<Number>
		{
			// calculate rect cosine window (in-place)
			var pos:int = 0;
			for (var i:int = 0; i < _w; i++) {
				for (var j:int = 0; j < _h; j++) {
					//pos = (i%_w)+(j*_w);
					var cww:Number = Math.sin((Math.PI * i) / (_w - 1));
					var cwh:Number = Math.sin((Math.PI * j) / (_h - 1));
					array[pos] = Math.min(cww, cwh) * array[pos];
					pos++;
				}
			}

			return array;
		}

		function complex_mult (cn1:Array, cn2:Array):Array
		{
			// not in-place
			var re_part:Array = new Array(_w);
			var im_part:Array = new Array(_w);
			var nucn:Array = [re_part, im_part];
			for (var r:int = 0; r < _arrlen; r++) {
				nucn[0][r] = (cn1[0][r] * cn2[0][r]) - (cn1[1][r] * cn2[1][r]);
				nucn[1][r] = (cn1[0][r] * cn2[1][r]) + (cn1[1][r] * cn2[0][r]);
			}
			return nucn;
		}

		function complex_mult_inplace (cn1:Array, cn2:Array):void
		{
			// in-place
			var temp1:Number, temp2:Number;
			for (var r:int = 0; r < _arrlen; r++) {
				temp1 = (cn1[0][r] * cn2[0][r]) - (cn1[1][r] * cn2[1][r]);
				temp2 = (cn1[0][r] * cn2[1][r]) + (cn1[1][r] * cn2[0][r]);
				cn1[0][r] = temp1;
				cn1[1][r] = temp2;
			}
		}

		function complex_conj (cn:Array):Array
		{
			// not in-place (TODO)
			var nucn:Array = [
				[],
				[]
			];
			for (var i:int = 0; i < _arrlen; i++) {
				nucn[0][i] = cn[0][i];
				nucn[1][i] = -cn[1][i];
			}
			return nucn;
		}

		function complex_div (cn1:Array, cn2:Array):Array
		{
			// not in-place (TODO)
			var nucn:Array = [
				[],
				[]
			];
			for (var r:int = 0; r < _arrlen; r++) {
				nucn[0][r] = ((cn1[0][r] * cn2[0][r]) + (cn1[1][r] * cn2[1][r])) / ((cn2[0][r] * cn2[0][r]) + (cn2[1][r] * cn2[1][r]));
				nucn[1][r] = ((cn1[1][r] * cn2[0][r]) - (cn1[0][r] * cn2[1][r])) / ((cn2[0][r] * cn2[0][r]) + (cn2[1][r] * cn2[1][r]));
			}
			return nucn;
		}
	}
}
