# DebugLog.rb
# briquette
#
# Created by Dominic Dagradi on 3/8/11.
# Copyright 2011 Bearded. All rights reserved.

class Debug

  def self.log s
    unless ENV.inspect.to_s.index("Debug").nil?
      NSLog(s)
    end
  end
  
end
