#
#  Transcript.rb
#  briquette
#
#  Created by Dominic Dagradi on 7/31/11.
#  Copyright 2011 Bearded. All rights reserved.
#

class Transcript
  
  attr_accessor :room
  attr_accessor :date
  attr_accessor :site
  attr_accessor :controller
  
  def initialize _room, _date, sender
    @room = _room
    @date = Time.parse _date
    @controller = sender
  end
  
  def loadTranscript
    # get transcript from campfire
    url = "/room/#{@room.id}/transcript/#{@date.year}/#{@date.month}/#{@date.day}.json"
    request = Request.get(url, delegate:self, callback:"transcriptLoaded:", site:@room.site, options:{})
  end
  
  def transcriptLoaded request
    @controller.transcriptLoaded request.responseHash["messages"]
  end
  
end