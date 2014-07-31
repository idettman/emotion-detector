package {

import flash.display.Sprite;

[SWF(width="950",height="250",frameRate="15")]
public class Main extends Sprite {

    public function Main() {

        opaqueBackground = 0xFFFFFF;
        graphics.lineStyle(1);
        graphics.drawRect(0.5, 0.5, 949, 249);
        graphics.endFill();

        var emotionDetector:CLMEmotionDetector = new CLMEmotionDetector();
        emotionDetector.x = 1;
        emotionDetector.y = 1;
        addChild(emotionDetector);
    }
}
}
