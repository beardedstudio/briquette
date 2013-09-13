# MessagesPreferencesView.rb
# briquette
#
# Created by Dominic Dagradi on 12/27/10.
# Copyright 2010 Bearded. All rights reserved.

require 'PreferencesView'

class MessagesPreferencesView < PreferencesView

  attr_accessor :join_left
  attr_accessor :images
  attr_accessor :timestamps

  def awakeFromNib
    join_left.setState(getDefault(MessagesPreferences::JOINLEAVE, {"type" => "bool"}))
    images.setState(getDefault(MessagesPreferences::IMAGES, {"type" => "bool"}))
    timestamps.setState(getDefault(MessagesPreferences::TIMESTAMPS, {"type" => "bool"}))
  end
end