var app_test = new Vue({
	el: '#test',
	data: {
	},
	methods: {
		submit: function(){
			 var data = new FormData();
        data.append('image', document.getElementById('image').files[0]);
        data.append('topic_id', 1);

        var config = { headers: { 'Content-Type': 'multipart/form-data' } };        
        axios.post('/galleries', data, config)
          .then(function (res) {
            console.log("OK", res);
          })
          .catch(function (err) {
            console.log("ERROR", res);
          });
		}		
	},

	created: function() {
		console.log("created");
	},
	mounted: function() {
		console.log("mounted");
	}
});
