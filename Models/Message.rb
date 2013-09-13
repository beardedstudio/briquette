# Message.rb
# briquette
#
# Created by Dominic Dagradi on 10/28/10.
# Copyright 2010 Bearded. All rights reserved.

# Sample hash
# {
#		"room_id"=>342636, 
#		"created_at"=>"2010/10/29 02:13:17 +0000", 
#		"body"=>"asdf ", 
#		"id"=>273074657, 
#		"user_id"=>725499, 
#		"type"=>"TextMessage"
#	}

require 'cgi'
require 'TextHelper'

class Message
  
  include TextHelper
    
  # Campfire Message types
  TEXT    = "TextMessage"
  ENTER   = "EnterMessage"
  KICK    = "KickMessage"
  LEAVE   = "LeaveMessage"
  TIME    = "TimestampMessage"
  PASTE   = "PasteMessage"
  SYSTEM  = "SystemMessage"
  META    = "MetaMessage"
  UPLOAD  = "UploadMessage"
  LOCK    = "LockMessage"
  UNLOCK  = "UnlockMessage"
  TOPIC   = "TopicChangeMessage"
  TWEET   = "TweetMessage"
  SOUND   = "SoundMessage"
  AD      = "AdvertisementMessage"

  # Our Message types
  SITE  = "SiteMessage"
  DAY = "DayMessage"

  # Our additions
  DAYCHANGE  = "DayChangeMessage"
  ROOMCHANGE  = "RoomChangeMessage"
  
	TIMESTAMP_FORMAT = "%l:%M%p"
	DATE_FORMAT = "%a, %b %d"
	
	attr_accessor :id
	attr_accessor :room 
	attr_accessor :user
	attr_accessor :body
  attr_accessor :raw
  attr_accessor :upload
	attr_accessor :type
  attr_accessor :created_at
  attr_accessor :starred
  attr_accessor :upload_delegate
  attr_accessor :classes
	
	def initialize message_hash, room = nil, upload_delegate = nil
    # Set defaults
    user_id = message_hash.fetch("user_id"){ "null" }
    @created_at = Time.parse(message_hash.fetch("created_at"){ Time.now.to_s })
    
    @id = message_hash.fetch("id"){ "#{user_id}-#{@created_at.to_i}" }.to_s
    @room = room
    @type = message_hash.fetch("type"){ Message::SYSTEM }

    @upload = nil
    @upload_delegate = upload_delegate.nil? ? @room.controller : upload_delegate

    @waitingOnUpload = false
    @starred = false

    @user = user_id == "null" ? nil : User.find(user_id, nil, {"site" => @room.site})
    
    @raw = message_hash.fetch("body"){""} # Raw message is stored before HTML is added
    @body = @raw
    
    if @type == Message::TWEET # Pull raw tweet data 
      tweet = message_hash.fetch("tweet"){{}}
      @raw = tweet.fetch("message"){@body}
    elsif ![Message::AD, Message::META, Message::SYSTEM].include?(@type) # Let ads and system messages post their own HTML
      @body = html_replace CGI::escapeHTML(@body) unless @body.nil?
    end
    
    @classes = message_hash.fetch("classes"){""}
    
    retrieveUpload if @type == Message::UPLOAD
  end
  
  def waitingOnUpload
    @waitingOnUpload
  end
  
  def retrieveUpload
    @waitingOnUpload = true
    Request.get(getUploadUrl(self), delegate:self, callback:"uploadRetrieved:", site:@room.site, options:{})
  end
  
  def uploadRetrieved request
    @waitingOnUpload = false
    @upload = Upload.new(request.responseHash, self) if request.responseStatusCode == 200
    @upload_delegate.updateMessage(self)
  end
    
    
  ###############################
  # Display Helpers
  ###############################    
  def timestamp format = Message::TIMESTAMP_FORMAT
    time = created_at.strftime(format)
  end
    
  def mine?
    return false if @user.nil?
  
    message_user = @user.id.to_i
    app_user = @room.site.owner_id
    
    message_user == app_user
  end
  
  def mentioned?
    return false if @body.nil? or !userMessage?
  
    # Build new array, because modifiying the returned array derps out
    custom = Preferences.sharedPreferences.getDefault(NotificationPreferences::CUSTOM_NOTIFICATIONS) || []
    notifications = [] + custom + [@room.site.name.downcase]

    notifications.each do |mention|
      return true if @body.downcase.index(/\b(#{mention.downcase})\b/)
    end

    return false
  end  
  
  ###############################
  # Notifications
  ###############################
  def shouldUpdateBadgeLabel?
    userMessage? && !mine?
  end
  
  def shouldBounceDockIcon?
    bounce = Preferences.sharedPreferences.getDefault(mentioned? ? NotificationPreferences::MENTION_BOUNCE : NotificationPreferences::NEW_BOUNCE)
    bounce.nil? ? false : bounce
  end
  
  def shouldPostGrowlMessage?
    # If Growl not installed, do nothing
    return false if (!GrowlApplicationBridge.isGrowlInstalled || mine?)

    growl = Preferences.sharedPreferences.getDefault NotificationPreferences::NEW_GROWL if userMessage?

    unless growl
      growl = Preferences.sharedPreferences.getDefault NotificationPreferences::MENTION_GROWL if mentioned?
    end

    growl = false if growl.nil?
    growl
  end

  def growlMessageIsSticky?
    # If Growl not installed, do nothing
    return false if (!GrowlApplicationBridge.isGrowlInstalled || mine?)

    sticky = Preferences.sharedPreferences.getDefault NotificationPreferences::NEW_GROWL_PERSIST if userMessage?
    
    unless sticky
      sticky = Preferences.sharedPreferences.getDefault NotificationPreferences::MENTION_GROWL_PERSIST if mentioned?
    end
    
    sticky = false if sticky.nil?
    sticky
  end
  
  def shouldPlaySoundNotification?
  
    # If it's a message from a user
    if userMessage?
      play_sound = Preferences.sharedPreferences.getDefault NotificationPreferences::SOUND_ANNOUNCE_ALL

      # If they don't have all incoming messages notification on, check for if user is mentioned
      if mentioned? && !play_sound
        play_sound = Preferences.sharedPreferences.getDefault NotificationPreferences::SOUND_ANNOUNCE_MENTION
      end
    end

    # Default is off just in case
    play_sound = false if play_sound.nil?
    play_sound
  end

  ###############################
  # Message info
  ###############################
  def userMessage?
    [TEXT, PASTE, UPLOAD, TWEET, SOUND].include?(@type)
  end
  
  def roomEvent?
    [ENTER, LEAVE, SYSTEM, TOPIC, LOCK, UNLOCK].include?(@type)
  end
  
end
