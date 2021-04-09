// ChroMag - Manual analysis
// 
// Script for step 5 - Version 1.0.5
// - Scales the force map based on parameters below.
// - Merges the force map with the data, as 3 extra channels 

//------ Parameters -------//
locusIntensity        =2904263-1843246;

cameraGain            =30;
exposure_ms           =100;
SpectraX_Cyan_percent =5;

singleMNPintensity    =973.1; // Use 973.1 if pixel size is 0.130um, use 886.4 if pixel size is 0.087um
forceUnitChangeFactor =1e-3; // 1e-3 for converting from fN tp pN
//-------------------------//

// Correction if imaging conditions are not 'standard'
// (i.e. cameraGain=30; exposure_ms=100; SpectraX_Cyan_percent=5)
locusIntensity_corrected = locusIntensity / ( pow(SpectraX_Cyan_percent/5,0.7)
                                              * exposure_ms/100.
                                              * cameraGain/30                )

nb_MNP_at_locus = locusIntensity_corrected / singleMNPintensity
print("MNPs at the locus: ",nb_MNP_at_locus);

Stack.getDimensions(width, height, channels, slices, frames);
title=getTitle();
if (endsWith(title,".tif")) title2=substring(title,0,lengthOf(title)-4);
else title2=title;
rename("data");

selectWindow("F");
run("Multiply...", "value="+(nb_MNP_at_locus*forceUnitChangeFactor)+" stack");
run("Split Channels");
newImage("C1-F-t", "32-bit color-mode", width, height, 1, slices, frames);
imageCalculator("Add stack", "C1-F-t","C1-F"); close("C1-F");
newImage("C2-F-t", "32-bit color-mode", width, height, 1, slices, frames);
imageCalculator("Add stack", "C2-F-t","C2-F"); close("C2-F");
newImage("C3-F-t", "32-bit color-mode", width, height, 1, slices, frames);
imageCalculator("Add stack", "C3-F-t","C3-F"); close("C3-F");

selectWindow("data"); run("Split Channels");
run("Concatenate...", "  title=merged image1=C1-data image2=C2-data image3=C3-data image4=C4-data image5=C1-F-t image6=C2-F-t image7=C3-F-t image8=[-- None --]");
run("Stack to Hyperstack...", "order=xyztc channels=7 slices="+slices+" frames="+frames+" display=Composite");

// Adjust contrasts
Stack.setChannel(1); run("Green"); setMinAndMax(1500, 23000);
Stack.setChannel(2); run("Grays"); setMinAndMax(5500, 17000);
Stack.setChannel(3); run("Green"); setMinAndMax(0, 15000);
Stack.setChannel(4); run("Grays"); setMinAndMax(-400, 1600);
Stack.setChannel(5); run("ICA"); setMinAndMax(-100, 100);
Stack.setChannel(6); run("ICA"); setMinAndMax(-100, 100);
Stack.setChannel(7); run("ICA"); setMinAndMax(-100, 100);
Stack.setActiveChannels("0011000");

rename(title2+"_Fxyz");

