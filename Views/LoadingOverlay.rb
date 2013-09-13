# LoadingOverlay.rb
# briquette
#
# Created by Dominic Dagradi on 11/21/10.
# Copyright 2010 Bearded. All rights reserved.

class LoadingOverlay < NSView

  def drawRect rect
    NSColor.whiteColor.setFill
    NSRectFill(rect)
  end
  
  def mouseDown event
    return
  end
  
end