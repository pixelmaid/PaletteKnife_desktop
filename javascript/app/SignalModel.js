//SignalModel.js
'use strict';
define(['emitter', 'app/id', 'app/Emitter', 'app/DatasetLoader'],

  function(EventEmitter, ID, Emitter,DatasetLoader) {

    var SignalModel = class extends Emitter {

      constructor() {
        super();
        this.selected = "live_input";
        this.lastAuthoringRequest = null;
        this.data={};
        this.datasetLoader = new DatasetLoader();
        this.datasetLoader.addListener("ON_DATA_LOADED",  function(id,items,data) {
                    this.onDatasetLoaded(id,items,data);
                }.bind(this));
        this.setupData();
      }

      onDatasetLoaded(id,items,data){ 
        var classType = items[0].classType;
        switch (classType) {
          case "imported":
          this.data["datasets"].items.push(items[0]); 
          break;
          case "recording":
          this.data["recordings"].items.push(items[0]); 
          break;
          case "live":
          this.data["live_input"].items.push(items[0]); 
          break;
          case "generator":
          this.data["generators"].items.push(items[0]); 
          break;
          case "brush":
          this.data["brushes"].items.push(items[0]); 
          break;
          case "drawing":
          this.data["drawings"].items.push(items[0]); 
          break;
        }

        console.log("data_loaded",items,this);
        this.trigger("ON_DATASET_READY",[id,{items:items}]);
      }

      setupData(){
        this.data = {
         
          "live_input": { items: [] },

          "generators": { items: [] },

          "brushes": { items: [] },

          "recordings": { items: [] },

          "datasets": { items: [] },

          "drawings": { items: [] }

        };
      }
    };


    return SignalModel;

  });