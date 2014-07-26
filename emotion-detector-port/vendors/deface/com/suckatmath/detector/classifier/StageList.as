/**
* ...
* @author Default
* @version 0.1
*/

package com.suckatmath.detector.classifier {

	public class StageList {
		public var head:StageCell;
		public var tail:StageCell;
		
		public function StageList() {
			head = null;
			tail = null;
		}
		
		public function add(s:HaarClassifierStage):void{
			if (null == tail) {
				head = tail = new StageCell(s, null);
			}else {
				var t:StageCell = new StageCell(s, null);
				tail.next = t;
				tail = t;
			}
		}
		
	}
	
}
