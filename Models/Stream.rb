# Stream.rb
# briquette
#
# Created by Dominic Dagradi on 10/26/10.
# Copyright 2010 Bearded. All rights reserved.
#
# Modified from Twitter Stream example
# http://blancer.com/tutorials/i-phone/36653/diving-into-the-twitter-stream/

class Stream
  attr_accessor :connection
  attr_accessor :partial_streaming_data 
  
  def initialize(room)
    @room = room
    @closed = false
    @partial_streaming_data = ""
  end
  
  def start
    return if @closed
    
    request = NSMutableURLRequest.alloc().initWithURL(NSURL.URLWithString("https://streaming.campfirenow.com/room/#{@room.id}/live.json"))
    
    # Base64 Encode authorization string
    authorization = "Basic " + ["#{@room.site.token}:x"].pack('m').gsub("\n","")
    request.addValue(authorization, forHTTPHeaderField:"Authorization");    

    @connection = NSURLConnection.alloc().initWithRequest(request, delegate:self, startImmediately:true)
  end
  
  def close
    @closed = true
    @connection.cancel if @connection
  end

  def rejoin
    close
    @room.rejoin
  end  
  
  ########################################
  # NSURLConnection delegate methods
  ########################################
  def connection(connection, didReceiveData:data)   
    dataString = NSString.alloc.initWithData(data, encoding:NSUTF8StringEncoding)
    if dataString.strip.empty?
      dataString = nil
      return
    end
    
    messages = dataString.split "\r"
    
    # When big messages are received, we only get part of the entire JSON string 
    # So Crack::JSON.parse throws Crack::ParseError.  In this case,
    # Store that chunk we received (in @partial_streaming_data)
    # And on the next message, concatenate it with whatever we receive 
    # to see if we have the whole json string.
    # As soon as parsing works, reset the @partial streaming data to its original state.
    messages.each do |m|
      m = "#{@partial_streaming_data}#{m}" if @partial_streaming_data != ""
      m = m.force_encoding("UTF-8").encode("UTF-8", {:invalid => :replace, :undef => :replace})

      # Create a new pointer to pass to YALJ by reference
      error = Pointer.new(:object)
      parsed = CustomParser.parse(m, withError:error)
      
      # Check that messages come back complete, as YAJL will truncate and return without error
      # if it can find any JSON-like attributes at the beginning of the string
      message_valid = parsed["id"] != nil and parsed["body"] != nil
      
      if error[0].nil? and message_valid
        @partial_streaming_data = ""
        @room.messageReceived(parsed) 
      else
        @partial_streaming_data = m
      end
    end
  end
  
  def connection(connection, didReceiveResponse:response)    
    # If the stream was not successful, it's because we weren't in the room: try again
    response.statusCode != 200 ? rejoin : @room.streamStarted(self)
  end
  
  # The stream failed because of the connection closing (because of lack of internet connection, etc)
  def connection(connection, didFailWithError:error)
    @room.streamFailed
    rejoin
  end
  
  def connectionDidFinishLoading connection
    rejoin
  end
  
  ########################################
  # Authentication challenge - allow untrusted certs
  # from http://stackoverflow.com/questions/933331/how-to-use-nsurlconnection-to-connect-with-ssl-for-an-untrusted-cert/2033823#2033823
  ########################################
  def connection(connection, canAuthenticateAgainstProtectionSpace:protectionSpace)
    true
  end

  def connection(connection, didReceiveAuthenticationChallenge:challenge)
    if challenge.protectionSpace.authenticationMethod.isEqualToString(NSURLAuthenticationMethodServerTrust)
      challenge.sender.useCredential(StreamHelper.credentialForChallenge(challenge), forAuthenticationChallenge:challenge)
    end

    challenge.sender.continueWithoutCredentialForAuthenticationChallenge(challenge)
  end
    
end