var util = {
	renderScriptMarkdown: function(){
		setTimeout(function(){
			document.querySelectorAll("pre code").forEach(function(item){ 
				hljs.highlightBlock(item); 
			});
		}, 50);
	}
};