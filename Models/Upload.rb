# Upload.rb
# briquette
#
# Created by Brett Bender on 12/31/10.
# Copyright 2010 Bearded. All rights reserved.

class Upload 
  attr_accessor :id
  attr_accessor :name
  attr_accessor :url
  attr_accessor :size
  attr_accessor :mime_type
  attr_accessor :room_id
  attr_accessor :user_id
  
  attr_accessor :message

  def initialize(upload_hash, message)
    upload_hash = upload_hash.fetch('upload'){ {} }
    
    @id =         upload_hash['id']
    @name =       upload_hash['name']
    @url =        upload_hash['full_url']
    @size =       upload_hash['byte_size']
    @mime_type =  upload_hash['content_type']
    @room_id =    upload_hash['room_id']
    @user_id =    upload_hash['user_id']
    
    @message = message
  end
end
