# SearchView.rb
# briquette
#
# Created by Brett Bender on 5/25/11.
# Copyright 2011 Bearded. All rights reserved.

class SearchView < RoomView
  
  attr_accessor :breadcrumbView
  attr_accessor :text_field
  attr_accessor :site
  
  def awakeFromNib
    @html_type = "search"
    @cache = ""
    @last_message = Message.new({}, nil, self)
    @last_time = nil
    setTerm nil
    
    # Load index view
    @messagesView.setShouldCloseWithWindow false
    @messagesView.UIDelegate = self
    @messagesView.frameLoadDelegate = self
    @messagesView.resourceLoadDelegate = self
    @messagesView.policyDelegate = self
    @messagesView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSBundle.mainBundle.URLForResource("index.html", withExtension:nil)))    
  end
  
  def clearResults
    @scriptobj.evaluateWebScript("$('#messages').empty()") if @scriptobj
    setTerm nil
  end
      
  def setTerm term
    @term = term
    @breadcrumbView.setCrumbs breadcrumbs
  end
  
  def breadcrumbs
    crumbs = [{:title => "Search", :callback => ""}]
    crumbs << {:title => @term, :callback => ""} if @term
    
    crumbs
  end
    
  def display_day_breaks?
    false
  end

  def transcript element
    room = element.valueForKey("room").to_i
    date = element.valueForKey "date"
    
    @controller.load_transcript room, date
  end
  
  def webView(wv, windowScriptObjectAvailable:obj)
    @scriptobj = obj
    @scriptobj.setValue(self, forKey:'myController')
    self.respondsToSelector("transcript:")
  end
  
private

  def scrollToLast
    return
  end
  
end
