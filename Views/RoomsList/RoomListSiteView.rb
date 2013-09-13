# RoomListSiteView.rb
# briquette
#
# Created by Dominic Dagradi on 12/24/10.
# Copyright 2010 Bearded. All rights reserved.

class RoomListSiteView < RoomListItem

  attr_accessor :title
  attr_accessor :site

  def drawRect rect
    # Set text attributes
    attributes = {}
    attributes[NSForegroundColorAttributeName] = NSColor.colorWithDeviceRed(0.541, :green => 0.631, :blue => 0.702, :alpha => 1.0)

    @title.setStringValue NSAttributedString.alloc.initWithString(@site.title.upcase, attributes:attributes)
        
    indicator = NSImage.imageNamed(@site.collapsed ? "site-collapsed.png" : "site-open.png")

    indicatorXOffset = 12
    indicatorYOffset = self.bounds.size.height/2 - indicator.size.height/2 - 1
    indicator.drawAtPoint(NSMakePoint(indicatorXOffset, indicatorYOffset), fromRect:self.bounds, operation:NSCompositeSourceOver, fraction:1.0)
    
    super rect
  end

end