Vue.component('markdown', {
	template: "<div :style='style'><textarea :id='markdown_id'></textarea></div>",
	props: ["id", "content", "style"],	
	data: function() {
		return {
			simplemde: null
		};
	},
	methods: {
		// save: function() {
		// 	alert(this.simplemde.value());
		// 	this.$emit('save', this.simplemde.value());
		// }
	},
	computed: {
    markdown_id: {
      get: function () {
        if(this.id){
          return this.id;
        } else {
          return "markdown";
        }
      }
    }
  },
	mounted: function() {
		this.simplemde = new SimpleMDE({ element: document.getElementById(this.markdown_id) });
		this.simplemde.value(this.content);

		var _this = this;
		this.simplemde.codemirror.on("blur", function(){
			_this.$emit('change', _this.simplemde.value());
		});
	},
	watch: {
    "content": function(new_val, old_val) {
    	console.log(new_val);

      if(new_val != old_val){
        this.simplemde.value(new_val);
      }
    }
  }
});