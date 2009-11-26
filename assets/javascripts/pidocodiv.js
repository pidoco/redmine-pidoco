new Ajax.Request('/pidoco/prototypes/' + ProjectId, {
    method: 'get', 
    onSuccess: function(transport) {
        var jsonResponse = transport.responseJSON;
        var pidocoDiv = document.getElementById('pidocodiv');
        pidocoDiv.removeChild(pidocoDiv.firstChild);
        var result = "<ul>";
        for(var i=0; i<jsonResponse.length; i++) {
            var p = jsonResponse[i][0];
            var tmpl = '<li><strong>#{name}</strong>: last change on #{lastChange}, ' +
            '#{discussionCount} <a href="/pidoco/discussions/' + ProjectId + '#prot-#{name}">discussions</a>'
            var recentDiscussion = null;
            for(var j=0; j<p.discussions.length; j++) {
                disc = p.discussions[j];
                if(recentDiscussion == null || disc.timestamp > recentDiscussion.timestamp) {
                    recentDiscussion = {title: disc.title, timestamp: disc.timestamp};
                }
            }
            if(recentDiscussion != null) {
                tmpl += ', the most recent discussion is titled <a href="/pidoco/discussions/' + ProjectId + 
                '#prot-#{name}-disc-' + recentDiscussion.title +'">"' + recentDiscussion.title + '</a>"';
            }
            tmpl += '</li>';
            var t1 = new Template(tmpl);
            var d = new Date();
            d.setTime(p.prototypeData.lastModification);
            dStr = d.toLocaleDateString() + ' ' + d.toLocaleTimeString();
            result += t1.evaluate({name: p.prototypeData.name, discussionCount: p.discussions.length, lastChange: dStr});
        }
        result += '</ul>';
        Element.insert(pidocoDiv, {bottom: result});
        //pidocoDiv.appendChild(document.createTextNode(jsonResponse));
    },
    onFailure: function(transport) {
      console.log("Yada yada yada!");
    }
});