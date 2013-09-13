#
#  TranscriptViewController.rb
#  briquette
#
#  Created by Dominic Dagradi on 7/31/11.
#  Copyright 2011 Bearded. All rights reserved.
#

require 'Message'

class TranscriptViewController < NSViewController
  
  attr_accessor :transcript
  attr_accessor :room
  attr_accessor :windowController
  attr_accessor :term
  attr_accessor :upload_messages
  
  def awakeFromNib
    view.controller = self
  end
  
  def setInfo room_id, date, term, site    
    @room = site.rooms[room_id]
    @date = date
    @transcript = Transcript.new(@room, date, self);
    @term = term
    
    @transcript.loadTranscript
    view.setTerm @term, "#{@room.title} - #{Date.parse(date).strftime('%b %d, %Y')}"
  end
  
  def notifications
    [@term]
  end
  
  def transcriptLoaded messages
    @upload_messages ||= {}

    transcript_url = "https://#{transcript.room.site.title}.campfirenow.com/room/#{transcript.room.id}/transcript/#{transcript.date.year}/#{transcript.date.month}/#{transcript.date.day}"
    transcript_link = Message.new({'type' => Message::META,
                                 'body' => "<a href='#{transcript_url}' target='_blank'>View transcript on Campfire</a>",
                                 'created_at' => Date.parse(@date).to_s,
                                 'user_id' => "null",
                                 'id' => "status-#{Time.now.to_i}"}, nil, self)   

    view.addMessage transcript_link, {"is_from_join" => true}
    messages.each do |m|
      _message = Message.new(m, @room, self)
      view.addMessage(_message, {"is_from_join" => true}) unless m["type"] == Message::TIME
      @upload_messages[_message.id.to_s] = _message
    end
    transcript_link.classes = "last"
    view.addMessage transcript_link, {"is_from_join" => true}
    view.ready
  end
  
  def leaveTranscript sender
    @windowController.unload_transcript
  end
  
  def updateMessage message
    view.updateMessage @upload_messages.delete(message.id)    
  end
end