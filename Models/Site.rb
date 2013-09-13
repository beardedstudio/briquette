# Site.rb
#
# Created by Dominic Dagradi on 10/24/10.
# Copyright 2010 Bearded. All rights reserved.
	
class Site
  
  attr_accessor :token  
  attr_accessor :owner_id
  attr_accessor :name

  attr_accessor :collapsed
  
  attr_accessor :controller
  attr_accessor :title
  
	def initialize title, info, controller
    @title = title
    @controller = controller
    
    @token = info["api_token"]
    @name = info["name"]
    @username = info["username"]
    @password = info["password"]
    @owner_id = info["user_id"]
        
    @collapsed = false
    @rooms = {}
    
    refreshRooms self, true
	end

	###################################
  # Site information
	###################################
  def baseURL
    "https://#{@title}.campfirenow.com"
  end
  
	###################################
  # Room management
	###################################
  def rooms
    # Get rooms from server if array empty and not already waiting on server
		if (@rooms.nil? || @rooms.empty?) && @refreshing == false 
      @rooms = {}
      refreshRooms(self, true)
		end
		
		@rooms
  end

	def refreshRooms sender, select = false, silent = false
    @select = select
    @refreshing = true
    get("/rooms.json", self, silent ? "refreshedRoomsSilently:" : "refreshedRooms:")
	end
  
  # When they click the ok button on the "Could not connect" sheet, find the alert's window and dismiss it.
  def alertDidEnd alert, returnCode:return_code, contextInfo:context_info
    alert.window.orderOut self
  end 
  
	def refreshedRooms request
    if request.responseHash.empty?
      window = @controller.window

      ConnectionManager.sharedManager.queueRequest("refreshRooms:", onObject:self, withOptions:[self, false, true])

      #NSApplication.sharedApplication.delegate.addAlert("Could not connect to Campfire", "Verify that your internet connection is working, or check \nhttp://status.37signals.com/\nfor service information.", Alert::ERROR)

      alert = NSAlert.alertWithMessageText("Could not connect to Campfire.\n\nVerify that your internet connection is working, or check \nhttp://status.37signals.com/\nfor service information.", 
        defaultButton:nil, 
        alternateButton:nil, 
        otherButton:nil, 
        informativeTextWithFormat:"")
        
      
      alert.beginSheetModalForWindow window, :modalDelegate => self, :didEndSelector => NSSelectorFromString("alertDidEnd:returnCode:contextInfo:"), :contextInfo => nil
    else
      _refreshedRooms request.responseHash["rooms"]
    end
    
    @refreshing = false
	end 
  
  def refreshedRoomsSilently request
    if request.responseHash.empty?
      ConnectionManager.sharedManager.queueRequest("refreshRooms:", onObject:self, withOptions:[self, false, true])
    else
      _refreshedRooms request.responseHash["rooms"]
    end
    
    @refreshing = false
  end
  
  def _refreshedRooms _rooms_data
    _rooms = @rooms
    @rooms = {} 
    
    _rooms_data.each do |r|

      room = _rooms[r["id"]]
      
      if room.nil?
        room = Room.new(r, self)
      else
        # update info w hash
        room.title = r["name"]
        room.topic = r["topic"]
      end
      
      @rooms[room.id] = room

    end
    @controller.refreshedRooms self, {"select" => @select}
  end
  
  #def addMessage message
  #  @stream.messageReceived message
  #end
  
  def leaveAllRooms options = {}
    @rooms.keys.each do |id|
      leaveRoom id, options
    end
  end
  
  def leaveRoom id, options
    room = @rooms[id]
    room.leave options
  end
  
  def leftRoom room
    @controller.leftRoom room
  end
  
	###################################
  # Sidebar view management
	###################################
  def listItemView
    if @view.nil?
      @view = RoomListSiteView.roomListItem
      @view.site = self
    end
    #@view.setNeedsDisplay true
    @view
  end
	
	def children
    if @collapsed
      []
    else
      @rooms.values.sort_by{|x| [x.title.downcase]}
    end
	end
	
	def childAt(index)
		children[index]
	end
  
private
  
  # GET request with given url and options
  def get(action = "", receiver = nil, callback = "requestFinished:")  

    # Make get request
    request = Request.get(action, delegate:receiver, callback:callback, site:self, options:{})
    
    # If synchronous, return response string
    if receiver.nil?
      request.responseHash
    end
  end

  
end