Vue.component('markdown', {
	template: `
	<div>		
		<div :style='style'><textarea :id='markdown_id'></textarea></div>	
		<div class="modal" :class="{ 'is-active': is_upload }">
		  <div class="modal-background"></div>
		  <div class="modal-card">
		    <header class="modal-card-head">
		      <p class="modal-card-title">Select Image</p>
		      <button class="delete" @click="cancel"></button>
		    </header>
		    <section class="modal-card-body">
					<div>
				    <input id='gallery_image' type="file" />
				  	<button @click="uploadImage">Upload</button>				  		
				  </div>
				  <div style="margin-top:10px;">
				  	<img v-for="image in image_list" :src="image.thump_url" style="padding: 10px;"/>
				  </div>
		    </section>
		    <footer class="modal-card-foot">
		      <a class="button is-success" @click="choose">Choose</a>
		      <a class="button" @click="cancel">Cancel</a>
		    </footer>
		  </div>
		</div>
	</div>
	`,
	props: ["id", "content", "style", "topic_id"],	
	data: function() {
		return {
			simplemde: null,
			is_upload: false,
			editor: null,
			image_list: []
		};
	},
	methods: {
		cancel: function(){
			this.is_upload = false;
		},
		choose: function() {
			var cm = this.editor.codemirror;
	    var output = '';
	    var selectedText = cm.getSelection();
	    var text = selectedText || 'placeholder';

	    output = "![](" + this.image_list[0].image_url + ")";
	    cm.replaceSelection(output);
	    this.is_upload = false;
		},
		uploadImage: function() {
			var self = this;

			var files = document.getElementById('gallery_image').files;

			if(files.length > 0){
				var data = new FormData();
	      data.append('image', files[0]);
	      data.append('topic_id', this.topic_id);

	      var config = { headers: { 'Content-Type': 'multipart/form-data' } };        
	      axios.post('/galleries', data, config)
	        .then(function (res) {
	          console.log("OK", res);
	          self.getImageList();
	          document.getElementById('gallery_image').value = "";
	        })
	        .catch(function (err) {
	          console.log("ERROR", res);
	        });
      }
		},
		getImageList: function() {
			var self = this;
			axios.get('/galleries/list/' + this.topic_id)
        .then(function (res) {
          self.image_list = res.data;
          // console.log(res.data);
        })
        .catch(function (err) {
          console.log("ERROR", res);
        });
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
				    self.getImageList();
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