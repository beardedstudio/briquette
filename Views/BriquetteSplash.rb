#
#  BriquetteSplash.rb
#  briquette
#
#  Created by Dominic Dagradi on 8/11/11.
#  Copyright 2011 Bearded. All rights reserved.
#

class BriquetteSplash < NSView
  
  attr_accessor :message
    
  def drawRect rect
    NSColor.colorWithHexColorString("CCCCCC").set
    NSRectFill self.bounds
    
    icon = NSImage.imageNamed "logo_grayscale"
    icon.drawAtPoint(NSMakePoint(self.bounds.size.width/2 - 105, self.bounds.size.height/2 - 153), fromRect:self.bounds, operation:NSCompositeSourceOver, fraction:1.0)
  end
  
end