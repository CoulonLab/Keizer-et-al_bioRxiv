// ChroMag - Manual analysis
// 
// Script for step 1 - Version 1.0.0
// - Computes a band-pass filtered image using the 'difference of Gaussians' methods.
//   sd1 and sd2 are the standard deviations of the two Gaussians, i.e. the range of sizes that will be kept.
// - Merge the original channels and the bpassed channels

//------ Parameters -------//
sd1=0.8
sd2=10
//-------------------------//

title=getTitle();
if (endsWith(title,".tif")) title2=substring(title,0,lengthOf(title)-4);
else title2=title;

// Generate band-passed images
//run("Duplicate...", "title=raw duplicate"); // Use either this line ...
run("Crop"); rename("raw"); //                   ... or this line.
run("32-bit");
run("Duplicate...", "title=tmp1 duplicate");
run("Duplicate...", "title=tmp2 duplicate");
selectWindow("tmp1");
run("Gaussian Blur...", "sigma="+sd1+" stack");
selectWindow("tmp2");
run("Gaussian Blur...", "sigma="+sd2+" stack");
imageCalculator("Subtract create 32-bit stack", "tmp1","tmp2");
rename("bPass");
close("tmp1"); close("tmp2");

// Merge raw and band-passed
selectWindow("raw");
run("Split Channels");
selectWindow("bPass");
run("Split Channels");
run("Merge Channels...", "c1=C1-raw c2=C2-raw c3=C1-bPass c4=C2-bPass create");
rename("merged");

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

rename(title2+"_addBPass"+sd1+"-"+sd2);

