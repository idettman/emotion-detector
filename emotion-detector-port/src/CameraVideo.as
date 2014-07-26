package {
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.media.Camera;
    import flash.media.Video;

    public class CameraVideo extends Sprite{

        public static const CAMERA_INIT_COMPLETE:String = "cameraInit";

        public var bitmapData:BitmapData;
        public var camera:Camera;
        public var video:Video;

        public function CameraVideo() {
            if(!stage){
                addEventListener(Event.ADDED_TO_STAGE, addedToStage);
            } else addedToStage(null);
        }


        private function addedToStage(e:Event):void {
            removeEventListener(e.type, arguments.callee);

            graphics.beginFill(0x00ffff);
            graphics.drawRect(0,0,320,240);
            graphics.endFill();

            bitmapData = new BitmapData(320, 240, false, 0xff0000);
            video = new Video();

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
                video.attachCamera(camera);
                addEventListener(Event.ENTER_FRAME, enterFrame);
                dispatchEvent(new Event(CAMERA_INIT_COMPLETE));
            }
            else {
                graphics.beginFill(0xffCDff);
                graphics.drawRect(0, 0, 320, 240);
            }
        }

        private function enterFrame(e:Event):void {
            bitmapData.draw(video);
            graphics.beginBitmapFill(bitmapData, null, false);
            graphics.drawRect(0, 0, 320, 240);
        }

        public function play():void {

        }
    }
}
