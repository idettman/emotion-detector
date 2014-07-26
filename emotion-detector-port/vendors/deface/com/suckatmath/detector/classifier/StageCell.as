/**
* ...
* @author Default
* @version 0.1
*/

package com.suckatmath.detector.classifier {

	public class StageCell {
		public var elt:HaarClassifierStage;
		public var next:StageCell;
		
		public function StageCell(el:HaarClassifierStage, n:StageCell) {
			this.elt = el;
			this.next = n;
		}
		
	}
	
}
