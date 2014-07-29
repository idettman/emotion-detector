package {
    public class SVMFilter {

        var _fft:FFT, fft_filters:Array, responses:Array, biases:Vector.<Number>;
        var fft_size:uint, filterLength:uint, filter_width:uint, search_width:uint, num_patches:uint;
        var temp_imag_part:Array, temp_real_part:Array;


        // fft function
        function fft_inplace (array:Array, _im_part:Array = null):Array {
            // in-place

            if (_im_part) {
                _im_part = temp_imag_part;
            }

            for (var i:int = 0;i < filterLength;i++) {
                _im_part[i] = 0.0;
            }

            _fft.real_fft2d(array,_im_part);

            return [array, _im_part];
        }

        function ifft (rn:Array, cn:Array):Array {
            // in-place
            _fft.real_ifft2d(rn, cn);
            return rn;
        }

        function complex_mult_inplace (cn1:Array, cn2:Array):void {
            // in-place, cn1 is the one modified
            var temp1:Number, temp2:Number;
            for (var r = 0;r < filterLength;r++) {
                temp1 = (cn1[0][r]*cn2[0][r]) - (cn1[1][r]*cn2[1][r]);
                temp2 = (cn1[0][r]*cn2[1][r]) + (cn1[1][r]*cn2[0][r]);
                cn1[0][r] = temp1;
                cn1[1][r] = temp2;
            }
        }

        function init (filter_input:Array, bias_input:Array, numPatches:uint, filterWidth:uint, searchWidth:uint) {

            var fft:FFT;

            // calculate needed size of fft (has to be power of two)
            fft_size = upperPowerOfTwo(filterWidth-1+searchWidth);
            filterLength = fft_size*fft_size;
            _fft = new FFT();
            _fft.init(fft_size);
            fft_filters = Array(numPatches);
            var fft_filter:Array;
            var edge:Number = (filterWidth-1)/2;

            for (var i:int = 0;i < numPatches;i++) {
                var flar_fi0:Array = new Array(filterLength);
                var flar_fi1:Array = new Array(filterLength);

                // load filter
                var xOffset:int, yOffset:int;
                for (var j:int = 0;j < filterWidth;j++) {
                    for (var k:int = 0;k < filterWidth;k++) {
                        xOffset = k < edge ? (fft_size-edge) : (-edge);
                        yOffset = j < edge ? (fft_size-edge) : (-edge);
                        flar_fi0[k+xOffset+((j+yOffset)*fft_size)] = filter_input[i][(filterWidth-1-j)+((filterWidth-1-k)*filterWidth)];
                    }
                }

                // fft it and store
                fft_filter = this.fft_inplace(flar_fi0, flar_fi1);
                fft_filters[i] = fft_filter;
            }

            // set up biases
            biases = new Vector.<Number>(numPatches);
            for (var i:int = 0;i < numPatches;i++) {
                biases[i] = bias_input[i];
            }

            responses = Array(numPatches);
            temp_imag_part = Array(numPatches);
            for (var i:int = 0;i < numPatches;i++) {
                responses[i] = new Vector.<Number>(searchWidth*searchWidth);
                temp_imag_part[i] = new Vector.<Number>(searchWidth*searchWidth);
            }
            temp_real_part = new Array(filterLength);

            num_patches = numPatches;
            filter_width = filterWidth;
            search_width = searchWidth;
        }

        function getResponses (patches:Array):Array {
            var response:Array, edge:uint;
            var patch_width:uint = filter_width-1+search_width;

            for (var i:int = 0;i < num_patches;i++) {
                // reset zeroes in temp_real_part
                for (var j:int = 0;j < fft_size*fft_size;j++) {
                    temp_real_part[j] = 0.0;
                }

                // normalize patches to 0-1
                patches[i] = normalizePatches(patches[i]);

                // patch must be padded (with zeroes) to match fft size
                for (var j:int = 0;j < patch_width;j++) {
                    for (var k:int = 0;k < patch_width;k++) {
                        temp_real_part[j + (fft_size*k)] = patches[i][k + (patch_width*j)];
                    }
                }

                //drawData(document.getElementById('sketch').getContext('2d'), temp_real_part, 32, 32, false, 0, 0);

                // fft it
                response = this.fft_inplace(temp_real_part);

                // multiply pointwise with filter
                complex_mult_inplace(response, fft_filters[i]);

                // inverse fft it
                response = this.ifft(response[0], response[1]);

                // crop out edges
                edge = (filter_width-1)/2;
                for (var j:int = 0;j < search_width;j++) {
                    for (var k:int = 0;k < search_width;k++) {
                        responses[i][j + (k*search_width)] = response[edge + k + ((j+edge)*(fft_size))];
                    }
                }

                // add bias
                for (var j:int = 0;j < search_width*search_width;j++) {
                    responses[i][j] += biases[i];
                }

                // logistic transformation
                responses[i] = logisticResponse(responses[i]);

                // normalization?
                inplaceNormalizeFilterMatrix(responses[i]);
            }

            return responses;
        }

        function normalizePatches (patch:Array):Array {
            var patch_width:uint = filter_width-1+search_width;
            var max:Number = 0;
            var min:Number = 1000;
            var value:Number;

            for (var j:int = 0;j < patch_width;j++) {
                for (var k:int = 0;k < patch_width;k++) {
                    value = patch[k + (patch_width * j)];
                    if (value < min) {
                        min = value;
                    }
                    if (value > max) {
                        max = value;
                    }
                }
            }
            var scale:Number = max-min;
            for (var j:int = 0;j < patch_width;j++) {
                for (var k:int = 0;k < patch_width;k++) {
                    patch[k + (patch_width*j)] = (patch[k + (patch_width*j)]-min)/scale;
                }
            }
            return patch;
        }

        function logisticResponse (response:Array):Array {
            // create probability by doing logistic transformation
            for (var j:int = 0;j < search_width;j++) {
                for (var k:int = 0;k < search_width;k++) {
                    response[j + (k*search_width)] = 1.0/(1.0 + Math.exp(- (response[j + (k*search_width)] - 1.0 )));
                }
            }
            return response;
        }

        function upperPowerOfTwo (x:int):int {
            x--;
            x |= x >> 1;
            x |= x >> 2;
            x |= x >> 4;
            x |= x >> 8;
            x |= x >> 16;
            x++;
            return x;
        }

        function inplaceNormalizeFilterMatrix (response:Array):void {
            // normalize responses to lie within [0,1]
            var msize:int = response.length;
            var max:Number = 0;
            var min:Number = 1;

            for (var i:int = 0;i < msize;i++) {
                max = response[i] > max ? response[i] : max;
                min = response[i] < min ? response[i] : min;
            }
            var dist:Number = max-min;

            if (dist == 0) {
                //console.log("a patchresponse was monotone, causing normalization to fail. Leaving it unchanged.")
            } else {
                for (var i:int = 0;i < msize;i++) {
                    response[i] = (response[i]-min)/dist;
                }
            }
        }

    }
}
