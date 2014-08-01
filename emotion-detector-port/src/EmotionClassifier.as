/**
 * Created by wildlife on 7/24/14.
 */
package {
    import flash.events.Event;

    public class EmotionClassifier {

        private var previousParameters:Array;
        private var classifier:Object;
        private var emotions:Array;
        private var coefficient_length:int;


        public function EmotionClassifier() {
            previousParameters = [];
            classifier = {};
            emotions = [];
        }


        public function getEmotions ():Array {
            return emotions;
        }

        public function init (model:Object) {
            // load it
            for (var m in model) {
                emotions.push(m);
                classifier[m] = {};
                classifier[m]['bias'] = model[m]['bias'];
                classifier[m]['coefficients'] = model[m]['coefficients'];
            }
            coefficient_length = classifier[emotions[0]]['coefficients'].length;
        }

        public function getBlank():Array {
            var prediction = [];
            for (var j = 0;j < emotions.length;j++) {
                prediction[j] = {"emotion" : emotions[j], "value" : 0.0};
            }
            return prediction;
        }

        public function predict(parameters:Vector.<Number>):Array {
            var prediction = [];
            for (var j = 0;j < emotions.length;j++) {
                var e = emotions[j];
                var score = classifier[e].bias;
                for (var i = 0;i < coefficient_length;i++) {
                    score += classifier[e].coefficients[i]*parameters[i+6];
                }
                prediction[j] = {"emotion" : e, "value" : 0.0};
                prediction[j]['value'] = 1.0/(1.0 + Math.exp(-score));
            }
            return prediction;
        }

        public function meanPredict(parameters:Vector.<Number>):Array {
            // store to array of 10 previous parameters
            previousParameters.splice(0, previousParameters.length == 10 ? 1 : 0);
            previousParameters.push(parameters.slice(0));

            if (previousParameters.length > 9) {
                // calculate mean of parameters?
                var meanParameters:Vector.<Number> = new Vector.<Number>(parameters.length);
                for (var i = 0;i < parameters.length;i++) {
                    meanParameters[i] = 0;
                }
                for (var i = 0;i < previousParameters.length;i++) {
                    for (var j = 0;j < parameters.length;j++) {
                        meanParameters[j] += previousParameters[i][j];
                    }
                }
                for (var i = 0;i < parameters.length;i++) {
                    meanParameters[i] /= 10;
                }

                // calculate logistic regression
                return this.predict(meanParameters);
            } else {
                return null;
            }
        }

    }
}
