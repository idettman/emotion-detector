package {
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;

    public class CLMEmotionDetector extends Sprite {

        public var emotionClassifier:EmotionClassifier;
        public var emotionModel:EmotionModel;
        public var clmModel:CLMModel;
        public var ctrack:CLMTracker;
        public var faceTracker:FaceTracker;
        public var video:Webcam;

        private var updateTime:uint;
        private var lastUpdateTimeCamera:uint = 0;
        private var lastUpdateTimeFaceTracker:uint = 0;




        public function CLMEmotionDetector() {
            if (!stage) {
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
            ctrack.addEventListener("stopTrackingAndDrawPositions", stopTrackingAndDrawPositions);
            ctrack.init(clmModel);

            emotionModel = new EmotionModel();
            emotionClassifier = new EmotionClassifier();
            emotionClassifier.init(emotionModel.data);
            var emotionData = emotionClassifier.getBlank();

            video = new Webcam();
            video.addEventListener(Webcam.WEBCAM_NOT_FOUND, cameraNotFound);
            video.addEventListener(Webcam.WEBCAM_INIT_FAIL, cameraInitFail);
            video.addEventListener(Webcam.WEBCAM_INIT_COMPLETE, cameraInitComplete);
            addChild(video);
        }

        private function stopTrackingAndDrawPositions(e:Event):void {
            ctrack.removeEventListener(e.type, arguments.callee);
            removeEventListener(Event.ENTER_FRAME, enterFrame);


            var currentPositions:Array = ctrack.getCurrentPosition();

            video.graphics.clear();
            video.graphics.beginFill(0x00FF00);

            var positions:Array;
            for (var i:int = 0; i < currentPositions.length; i++) {
                positions = currentPositions[i];
                trace("positions:", positions[0], positions[1]);
                video.graphics.drawCircle(Number(positions[0]), Number(positions[1]), 4);
            }

        }

        private function removeCameraListeners():void {
            video.removeEventListener(Webcam.WEBCAM_INIT_COMPLETE, cameraInitComplete);
            video.removeEventListener(Webcam.WEBCAM_INIT_FAIL, cameraInitFail);
            video.removeEventListener(Webcam.WEBCAM_NOT_FOUND, cameraNotFound);
        }

        private function cameraInitFail(e:Event):void {
            removeCameraListeners();
            graphics.beginFill(0xff0000);
            graphics.drawRect(0, 0, 950, 250);
        }

        private function cameraNotFound(e:Event):void {
            removeCameraListeners();
            graphics.beginFill(0xff0000);
            graphics.drawRect(0, 0, 950, 250);
        }

        private function cameraInitComplete(e:Event):void {
            removeCameraListeners();
            faceTracker = new FaceTracker();
            faceTracker.bitmapData = video.bitmapData;
            faceTracker.addEventListener(FaceTracker.FACE_TRACKER_INIT_COMPLETE, faceTrackerInitComplete);
            addChild(faceTracker);
        }

        private function faceTrackerInitComplete(e:Event):void {
            faceTracker.removeEventListener(e.type, arguments.callee);
            start();
        }

        public function start() {
            ctrack.start(video.bitmapData);
            addEventListener(Event.ENTER_FRAME, enterFrame);
        }

        private function enterFrame(e:Event):void {

            updateTime = getTimer();

            if (updateTime - lastUpdateTimeCamera > 1000 / 15) {
                lastUpdateTimeCamera = updateTime;
                video.update();
            }

            if (updateTime - lastUpdateTimeFaceTracker > 1000 / 6) {
                lastUpdateTimeFaceTracker = updateTime;

                if (faceTracker.update()) {
                    ctrack.box = faceTracker.faceRect;
                    if (ctrack.getCurrentPosition()) {
                        // check players emotions vs current target emotion
                        //video.bitmapData.fillRect(new Rectangle(0, 0, 100, 100), 0xff0000);
                    }
                    var cp:Array = ctrack.getCurrentParameters();
                    var er:Array = emotionClassifier.meanPredict(cp);
                    if (er) {
                        //updateData(er);
                        for (var i:int = 0; i < er.length; i++) {
                            if (er[i].value > 0.4) {
                                // detect success
                            } else {
                                // detect fail
                            }
                        }
                    }
                }
            }
        }

        //private function updateData(data:Object):void {
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
        //}

    }
}
