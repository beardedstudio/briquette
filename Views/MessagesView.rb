# MessagesView.rb
# briquette
#
# Created by Brett Bender on 1/3/11.
# Copyright 2011 Bearded. All rights reserved.

class MessagesView < WebView

  #uploadhandler does everything but registering for filetypes (in awakeFromNib).
  include UploadHandler

  def awakeFromNib
    # We register for files dragged on us (for drag and drop upload)
    self.registerForDraggedTypes([NSFilenamesPboardType])
    super
  end

end

