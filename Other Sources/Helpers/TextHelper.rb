# TextHelper.rb
# briquette
#
# Created by Dominic Dagradi on 12/22/10.
# Copyright 2010 Bearded. All rights reserved.

module TextHelper

  def html_replace string
    replace_smart_quotes(string)
    string = replace_links(string)
    string = replace_linebreaks(string)
    string = replace_images(string)
    string = embed_youtube(string)
    string
  end
      
  def strip_html string
    string.gsub(/<(.|\n)*?>/, "")
  end
  
  def replace_smart_quotes string
    string.gsub! "\\xE2\\x80\\x9C", '"'
    string.gsub! "\\xE2\\x80\\x9D", '"'
    string.gsub! "\\xE2\\x80\\x99", "'"
  end
  
  def replace_linebreaks string
    string.rstrip.gsub(/[\n\r]/, "<br>")
  end
  
  def replace_links string
    string.gsub!("&quot;", '"')
    urls = URI.extract(string, ["http", "https"])
        
    urls.each do |url|
      unless url.empty? 
        replace = url.dup
        if (replace[replace.length-1] == ")")
          replace.slice!(replace.length-1) if (replace.count(")") > replace.count("("))
        end

        # Add http to URL to properly open browser if not present
        external_url = replace
        external_url.gsub!('"', "%22")
        
        short_url = replace
        short_url.length > 50 ? short_url = short_url[0..49]+"..." : short_url

        # Replace url text with HTML-formatted url string
        replace = Regexp.escape(replace)
        string.gsub! /#{replace}/ do |sub|
          "<a href=\"#{external_url}\" target=\"_blank\" title=\"#{external_url}\">#{short_url}</a>"
        end
      end
    end
    
    string
  end
  
  def replace_images string
    matches = string.scan(/<a[^>]*?href="(.*?(?:gif|jpeg|jpg|png))".*?<\/a>/)
    
    matches.each do |match| 
      match = match[0]
      string += '<div class="image"><a href="'+match+'" target="_blank"><img src="'+match+'"></a></div>'
    end
    
    string 
  end
  
  def embed_youtube string
    matches = string.scan(/youtube.com\/watch\?v=([a-zA-Z0-9_]*)/).map{|m| m[0]}.uniq
        
    matches.each do  |match|
      string += "<p><a target='_blank' href='http://youtube.com/watch?v=#{match}'><img src='http://img.youtube.com/vi/#{match}/0.jpg'></a></p>"
    end
    string
  end
  
  def dehumanize(string)
    string.to_s.downcase.gsub(/ +/,'_').gsub(/\//,'_')
  end
  
  def getUploadUrl message
    "/room/#{message.room.id}/messages/#{message.id}/upload.json"
  end
  
  #####################
  # Javacsript escape
  #####################
  JS_ESCAPE_MAP	=	{ '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'"}
  
  def escape_javascript(javascript)
    if javascript
      javascript.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { JS_ESCAPE_MAP[$1] }
    else
      ''
    end
  end
end