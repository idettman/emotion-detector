package {

import flash.display.Sprite;

[SWF(width="950",height="250",frameRate="30")]
public class Main extends Sprite {


    public function Main() {

        graphics.lineStyle(1);
        graphics.drawRect(0, 0, 950, 250);
        graphics.endFill();

        var emotionDetector:CLMEmotionDetector = new CLMEmotionDetector();
        addChild(emotionDetector);
    }
}
}
