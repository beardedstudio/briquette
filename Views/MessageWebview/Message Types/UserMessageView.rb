# UserMessageView.rb
# scoutmaster
#
# Created by Brett Bender on 11/30/10.
# Copyright 2010 Bearded. All rights reserved.

class UserMessageView < AbstractMessageView
  def user_message?
    true
  end
  
  def postContent type = "room"
    # Enable star support
    # "<div class='star' data-message=\"#{@message.id}\" data-starred=\"#{@message.starred}\""></div>" 
    if type == "room"
      "<div class='reply' data-room=\"#{@message.room.title}\" data-user=\"#{@message.user.name}\"></div>" 
    elsif type == "search"
      "<div class='transcript' data-room=\"#{@message.room.id}\" data-date=\"#{@message.created_at}\"></div>" 
    else
      ""
    end
  end
  
  def classes
    "user-message " + super 
  end
end

class TextMessageView < UserMessageView
end

PASTE_TEASER_LENGTH = 6

class PasteMessageView < UserMessageView
  def body
    lines = @message.body.split("<br>")

    top = lines[0..PASTE_TEASER_LENGTH].join("<br>")
    bottom = lines[PASTE_TEASER_LENGTH+1..lines.length].join("<br>") if PASTE_TEASER_LENGTH+1 < lines.length
    
    _body = "<div class='paste-top'><pre>#{top}</pre></div>"
    unless bottom.nil?
      _body += "<div class='paste-bottom'><pre>#{bottom}</pre></div>"
    end

    _body += "<div class='paste-links'>"
      _body += "<a class='show-all-paste' href='#'>Show #{lines.length-(PASTE_TEASER_LENGTH+1)} more lines</a>" unless bottom.nil?
      _body += "<a href='https://#{@message.room.site.title}.campfirenow.com/room/#{@message.room.id}/paste/#{@message.id}' target='_blank'>View on Campfire</a>"
    _body += "</div>"
    _body
    
  end
  
  def classes
    "paste " + super
  end
end

class TweetMessageView < UserMessageView

  include TextHelper

  def body
    tweet_hash = {}
    body = @message.body

    # Parse response if message received via the stream
    if body[0,3] == "---"
      tweet = body.split("\n")
      tweet = tweet[1,tweet.length]
      
      tweet.each do |part|
        match = part.match(/:([a-z_]+): (.*)/)
        tweet_hash[match[1]] = match[2]
      end
      
    # Parse response if received via recent message
    else
      matches = body.match(/^(.*) -- @([A-Za-z0-9]*), http[s]?:\/\/twitter.com\/(.*)\/status\/([0-9]*)$/)

      # If no matches, Twitter message could not load its content; use message body
      if matches.nil?
        @body = html_replace CGI::escapeHTML(body)
        tweet_hash = nil
        
      # Construct tweet data hash from regex matches (use default avatar)
      else
        tweet_hash["message"] = matches[1] 
        tweet_hash["author_username"] = matches[2]
        tweet_hash["id"] = matches[4]
      end
    end
    
    # Build view HTML from tweet hash
    if tweet_hash
      tweet_hash["author_avatar_url"] = "http://img.tweetimag.es/i/#{tweet_hash['author_username']}_n"
      content = html_replace CGI::escapeHTML(tweet_hash['message'])
      @body = "<div class='tweet-wrap'>
              <div class='tweet-avatar'>
                <img src='#{tweet_hash['author_avatar_url']}'>
              </div>
              <div class='tweet-content'>
                #{content}
                <div class='tweet-info'>
                  @#{tweet_hash['author_username']} via <a href='http://twitter.com/#{tweet_hash['author_username']}/status/#{tweet_hash['id']}' target='_blank'>Twitter</a>
                </div>
              </div>
              </div>"
    end

    @body
  end
  
  
  def classes
    "tweet " + super
  end
end

class UploadMessageView < UserMessageView

  def body
    if @message.upload
      file_url = URI.escape(@message.upload.url)
      _body = "Uploaded a file: <a href='#{file_url}' target='_blank'>#{@message.upload.name}</a>"
      
      if @message.upload.mime_type =~ /image/
        # Load thumbnails instead of full files  
        thumbnail_url = file_url.sub("/uploads/", "/thumb/")

        _body += "<div class='image'><a href='#{file_url}', target='_blank'><img src='#{thumbnail_url}'/></a></div>"
      end
    else
      if @message.waitingOnUpload
        _body = "Loading \"#{@message.body}\""
      else
        _body = "Upload not found or deleted"
      end
    end
    _body
  end
  
  def classes
    "upload " + super
  end

end

class SoundMessageView < UserMessageView

  def body
    _body = "<div class='sound-name'>#{@message.body}</div>"
    _body += case @message.body
      when "rimshot"
        "plays a rimshot "
      when "trombone"
        "plays a sad trombone"
      when "crickets"
        "hears crickets chirping"
      when "vuvuzela"
        "======<() ~ ♪ ~♫"
      when "live"
        "is DOING IT LIVE"
      when "tmyk"
        "<img src='stars.png'>The More You Know<img src='stars.png'>"
      when "drama"
        "<img src='drama.jpeg'>"
      when "pushit"
        "<img height=16 src='pushit.png'>"
      when "greatjob"
        "<img src='greatjob.png'>"
      else @message.body
      end
  
    _body
  end
  
  def classes
    "sound " + super
  end
end
