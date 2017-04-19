Vue.component('markdown', {
	template: `
	<div>		
		<div :style='style'><textarea :id='markdown_id'></textarea></div>	
		<div class="modal" :class="{ 'is-active': is_upload }">
		  <div class="modal-background"></div>
		  <div class="modal-card">
		    <header class="modal-card-head">
		      <p class="modal-card-title">Modal title</p>
		      <button class="delete"></button>
		    </header>
		    <section class="modal-card-body">
		      <!-- Content ... -->
		    </section>
		    <footer class="modal-card-foot">
		      <a class="button is-success" @click="save">Save changes</a>
		      <a class="button" @click="cancel">Cancel</a>
		    </footer>
		  </div>
		</div>
	</div>
	`,
	props: ["id", "content", "style"],	
	data: function() {
		return {
			simplemde: null,
			is_upload: false,
			editor: null
		};
	},
	methods: {
		cancel: function(){
			this.is_upload = false;
		},
		save: function() {
			var cm = this.editor.codemirror;
	    var output = '';
	    var selectedText = cm.getSelection();
	    var text = selectedText || 'placeholder';

	    output = '!!' + text + '!!';
	    cm.replaceSelection(output);
	    this.is_upload = false;
		}
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
		var self = this;
		this.simplemde = new SimpleMDE({ 
			element: document.getElementById(this.markdown_id),
			toolbar: [
				'bold', 'italic',
				{
					name: "custom",
					action: function customFunction(editor){
				  	self.editor = editor;
				    self.is_upload = true;
					},
					className: "fa fa-star",
					title: "Custom Button",
				},
			],
		});
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