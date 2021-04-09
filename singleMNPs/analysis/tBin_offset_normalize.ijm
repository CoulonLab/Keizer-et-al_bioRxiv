
tBin=10
winSize=30;

// Crop (if there is a selection)
title=getTitle();
if (endsWith(title,".tif")) title1=substring(title,0,lengthOf(title)-4);
else title1=title;
getDimensions(w,h,c,s,f);
getSelectionBounds(x,y,sw,sh);
if ((x==0) & (y==0) & (sw==w) & (sh==h)) { title2=title1; }
else {
	title2=title1+"_crop";
	run("Duplicate...", "title="+title2+" duplicate");
}

// Time-binning
run("Duplicate...", "title=tmp duplicate range=1-"+(floor(s*f/tBin)*tBin));
getDimensions(w,h,c,s,f);
run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices="+tBin+" frames="+floor(f*s/tBin));
selectWindow("tmp"); run("Z Project...", "projection=[Average Intensity] all");
//run("Z Project...", "projection=[Median] all");
//run("Z Project...", "projection=[Min Intensity] all");
title3=title2+"_tBin"+tBin; rename(title3);
close("tmp");
//close(title2);

// Offset using background
selectWindow(title3);
makeRectangle(0, h-winSize, winSize, winSize);
getDimensions(w,h,c,s,f);
run("Scale...", "x=- y=- z=1.0 width=1 height=1 interpolation=Bilinear average process create title=tmp1");
run("Scale...", "x=- y=- z=1.0 width="+w+" height="+h+" interpolation=Bilinear average process create title=tmp2");
close("tmp1"); v0=getPixel(1,1);
imageCalculator("Subtract create 32-bit stack", title3,"tmp2");
title4=title3+"_off0"; rename(title4);
close("tmp2");
close(title3);

// Normalize using whole image
selectWindow(title4);
run("Select None");
run("Scale...", "x=- y=- z=1.0 width=1 height=1 interpolation=Bilinear average process create title=tmp1");
run("Scale...", "x=- y=- z=1.0 width="+w+" height="+h+" interpolation=Bilinear average process create title=tmp2");
close("tmp1"); v0=getPixel(1,1);
imageCalculator("Divide create 32-bit stack", title4,"tmp2");
title5=title4+"_nrmd"; rename(title5);
run("Multiply...", "value="+v0+" stack");
resetMinAndMax();
close("tmp2");
close(title4);

