// Before running: open image and select area to be analyzed (optimal is <= 2^n).

sd1=1; sd2=3.;
spotDetectionCutoff=50 
sizeResultPx=41


title=getTitle();
if (endsWith(title,".tif")) title1=substring(title,0,lengthOf(title)-4);
else title1=title;

// Crop
run("Duplicate...", "title=tmp duplicate");
title2=title1+"_crop"; rename(title2);

// Create mask
run("Create Mask");
rename("mask");

// Subtract `min` image
//selectWindow(title2);
//run("Z Project...", "projection=[Min Intensity]"); rename("min");
//imageCalculator("Subtract create 32-bit stack", title2,"min");
//title_mMin=title2+"_mMin"; rename(title_mMin);
//close("min");

// Compute bandpass image
selectWindow(title2);
//selectWindow(title_mMin);
run("Select None");
run("Duplicate...", "title=tmp1 duplicate");
run("32-bit");
run("Duplicate...", "title=tmp2 duplicate");
selectWindow("tmp1");
run("Gaussian Blur...", "sigma="+sd1+" stack");
selectWindow("tmp2");
run("Gaussian Blur...", "sigma="+sd2+" stack");
imageCalculator("Subtract create 32-bit stack", "tmp1","tmp2");
title_bp=title2+"_bPass"+sd1+"-"+sd2; rename(title_bp);
close("tmp1"); close("tmp2");

// Spot detection
selectWindow(title_bp);
getDimensions(w,h,c,s,f);
for (i=1; i<=f; i++) {
	selectWindow(title_bp);
	Stack.setFrame(i);
	run("Find Maxima...", "prominence="+spotDetectionCutoff+" output=[Single Points]");
	rename("tmp");
	imageCalculator("AND", "tmp","mask");
	if (i!=1) {
		run("Concatenate...", "open image1=maxima image2=tmp image3=[-- None --]");
	}
	rename("maxima");
}
close("mask");

// Keep copy of raw, bp and maxima images
selectWindow(title2); run("Duplicate...", "title=c1 duplicate");
selectWindow("maxima"); run("Duplicate...", "title=c2 duplicate"); run("32-bit");
selectWindow(title_bp); rename("c3");
run("Merge Channels...", "c1=c1 c2=c2 c3=c3 create");
Stack.setChannel(1); run("Grays");
Stack.setChannel(2); run("Green");
Stack.setChannel(3); run("Grays");
Stack.setActiveChannels("110");
Stack.setChannel(1); Stack.setDisplayMode("color");
rename(title2+"_spot");


// Rezise canevas 
selectWindow(title2); rename("raw_crop");
getDimensions(w,h,c,s,f);
sizePow2=pow(2,-floor(-log(maxOf(w,h))/log(2)));
run("Canvas Size...", "width="+sizePow2+" height="+sizePow2+" position=Top-Left zero");

selectWindow("maxima");
getDimensions(w,h,c,s,f);
sizePow2=pow(2,-floor(-log(maxOf(w,h))/log(2)));
run("Canvas Size...", "width="+sizePow2+" height="+sizePow2+" position=Top-Left zero");
run("32-bit"); run("Divide...", "value=255 stack"); setMinAndMax(0, 1);

// Compute average images frame by frame
nSpots=0;
for (i=1; i<=f; i++) {
	selectWindow("maxima");   Stack.setFrame(i);
	getRawStatistics(nPixels, mean, min, max, std, histogram);
	nSpots=nSpots+nPixels*mean;

	// Particles
	selectWindow("raw_crop"); Stack.setFrame(i);
	run("FD Math...", "image1=maxima operation=Correlate image2=raw_crop result=Result do");
	rename("tmp");
	if (i!=1) { run("Concatenate...", "open image1=avgSpotS image2=tmp image3=[-- None --]"); }
	rename("avgSpotS");

	// Control
	selectWindow("raw_crop"); Stack.setFrame((i-1+f/2)%f+1);
	run("FD Math...", "image1=maxima operation=Correlate image2=raw_crop result=Result do");
	rename("tmp");
	if (i!=1) { run("Concatenate...", "open image1=avgCtrlS image2=tmp image3=[-- None --]"); }
	rename("avgCtrlS");
}

print("Number of particles: "+nSpots);

// Compute average images
selectWindow("avgCtrlS");
run("Z Project...", "projection=[Sum Slices]");
makeRectangle(sizePow2/2-sizeResultPx/2+1, sizePow2/2-sizeResultPx/2+1, sizeResultPx, sizeResultPx);
run("Crop"); run("Divide...", "value="+nSpots);
resetMinAndMax();
//rename(title+"_avgCtrl");
rename("avgCtrl");

selectWindow("avgSpotS");
run("Z Project...", "projection=[Sum Slices]");
makeRectangle(sizePow2/2-sizeResultPx/2+1, sizePow2/2-sizeResultPx/2+1, sizeResultPx, sizeResultPx);
run("Crop"); run("Divide...", "value="+nSpots);
resetMinAndMax();
//rename(title+"_avgSpot");
rename("avgSpot");

// Compute difference
imageCalculator("Subtract create 32-bit", "avgSpot","avgCtrl");
rename("avgSpotMinusCtrl");

// Rename
selectWindow("avgCtrl"); rename(title+"_avgCtrl");
selectWindow("avgSpot"); rename(title+"_avgSpot");
selectWindow("avgSpotMinusCtrl"); rename(title+"_avgSpotMinusCtrl");
run("In [+]"); run("In [+]"); run("In [+]"); run("In [+]"); run("In [+]"); setMinAndMax(-20, 130);

close("maxima"); close("raw_crop"); close("avgSpotS"); close("avgCtrlS");

