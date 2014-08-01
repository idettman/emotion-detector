package
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;


	public class CLMEmotionDetector extends Sprite
	{
		public var emotionClassifier:EmotionClassifier;
		public var emotionModel:EmotionModel;
		public var clmModel:CLMModel;
		public var ctrack:CLMTracker;
		public var faceTracker:FaceTracker;
		public var video:Webcam;

		private var updateTime:uint;
		private var lastUpdateTimeCamera:uint = 0;
		private var lastUpdateTimeFaceTracker:uint = 0;

		private var detectedFace:Boolean = false;

		public var debugLayer:Shape;


		public function CLMEmotionDetector ()
		{
			if (!stage) {
				addEventListener(Event.ADDED_TO_STAGE, addedToStage);
			} else addedToStage(null);
		}

		private function addedToStage (e:Event):void
		{
			removeEventListener(e.type, arguments.callee);
			init();
		}

		private function init ():void
		{
			clmModel = new CLMModel();

			// init cml tracker
			ctrack = new CLMTracker();
			//ctrack.addEventListener("stopTrackingAndDrawPositions", stopTrackingAndDrawPositions);
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


			debugLayer = new Shape();
			addChild(debugLayer);
		}

		private function stopTrackingAndDrawPositions (e:Event):void
		{
			ctrack.removeEventListener(e.type, arguments.callee);
			removeEventListener(Event.ENTER_FRAME, enterFrame);
			drawPositions();
		}

		private function drawPositions ():void
		{
			var currentPositions:Vector.<Vector.<Number>> = ctrack.getCurrentPosition();
			if (!currentPositions) return;

			var positions:Vector.<Number>;

			debugLayer.graphics.clear();
			debugLayer.graphics.beginFill(0x00FF00);
			for (var i:int = 0; i < currentPositions.length; i++) {
				positions = currentPositions[i];
				debugLayer.graphics.drawCircle(Number(positions[0]), Number(positions[1]), 3);
			}
		}

		private function removeCameraListeners ():void
		{
			video.removeEventListener(Webcam.WEBCAM_INIT_COMPLETE, cameraInitComplete);
			video.removeEventListener(Webcam.WEBCAM_INIT_FAIL, cameraInitFail);
			video.removeEventListener(Webcam.WEBCAM_NOT_FOUND, cameraNotFound);
		}

		private function cameraInitFail (e:Event):void
		{
			removeCameraListeners();
			graphics.beginFill(0xff0000);
			graphics.drawRect(0, 0, 950, 250);
		}

		private function cameraNotFound (e:Event):void
		{
			removeCameraListeners();
			graphics.beginFill(0xff0000);
			graphics.drawRect(0, 0, 950, 250);
		}

		private function cameraInitComplete (e:Event):void
		{
			removeCameraListeners();
			faceTracker = new FaceTracker();
			faceTracker.bitmapData = video.bitmapData;
			faceTracker.addEventListener(FaceTracker.FACE_TRACKER_INIT_COMPLETE, faceTrackerInitComplete);
			addChild(faceTracker);
		}

		private function faceTrackerInitComplete (e:Event):void
		{
			faceTracker.removeEventListener(e.type, arguments.callee);
			start();
		}

		public function start ()
		{
			ctrack.start(video.bitmapData);
			addEventListener(Event.ENTER_FRAME, enterFrame);
		}

		private function enterFrame (e:Event):void
		{
			updateTime = getTimer();

			if (updateTime - lastUpdateTimeCamera > 1000 / 15) {
				lastUpdateTimeCamera = updateTime;
				video.update();
			}

			if (updateTime - lastUpdateTimeFaceTracker > 1000 / 7) {
				lastUpdateTimeFaceTracker = updateTime;

				if (!detectedFace) {
					if (faceTracker.update()) {
						ctrack.box = faceTracker.faceRect;
						detectedFace = true;
					}
				}
				else {
					if (ctrack.getCurrentPosition()) {
						// check players emotions vs current target emotion
					}
					drawPositions();

					/*var cp:Vector.<Number> = ctrack.getCurrentParameters();
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
					 }*/
					}
			}
		}
	}
}
