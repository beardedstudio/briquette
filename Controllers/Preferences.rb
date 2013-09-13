# Preferences.rb
# briquette
#
# Created by Dominic Dagradi on 1/22/11.
# Copyright 2011 Bearded. All rights reserved.

class Preferences

  @@preferences = nil

  ####################################
  # Default accessors object
  ####################################  
  def getDefault key
    NSUserDefaults.standardUserDefaults.objectForKey(key)
  end
  
  def setDefault value, key
    NSUserDefaults.standardUserDefaults.setObject(value, :forKey => key)
    NSUserDefaults.standardUserDefaults.synchronize
  end
  
  def setDefaultIfNil value, key
    stored = NSUserDefaults.standardUserDefaults.objectForKey(key)

    if stored.nil?
      NSUserDefaults.standardUserDefaults.setObject(value, :forKey => key)
      NSUserDefaults.standardUserDefaults.synchronize
    end
  end

  ####################################
  # App management
  ####################################
  def firstLaunch?
    getSites.empty?
  end

  ####################################
  # Site management
  ####################################

  # Set new API token for a site
  def addSite name, site 
    sites = getSites
    
    new_sites = {}
    new_sites.merge!(sites)
    new_sites[name] = site
    
    setDefault new_sites, :sites
  end
  
  def removeSite site
    sites = getSites

    new_sites = {}
    new_sites.merge!(sites)
    new_sites.delete site
    
    setDefault new_sites, :sites
  end
  
  # Get dictionary from defaults, and set empty if none exists
  def getSites
    sites = getDefault :sites
    
    if sites.nil?
      sites = {}
      setDefault sites, :sites
    end
    
    sites
  end
  
  ####################################
  # Room management
  ####################################
  def joinedRoom room
    rooms = getRooms
    
    new_rooms = [] + rooms
    unless new_rooms.include? room
      new_rooms << room
      setDefault new_rooms, :rooms
    end
  end
  
  def leftRoom room
    rooms = getRooms

    new_rooms = [] + rooms
    new_rooms.delete room
    
    setDefault new_rooms, :rooms
  end
  
  def getRooms
    rooms = getDefault :rooms

    if rooms.nil?
      rooms = []
      setDefault rooms, :rooms
    end
    
    rooms
  end
  
  ####################################
  # Shared preferences object
  ####################################
  
  def self.sharedPreferences
    if @@preferences.nil?
      @@preferences = Preferences.new
    end
    
    @@preferences
  end

end