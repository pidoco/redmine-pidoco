// TODO Licensing
/* ***** BEGIN LICENSE BLOCK *****
 * This file is part of DotClear.
 * Copyright (c) 2005 Nicolas Martin & Olivier Meunier and contributors. All
 * rights reserved.
 *
 * DotClear is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * DotClear is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with DotClear; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * ***** END LICENSE BLOCK *****
*/

/* Modified by JP LANG for textile formatting */

jsToolBar.prototype.elements.page_png = {
	type: 'button',
	title: 'Embed an image of a prototype page',
	fn: { wiki: function() { 
            new Ajax.Request('/pidoco/prototypes/' + ProjectId, {
                method: 'get', 
                onSuccess: function(transport) {
                    var jsonResponse = transport.responseJSON;
                    this.getUrlForImage(jsonResponse);
                }.bind(jsToolBar.prototype.elements.page_png),
                onFailure: function(transport) {
                  console.log("Yada yada yada!");
                }
            });
		}
	},
	getUrlForImage: function(o) {
	    try {
    	    Element.remove('pidoco_plugin_div');
	    } catch(e) {}
	    var result = "<div id='pidoco_plugin_div'" +
	    "<select name='pageId' onchange='jsToolBar.prototype.elements.page_png.insertPngLink( " +
        	    "this.options[this.selectedIndex].value, " +
        	    "this.options[this.selectedIndex].parentNode.getAttribute(\"apikey\"))'>" +
	        "<option value='0'>Choose a page...</option>";
	    var t1 = new Template('<optgroup apikey="#{key}" style="font-weight:bold;" label="#{prototype}">');
	    var t2 = new Template('<option value="#{prototype_id}/pages/#{id}">::#{name}</option>');
	    for each(var _prototype in o) {
	        if(typeof(_prototype) != 'function') {
	            try {
    	            result += t1.evaluate({prototype: _prototype[0].prototypeData.name, key: _prototype[1]});
    	        } catch(e) {console.log(e)}
    	        for(var _page in _prototype[0].pageNames) {
        	        try {
                        result += t2.evaluate({prototype_id: _prototype[0].id, id: _page, name: _prototype[0].pageNames[_page]});
    	            } catch(e) {}                
    	        }
    	        result += '</optgroup>'
            }
	    }
	    result += "</select></div>";
	    Element.insert(document.getElementsByClassName("jstEditor")[0], {before: result});
	},
	insertPngLink: function(uri_part, key) {
	    if(uri_part == null || uri_part == "") {
	        return;
	    }
	    try {
    	    Element.remove('pidoco_plugin_div');
	    } catch(e) {}
	    window.toolbar.singleTag("!http://alphasketch.com/rabbit/api/prototypes/" + uri_part + ".png?api_key=" + key + "!", " ");
	}
}
