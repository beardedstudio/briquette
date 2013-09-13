# PreferencesView.rb
# briquette
#
# Created by Dominic Dagradi on 12/27/10.
# Copyright 2010 Bearded. All rights reserved.

class PreferencesView < NSView

private

  def getDefault key, options = {}
    options["type"] ||= nil
    value = Preferences.sharedPreferences.getDefault key 
    
    unless options["type"].nil?
      case options["type"]
        when "bool"
          if value.nil?
            options["default"] = true if options["default"].nil?
            value = options["default"]
            Preferences.sharedPreferences.setDefault value, key
          end
        else
          value = "" if value.nil?
      end
    end
    
    value
  end

end