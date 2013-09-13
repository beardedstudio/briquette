#
#  AlertView.rb
#  briquette
#
#  Created by Dominic Dagradi on 8/14/11.
#  Copyright 2011 Bearded. All rights reserved.
#

class Alert
  SUCCESS = "SUCCESS"
  ERROR = "ERROR"
end

class AlertView < NSView
  
  SUCCESS_BACKGROUND_COLOR = "026f95"
  ERROR_BACKGROUND_COLOR = "91201b"
  
  attr_accessor :title
  attr_accessor :message
  attr_accessor :type
  
  def drawRect rect
    backgroundColor.set
    NSRectFill(self.bounds)

    attributes = {NSFontAttributeName => NSFont.systemFontOfSize(14.0), NSForegroundColorAttributeName => textColor}
    @titleString = NSAttributedString.alloc.initWithString(@title, attributes:attributes)
    @titleString.drawAtPoint NSMakePoint(10,22)

    attributes = {NSFontAttributeName => NSFont.systemFontOfSize(11.0), NSForegroundColorAttributeName => textColor}
    @messageString = NSAttributedString.alloc.initWithString(@message, attributes:attributes)
    @messageString.drawAtPoint NSMakePoint(10,8)
  end

private
  
  def backgroundColor
    NSColor.colorWithHexColorString (@type == Alert::SUCCESS ? SUCCESS_BACKGROUND_COLOR : ERROR_BACKGROUND_COLOR)
  end

  def textColor
    NSColor.colorWithHexColorString "FFFFFF"
  end
  
end