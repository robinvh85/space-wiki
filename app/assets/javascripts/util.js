var util = {
	renderScriptMarkdown: function(callback){
		setTimeout(function(){
			document.querySelectorAll("pre code").forEach(function(item){ 
				hljs.highlightBlock(item); 
			});

			if(typeof(callback) == 'function'){
				callback();
			}
		}, 50);
	}
};