# MessagesPreferencesController.rb
# briquette
#
# Created by Dominic Dagradi on 7/2/11.
# Copyright 2011 Bearded. All rights reserved.

require 'PreferencePaneController'

class MessagesPreferences < PreferencePaneController

  SECTION = "messages"

  JOINLEAVE = SECTION+"_show_join"
  IMAGES = SECTION+"_show_images"
  TIMESTAMPS = SECTION+"_show_time"

  attr_accessor :message_display_changed

  def init
    @message_display_changed = false
    return super.initWithNibName("Messages", bundle:nil)
  end
  
  def toolbarItemIdentifier
    "MessagePreferences"
  end
  
  def toolbarItemImage
    NSImage.imageNamed "MessagePreferences"
  end

  def toolbarItemLabel
    "Messages"
  end
  
  #########################################
  # Actions
  #########################################

  # Show/Hide Message types
  def updateShowJoined sender
    updateBoolean JOINLEAVE, sender.state
    @message_display_changed = true
  end

  def updateShowImages sender
    updateBoolean IMAGES, sender.state    
    @message_display_changed = true
  end

  def updateShowTimestamps sender
    updateBoolean TIMESTAMPS, sender.state
    @message_display_changed = true
  end
  
end
