# UserListCell.rb
# briquette
#
# Created by Dominic Dagradi on 1/2/11.
# Copyright 2011 Bearded. All rights reserved.

class UserListCell < NSTextFieldCell

  def drawWithFrame cellFrame, inView:controlView
      
    style = NSParagraphStyle.defaultParagraphStyle.mutableCopy
    style.setLineBreakMode NSLineBreakByTruncatingTail
      
    attributes = {NSForegroundColorAttributeName => NSColor.colorWithHexColorString("5f7484"), NSParagraphStyleAttributeName => style}
    stringValue.drawInRect NSMakeRect(cellFrame.origin.x+12, cellFrame.origin.y+3, cellFrame.size.width-16, cellFrame.size.height), :withAttributes => attributes

  end

end