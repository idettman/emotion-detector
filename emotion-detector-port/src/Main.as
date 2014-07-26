package {

import flash.display.Sprite;
import flash.text.TextField;

public class Main extends Sprite {
    public function Main() {

        var emotionDetector:CLMEmotionDetector = new CLMEmotionDetector();
        addChild(emotionDetector);
    }
}
}
