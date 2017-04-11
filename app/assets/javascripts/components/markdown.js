Vue.component('markdown', {
	template: "<div :style='style'><textarea :id='markdown_id'></textarea></div>",
	props: ["id", "content", "style"],	
	data: function() {
		return {
			simplemde: null
		};
	},
	methods: {
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
			_this.$emit('input', _this.simplemde.value());	// Auto assign to v-model at parent
		});
	},
	watch: {
    "content": function(new_val, old_val) {
      if(new_val != old_val){
        this.simplemde.value(new_val);
      }
    }
  }
});