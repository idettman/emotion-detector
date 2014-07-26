/**
* ...
* @author Default
* @version 0.1
*/

package com.suckatmath.detector.classifier {

	public class RectCell {
		public var elt:HaarRect;
		public var next:RectCell;
		
		public function RectCell(el:HaarRect, n:RectCell) {
			this.elt = el;
			this.next = n;
		}
		
	}
	
}
