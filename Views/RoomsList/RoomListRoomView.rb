# RoomListRoomView.rb
# briquette
#
# Created by Dominic Dagradi on 12/24/10.
# Copyright 2010 Bearded. All rights reserved.

class RoomListRoomView < RoomListItem

  include BackgroundImage
  include KeyboardHelper

  TITLE_OFFSET = 31.0
  MIN_BADGE_WIDTH	 = 22.0
  BADGE_HEIGHT = 18.0
  BADGE_MARGIN	= 5.0
  BADGE_RADIUS = 3.0

  attr_accessor :title
  attr_accessor :badge
  attr_accessor :room
  attr_accessor :leave_button

  def awakeFromNib
    # Allow us to capture mouse hover events
    self.addTrackingRect(self.bounds, :owner => self, :userData => nil, :assumeInside => false) 
    leave_button.setTransparent true
    leave_button.setEnabled false
    
    @entered = false
  end

  def leaveRoom sender
    @room.leave
  end

  def mouseEntered event
    # Show "leave room" buttom if button enabled
    leave_button.setTransparent false if leave_button.isEnabled
    @entered = true
  end
  
  def mouseExited event
    # Hide "leave room" button when ending hover
    leave_button.setTransparent true
    @entered = false
  end

  def drawRect rect
    super rect

    # Set text color and button state appropriately
    if @room.joined
      textColor = NSColor.colorWithDeviceWhite(0.388, alpha:1.0)

      leave_button.setEnabled true 
      leave_button.setTransparent false if @entered
    else
      textColor = NSColor.colorWithHexColorString("8b979e")
      leave_button.setEnabled false
      leave_button.setTransparent true
    end

    style = NSParagraphStyle.defaultParagraphStyle.mutableCopy
    style.setLineBreakMode NSLineBreakByTruncatingTail
    
    attributes = {NSForegroundColorAttributeName => textColor, NSParagraphStyleAttributeName => style}

    if isSelected == 1
      
      # Set selected text color
      shadow = NSShadow.alloc.init
      shadow.setShadowColor(NSColor.colorWithDeviceWhite(0.0, alpha:0.25))
      shadow.setShadowOffset(NSMakeSize(1.0, -1.1))

      attributes[NSForegroundColorAttributeName] = NSColor.whiteColor
      attributes[NSShadowAttributeName] = shadow
      
      leave_button.setImage NSImage.imageNamed("close_button_active")
      leave_button.setAlternateImage NSImage.imageNamed("close_button_active_hover")
    else
      leave_button.setImage NSImage.imageNamed("close_button")
      leave_button.setAlternateImage NSImage.imageNamed("close_button_hover")
    end

    @title.setStringValue NSAttributedString.alloc.initWithString(room.title, :attributes => attributes) 

    titleFrame = @title.frame
    titleFrame.size.width = self.frame.size.width - TITLE_OFFSET
    
    # Draw badge
    if @room.hasBadge?

      shadow = NSShadow.alloc.init
      shadow.setShadowColor(NSColor.colorWithDeviceWhite(0.0, alpha:0.25))
      shadow.setShadowOffset(NSMakeSize(1.0, -1.1))

      attributes = {NSFontAttributeName => NSFont.boldSystemFontOfSize(12.0), NSForegroundColorAttributeName => NSColor.whiteColor, NSShadowAttributeName => shadow}

      # Calculate badge width      
      badgeWidth = 0
      if @room.badgeMessage?
        messageString = NSAttributedString.alloc.initWithString(@room.badgeMessage.to_s, attributes:attributes)
        badgeWidth += messageString.size.width + (BADGE_MARGIN*2)
      end
      if @room.badgeMention?
        mentionString = NSAttributedString.alloc.initWithString(@room.badgeMention.to_s, attributes:attributes)
        badgeWidth += mentionString.size.width + (BADGE_MARGIN*2)
      end
      
      badgeWidth = [badgeWidth, MIN_BADGE_WIDTH].max
      badgeSize = NSMakeSize(badgeWidth, BADGE_HEIGHT)
      badgeX = NSMaxX(self.bounds) - badgeSize.width - 18
      badgeY = NSMidY(self.bounds) - (badgeSize.height/2.0)
      
      # Trunacte room label
      titleFrame.size.width = titleFrame.size.width-badgeWidth-10
      
      # Badge clipping path
      badgeFrame = NSMakeRect(badgeX, badgeY, badgeSize.width, badgeSize.height)
      badgePath = NSBezierPath.bezierPathWithRoundedRect(badgeFrame, :xRadius => BADGE_RADIUS, :yRadius => BADGE_RADIUS)
      badgeShadowFrame = NSMakeRect(badgeX, badgeY-1, badgeSize.width, badgeSize.height)
      badgeShadow = NSBezierPath.bezierPathWithRoundedRect(badgeShadowFrame, :xRadius => BADGE_RADIUS, :yRadius => BADGE_RADIUS)

      # Draw badge shadow
      NSGraphicsContext.currentContext.saveGraphicsState
        badgeShadow.addClip
        if isSelected == 1
          NSColor.colorWithHexColorString("88a7c0").set
        else
          NSColor.colorWithHexColorString("FFFFFF").set
        end
        NSRectFill badgeShadowFrame
      NSGraphicsContext.currentContext.restoreGraphicsState      

      # Draw badge
      NSGraphicsContext.currentContext.saveGraphicsState
        badgePath.addClip

        messageOffset = 0
        
        # Set badge color and draw oval
        if @room.badgeMention?
          NSColor.colorWithHexColorString("93BB5F").set          

          messageOffset = [mentionString.size.width + (BADGE_MARGIN*2), @room.badgeMessage? ? 0 : MIN_BADGE_WIDTH].max
          mentionFrame = NSMakeRect(badgeX, badgeY, messageOffset, BADGE_HEIGHT)
          NSRectFill(mentionFrame)
          
          # Set badge text color and draw text
          badgeTextPoint = NSMakePoint(NSMidX(mentionFrame)-(mentionString.size.width/2.0),	 NSMidY(mentionFrame)-(mentionString.size.height/2.0)+1);
          mentionString.drawAtPoint badgeTextPoint
        end
        
        if @room.badgeMessage?
          NSColor.colorWithHexColorString("7893a9").set          

          messageWidth = [messageString.size.width + (BADGE_MARGIN*2), @room.badgeMention? ? 0 : MIN_BADGE_WIDTH].max
          messageFrame = NSMakeRect(badgeX+messageOffset, badgeY, messageWidth, BADGE_HEIGHT)
          NSRectFill(messageFrame)
          
          # Set badge text color and draw text
          badgeTextPoint = NSMakePoint(NSMidX(messageFrame)-(messageString.size.width/2.0),	 NSMidY(messageFrame)-(messageString.size.height/2.0)+1);
          messageString.drawAtPoint badgeTextPoint
        end
        
      NSGraphicsContext.currentContext.restoreGraphicsState      
    end

    @title.setFrame(titleFrame)
    
  end  
  
end