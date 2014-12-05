package components {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	import mx.charts.chartClasses.*;
	import mx.controls.*;

	public class RangeSelector extends ChartElement {
		public static const SELECTION_CHANGED:String="SELECTION_CHANGED";
		public var labelFunc:Function;
		/* the bounds of the selected region*/
		private var dLeft:Number=20;
		private var dTop:Number=20;
		private var dRight:Number=80;
		private var dBottom:Number=80;

		/* the x/y coordinates of the start of the tracking region */
		private var tX:Number;
		private var tY:Number;

		/* whether or not a region is selected */
		private var bSet:Boolean=false;

		/* whether or not we're currently tracking */
		private var bTracking:Boolean=false;

		/* the current position of the crosshairs */
		private var _crosshairs:Point;

		/* the four labels for the data bounds of the selected region */
		private var _labelCurr:Label;
		private var _labelLeft:Label;
		private var _labelRight:Label;
		private var _labelTop:Label;
		private var _labelBottom:Label;

		/* constructor */
		public function RangeSelector():void {
			super();
			setStyle("color", 0);
			/* mousedowns are where we start tracking the selection */
			addEventListener("mouseDown", startTracking);

			/* mousemove and rollout are used to track the crosshairs */
			addEventListener("mouseMove", updateCrosshairs);
			addEventListener("rollOut", removeCrosshairs);

			/* create our labels */
			_labelCurr=new Label();
			_labelLeft=new Label();
			_labelTop=new Label();
			_labelRight=new Label();
			_labelBottom=new Label();
			addChild(_labelCurr);
			addChild(_labelLeft);
			addChild(_labelTop);
			addChild(_labelRight);
			addChild(_labelBottom);


		}

		public function reset():void {
			bSet=false;
			invalidateDisplayList();
		}
		
		/* draw the overlay */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {

			super.updateDisplayList(unscaledWidth, unscaledHeight);


			var g:Graphics=graphics;
			g.clear();

			// draw a big transparent square so the flash player sees us for mouse events */
			g.moveTo(0, 0);
			g.lineStyle(0, 0, 0);
			g.beginFill(0, 0);
			g.drawRect(0, 0, unscaledWidth, unscaledHeight);
			g.endFill();

			/* draw the crosshairs. Crosshairs are drawn where the mouse is, only when the mouse is over us, so we don't need to transform
			 *    to data coordinates
			 */
			if(_crosshairs != null) {
				g.lineStyle(1, 0x005364, .5);

				//g.moveTo(0,_crosshairs.y);
				//g.lineTo(unscaledWidth,_crosshairs.y);

				g.moveTo(_crosshairs.x, 0);
				g.lineTo(_crosshairs.x, unscaledHeight);
			}

			/* draw the selected region, if there is one */
			if(bSet) {
				/* the selection is a data selection, so we want to make sure the region stays correct as the chart changes size and/or ranges.
				 *  so we store it in data coordaintes. So before we draw it, we need to transform it back into screen coordaintes
				 */
				var c:Array=[ { dx:dLeft, dy:dTop }, { dx:dRight, dy:dBottom } ];
				dataTransform.transformCache(c, "dx", "x", "dy", "y");

				trace("now draw the region on screen");
				//g.moveTo(c[0].x,c[0].y);                
				g.moveTo(c[0].x, 0);
				g.beginFill(0xEEEE22, .2);
				g.lineStyle(1, 0xBBBB22);
				//g.drawRect(c[0].x,c[0].y,c[1].x - c[0].x, c[1].y - c[0].y);
				g.drawRect(c[0].x, 0, c[1].x - c[0].x, unscaledHeight);
				g.endFill();


				/* now we're going to draw the decorators indicating the bottom and right edges of the box
				 */
				//g.lineStyle(2,0x995522);

				// draw bottom line
				/*g.moveTo(c[0].x,c[1].y + 9);
				   g.lineTo(c[0].x,c[1].y + 15);
				   g.moveTo(c[0].x,c[1].y + 12);
				   g.lineTo(c[1].x,c[1].y + 12);
				   g.moveTo(c[1].x,c[1].y + 9);
				 g.lineTo(c[1].x,c[1].y + 15);*/

				// draw right line
				/*g.moveTo(c[1].x + 9,c[0].y);
				   g.lineTo(c[1].x + 15,c[0].y);
				   g.moveTo(c[1].x + 12,c[0].y);
				   g.lineTo(c[1].x + 12,c[1].y);
				   g.moveTo(c[1].x + 9,c[1].y);
				 g.lineTo(c[1].x + 15,c[1].y);*/

				/* now we're going to position the labels at the edges of the box */
				_labelLeft.visible=_labelRight.visible=_labelTop.visible=_labelBottom.visible=true;
				_labelLeft.setActualSize(_labelLeft.measuredWidth, _labelLeft.measuredHeight);
				_labelLeft.move(c[0].x - _labelLeft.width, c[1].y + 24);
				_labelRight.setActualSize(_labelRight.measuredWidth, _labelRight.measuredHeight);
				_labelRight.move(c[1].x, c[1].y + 24);
				/*_labelTop.setActualSize(_labelTop.measuredWidth,_labelTop.measuredHeight);
				   _labelTop.move(c[1].x + 24,c[0].y - _labelTop.height/2);
				   _labelBottom.setActualSize(_labelBottom.measuredWidth,_labelBottom.measuredHeight);
				 _labelBottom.move(c[1].x + 24,c[1].y - _labelBottom.height/2);*/

			} else {
				_labelLeft.visible=_labelRight.visible=_labelTop.visible=_labelBottom.visible=false;
			}
		}


		/* to make sure we end up in any ranges autogenerated by the axes, we need to describe our data to them
		 */
		override public function describeData(dimension:String, requiredFields:uint):Array {
			/* if no region is selected, we have no data */
			if(bSet == false)
				return [];

			var dd:DataDescription=new DataDescription();


			if(dimension == CartesianTransform.HORIZONTAL_AXIS) {
				/* describe the minimum and maximum values we need on screen */
				dd.min=dLeft;
				dd.max=dRight;


				if((requiredFields & DataDescription.REQUIRED_BOUNDED_VALUES) != 0) {
					/* since we don't want our labels sticking off the edge of the chart, we need to ask for 'bounded values' around the selected data.
					 *  a bounded value is a pixel margin to the left/right of a specific data point. In this case, we'll ask for the width of our labels
					 */
					dd.boundedValues=[ new BoundedValue(dLeft), new BoundedValue(dRight, _labelLeft.width / 2, 24 + Math.max(_labelLeft.width, _labelRight.width)) ]
				}
			} else {
				dd.min=dBottom;
				dd.max=dTop;
				if((requiredFields & DataDescription.REQUIRED_BOUNDED_VALUES) != 0) {
					/* since we don't want our labels sticking off the edge of the chart, we need to ask for 'bounded values' around the selected data.
					 *  a bounded value is a pixel margin to the top/bottom of a specific data point. In this case, we'll ask for the height of our labels
					 */
					dd.boundedValues=[ new BoundedValue(dTop), new BoundedValue(dBottom, 24 + Math.max(_labelLeft.height, _labelRight.height, _labelTop.height / 2)) ]
				}
			}

			return [ dd ];
		}

		override protected function commitProperties():void {
			super.commitProperties();


			/* when our data changes, we need to update the text displayed in our labels */
			//_labelLeft.text=Math.round(dLeft).toString();
			if (null!=labelFunc) _labelLeft.text=labelFunc(dLeft);
			//_labelRight.text=Math.round(dRight).toString();
			if (null!=labelFunc) _labelRight.text=labelFunc(dRight);
			//_labelTop.text = Math.round(dTop).toString();
			//_labelBottom.text = Math.round(dBottom).toString();

		}


		override public function mappingChanged():void {
			/* since we store our selection in data coordinates, we need to redraw when the mapping between data coordinates and screen coordinates changes
			 */
			invalidateDisplayList();
		}

		private function startTracking(e:MouseEvent):void {
			/* the user clicked the mouse down. First, we need to add listeners for the mouse dragging */
			bTracking=true;
			parentApplication.addEventListener("mouseUp", endTracking, true);
			parentApplication.addEventListener("mouseMove", track, true);

			/* now store off the data values where the user clicked the mouse */
			var dataVals:Array=dataTransform.invertTransform(mouseX, mouseY);
			tX=dataVals[0];
			tY=dataVals[1];
			bSet=false;

			updateTrackBounds(dataVals);
		}

		private function track(e:MouseEvent):void {
			if(bTracking == false)
				return;
			bSet=true;
			updateTrackBounds(dataTransform.invertTransform(mouseX, mouseY));
			e.stopPropagation();
		}

		private function endTracking(e:MouseEvent):void {
			/* the selection is complete, so remove our listeners and update one last time to match the final position of the mouse */
			bTracking=false;
			parentApplication.removeEventListener("mouseUp", endTracking, true);
			parentApplication.removeEventListener("mouseMove", track, true);
			e.stopPropagation();
			updateTrackBounds(dataTransform.invertTransform(mouseX, mouseY));
			var selChgEvt:SelectionChangedEvent=new SelectionChangedEvent(SELECTION_CHANGED);
			selChgEvt.left=dLeft;
			selChgEvt.right=dRight;
			dispatchEvent(selChgEvt);
		}

		private function updateCrosshairs(e:MouseEvent):void {
			/* the mouse moved over the chart, so grab the mouse coordaintes and redraw */
			_crosshairs=new Point(mouseX, mouseY);
			invalidateDisplayList();
		}

		private function removeCrosshairs(e:MouseEvent):void {
			/* the mouse left the chart area, so throw away any stored coordinates and redraw */
			_crosshairs=null;
			invalidateDisplayList();
		}

		private function updateTrackBounds(dataVals:Array):void {
			/* store the bounding rectangle of the selection, in a normalized data-based rectangle */
			trace("1 dLeft=" + dLeft + "; dRight=" + dRight);
			dRight=Math.max(tX, dataVals[0]);
			dLeft=Math.min(tX, dataVals[0]);
			dBottom=Math.min(tY, dataVals[1]);
			dTop=Math.max(tY, dataVals[1]);
			trace("2 dLeft=" + dLeft + "; dRight=" + dRight);

			/* invalidate our data, and redraw */
			dataChanged();
			invalidateProperties();
			invalidateDisplayList();

		}

	}
}

