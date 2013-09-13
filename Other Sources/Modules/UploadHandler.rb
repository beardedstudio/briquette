# UploadHandler.rb
# briquette
#
# Created by Brett Bender on 1/3/11.
# Copyright 2011 Bearded. All rights reserved.

module UploadHandler
  
  # Drag and Drop upload implementation
  def draggingEntered sender
    # we support uploading files (filenamesPboardType) as a copy operation, nothing else.
    return sender.draggingPasteboard.types.containsObject(NSFilenamesPboardType) ? NSDragOperationCopy : NSDragOperationNone
  end

  def performDragOperation sender        
    filenames = sender.draggingPasteboard.propertyListForType(NSFilenamesPboardType)
    super sender and return if filenames.nil?
    
    _uploadFiles filenames
    
    return true
  end  
    
  def _uploadFiles filenames

    return if filenames.nil?

    # Use existing room instance variable if possible, otherwise get current room
    if !defined?(@room)
      @room = NSApplication.sharedApplication.delegate.windowController.selected.room
    end

    url = NSURL.URLWithString("#{@room.site.baseURL}/room/#{@room.id}/uploads.json")

    filenames.each do |absolute_file_url|
      request = ASIFormDataRequest.requestWithURL(url)
      request.username = @room.site.token
      request.password = "x"
    
      request.addFile absolute_file_url, :forKey => 'upload'
    
      request.setShouldAttemptPersistentConnection false
      request.setDelegate self
      request.setDidFinishSelector NSSelectorFromString("uploadFinished:")
      request.setDidFailSelector NSSelectorFromString("uploadFailed:")

      request.startAsynchronous
    end
    
    # Notify user we're starting an upload.
    NSApplication.sharedApplication.delegate.addStatusMessage("Uploading file"+(filenames.length > 1 ? "s" : "")+"...", toRoom:@room)
    
  end
    
  # Uploaded file successfully
  def uploadFinished request
    if request.responseStatusCode == 507
      NSApplication.sharedApplication.delegate.addStatusMessage("Could not complete upload - your Campfire account is out of storage", toRoom:@room)
    elsif request.responseStatusCode != 201
      NSLog("Error uploading file: #{request.responseStatusCode}")
      NSApplication.sharedApplication.delegate.addStatusMessage("There was an error uploading your file", toRoom:@room)
    end
  end
    
  # Uploading failed
  def uploadFailed request
    NSApplication.sharedApplication.delegate.addStatusMessage("Upload failed, please try again.", toRoom:@room)
  end
  
end
