package {
    import com.suckatmath.detector.BigToSmallDetector;
    import com.suckatmath.detector.Detector;
    import com.suckatmath.detector.classifier.HaarClassifier;

    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

    public class FaceTracker extends Sprite {

        public static const FACE_TRACKER_INIT_COMPLETE:String = "faceTrackerInitComplete";

        public function FaceTracker():void {
            if (stage) init();
            else addEventListener(Event.ADDED_TO_STAGE, init);
        }

        public var detector:Detector;
        public var bitmapData:BitmapData;
        public var output:Sprite;
        public var faceRect:Rectangle = new Rectangle( 100, 100, 100, 250);
        private var myLoader:URLLoader;

        private function init(e:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);

            var XML_URL:String = "./classifiers/haarcascade_frontalface_alt.xml";
            var myXMLURL:URLRequest = new URLRequest(XML_URL);
            myLoader = new URLLoader();
            myLoader.addEventListener(Event.COMPLETE, xmlLoaded);
            myLoader.load(myXMLURL);

            output = new Sprite();
            addChild(output);
        }


        private function xmlLoaded(event:Event):void {
            var myXML:XML = XML(myLoader.data);
            var classifier:HaarClassifier = HaarClassifier.fromXML(myXML.*.(@type_id == "opencv-haar-classifier")[0]);

            detector = new BigToSmallDetector(classifier, 1, 60); //new Detector(classifier, 1, 30);
            if (bitmapData) {
                detector.bitmap = bitmapData;
            }
            dispatchEvent(new Event(FACE_TRACKER_INIT_COMPLETE));
        }

        public function update():Boolean {
            var faceRects:Vector.<Rectangle> = detector.detect();
            if (faceRects) {
                var faceRect:Rectangle = faceRects[0];
                output.graphics.clear();
                output.graphics.lineStyle(1, 0x00ff00);
                output.graphics.drawRect(faceRect.x, faceRect.y, faceRect.width, faceRect.height);
                this.faceRect.copyFrom(faceRect);
                return true;
            }
            else return false;
        }
    }

}