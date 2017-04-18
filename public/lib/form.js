class Form {

	constructor(data) {
		this.original_data = data;

		for(var field in data){
			this[field] = data[field];
		}

		this.errors = new Errors();

	}

	data() {
		// var data = Object.assign({}, this);

		// delete data.original_data;
		// delete data.errors;

		var data = {};
		for(var property in this.original_data){
			data[property] = this[property];
		}

		return data;
	}

	reset() {
		for( var field in this.original_data ){
			this[field] = "";
		}

		this.errors.clear();
	}

	post(url) {
		return this.submit('POST', url);
	}

	put(url){
		return this.submit('PUT', url);
	}

	submit(request_type, url) {
		var _this = this;

		return new Promise(function(resolve, reject){
			axios[request_type.toLowerCase()](url, _this.data())
			.then(function(response){
				_this.onSuccess(response.data);

				resolve(response.data);	// Callback on success
			})
			.catch(function(error){
				_this.onFail(error.response.data.errors);

				reject(error.response.data); // Callback on fail
			});
		});
	}

  onSuccess(data) {
    this.reset();
  }


  /**
   * Handle a failed form submission.
   *
   * @param {object} errors
   */
  onFail(errors) {
    this.errors.record(errors);
  }
}
