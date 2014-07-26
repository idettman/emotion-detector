package {

    public class MosseFilter {

        var _filter:Array, _top:Array, _bottom:Array;
        var _fft:FFT;
        var _w:int, _h:int;
        var _im_part:Vector.<Number>;
        var _arrlen:int;
        var _cc;
        var _image_array:Vector.<Number>;

        var peak:Number = 0.0;
        var updateable:Boolean = false;
        var params:Object;
        var psr_prev:Number;
        var peak_prev:Number;


        public function MosseFilter(params:Object = null) {
            this.psr_prev = undefined;
            this.peak_prev = undefined;

            if (!params) this.params = {};
            else this.params = params;

            if (this.params.psrThreshold === undefined) this.params.psrThreshold = 10;
            if (this.params.eta === undefined) this.params.eta = 0.10;
            if (this.params.convertToGrayscale === undefined) this.params.convertToGrayscale = true;

        }

        public function load(filter:Object) {
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
            _fft.init(parseInt(filter.width));

            // set up temporary variables
            _im_part = new Vector.<Number>(_arrlen);
            _image_array = new Vector.<Number>(_arrlen);
        }

        public function init(w:int, h:int) {
            // initialize filter width and height for a blank filter
            _w = w;
            _h = h;
            _arrlen = _w * _h;

            _filter = [
                [],
                []
            ];
            _top = [
                [],
                []
            ];
            _bottom = [
                [],
                []
            ];
            for (var i:int = 0; i < _arrlen; i++) {
                _filter[0][i] = 0;
                _filter[1][i] = 0;
                _top[0][i] = 0;
                _top[1][i] = 0;
                _bottom[0][i] = 0;
                _bottom[1][i] = 0;
            }
            updateable = true;

            // initialize fft to given width
            _fft = new FFT();
            _fft.init(w);

            _im_part = new Vector.<Number>(_arrlen);
        }

        // not in-place// fft function
        function fft(array:Vector.<Number>):Array {
            var cn:Vector.<Number> = new Vector.<Number>(_arrlen);
            for (var i:int = 0; i < _arrlen; i++) {
                cn[i] = 0.0;
            }

            _fft.fft2d(array, cn);
            return [array, cn];
        }

        // fft function
        function fft_inplace(array:Vector.<Number>):Array {
            // in-place

            for (var i = 0; i < _arrlen; i++) {
                _im_part[i] = 0.0;
            }

            _fft.fft2d(array, _im_part);
            return [array, _im_part];
        }

        function ifft(rn, cn) {
            // in-place
            _fft.ifft2d(rn, cn);
            return rn;
        }

        // peak to sidelobe ratio function (optional)
        function psr(array):Number {
            // proper
            var sum:Number = 0;
            var max:Number = 0;
            var maxpos:Array = [];
            var sdo:Number = 0;
            var val:Number;
            for (var x:int = 0; x < _w; x++) {
                for (var y:int = 0; y < _h; y++) {
                    val = array[(y * _w) + x];
                    sum += val;
                    sdo += (val * val);
                    if (max < val) {
                        max = val;
                        maxpos = [x, y];
                    }
                }
            }

            // subtract values around peak
            for (var x = -5; x < 6; x++) {
                for (var y = -5; y < 6; y++) {
                    if (Math.sqrt(x * x + y * y) < 5) {
                        val = array[((maxpos[1] + y) * _w) + (maxpos[0] + x)]
                        sdo -= (val * val);
                        sum -= val;
                    }
                }
            }

            var mean = sum / array.length;
            var sd = Math.sqrt((sdo / array.length) - (mean * mean));

            // get mean/variance of output around peak
            var psr:Number = (max - mean) / sd;
            return psr;
        }

        function getResponse(imageData) {
            // in-place

            // preprocess
            var prepImage:Vector.<Number> = preprocess(imageData);
            prepImage = cosine_window(prepImage);

            // filter
            var res:Array = this.fft_inplace(prepImage);

            // elementwise multiplication with filter
            complex_mult_inplace(res, _filter);

            // do inverse 2d fft
            var filtered = this.ifft(res[0], res[1]);
            return filtered;
        }

        function track(input, left:Number, top:Number, width:Number, height:Number, updateFilter:Boolean, gaussianPrior, calcPSR) {
            // finds position of filter in input image

            if (!_filter) {
                //console.log("Mosse-filter needs to be initialized or trained before starting tracking.");
                return false;
            }

           /* if (input.tagName == "VIDEO" || input.tagName == "IMG") {
                // scale selection according to original source image
                var videoLeft = Math.round((left / input.width) * input.videoWidth);
                var videoTop = Math.round((top / input.height) * input.videoHeight);
                var videoWidth = Math.round((width / input.width) * input.videoWidth);
                var videoHeight = Math.round((height / input.height) * input.videoHeight);
                _cc.drawImage(input, videoLeft, videoTop, videoWidth, videoHeight, 0, 0, _w, _h);
            } else if (input.tagName == "CANVAS") {
                _cc.drawImage(input, left, top, width, height, 0, 0, _w, _h);
            }

            var image = _cc.getImageData(0, 0, _w, _h);
            var id = image.data;

            if (params.convertToGrayscale) {
                // convert to grayscale
                for (var i = 0; i < _arrlen; i++) {
                    _image_array[i] = id[(4 * i)] * 0.3;
                    _image_array[i] += id[(4 * i) + 1] * 0.59;
                    _image_array[i] += id[(4 * i) + 2] * 0.11;
                }
            } else {
                // use only one channel
                for (var i = 0; i < _arrlen; i++) {
                    _image_array[i] = id[(4 * i)];
                }
            }*/

            // preprocess
            var prepImage = preprocess(_image_array);
            prepImage = cosine_window(prepImage);

            // filter
            var res = this.fft_inplace(prepImage);
            // elementwise multiplication with filter
            var nures = complex_mult(res, _filter);
            // do inverse 2d fft
            var filtered = this.ifft(nures[0], nures[1]);

            // find max and min
            var max = 0;
            var min = 0;
            var maxpos = [];

            //method using centered gaussian prior
            if (gaussianPrior) {
                var prior, dx, dy;
                var variance = 128;
                for (var x = 0; x < _w; x++) {
                    for (var y = 0; y < _h; y++) {
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
                for (var x = 0; x < _w; x++) {
                    for (var y = 0; y < _h; y++) {
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

            /*if (params.drawResponse) {
             // draw response
             var diff = max-min;
             var dc = document.createElement('canvas');
             dc.setAttribute('width', 32);
             dc.setAttribute('height', 32);
             var dcc = dc.getContext('2d');
             var psci = dcc.createImageData(32, 32);
             var pscidata = psci.data;
             for (var j = 0;j < 32*32;j++) {
             //draw with priors
             //var val = filtered[j]*Math.exp(-0.5*(((j%_w - _w/2)*(j%_w -_w/2))+((Math.floor(j/_h)-(_h/2))*(Math.floor(j/_h)-(_h/2))))/128);
             var val = filtered[j];
             val = Math.round((val+Math.abs(min))*(255/diff));
             pscidata[j*4] = val;
             pscidata[(j*4)+1] = val;
             pscidata[(j*4)+2] = val;
             pscidata[(j*4)+3] = 255;
             }
             dcc.putImageData(psci, 0, 0);
             responseContext.drawImage(dc, left, top, width, width);
             }*/

            if (calcPSR) {
                this.psr_prev = this.psr(filtered);
            }

            if (updateFilter) {
                if (!updateable) {
                    //console.log("The loaded filter does not support updating. Ignoring parameter 'updateFilter'.");
                } else {
                    if (calcPSR) {
                        var psr = this.psr_prev;
                    } else {
                        var psr = this.psr(filtered);
                    }

                    if (psr > params.psrThreshold) {
                        // create target
                        var target:Vector.<Number> = new Vector.<Number>(_w*_h);
                        var nux = maxpos[0];
                        var nuy = maxpos[1];
                        for (var x = 0; x < _w; x++) {
                            for (var y = 0; y < _h; y++) {
                                target[(y * _w) + x] = Math.exp(-(((x - nux) * (x - nux)) + ((y - nuy) * (y - nuy))) / (2 * 2));
                            }
                        }

                        // create filter
                        var res_conj:Array = complex_conj(res);
                        var fuTop:Array = complex_mult(this.fft(target), res_conj);
                        var fuBottom:Array = complex_mult(res, res_conj);

                        // add up
                        var eta = params.eta;
                        for (var i = 0; i < _arrlen; i++) {
                            _top[0][i] = eta * fuTop[0][i] + (1 - eta) * _top[0][i];
                            _top[1][i] = eta * fuTop[1][i] + (1 - eta) * _top[1][i];
                            _bottom[0][i] = eta * fuBottom[0][i] + (1 - eta) * _bottom[0][i];
                            _bottom[1][i] = eta * fuBottom[1][i] + (1 - eta) * _bottom[1][i];
                        }

                        _filter = complex_div(_top, _bottom);
                    }
                }
            }

            /*if (psr < 5) {
             maxpos = [_w/2,_h/2];
             }*/

            maxpos[0] = maxpos[0] * (width / _w);
            maxpos[1] = maxpos[1] * (width / _h);

            // check if output is strong enough
            // if not, return false?
            if (max < 0) {
                return false;
            } else {
                return maxpos;
            }
        }

        function preprocess(array:Vector.<Number>):Vector.<Number> {
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

        function cosine_window(array:Vector.<Number>):Vector.<Number> {
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

        function complex_mult(cn1:Array, cn2:Array):Array {
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

        function complex_mult_inplace(cn1:Array, cn2:Array) {
            // in-place
            var temp1:Number, temp2:Number;
            for (var r:int = 0; r < _arrlen; r++) {
                temp1 = (cn1[0][r] * cn2[0][r]) - (cn1[1][r] * cn2[1][r]);
                temp2 = (cn1[0][r] * cn2[1][r]) + (cn1[1][r] * cn2[0][r]);
                cn1[0][r] = temp1;
                cn1[1][r] = temp2;
            }
        }

        function complex_conj(cn:Array):Array {
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

        function complex_div(cn1:Array, cn2:Array):Array {
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
