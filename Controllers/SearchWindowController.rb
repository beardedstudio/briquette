# SearchWindowController.rb
# briquette
#
# Created by Brett Bender on 5/19/11.
# Copyright 2011 Bearded. All rights reserved.

require 'Message'

class SearchWindowController < NSWindowController

  include TextHelper

  attr_accessor :text_field
  attr_accessor :view
  attr_accessor :search_view
  attr_accessor :term
  attr_accessor :upload_messages
  attr_accessor :starting_term
  attr_accessor :last_search_term
  attr_accessor :search_error_handled
  
  def awakeFromNib
    @search_error_handled = false
    @term = ""
    @search_view.controller = self
    @upload_messages = {}
    view_controller = NSViewController.alloc.init
    view_controller.view = @search_view

    @view.setViewController view_controller
  end
  
  def windowDidLoad
    NSNotificationCenter.defaultCenter.addObserver(self, 
                                                   :selector => NSSelectorFromString("updateSearchFieldAndSearch:"), 
                                                   :name => "NSWindowDidBecomeMainNotification",
                                                   :object => nil)    
    NSNotificationCenter.defaultCenter.addObserver(self, 
                                                   :selector => NSSelectorFromString("updateSearchFieldAndSearch:"), 
                                                   :name => "NSWindowDidBecomeKeyNotification",
                                                   :object => nil)
  end
  
  def updateSearchFieldAndSearch notification
    return if self.starting_term.nil? || self.starting_term == self.last_search_term
    self.last_search_term = starting_term
    text_field.setStringValue(starting_term.strip.gsub(/\s/, ' '))

    self.starting_term = nil
    search(self)
  end
  
  def notifications
    [@term]
  end
  
  def search sender
    @search_error_handled = false
    @search_view.clearResults
    @view.popViewController

    if !(text_field.stringValue == '' || text_field.stringValue.nil?)
      @results = {}
      @rooms = {}
      @sites = NSApplication.sharedApplication.delegate.windowController.sites
     
      fixed_term = @text_field.stringValue.dup.gsub(/[\'\"\!]/, '')#This comment to fix syntax parsing in xcode from hanging single quote in regex (derp)'
                                                
      # replace @'s with \@ since that actually searches correctly (thanks, campfire API) 
      # also uri escape, set the search field to whatever we actually sent (except the \@ fix since that looks strange
      @term = URI.escape(fixed_term.gsub('@', '\\@'))
      @text_field.setStringValue(fixed_term.dup)

      @sites.values.each{|site| Request.get("/search/#{@term}.json" , delegate:self, callback:"results_loaded:", site:site, options:{})}
    end
  end
  
  def results_loaded request  
    if request.responseStatusCode == 200
      # Parse site name out of response's url.
      match = /https:\/\/(.+)\.campfirenow/.match(request.url.absoluteString)
      
      # This should probably never happen but if it does, just ditch this search.
      return if match.nil?
      
      site_name = match[1]
      @results[site_name] = request.responseHash["messages"]
      
      @search_view.setTerm @text_field.stringValue
      renderSearchResults if @results.keys.size == @sites.size

    else
      unless @search_error_handled
        system_message = Message.new({'type' => Message::SYSTEM,
                                     'body' => "There was a problem searching, please try again.",
                                     'created_at' => Time.now.to_s,
                                     'user_id' => "null",
                                     'id' => "status-#{Time.now.to_i}"}, nil, self)      
        
        @search_view.addMessage system_message, {"is_from_join" => true}
        @search_view.ready
        @search_error_handled = true
      end
    end
  end
  
  def renderSearchResults
    @results.each do |site, messages|
      if messages && messages.size > 0
        system_message = Message.new({'type' => Message::SYSTEM,
                                     'body' => "Results on #{site} for: \"#{text_field.stringValue}\"",
                                     'created_at' => Time.now.to_s,
                                     'user_id' => "null",
                                     'id' => "status-#{Time.now.to_i}"}, nil, self)      
        
        @search_view.addMessage system_message, {"is_from_join" => true}

                                                    
        messages.each do |m| 
          if @rooms[m['room_id']].nil?
            @rooms[m['room_id']] = @sites[site].rooms[m['room_id']]
          end

          _message = Message.new(m, @rooms[m['room_id']], self)
          @search_view.addMessage(_message, {'is_from_join' => true}) unless m["type"] == Message::TIME
          @upload_messages[m['id'].to_s] = _message if m['type'] == Message::UPLOAD
        end
                                                    
      else
        @search_view.addMessage Message.new({'type' => Message::SYSTEM, 'body' => "No results on #{site} for: \"#{text_field.stringValue}\""}, nil, self), {"is_from_join" => true}
      end
                                                    
      system_message = Message.new({'type' => Message::META,
                                   'body' => "<a href='https://#{site}.campfirenow.com/search' target='_blank'>Search #{site}.campfirenow.com</a>",
                                   'created_at' => Time.now.to_s,
                                   'user_id' => "null",
                                   'id' => "status-#{Time.now.to_i}"}, nil, self)      
      @search_view.addMessage system_message, {"is_from_join" => true}
      @search_view.ready
    end
  end
  
  def updateMessage message 
    @search_view.updateMessage @upload_messages.delete(message.id)
  end
  
  def load_transcript room_id, date
    @transcript = TranscriptViewController.alloc.initWithNibName "TranscriptView", bundle:nil
    @transcript.windowController = self
    
    site = @rooms[room_id].site
    @transcript.setInfo room_id, date, @term, site

    @view.pushViewController @transcript
  end
  
  def unload_transcript
    @view.popViewController
  end
  
end
