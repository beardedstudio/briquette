# BackgroundImage.rb
# briquette
#
# Created by Dominic Dagradi on 1/23/11.
# Copyright 2011 Bearded. All rights reserved.

module BackgroundImage

  def setBackgroundImage filename
    NSGraphicsContext.currentContext.saveGraphicsState

    xOffset = NSMinX(self.convertRect(self.bounds, :toView => nil))
    yOffset = NSMaxY(self.convertRect(self.bounds, :toView => nil))
    NSGraphicsContext.currentContext.setPatternPhase(NSMakePoint(xOffset,yOffset))

    background = NSImage.imageNamed filename
    NSColor.colorWithPatternImage(background).set
    NSRectFill(self.bounds)

    NSGraphicsContext.currentContext.restoreGraphicsState
  end
end