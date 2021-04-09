// ChroMag - Manual analysis
// 
// Script for step 7 - Version 1.0.0

//------ Parameters -------//
rectSize=15;
//-------------------------//

title=getTitle();
if (endsWith(title,".tif")) title2=substring(title,0,lengthOf(title)-4);
else title2=title;

Stack.getPosition(channel, slice, frame);
Stack.getDimensions(width, height, channels, slices, frames);

run("Duplicate...", "title=tmp duplicate");
run("Split Channels");
run("Duplicate...", "title=C5-tmp duplicate");
run("Multiply...", "value=0.000 stack");
run("Red");
setMinAndMax(0, 1);
run("Merge Channels...", "c1=C1-tmp c2=C2-tmp c3=C3-tmp c4=C4-tmp c5=C5-tmp create");

Stack.setSlice(slice); Stack.setChannel(5);
setPixel(width/2,height/2,1);
makeRectangle(width/2-(rectSize-1)/2, height/2-(rectSize-1)/2, rectSize, rectSize);
Stack.setActiveChannels("00011");
rename(title2+"_mRegCh");

