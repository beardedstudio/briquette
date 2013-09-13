#
#  BreadcrumbDisplay.rb
#  briquette
#
#  Created by Dominic Dagradi on 8/6/11.
#  Copyright 2011 Bearded. All rights reserved.
#

BREADCRUMB_HEIGHT = 25
BREADCRUMB_PADDING = 12

class BreadcrumbView < NSView
  
  include BackgroundImage

  attr_accessor :delegate
  attr_accessor :crumbs

  def awakeFromNib
  end
  
  def setCrumbs _crumbs
    setSubviews []

    offset = 0
    _crumbs.each_with_index do |c, i|
      next if c[:title].nil?

      crumb = Breadcrumb.alloc.initWithFrame NSMakeRect(0,0,0,0)
      crumb.updateAttributes c[:title], c[:callback], @delegate, offset, (i+1 == _crumbs.length ? true : false)
      addSubview crumb

      offset += crumb.frame.size.width
    end
  end
  
  def drawRect rect
    setBackgroundImage "search-background.png"
    super rect
  end
  
end

class Breadcrumb < NSView
  attr_accessor :title
  attr_accessor :callback
  attr_accessor :delegate
  
  def updateAttributes title, callback, delegate, offset = 0, last = false
    @title = title
    @callback = callback
    @delegate = delegate
    @last = last
    
    attributes = {NSFontAttributeName => NSFont.systemFontOfSize(11.0), NSForegroundColorAttributeName => NSColor.colorWithHexColorString("666666")}
    @titleString = NSAttributedString.alloc.initWithString(@title, attributes:attributes)

    self.frame = NSMakeRect(0 + offset, 1, @titleString.size.width + BREADCRUMB_PADDING * 2.5, BREADCRUMB_HEIGHT)
  end
  
  def mouseUp event
    @delegate.send callback, self unless @delegate.nil? || callback.empty?
  end
  
  def drawRect rect    
    unless @last
      arrow = NSImage.imageNamed "search-breadcrumb-arrow.png"    
      arrow.drawAtPoint(NSMakePoint(self.frame.size.width - 9, 0), fromRect:self.bounds, operation:NSCompositeSourceOver, fraction:1.0)
    end
    
    
    titleStringPoint = NSMakePoint(BREADCRUMB_PADDING,5)
    @titleString.drawAtPoint titleStringPoint
  end
end