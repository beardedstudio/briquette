# CampfireController.rb
# briquette
#
# Created by Dominic Dagradi on 10/24/10.
# Copyright 2010 Bearded. All rights reserved.


class MainWindowController < NSWindowController

  include KeyboardHelper

  attr_accessor :sheet
  
  attr_accessor :sites
  attr_reader   :selected
  
  attr_writer :mainView
  attr_accessor :roomList
  attr_accessor :buttonBar
  attr_accessor :messagesView
  attr_accessor :blankView
  
  def awakeFromNib

    @sites = {}
    @selected = nil
    @blankView = BriquetteSplash.new
    
    # Get stored site data
    _sites = Preferences.sharedPreferences.getSites
    
    _sites.each do |name,info|
      addSite name, info
    end
  
    # Set split view configuration
    @mainView.minValues = {0 => 125, 1 => 500}
    @mainView.maxValues = {0 => 300}
    @mainView.colorIsEnabled = true
    @mainView.color = NSColor.colorWithHexColorString("FFFFFF")
    
    NSTimer.scheduledTimerWithTimeInterval(300, target:self, selector:NSSelectorFromString("updateSites"), userInfo:nil, repeats:false)
    
    updateRoomView nil
  end

  ###############################################	
	# Site management
  ###############################################	

  # Add site to collection for room list
  def addSite name, site_info
    site = Site.new(name, site_info, self)
    @sites[name] = site
    
    @roomList.reloadData
  end
  
  # Remove site from collection for room list
  def removeSite site
    removed = @sites.delete(site)
    
    # TODO: close all rooms in removed
    removed.rooms.values.each do |room|
      room.leave
    end
    
    @roomList.reloadData
  end
	
  def updateSites silent = false
    @sites.each do |name, site|
      site.refreshRooms self, false, silent
    end
    
    NSTimer.scheduledTimerWithTimeInterval(180, target:self, selector:NSSelectorFromString("updateSitesSilently"), userInfo:nil, repeats:false)
  end
  
  def updateSitesSilently
    updateSites true
  end
  
  # Refresh views and join rooms as dictated by preferences
	def refreshedRooms site, options
    @roomList.reloadData
    
    # Only select all rooms on first run
    if options["select"]
    
      # Start join process for rooms you were in before loading application
      _rooms = Preferences.sharedPreferences.getRooms

      # Get the last active room, then fire the event on each room list item (to join it), then set the last active room in the defaults.
      # Firing the event updates the 'last_active_room', so this is a bit of a workaround.
      last_active_room = Preferences.sharedPreferences.getDefault(:last_active_room)
      site.rooms.values.each do |room|
        if _rooms.include?(room.id)
          @roomList.selectView room.listItemView
        end
      end

      Preferences.sharedPreferences.setDefault(last_active_room, :last_active_room)
      
      # Reload room list
      @roomList.deselectAllViews
      @roomList.reloadData

      # Select the room that was last active, if one exists
      last_active_room = Preferences.sharedPreferences.getDefault(:last_active_room)
      @last_joined_room = site.rooms[last_active_room] unless site.rooms[last_active_room].nil?
      
      # Make sure to select it if it's ever been found, since deselectAllViews gets called once for each site!
      if @last_joined_room && @last_joined_room.joined
        @roomList.selectView @last_joined_room.listItemView
        @selected = @last_joined_room.controller
      end
      
    end

    window.setTitle("#{@selected.site.title} - #{@selected.room.title}") if !@selected.nil? && site.rooms.values.size == 0
	end
  
  def rooms
    _rooms = {}
    @sites.each_value do |s|
      _rooms.merge! s.rooms
    end
    _rooms
  end
  

	def leftRoom room
    @roomList.reloadData
    if @roomList.selectedViews.include? room.listItemView
      @roomList.deselectAllViews
      @roomList.selectNextRoomView
    end
	end
	
	def selectRoomWithId selectId
    @sites.each do |name,site|
      site.rooms.each do |id,room|
        if selectId == id
          @roomList.deselectAllViews
          @roomList.selectView room.listItemView
          return
        end
      end
    end
	end
  
	###############################################	
  # Source list data methods
	###############################################	
  def children
    @sites = {} if @sites.nil?
    @sites.values
  end
	
	def childAt(index)
		children[index]
	end
  
	###############################################	
	# Source list delegate methods
	###############################################	
  
  # Store old view when deselecting
  def listView(listView, didDeselectView:view)
    return if view.is_a? RoomListSiteView
    
    @oldView = view.room.joined ? view : nil

    # Load blank view when no selection
    view = nil

    # Load blank view and set 
    window.setTitle "Briquette"
    updateRoomView view
  end

  def listView(listView, didSelectView:view)
    # Collapse site when site is selected
    if view.is_a? RoomListSiteView 
      view.site.collapsed = !view.site.collapsed
      
      @roomList.reloadData
      
      # Restore old view if site view selected
      @roomList.selectView @oldView unless @oldView.nil?      
      return
    end

    @selected.deselect unless @selected.nil?
    
    view.room.join
    @selected = view.room.controller

    # Set window title and update views appropriately
    window.setTitle "#{@selected.site.title} - #{@selected.room.title}"
    updateRoomView @selected.view

    # Join room and set room status appropriately
    @selected.select

    Preferences.sharedPreferences.setDefault @selected.room.id, :last_active_room
    @roomList.setNeedsDisplay true
  end
        
  def markCurrentRoomAsRead
    @selected.markMessagesAsRead unless @selected.nil?
  end
	
private
	
  # Swap selected room view for old view
  def updateRoomView selectedView
  
    selectedView = @blankView if selectedView.nil?
    
    # Make new view same size as existing view
    selectedView.frame = @messagesView.frame
    selectedView.setAutoresizingMask @messagesView.autoresizingMask
    
    # Replace old view with new view
    @mainView.replaceSubview @messagesView, :with => selectedView

    # Store reference to new view for when it needs to be swapped later
    @messagesView = selectedView    
	end
      
end