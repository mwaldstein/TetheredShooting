var currentImage = "tether.jpg";

function checkImage () {
  // get some data,  convert to JSON
  dojo.xhrGet({
       url:"data/latest", 
       handleAs:"json", 
       load: function(data){
               if (data['image'] != currentImage) {
                 currentImage = data["image"];
                 dojo.byId('tetherImage').src = currentImage;
               } 
               setTimeout(checkImage, 1000);
             }  
  });
}

function uiAction () {
  dojo.xhrGet({
       url:"data/action", 
       handleAs:"json", 
       load: function(data){
             }  
  });
}
 
//dojo.addOnLoad(checkImage);
dojo.addOnLoad(function(){
  setTimeout(checkImage, 1000);
  dojo.connect(dojo.byId('tetherImage'), 'onclick', null, uiAction);
  });
