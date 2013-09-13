# SystemMessageView.rb
# scoutmaster
#
# Created by Brett Bender on 11/30/10.
# Copyright 2010 Bearded. All rights reserved.

class SystemMessageView < AbstractMessageView
  def user
    _user = "&nbsp;"
    _user = @message.user.short_name unless message.user.nil?
  end
  
  def date
    if @type == "room"
      super
    else
      ""
    end
  end
  
  def classes
    "system " + super
  end
end

class EnterMessageView < SystemMessageView
  def body
    "entered the room"
  end
  
  def classes
    "joinleave " + super
  end
end

class MetaMessageView < SystemMessageView
  def time
    if @type == "room"
      super
      else
      ""
    end
  end

  def classes
    "meta " + super
  end
end

class AdvertisementMessageView < SystemMessageView  
  def classes
    "advertisement " + super
  end
end

class KickMessageView < SystemMessageView
  def body
    "left the room"
  end

  def classes
    "joinleave " + super
  end
end

class LeaveMessageView < KickMessageView
end

class DayMessageView < SystemMessageView
  def user
    "&nbsp;"
  end
  
  def body
    @message.created_at.strftime("%A, %b %e")
  end
  
  def classes
    "day " + super
  end
end

class TopicChangeMessageView < SystemMessageView
  def body
    "Changed the topic to: <em>#{@message.body}</em>"
  end
  
  def classes
    "topic " + super
  end
end

class AllowGuestsMessageView < SystemMessageView
  def body
    "turned on guest access"
  end
  
  def classes
    "guest " + super
  end
end

class DisallowGuestsMessageView < AllowGuestsMessageView
  def body
    "turned off guest access"
  end
end

class LockMessageView < SystemMessageView
  def body
    "has locked the room"
  end
  
  def classes
    "lock " + super
  end
end

class UnlockMessageView < LockMessageView
  def body
    "has unlocked the room"
  end
end