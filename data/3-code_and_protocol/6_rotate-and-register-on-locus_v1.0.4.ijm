// ChroMag - Manual analysis
// 
// Script for step 6 - Version 1.0.4

//------ Parameters -------//
ROI_size_for_registration = 100;
useVirtualStacks=false; // Use if RAM is limiting
//-------------------------//

title=getTitle();
if (endsWith(title,".tif")) title2=substring(title,0,lengthOf(title)-4);
else title2=title;
if (endsWith(title2,"_Fxyz")) title3=substring(title2,0,lengthOf(title2)-5);
else title3=title2;

// Look for max value in channel 3
Stack.setChannel(3); //Stack.setFrame(1);
Stack.getDimensions(width, height, channels, slices, frames);
maxZ=0; maxVal=0;
for (i=1; i<=slices; i++) {
    Stack.setSlice(i);
    getRawStatistics(nPixels, mean, min, max);
	if (max>maxVal) { maxZ=i; maxVal=max; }
}
Stack.setSlice(maxZ);
getRawStatistics(nPixels, mean, min, max);

run("Find Maxima...", "noise="+max+" output=[Point Selection]");
getSelectionBounds(x, y, w, h);
Stack.setChannel(5); Fx=getPixel(x,y);
Stack.setChannel(6); Fy=getPixel(x,y);
Stack.setChannel(7); Fz=getPixel(x,y);
Stack.setChannel(3);
run("Select None");
print("Force at locus (pN):\n  Fx="+Fx+", Fy="+Fy+", Fz="+Fz);

F_angle=-atan(Fx/Fy)*180/PI + 180*(Fy>0);
print("Angle of force: "+F_angle+" °");
run("Rotate... ", "enlarge angle="+F_angle+" grid=1 interpolation=Bilinear");
rename("rotated");

//-------------

run("Split Channels");

selectWindow("C5-rotated");
run("Duplicate...", "title=C5-rotated_cos duplicate");
run("Multiply...", "value="+(cos(F_angle*PI/180))+" stack");
selectWindow("C6-rotated");
run("Duplicate...", "title=C6-rotated_sin duplicate");
run("Multiply...", "value="+(sin(F_angle*PI/180))+" stack");
imageCalculator("Add create 32-bit stack", "C5-rotated_cos","C6-rotated_sin"); rename("C5"); setMinAndMax(-100, 100);

selectWindow("C5-rotated");
run("Duplicate...", "title=C5-rotated_-sin duplicate");
run("Multiply...", "value="+(-sin(F_angle*PI/180))+" stack");
selectWindow("C6-rotated");
run("Duplicate...", "title=C6-rotated_cos duplicate");
run("Multiply...", "value="+(cos(F_angle*PI/180))+" stack");
imageCalculator("Add create 32-bit stack", "C5-rotated_-sin","C6-rotated_cos"); rename("C6"); setMinAndMax(-100, 100);

close("C6-rotated_cos"); close("C5-rotated_-sin"); close("C6-rotated_sin"); close("C5-rotated_cos"); close("C5-rotated"); close("C6-rotated");
run("Merge Channels...", "c1=C1-rotated c2=C2-rotated c3=C3-rotated c4=C4-rotated c5=C5 c6=C6 c7=C7-rotated create");

//-------------

run("Duplicate...", "duplicate channels=1-4");
rename(title3+"_rot");

selectWindow("rotated");
Stack.setChannel(3); Stack.setFrame(1);
getRawStatistics(nPixels, mean, min, max);
run("Find Maxima...", "noise="+max+" output=[Point Selection]");
getSelectionBounds(x, y, w, h); run("Select None");
makeRectangle(x-ROI_size_for_registration/2, y-ROI_size_for_registration/2, ROI_size_for_registration, ROI_size_for_registration);	
waitForUser("- Save and close '..._rot' window.\n- (Optional) Crop the 'rotated' movie to save RAM, if needed.\n - Adjust ROI for locus registration, if needed.");

if (useVirtualStacks){uVS=" use";} else {uVS="";} // 
run("Correct 3D drift", "channel=3 multi_time_scale sub_pixel edge_enhance only=0"+uVS);
rename("rotated_drift-corrected");
close("rotated");

Stack.setChannel(3); Stack.setFrame(1);
Stack.getDimensions(width, height, channels, slices, frames);
maxZ=0; maxVal=0;
for (i=1; i<=slices; i++) {
    Stack.setSlice(i);
    getRawStatistics(nPixels, mean, min, max);
	if (max>maxVal) { maxZ=i; maxVal=max; }
}
Stack.setSlice(maxZ); 
getRawStatistics(nPixels, mean, min, max);
run("Find Maxima...", "noise="+max+" output=[Point Selection]");
getSelectionBounds(x, y, w, h); run("Select None");
cropSizeX=minOf(x*2, (width-x)*2); cropSizeY=minOf(y*2, (height-y)*2);
cropSizeX=minOf(x*2, (width-x)*2); cropSizeY=minOf(y*2, (height-y)*2);
makeRectangle(x-cropSizeX/2, y-cropSizeY/2, cropSizeX, cropSizeY);

waitForUser("Adjust ROI (if needed) and crop.\n*Important*: Keep selection symmetrical around locus\n(press and maintain shift+alt before ajusting selection)");
//selectWindow("rotated_drift-corrected"); run("Crop");

Stack.setChannel(3); Stack.setFrame(1); Stack.setSlice(maxZ);
Stack.getDimensions(width, height, channels, slices, frames);
getRawStatistics(nPixels, mean, min, max);
run("Find Maxima...", "noise="+max+" output=[Point Selection]");
getSelectionBounds(x, y, w, h); run("Select None");
cropSizeX=minOf(x*2, (width-x)*2); cropSizeY=minOf(y*2, (height-y)*2);
cropSizeX=minOf(x*2, (width-x)*2); cropSizeY=minOf(y*2, (height-y)*2);

makeRectangle(x, y, 1, 1);

selectWindow("rotated_drift-corrected"); Stack.setChannel(6);
run("Plot Z-axis Profile", "profile=time"); rename("F");
selectWindow("rotated_drift-corrected"); Stack.setChannel(5);
run("Plot Z-axis Profile", "profile=time"); rename("Fx");
selectWindow("rotated_drift-corrected"); Stack.setChannel(7);
run("Plot Z-axis Profile", "profile=time"); rename("Fz");
selectWindow("F"); Plot.addFromPlot("Fx", 0); Plot.setStyle(2, "black,none,1.0,Line"); close("Fx");
selectWindow("F"); Plot.addFromPlot("Fz", 0); Plot.setStyle(2, "black,none,1.0,Line"); close("Fz");
Plot.setXYLabels("Time (frames)", "Force (pN)"); Plot.setLimitsToFit(); Plot.setFrameSize(300, 200)
rename(title2+"-profile");

selectWindow("rotated_drift-corrected");
Stack.setChannel(4);
makeRectangle(x-3, y-3, 7, 7);
run("Plot Z-axis Profile", "profile=time"); rename("");
Plot.setXYLabels("Time (frames)", "DNA density (a.u.)"); Plot.setLimitsToFit(); Plot.setFrameSize(300, 200);
rename(title2+"-DNAdensity");

selectWindow("rotated_drift-corrected");
rename(title2+"_rot_regLocus");



