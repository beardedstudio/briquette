# MessageInput.rb
# briquette
#
# Created by Dominic Dagradi on 12/10/10.
# Copyright 2010 Bearded. All rights reserved.

require 'UploadHandler'

class MessageInput < NSTextView
  include UploadHandler
  
  def awakeFromNib
    # We register for files dragged on us (for drag and drop upload)
    self.registerForDraggedTypes([NSFilenamesPboardType])
    
    self.setAutomaticSpellingCorrectionEnabled (Preferences.sharedPreferences.getDefault(BriquetteDelegate::SPELLING_CORRECTION_ENABLED) == 1)
    
    super
  end
  
  # Overrode method inserts ":" after completions at beginning of string
  def insertCompletion(word, forPartialWordRange:range, movement:movement, isFinal:flag)

    # If we're inserting the word and it starts at the beginning, append a colon
    if flag == true and range.location == 0
      word = word + ":"
    end
    
    super word, range, movement, flag
  end

end

class MessageInputWrapper < NSView
  
  attr_accessor :message_input
  attr_accessor :message_icon
  
  def awakeFromNib
    
    #    @message_input = MessageInput.alloc.initWithFrame get_input_frame
    #@message_input.setAutoresizingMask self.autoresizingMask
    @message_input.frame = get_input_frame

  end
  
  def drawRect rect
    @message_input.frame = get_input_frame
    @message_icon.frame = get_icon_frame

    super rect
    
    NSColor.colorWithHexColorString("D4DEE4").set
    NSBezierPath.strokeLineFromPoint NSMakePoint(0,rect.size.height), :toPoint => NSMakePoint(rect.size.width, rect.size.height)
  end

private
  
  def get_input_frame
    text_bounds = NSMakeRect(0,0,0,0)
    text_bounds.size.width = self.bounds.size.width * 0.72
    text_bounds.size.height = 40
    text_bounds.origin.x = self.bounds.size.width * 0.18
    text_bounds.origin.y = 15
    text_bounds
  end
  
  def get_icon_frame
    icon_frame = @message_icon.frame
    icon_frame.origin.x = (self.bounds.size.width * 0.18) - (icon_frame.size.width + 20)
    icon_frame
  end
  
end

