# PreferencePaneController.rb
# briquette
#
# Created by Dominic Dagradi on 12/26/10.
# Copyright 2010 Bearded. All rights reserved.

require 'TextHelper'

class PreferencePaneController < NSViewController

  include TextHelper

  def updateBoolean name, state
    setDefault((state == NSOnState), name)
  end
  
  def updateString name, value
    setDefault value, name
  end
    
private

  def setDefault value, key
    Preferences.sharedPreferences.setDefault value, key
  end
  
end