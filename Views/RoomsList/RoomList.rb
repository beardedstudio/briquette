# RoomList.rb
# briquette
#
# Created by Dominic Dagradi on 12/24/10.
# Copyright 2010 Bearded. All rights reserved.

class RoomList < JASectionedListView
  
  include BackgroundImage
  include KeyboardHelper

  BACKWARD = 0
  FORWARD = 1

  def drawRect rect
    setBackgroundImage "sidebar_background.png"
    
    NSColor.colorWithHexColorString("BBBBBB").bwDrawPixelThickLineAtPosition(self.bounds.size.width-1, withInset: 0, inRect: self.bounds, inView: self, horizontal: false, flip: false)
    
    super rect
    
    # Draw selected state
    selected_rect = nil
    selected = nil
    self.selectedViews.each do |s|
      selected = s if s.is_a? RoomListRoomView
    end
    selected_rect = selected.frame if selected and !selected.room.site.collapsed
        
    if selected_rect
      # Set selected background gradient
      NSColor.colorWithHexColorString("708697").set
      NSRectFill(selected_rect)
      
      # Draw selection arrow
      arrow = NSImage.imageNamed "room_arrow.png"    
      arrow.drawAtPoint(NSMakePoint(self.frame.size.width - 10, selected_rect.origin.y - 3), fromRect:self.bounds, operation:NSCompositeSourceOver, fraction:1.0)
    end

  end
  
  # We can safely ignore drag events in the roomlist (keeps from opening / joining every room you drag over)
  def mouseDragged event
  end

  def selectNextRoomView
    selectRoomWithDirection FORWARD
  end
  
  def selectPrevRoomView
    selectRoomWithDirection BACKWARD    
  end
  
  def selectRoomWithDirection direction
    
    return if numberOfViews <= 0
  
    index = indexForView(selectedViews.first) + (direction == FORWARD ? 1 : -1) 
    index = 1 if selectedViews.empty?
      
    startIndex = index
    
    nextView = nil
    while nextView.nil?
      index = 0 if index >= numberOfViews
      index = numberOfViews-1 if index < 0
      
      potentialView = viewAtIndex index
      
      unless potentialView.is_a? RoomListSiteView
        nextView = potentialView if potentialView.room.joined
      end
      
      if direction == FORWARD
        index += 1
      else
        index -= 1
      end

      return if index == startIndex
    end
    
    if !nextView.nil?
      deselectAllViews
      selectView nextView
    end
    
    self.setNeedsDisplay true
  end
  
  # If there is no view at the point the mouse was clicked at, do not fire any further events.
  # This keeps a selected room from being deselected when clicking in the blank space below the room list.
  def mouseUp event
    return if viewAtPoint(convertPoint(event.locationInWindow, fromView:nil)).nil?
    super(event) 
  end
    
end