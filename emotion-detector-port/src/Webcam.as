package {
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.StatusEvent;
    import flash.geom.Matrix;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.system.Security;
    import flash.system.SecurityPanel;

    public class Webcam extends Sprite{

        public static const WEBCAM_INIT_COMPLETE:String = "webcamInitComplete";
        public static const WEBCAM_INIT_FAIL:String = "webcamInitFail";
        public static const WEBCAM_NOT_FOUND:String = "webcamNotFound";

        public var bitmapData:BitmapData;
        public var camera:Camera;
        public var video:Video;

        private var fitWebcam:Matrix;

	    private const WIDTH:Number = 400;
	    private const HEIGHT:Number = 300;


        public function Webcam() {
            if(!stage){
                addEventListener(Event.ADDED_TO_STAGE, addedToStage);
            } else addedToStage(null);
        }


        private function addedToStage(e:Event):void {
            removeEventListener(e.type, arguments.callee);

            if (Camera.names.length <= 0) {
                dispatchEvent(new Event(WEBCAM_NOT_FOUND));
                return;
            }

            graphics.beginFill(0x00ffff);
            graphics.drawRect(0,0,WIDTH,HEIGHT);
            graphics.endFill();

            addEventListener(MouseEvent.CLICK, onClick);
            opaqueBackground = true;
        }

        private function onClick(e:MouseEvent):void {
            removeEventListener(e.type, arguments.callee);
            initCamera();
        }

        private function initCamera():void{
            camera = Camera.getCamera();

            if (camera) {
                if (camera.muted) {
                    camera.addEventListener(StatusEvent.STATUS, statusHandler);
                }
                camera.setMode(WIDTH, HEIGHT, 15, false);

                bitmapData = new BitmapData(camera.width, camera.height, false);
	            //fitWebcam = new Matrix();
                //var scaleMult:Number = 320/bitmapData.width;
                //fitWebcam.scale(scaleMult, scaleMult);

                video = new Video(camera.width, camera.height);
                video.attachCamera(camera);

                if (!camera.muted) {
                    dispatchEvent(new Event(WEBCAM_INIT_COMPLETE));
                }
            }
            else {
                Security.showSettings(SecurityPanel.PRIVACY);
                dispatchEvent(new Event(WEBCAM_INIT_FAIL));
            }
        }

        private function statusHandler(e:StatusEvent):void {
            switch (e.code) {
                case "Camera.Muted":
                    trace("User clicked Deny.");
                    dispatchEvent(new Event(WEBCAM_INIT_FAIL));
                    break;
                case "Camera.Unmuted":
                    trace("User clicked Accept.");
                    dispatchEvent(new Event(WEBCAM_INIT_COMPLETE));
                    break;
            }
        }

        public function update():void {
            bitmapData.draw(video);
            graphics.beginBitmapFill(bitmapData, null, false);
            graphics.drawRect(0, 0, bitmapData.width, bitmapData.height);
        }
    }
}
