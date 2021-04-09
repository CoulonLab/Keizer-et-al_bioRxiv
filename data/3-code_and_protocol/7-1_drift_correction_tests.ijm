// ChroMag - Manual analysis
// 
// Script for step 7 - Version 1.0.1

//------ Parameters -------//
pixValueThreshold=-1000;
lowestZ=4;
highestZ=16;
//-------------------------//

title=getTitle();
Stack.getDimensions(width, height, channels, slices, frames);

run("Correct 3D drift", "channel=4 only="+pixValueThreshold+" lowest="+lowestZ+" highest="+highestZ);
rename("0"); run("Duplicate...", "duplicate slices=1-"+slices+" frames=1-"+frames); close("0");


selectWindow(title);
run("Correct 3D drift", "channel=4 multi_time_scale only="+pixValueThreshold+" lowest="+lowestZ+" highest="+highestZ);
rename("M"); run("Duplicate...", "duplicate slices=1-"+slices+" frames=1-"+frames); close("M");

selectWindow(title);
run("Correct 3D drift", "channel=4 edge_enhance only="+pixValueThreshold+" lowest="+lowestZ+" highest="+highestZ);
rename("E"); run("Duplicate...", "duplicate slices=1-"+slices+" frames=1-"+frames); close("E");

selectWindow(title);
run("Correct 3D drift", "channel=4 multi_time_scale edge_enhance only="+pixValueThreshold+" lowest="+lowestZ+" highest="+highestZ);
rename("ME"); run("Duplicate...", "duplicate slices=1-"+slices+" frames=1-"+frames); close("ME");

run("Combine...", "stack1=0-1 stack2=M-1");
run("Combine...", "stack1=[Combined Stacks] stack2=E-1");
run("Combine...", "stack1=[Combined Stacks] stack2=ME-1");
rename("0_M_E_ME");

// Adjust contrasts
run("Green");
setMinAndMax(1500, 23000);
run("Next Slice [>]");
run("Grays");
setMinAndMax(5500, 17000);
run("Next Slice [>]");
run("Green");
setMinAndMax(0, 15000);
run("Next Slice [>]");
run("Grays");
setMinAndMax(-400, 1600);
Stack.setActiveChannels("0011");
