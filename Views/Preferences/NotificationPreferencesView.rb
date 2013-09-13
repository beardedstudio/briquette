# NotificationPreferencesView.rb
# briquette
#
# Created by Dominic Dagradi on 1/8/11.
# Copyright 2011 Bearded. All rights reserved.

require 'PreferencesView'

class NotificationPreferencesView < PreferencesView

  GROWL_NOT_INSTALLED = 0

  attr_accessor :new_bounce
  attr_accessor :new_growl
  attr_accessor :new_growl_persist
  attr_accessor :mention_bounce
  attr_accessor :mention_growl
  attr_accessor :mention_growl_persist
  attr_accessor :sound_announce_all
  attr_accessor :sound_announce_mention

  def awakeFromNib
    if GrowlApplicationBridge.isGrowlInstalled == GROWL_NOT_INSTALLED
      new_growl.setEnabled false
      mention_growl.setEnabled false
      new_growl_persist.setEnabled false
      mention_growl_persist.setEnabled false
    end

    new_bounce.setState(getDefault(NotificationPreferences::NEW_BOUNCE, {"type" => "bool", "default" => false}))
    new_growl.setState(getDefault(NotificationPreferences::NEW_GROWL, {"type" => "bool", "default" => false}))
    new_growl_persist.setState(getDefault(NotificationPreferences::NEW_GROWL_PERSIST, {"type" => "bool", "default" => false}))
    mention_bounce.setState(getDefault(NotificationPreferences::MENTION_BOUNCE, {"type" => "bool", "default" => false}))
    mention_growl.setState(getDefault(NotificationPreferences::MENTION_GROWL, {"type" => "bool", "default" => true}))
    mention_growl_persist.setState(getDefault(NotificationPreferences::MENTION_GROWL_PERSIST, {"type" => "bool", "default" => true}))

    [mention_growl, mention_growl_persist].each{|item| item.enabled = false} if new_growl_persist.state == NSOnState
    
    sound_announce_all.setState(getDefault(NotificationPreferences::SOUND_ANNOUNCE_ALL, {"type" => "bool", "default" => false}))

    sound_mention_default = getDefault(NotificationPreferences::SOUND_ANNOUNCE_MENTION, {"type" => "bool", "default" => false})
    sound_announce_mention.setState(sound_announce_all.state == NSOnState ? NSOnState : sound_mention_default)
    sound_announce_mention.enabled = sound_announce_all.state != NSOnState
  end

end