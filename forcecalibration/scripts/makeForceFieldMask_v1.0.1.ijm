// Version 1.0.1

// Usage:
// - Select the window `..._imgAllCorr` from the run of `computeForceField_[...].ijm`
// - Run script.
// - You will be asked to ajust thresholds. Exclude dim pixels where noise is important.
//   Exclude bright pixels, where fluorescence may not accurately reflect particle density.
// - You will be asked to select a region. Make a region that exclude areas that were kept
//   by the thresholding but that should not be included in the mask.


zToDisplay=9

defaultThMin=0.16
defaultThMax=0.58


/////////////////////
title=getTitle();
if (endsWith(title,".tif")) title2=substring(title,0,lengthOf(title)-4);
else title2=title;
if (endsWith(title2,"_mask")) title3=substring(title2,0,lengthOf(title2)-5);
else title3=title2;

run("Duplicate...", "title=tmp_mask channels=1 duplicate");

Stack.setSlice(zToDisplay);
setAutoThreshold("Default");
setThreshold(defaultThMin,defaultThMax);
run("Threshold...");
waitForUser("Adjust thresholds if necessary");

selectWindow("tmp_mask");
setOption("BlackBackground", true);
run("Make Binary", "method=Default background=Default");
close("Threshold");

setTool("freehand");
setBackgroundColor(255, 255, 255);
waitForUser("Select region");

run("Clear Outside", "stack");
run("Select None");
run("32-bit");
setMinAndMax(-500, 255);

selectWindow(title);
run("Duplicate...", "title=tmp_orig channels=1 duplicate");
run("Merge Channels...", "c1=tmp_orig c2=tmp_mask create");
rename(title3+"_mask");
