/**
* ...
* @author Default
* @version 0.1
*/

package com.suckatmath.detector.classifier {

	public class RectList {
		public var head:RectCell;
		public var tail:RectCell;
		
		public function RectList() {
			head = null;
			tail = null;
		}
		
		public function add(r:HaarRect):void{
			if (null == tail) {
				head = tail = new RectCell(r, null);
			}else {
				var t:RectCell = new RectCell(r, null);
				tail.next = t;
				tail = t;
			}
		}
		
	}
	
}
