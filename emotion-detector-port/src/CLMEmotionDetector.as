package {
    import flash.display.Sprite;
    import flash.events.Event;

    public class CLMEmotionDetector extends Sprite {

        public var emotionClassifier:EmotionClassifier;
        public var emotionModel:EmotionModel;
        public var clmModel:CLMModel;
        public var ctrack:CLMTracker;
        public var faceTracker:FaceTracker;
        public var video:CameraVideo;


        public function CLMEmotionDetector() {
            if(!stage){
                addEventListener(Event.ADDED_TO_STAGE, addedToStage);
            } else addedToStage(null);
        }

        private function addedToStage(e:Event):void {
            removeEventListener(e.type, arguments.callee);
            init();
        }

        private function init():void {
            clmModel = new CLMModel();

            // init cml tracker
            ctrack = new CLMTracker();
            ctrack.init(clmModel);

            emotionModel = new EmotionModel();
            emotionClassifier = new EmotionClassifier();
            emotionClassifier.init(emotionModel.data);
            var emotionData = emotionClassifier.getBlank();

            video = new CameraVideo();
            video.addEventListener(CameraVideo.CAMERA_INIT_COMPLETE, cameraInitComplete);
            addChild(video);
        }

        private function cameraInitComplete(e:Event):void {
            video.removeEventListener(CameraVideo.CAMERA_INIT_COMPLETE, cameraInitComplete);

            faceTracker = new FaceTracker();
            faceTracker.bitmapData = video.bitmapData;
            addChild(faceTracker);

            start();
        }

        public function start() {
            // start video
            video.play();
            // start tracking
            ctrack.start(video.bitmapData);
            addEventListener(Event.ENTER_FRAME, enterFrame);
        }

        private function enterFrame(e:Event):void {
            if (ctrack.getCurrentPosition()) {
                // check players emotions vs current target emotion
            }
            var cp = ctrack.getCurrentParameters();
            var er = emotionClassifier.meanPredict(cp);
            if (er) {
                //updateData(er);
                for (var i = 0;i < er.length;i++) {
                    if (er[i].value > 0.4) {
                        // detect success
                    } else {
                        // detect fail
                    }
                }
            }
        }

        private function updateData(data:Object):void {
            // update
            /*var rects = svg.selectAll("rect")
                    .data(data)
                    .attr("y", function(datum) { return height - y(datum.value); })
                    .attr("height", function(datum) { return y(datum.value); });
            var texts = svg.selectAll("text.labels")
                    .data(data)
                    .attr("y", function(datum) { return height - y(datum.value); })
                    .text(function(datum) { return datum.value.toFixed(1);});*/

            // enter
            //rects.enter().append("svg:rect");
            //texts.enter().append("svg:text");

            // exit
            //rects.exit().remove();
            //texts.exit().remove();
        }

    }
}
