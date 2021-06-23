# playback-controller-vlc-extension
a mish mosh of the time  and moment extension, plus more!  

![gui](https://github.com/nima64/playback-controller-vlc-extension/blob/main/Screenshot%20from%202021-06-23%2012-51-44.png)
## Installion
The extension can be installed in either  
~/.local/share/vlc/lua/extensions/  
OR  
/usr/lib/x86_64-linux-gnu/vlc/lua/extensions/  
## About the saved data and it's schema  
All saved data is stored under **vlc.config.userdatadir** which evaluates to the path ~/.local/share/ in ubuntu.  
The schema is copied from the moment time plugin, looking back I should've used json to avoid the hassle of parsing and all the validating that comes with it.  

About the schema, each record has two parts the header which contains the information, such as the title and filename, and the body which contains all the momented/marked times.  
Moments are seperated by *&, and each moment contains scene,slate,and clap, which are formated as such ex: slate:2/. The actual time of the moment is seperated by ~.  

See the example below which shows the record for Big Buck Bunny.
![record](https://github.com/nima64/playback-controller-vlc-extension/blob/main/Screenshot%20from%202021-06-23%2012-53-56.png)
