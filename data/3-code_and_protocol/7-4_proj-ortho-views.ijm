// ChroMag - Manual analysis
// 
// Script for step 7 - Version 1.0.0


//-------------------------//
title=getTitle();

// Look for minimal 3D box that includes the locus
xMin=1000000; xMax=-1000000; yMin=1000000; yMax=-1000000; zMin=1000000; zMax=-1000000; maxValLocus=0;
Stack.getDimensions(width, height, channels, slices, frames);
Stack.setChannel(3);
for (t=1; t<=frames; t++) {
	Stack.setFrame(t);
	zLocus=0; valLocus=0;
	for (z=1; z<=slices; z++) {
	    Stack.setSlice(z);
	    getRawStatistics(nPixels, mean, min, max);
		if (max>valLocus) { zLocus=z; valLocus=max; }
	}
	if (valLocus>0.3*maxValLocus) {
		Stack.setSlice(zLocus);
		run("Find Maxima...", "noise="+valLocus+" output=[Point Selection]");
		getSelectionBounds(x, y, w, h);
		if (x     <xMin) { xMin=x; }
		if (y     <yMin) { yMin=y; }
		if (zLocus<zMin) { zMin=zLocus; }
		if (x     >xMax) { xMax=x; }
		if (y     >yMax) { yMax=y; }
		if (zLocus>zMax) { zMax=zLocus; }
	}
	if (valLocus>maxValLocus) { maxValLocus=valLocus; }
	Stack.setFrame(1); Stack.setSlice(round((zMin+zMax)/2));
	run("Select None");
    //print(t,x,y,z,valLocus);
}
//print(xMin,xMax,yMin,yMax,zMin,zMax,maxValLocus);

run("Z Project...", "start="+zMin+" stop="+zMax+" projection=[Max Intensity] all"); rename("projXY");
selectWindow(title);
makeRectangle(0, yMin, width, yMax-yMin+1);
run("Reslice [/]...", "output=0.300 start=Top avoid"); rename("tmp");
run("Z Project...", "projection=[Max Intensity] all"); rename("projXZ"); close("tmp");
selectWindow(title);
makeRectangle(xMin, 0, xMax-xMin+1, height);
run("Reslice [/]...", "output=0.300 start=Left rotate avoid"); rename("tmp");
run("Z Project...", "projection=[Max Intensity] all"); rename("projZY"); close("tmp");
selectWindow(title); run("Select None");
makeRectangle(xMin, yMin, xMax-xMin+1, yMax-yMin+1);

run("Combine...", "stack1=projXY stack2=projXZ combine");
run("Combine...", "stack1=[Combined Stacks] stack2=projZY");
rename("proj-ortho-views");

Stack.setChannel(1); run("Green"); setMinAndMax(1500, 23000);
Stack.setChannel(2); run("Grays"); setMinAndMax(5500, 17000);
Stack.setChannel(3); run("Green"); setMinAndMax(4000, 10000);
Stack.setChannel(4); run("Grays"); setMinAndMax(-20, 400);
Stack.setActiveChannels("0011");

