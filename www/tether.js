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

function windowChange () {
  var image = dojo.byId('tetherImage');

  var scale;

  var newHeight;
  var newWidth;

  // first try scaling to fit the height
  scale = screen.height / image.height;

  newWidth = scale * image.width;

  // too big, scale to width
  if (newWidth > screen.width) {
    scale = screen.width / image.width;
  }

  newWidth = scale * image.width;
  newHeight = scale * image.height;
  
  image.style.width = newWidth + "px";
  image.style.height = newHeight + "px";
}

// Detect whether device supports orientationchange event, otherwise fall back to
// the resize event.
var supportsOrientationChange = "onorientationchange" in window,
    orientationEvent = supportsOrientationChange ? "orientationchange" : "resize";

//window.addEventListener(orientationEvent, function() {
//    alert('HOLY ROTATING SCREENS BATMAN:' + window.orientation + " " + screen.width);
//}, false);
dojo.connect(window, orientationEvent, null, windowChange)
 
//dojo.addOnLoad(checkImage);
dojo.addOnLoad(function(){
  setTimeout(checkImage, 1000);
  dojo.connect(dojo.byId('tetherImage'), 'onclick', null, uiAction);
  });
