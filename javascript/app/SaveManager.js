//Save Manager
"use strict";
define(["app/Emitter"],

	function(Emitter) {

		var saved_params, s3, bucket;


		var SaveManager = class extends Emitter {
			constructor() {
				super();
				this.saved_files = {};
				this.backup_files = {};
				this.currentFile = null;
				this.currentName = "my_project";
			}


			save(filename) {
				this.currentname = filename;
				var data = {
					type: "save_request",
					filename: filename

				};
				this.emitter.emit("ON_SAVE_EVENT", data);

			}

			loadRequest(filename) {
				var data = {
					type: "load_request",
					filename: filename

				};
				this.emitter.emit("ON_SAVE_EVENT", data);

			}

			loadSavedFile(fileval) {
				var filename = this.saved_files[fileval];
				this.currentFile = fileval;
				this.currentName = filename;
				this.loadRequest(filename);
			}

			updateFileList(storage_data) {
				this.saved_files = storage_data.filelist;

				this.trigger("ON_SAVED_FILES_UPDATED");
			}

			savedFileExists(filename) {
				for (var key in this.saved_files) {
					if (this.saved_files.hasOwnProperty(key)) {
						var name = this.saved_files[key];
						if (name == filename) {
							return true;
						}
					}
				}
				return false;
			}

			loadStorageData(data) {
				console.log("load storage data called", data);
				var storage_data = data.data;
				var filelist = storage_data.filelist;
				var type = storage_data.type;
				if (type == "save") {
					console.log("type = save");
					this.currentFile = storage_data.filename;
					this.currentName = this.currentFile.split("/")[1];
					this.updateFileList(storage_data);
				} else if (type == "backup") {
					this.backup_files = filelist;
				} else if (type == "filelist") {
					this.updateFileList(storage_data);
				}
			}



		};
		return SaveManager;



	});