# Room.rb
# briquette
#
# Created by Dominic Dagradi on 10/24/10.
# Copyright 2010 Bearded. All rights reserved.

require 'json'
require 'cgi'

class Room
  include TextHelper
  
  attr_reader :id

  attr_accessor :site
  attr_accessor :controller

  attr_accessor :title
  attr_accessor :topic
  attr_accessor :present
  attr_accessor :joined

  attr_accessor :badgeMessage
  attr_accessor :badgeMention

  def initialize(info, site)  
    @id = info.fetch("id"){nil}
    @title = info["name"]
    @topic = info["topic"]
    @badgeMessage = 0
    @badgeMention = 0
    @joined = false

    @lastMessage = nil
    
    # Set a room's site so it can access the appropriate api token
    @site = site
    @stream = nil
    
    @present = []
    @buffer = []
  end 

  ############################################### 
  # Room state
  ############################################### 
  def hasBadge?
    badgeMessage? || badgeMention?
  end
  
  def badgeMessage?
    @badgeMessage > 0
  end
  
  def badgeMention?
    @badgeMention > 0
  end
  
  def badgeCount
    @badgeMessage + @badgeMention
  end
  
  def is_ready?
    @joined and @room_info and @recent and @users_loaded
  end
  
  def listItemView
    if @view.nil?
      @view = RoomListRoomView.roomListItem
      @view.room = self
    end
    @view.setNeedsDisplay true
    @view
  end
  
  def completions
    _completions = []
    @present.each do |user|
      _completions << user.name
    end
    
    _completions
  end

  ############################################### 
  # Room message handling
  ############################################### 
  def messageReceived message, options = {}

    # Ignore timestamps
    return if message["type"] == Message::TIME 

    
    # Capture messages pushed to stream before room loads
    @stream_buffer << message and return if !is_ready?
  
    received = nil
    is_from_join = options.fetch("is_from_join"){ false }
    should_buffer = options.fetch("buffer"){ false }    
  
    # Use given object if possible, otherwise create new from message data hash
    if options["message"]
      _message = options["message"]
    else
      _message = Message.new(message, self)    
    end
    _message.room = self

    if should_buffer

      # Add to buffer for future reference
      @buffer << {:hash => message, :object => _message}

    else
      # Search buffer for object and return if found
      @buffer.each do |b|
        if message["id"] == b[:object].id || message["body"] == b[:hash]["body"]
          received = b 
        end
      end
    
      # If we've already posted this message to the room, don't post it again.
      unless received.nil?
        received[:object].created_at = _message.created_at
        @buffer.delete received
        controller.updateMessage(_message) if _message.type == Message::PASTE
        return 
      end
    end
    
    # Handle joining/leaving rooms
    if _message.type == Message::ENTER
      user_joined(_message.user)
    elsif [Message::LEAVE, Message::KICK].include? _message.type
      user_left(_message.user)
      
      # If we get a message that we left (and it's not from joining a room)
      # Rejoin the room, you probably got dc'd on another computer.
      if _message.mine? && !is_from_join
        @joined = false
        self.join
      end
    end

    
    # Add message to room message
    @lastMessage = _message

    # Tell room controller that we've received a message
    @controller.addMessage(_message, {"is_from_join" => is_from_join})
  end
  
  ############################################### 
  # Room presence
  ############################################### 
  def join
    return if @joined == true
  
    if @controller.nil?
      @controller = RoomController.alloc().initWithNibName("RoomView",bundle:nil)
      @controller.room = self
      @controller.site = @site
    end
    
    @room_info = false
    @recent = false
    @users_loaded = false
    @joined = true
    
    @message_buffer = []
    @user_id_buffer = []
    @stream_buffer = []
    @present = []

    Preferences.sharedPreferences.joinedRoom @id
    post 'join', {"receiver" => self, "callback" => "joinResponse:"}
  end
    
  def joinResponse request
    if request.responseStatusCode == 200 && @joined

      # Start streaming messages
      stream = Stream.new(self)
      stream.start
      
      # Get room users, recent messages
      get_room_info
      recent
    else
      ConnectionManager.sharedManager.queueRequest "rejoin", onObject:self, withOptions:nil
    end
  end
  
  # Rejoin room if network fails, or stream demands it
  def rejoin
    @joined = false
    join  
  end
  
  def ready
    if is_ready?
      (@message_buffer+@stream_buffer).each do |m|
        messageReceived(m, {"is_from_join" => true})
      end
      
      @controller.joinedRoom
      # @controller.streamStarted
    end
  end

  def leave options = {}
    return if @joined == false
    
    if options.fetch("exiting"){ false }
      post "leave"
    else
      post "leave", {"receiver" => self}

      @joined = false
      closeStream
      
      # TODO: don't clear this info
      @present = []

      Preferences.sharedPreferences.leftRoom @id
      #@controller.leftRoom
      @controller.view.leftRoom
      @controller.view = nil
      @controller = nil

      @site.leftRoom self
    end
  end
  
  #########################################
  # Stream management
  #########################################  
  def streamStarted _stream
    closeStream unless @stream.nil?
    @stream = _stream
    @controller.streamStarted
  end
  
  def streamFailed
    @controller.streamFailed
  end
  
  def closeStream
    @stream.close if @stream
    @stream = nil
  end
    
  #########################################
  # Room info
  #########################################
  def get_room_info
    get "", {"receiver" => self, "callback" => "update_room_info:"}
  end
  
  def update_room_info request      
    if request.responseStatusCode == 200 && !request.responseHash.empty?
      _info = request.responseHash
      
      # Set topic
      @topic = _info["room"]["topic"]
      
      # Users currnetly in room
      _users = _info["room"]["users"] 
      
      _users.each do |u|
        user_joined(User.find(u["id"], u, {"site" => @site}))
      end   
    end
    
    @room_info = true and ready
  end
  
  ############################################### 
  # User management
  ############################################### 
  def user_joined(user)
    @present << user unless @present.include? user
    @controller.refreshUsers
  end
  
  def user_left(user)
    @present.delete user
    @controller.refreshUsers
  end

  ############################################### 
  # Campfire API
  ###############################################
  def lock
    post 'lock'
  end

  def unlock
    post 'unlock'
  end

  def message(message, options = {})
    send_message message
  end
  
  def tweet(tweet)
    send_message tweet, Message::TWEET
  end

  def paste(paste)
    send_message paste, Message::PASTE
  end

  def play(sound)
    send_message sound, Message::SOUND
  end
  
  def setTopic(topic)
    put '', {"body" => {"room" => {"topic" => topic}}.to_json, "receiver" => self, "callback" => "updatedTopic:"}
  end
  
  def updatedTopic request
    # Hande topic update in UI
  end

  def setName(name)
    put '', {"body" => {"room" => {"name" => name}}.to_json, "receiver" => self, "callback" => "updatedName:"}
  end
  
  def updatedName request
    NSApplication.sharedApplication.delegate.windowController.updateSitesSilently
  end
  
  def recent
    get "recent", {"receiver" => self, "callback" => "got_recent:"}
  end
  
  def got_recent request    
    _messages = request.responseHash['messages']
    
    if _messages.nil? || _messages.empty? 
      _messages = []
    end
    
    # No messages, load all messages received
    if @lastMessage.nil?
      _messages.each do |m|
        # TODO: don't buffer user id if already loaded
        @user_id_buffer << m["user_id"]
        @message_buffer << m
      end
      
      @user_id_buffer.delete("null")          
      @user_id_buffer.uniq!
      
      @user_id_buffer.each do |uid|
        User.load uid, {"receiver" => self, "callback" => "loaded_user:", "site" => @site}
      end
      
    # Existing messages: load only messages new than yours
    else
    
      # Time cutoff
      @time = @lastMessage.created_at
      
      _messages.each do |m|
        _check_time = Time.parse(m["created_at"])
        if _check_time > @time && m["body"] != @lastMessage.body
          @message_buffer << m
        end
      end
            
      if @message_buffer.count > 100
        status = { 'type' => Message::SYSTEM,
                    'created_at' => Time.now.to_s,
                    'room_id' => self.id,
                    'body' => @time.strftime("Messages since %l:%M%p, %m/%d/%Y"),
                    'user_id' => 'null',
                    'id' => "status-messages-since"
                  }
        @message_buffer = [status] + @message_buffer 
      end 
    end
      
    @users_loaded = true if @user_id_buffer.compact.empty?
    @recent = true and ready
  end
  
  def loaded_user request
    uid = "null"
    if request.responseStatusCode != 404 && request.responseHash.has_key?("user") && request.responseHash["user"].has_key?("id")
      
      uid = request.responseHash["user"]["id"]

      # TODO: dirty way to have room know about room responses
      User.loaded(request)
    end
    
    @user_id_buffer.delete uid
    @users_loaded = true if @user_id_buffer.compact.empty?

    ready
  end

  def transcript
    get('transcript')['messages']
  end

  private

  def send_message(body, type = Message::TEXT)
    message = {"user_id" => @site.owner_id, "body" => body.chomp, "type" => type}
    messageReceived(message, {"buffer" => true})

    post 'speak', {"body" => {:message => {:body => body, :type => type}}.to_json, "receiver" => self, "callback" => "updateMessageId:"}
  end

  def updateMessageId request
    # Format received message the same way we'd format a message we're sending out
    return if request.responseHash.nil?
    
    received = request.responseHash.fetch('message'){nil}
    return if received.nil?

    received_body = html_replace(received['body'].clone)

    @buffer.each do |sent|
      #Strip whitespace for all sent messages in the buffer, compare to received message
      sent_body = sent[:object].body
      
      # Update the sent message id when we find it
      if sent_body == received_body && sent[:object].user.id == received['user_id']
        original_message_id = sent[:object].id
        sent[:object].id = received['id']
        controller.updateMessage(sent[:object], :original_message_id => original_message_id) if sent[:object].type == Message::PASTE
      end
    end
  end

  # TODO: refactor below methods in single method
  # GET request with given url and options
  def get(action = "", options = {})  
    # Set get defaults
    options["receiver"] ||= nil
    options["callback"] ||= "requestFinished:"

    # Make get request
    request = Request.get(room_url_for(action), delegate:options["receiver"], callback:options["callback"], site:@site, options:{})
    
    # If synchronous, return response string
    if options["receiver"].nil?
      request.responseHash
    end
  end

  def put(action, options = {})
    
    options["method"] = "PUT"
    post action, options
  end

  # POST request with given url and options
  def post(action, options = {})    
    # Set post defaults
    options["body"] ||= nil
    options["receiver"] ||= nil
    options["callback"] ||= "requestFinished:"
    options["method"] ||= "POST"
    
    # Make post request
    request = Request.post(room_url_for(action), content:options["body"], delegate:options["receiver"], callback:options["callback"], site:@site, options:{"method" => options["method"]})
    
    # If synchronous, return response string
    if options["receiver"].nil?
      request.responseHash
    end
  end

  def room_url_for(action, format = "json")
    action.empty? ? "/room/#{id}.#{format}" : "/room/#{id}/#{action}.#{format}"
  end
  
end