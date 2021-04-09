// ChroMag - Manual analysis
// 
// Script for step 7 - Version 1.0.0

//------ Parameters -------//
dtPx=4 // Width of time steps (in pixels)
//-------------------------//

title=getTitle();
if (endsWith(title,".tif")) title2=substring(title,0,lengthOf(title)-4);
else title2=title;

Stack.getPosition(channel, slice, frame);
Stack.getDimensions(width, height, channels, slices, frames);
run("Duplicate...", "duplicate slices="+slice);
rename("tmp");

run("Stack to Hyperstack...", "order=xyczt(default) channels="+channels+" slices="+frames+" frames=1 display=Composite");
run("Reslice [/]...", "output=0.300 start=Left rotate avoid"); rename("tmp_reslice");
run("Scale...", "x="+dtPx+" y=1 interpolation=None average create");
close("tmp"); close("tmp_reslice");

Stack.setActiveChannels("0011");
rename(title2+"_kymo");

