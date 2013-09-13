# KeyboardHelper.rb
# briquette
#
# Created by Dominic Dagradi on 3/5/11.
# Copyright 2011 Bearded. All rights reserved.

module KeyboardHelper

  def keyDown event
    insertTextInActiveRoom event
  end

  def insertTextInActiveRoom event                         
    # Handle keydowns in normal rooms/roomlistviews/userlistviews
    if !self.respond_to?(:controller) || self.controller.is_a?(RoomController)
      windowController = NSApplication.sharedApplication.delegate.windowController
      selected = windowController.selected
      
      if selected
        windowController.window.makeFirstResponder selected.view.textView
        selected.view.textView.keyDown event
      end
    # Handle keydowns in transcripts
    elsif self.controller.is_a?(TranscriptViewController)
      self.controller.windowController.window.makeFirstResponder self.controller.windowController.text_field
      self.controller.windowController.text_field.keyDown event
    # Handle keydowns in search
    else
      self.controller.window.makeFirstResponder self.controller.text_field
      self.controller.text_field.keyDown event
    end
  end
end
