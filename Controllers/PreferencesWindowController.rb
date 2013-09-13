#
#  PreferenceWindow.rb
#  briquette
#
#  Created by Dominic Dagradi on 8/6/11.
#  Copyright 2011 Bearded. All rights reserved.
#

class PreferencesWindowController < MASPreferencesWindowController

  attr_accessor :messagePreferences
  
  def windowWillClose notification
    super
    NSApplication.sharedApplication.delegate.refreshRoomViews if @messagePreferences.message_display_changed
  end
  
end