# AbstractMessageView.rb
# scoutmaster
#
# Created by Brett Bender on 11/30/10.
# Copyright 2010 Bearded. All rights reserved.

class AbstractMessageView
  attr_accessor :message

  def initialize(m, display_user = true, first = false, display_time = false)
    @message = m
    @display_user = display_user
    @display_time = display_time
    @first = first  
  end
  
  def toHTML _type = "room"
    @type = _type
    html = if @type == "search"
      searchHTML
    else
      roomHTML
    end
    "<div id='#{@message.id}' class='message #{classes}' data-user=\"#{user}\">
      #{html}
    </div>"
  end
  
  def roomHTML
    column(user, "user") +
    column(body, "content", postContent(@type)) +
    column(time, "timestamp")
  end
    
  def searchHTML
    column(user, "user") +
    column(body, "content", postContent(@type)) +
    column(date, "date") +
    column(room, "room-name")
  end
    
  def user
    username = @message.user.short_name unless message.user.nil?
    if @display_user
      username
    else
      "&nbsp;"
    end
  end
  
  def body
    @message.body
  end

  def postContent type = "room"
    ""
  end
  
  def time
    @message.timestamp if @display_time
  end

  def date
    @message.timestamp Message::DATE_FORMAT
  end

  def room
    if @message.room
      @message.room.title
    else
      ""
    end
  end
    
  def user_message?
    false
  end

private

 def column data, column_class, after = ""
    "<div class='column #{column_class}'>
      <div class='wrap'>
        #{data}
        #{after}
      </div>
    </div>"
  end

  def classes
    _classes = []
    _classes << @message.classes
    _classes << (@message.mine? ? "mine" : "") 
    _classes << (@message.mentioned? && !@message.mine? ? "mentioned" : "")
    _classes << (@first ? "first" : "")
    _classes << @type
    _classes.join(" ")
  end
  
end