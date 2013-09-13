/*
 * jQuery replaceText - v1.1 - 11/21/2009
 * http://benalman.com/projects/jquery-replacetext-plugin/
 * 
 * Copyright (c) 2009 "Cowboy" Ben Alman
 * Dual licensed under the MIT and GPL licenses.
 * http://benalman.com/about/license/
 */


(function($){
 '$:nomunge'; // Used by YUI compressor.
 
 // Method: jQuery.fn.replaceText
 // 
 // Replace text in specified elements. Note that only text content will be
 // modified, leaving all tags and attributes untouched. The new text can be
 // either text or HTML.
 // 
 // Uses the String prototype replace method, full documentation on that method
 // can be found here: 
 // 
 // https://developer.mozilla.org/En/Core_JavaScript_1.5_Reference/Objects/String/Replace
 // 
 // Usage:
 // 
 // > jQuery('selector').replaceText( search, replace [, text_only ] );
 // 
 // Arguments:
 // 
 //  search - (RegExp|String) A RegExp object or substring to be replaced.
 //    Because the String prototype replace method is used internally, this
 //    argument should be specified accordingly.
 //  replace - (String|Function) The String that replaces the substring received
 //    from the search argument, or a function to be invoked to create the new
 //    substring. Because the String prototype replace method is used internally,
 //    this argument should be specified accordingly.
 //  text_only - (Boolean) If true, any HTML will be rendered as text. Defaults
 //    to false.
 // 
 // Returns:
 // 
 //  (jQuery) The initial jQuery collection of elements.
 
 $.fn.replaceText = function( search, replace, text_only ) {
 return this.each(function(){
                  var node = this.firstChild,
                  val,
                  new_val,
                  
                  // Elements to be removed at the end.
                  remove = [];
                  
                  // Only continue if firstChild exists.
                  if ( node ) {
                  
                  // Loop over all childNodes.
                  do {
                  
                  // Only process text nodes.
                  if ( node.nodeType === 3 ) {
                  
                  // The original node value.
                  val = node.nodeValue;
                  
                  // Added by Dominic on 9/7/11. Escape HTML in text nodes before matching/replacing
                  val = $("<div />").text(val).html()
                  
                  // The new value.
                  new_val = val.replace( search, replace );
                  
                  // Only replace text if the new value is actually different!
                  if ( new_val !== val ) {
                  
                  if ( !text_only && /</.test( new_val ) ) {
                  // The new value contains HTML, set it in a slower but far more
                  // robust way.
                  $(node).before( new_val );
                  
                  // Don't remove the node yet, or the loop will lose its place.
                  remove.push( node );
                  } else {
                  // The new value contains no HTML, so it can be set in this
                  // very fast, simple way.
                  node.nodeValue = new_val;
                  }
                  }
                  }
                  
                  } while ( node = node.nextSibling );
                  }
                  
                  // Time to remove those elements!
                  remove.length && $(remove).remove();
                  });
 };  
 
 })(jQuery);

////////////////////////////////////////////
// Add/Remove Mentions
////////////////////////////////////////////
function addMention(mention) {
  var add = new RegExp("\\b(" + mention + ")\\b", 'ig');
  $(".message").not(".system").each(function() {
    $(this).find(".content *:not(span)").not(".tweet-info").replaceText(add, "<span class='mention'>$1</span>");
    var spans = $(this).find("span.mention");
                                    
    if (spans.size() > 0 && !$(this).hasClass("mine")) {
      $(this).addClass("mentioned");
    }
  });
}

function removeMention(mention) {
  $("span.mention").each(function() {
    if ($(this).text().toLowerCase() == mention.toLowerCase()) {
      var message = $(this).parents(".message");
      $(this).replaceWith($(this).text());
                         
      var spans = message.find("span.mention");
      if (spans.size() < 1) {
        message.removeClass("mentioned");
      }
    }
  })
}