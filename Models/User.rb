# User.rb
# briquette
#
# Created by Dominic Dagradi on 11/3/10.
# Copyright 2010 Bearded. All rights reserved.

class User
	attr_accessor :id
	attr_accessor :name
	attr_accessor :short_name
  
  # Create class instance variable to store users
  class << self; attr_reader :users; end
  @users = {}

	def initialize(id, info = {})
    @id = id
    User.users[id] = self
    
    @name = info["name"]
    names = info["name"].split(/\s/)
    if names.size > 1
      # Get first letters of each name after their first name, join w/spaces
      initials = names[1..names.size].map{ |part| "#{part[0]}." }.join(' ')
      @short_name = "#{names.first} #{initials}"
    else
      @short_name = names.first
    end
    # Load user info from remote
	end

  ###############################################	
  # Class methods
  ###############################################  
  def self.find(id, info = nil, options = {})
    return nil if id.nil? || id.to_s.empty?
    # Get user from class collection, or create new user if not present
    u = self.users[id]

    if u.nil?
      info = User.show(id, options) if info.nil?
      u = self.new(id, info)
    end
    
    return u
  end
  
  def self.load(id, options)
    options["receiver"] ||= self
    options["callback"] ||= "loaded:"

    User.show id, options
  end
  
  def self.loaded request
    self.find request.responseHash["user"]["id"], request.responseHash["user"]
  end

private

	def self.show(id,  opts = {})
    return '' if id.nil?
    opts["receiver"] ||= nil
    opts["callback"] ||= "requestFinished:"
    opts["site"] ||= nil

    request = Request.get("/users/#{id}.json", delegate:opts["receiver"], callback:opts["callback"], site:opts["site"], options:{})

    if opts["receiver"].nil?
      request.responseHash["user"]    
    end
  end

end