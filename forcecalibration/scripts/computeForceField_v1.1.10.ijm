// Version 1.1.10

///////////////////
///////////////////

// Before running:
// - Make a single tif file with z-stacks and time of the raw TMR (1st channel) and GFP (2nd
//   channel) images. File `20190724_array1_ferritinJuly24_batch_1in10fromdil_pillar1.tif` is
//   provided as an example.
// - Open the flat and dark images.
// - Select the window with the raw data.
// - Run the macro.

// Output force maps are in fN / MNP


////// Parameters
pixXY=65.e-9 // in meters
stepZ=0.5e-6 // in meters

zCoverglass=10 // z plane where the coverglass is in focus (1-based)

T_celcius=25.0 // Temperature in deg celcius
pillarPointingUp=false; // Set of false is the pillar is pointing down

// Images for flat-field correction
flatImg="20190521_flat.tif"
darkImg="20190521_dark.tif"

// Rescaling of the images in the XZ and Z directions (recommended: minimize noise => more accurate gradient)
rescaleFactorXY=0.2
rescaleFactorZ =0.5

// Gaussian blur in the XZ and Z directions (recommended: minimize noise => more accurate gradient)
sBlurXY=rescaleFactorXY*5. // in pixels
sBlurZ =rescaleFactorZ *5. // in pixels

bleachCorr=1; // 0: no bleach correction.
              // 1: normalize based on a rectangular selection (note: make sure `pillarPointingUp` is set properly).
              // 2: normalize using the different time points.

// Average the different timepoints to minimize noise
averageTimePoints=true;

shadowCorr=0; // 0: no shadow correction.
              // 1: normalize using free dye channel.

////// Naming
includeOriginalImageName=true;

////// Display
defaultZ=22;
defaultX=480;

showGraphs=true;

layoutWindows=true; winSep=10;

////// Tool to close all the windows
// The best way to close all the windows after a run is to set this to `true`, run the script, and put it back to `false`.
JustCloseAllWindows=false;

///////////////////
///////////////////


kT= 1.3806e-23*(273.15+T_celcius)

title=getTitle();
if (includeOriginalImageName) { prefix=title+"_"; } else { prefix=""; }

// Close existing windows
close("imgFlatd");           close(prefix+"imgFlatd");
close("imgAllCorr");         close(prefix+"imgAllCorr");
close("imgAllCorr_side");    close(prefix+"imgAllCorr_side");
close("Fxyz");               close(prefix+"Fxyz");
close("Fxyz_side");          close(prefix+"Fxyz_side");
close("Fnorm");              close(prefix+"Fnorm");
close("Fnorm_side");         close(prefix+"Fnorm_side");
close("flatSc"); close("rawSc"); close("darkSc"); close("C1-rawSc"); close("C1-darkSc"); close("C2-rawSc"); close("C2-darkSc"); close("rawMinusDark"); close("flatMinusDark"); close("C1-rawMinusDark"); close("C1-flatMinusDark"); close("C2-rawMinusDark"); close("C2-flatMinusDark"); close("tmp1"); close("tmp2"); close("imgFlatd"); close("raw"); close("logFluo"); close("img_x"); close("img_y"); close("img_z"); close("img_0"); close("tmp2"); close("Fx_2"); close("Fy_2"); close("Fz_2"); close("Fxyz_combined"); close("Fxyz_plot"); close("Fnorm_plot");

if (JustCloseAllWindows) { exit(); }

// Copy and rescale raw z-stack of pillar
selectWindow(title);
getLocationAndSize(winOrigX,winOrigY,tmpX,tmpY);
getDimensions(w, h, channels, slices, frames);
run("Duplicate...", "title=tmpRaw duplicate slices="+zCoverglass+"-"+slices);
run("Scale...", "x="+rescaleFactorXY+" y="+rescaleFactorXY+" z="+rescaleFactorZ+" width="+(-floor(-w*rescaleFactorXY))+" height="+(-floor(-h*rescaleFactorXY))+" depth="+(-floor(-(slices-zCoverglass+1)*rescaleFactorZ))+"  interpolation=Bilinear title=rawSc average create");
run("Properties...", "unit=um pixel_width="+(pixXY*1e6/rescaleFactorXY)+" pixel_height="+(pixXY*1e6/rescaleFactorXY)+" voxel_depth="+(stepZ*1e6/rescaleFactorZ));
getDimensions(rawSc_w,rawSc_h,rawSc_c,rawSc_s,rawSc_f);
close("tmpRaw");

// Open, copy and rescale flat image
if (isOpen(flatImg)) { selectWindow(flatImg);      run("Revert"); rename("flat"); }
else { if (isOpen("flat")) { selectWindow("flat"); run("Revert"); rename("flat"); }
       else { open(flatImg); rename("flat"); } }
run("Scale...", "x="+rescaleFactorXY+" y="+rescaleFactorXY+" z=1.0 interpolation=Bilinear title=flatSc average create");
run("Properties...", "unit=um pixel_width="+(pixXY*1e6/rescaleFactorXY)+" pixel_height="+(pixXY*1e6/rescaleFactorXY));

// Open, copy and rescale dark image
if (isOpen(darkImg)) { selectWindow(darkImg);      run("Revert"); rename("dark"); }
else { if (isOpen("dark")) { selectWindow("dark"); run("Revert"); rename("dark"); }
       else { open(darkImg); rename("dark"); } }
run("Scale...", "x="+rescaleFactorXY+" y="+rescaleFactorXY+" z=1.0 interpolation=Bilinear title=darkSc average create");
run("Properties...", "unit=um pixel_width="+(pixXY*1e6/rescaleFactorXY)+" pixel_height="+(pixXY*1e6/rescaleFactorXY));

// Calculates flat-dark
imageCalculator("Subtract create 32-bit stack", "flatSc","darkSc"); rename("flatMinusDark");
run("Split Channels"); close("flatSc");

// Calculates raw-dark for each channel separately
selectWindow("rawSc"); run("Split Channels");
selectWindow("darkSc"); run("Split Channels");
imageCalculator("Subtract create 32-bit stack", "C1-rawSc","C1-darkSc"); rename("C1-rawMinusDark"); close("C1-rawSc"); close("C1-darkSc"); 
imageCalculator("Subtract create 32-bit stack", "C2-rawSc","C2-darkSc"); rename("C2-rawMinusDark"); close("C2-rawSc"); close("C2-darkSc");
//selectWindow("C2-rawMinusDark"); run("Subtract...", "value=12 stack"); // !!!!!!!!!!!!!!!!
imageCalculator("Divide create 32-bit stack", "C1-rawMinusDark","C1-flatMinusDark"); rename("C1-imgFlatd"); close("C1-rawMinusDark"); close("C1-flatMinusDark");
imageCalculator("Divide create 32-bit stack", "C2-rawMinusDark","C2-flatMinusDark"); rename("C2-imgFlatd"); close("C2-rawMinusDark"); close("C2-flatMinusDark");


// Normalize fluo intensity over stack to correct for bleaching
if (bleachCorr==1) { // ... based on a rectangular selection.
  for (i=0;i<2;i++) {
    if (i==0) { selectWindow("C1-imgFlatd"); }
    else { selectWindow("C2-imgFlatd"); }
    //makeRectangle(0, 0, rawSc_w, 20);
    if (pillarPointingUp) {
    	makeRectangle(rawSc_w-50, 0, 50, 20);
    } else {
    	makeRectangle(rawSc_w-50, rawSc_h-20, 50, 20);
    }
    imgName=getTitle();
    run("Scale...", "x=- y=- z=1.0 width=1 height=1 interpolation=Bilinear average process create title=tmp1");
    run("Scale...", "x=- y=- z=1.0 width="+rawSc_w+" height="+rawSc_h+" interpolation=Bilinear average process create title=tmp2");
    close("tmp1"); v0=getPixel(1,1);
    imageCalculator("Divide create 32-bit stack", imgName,"tmp2"); rename(imgName+"_nrmd");
    close(imgName); selectWindow(imgName+"_nrmd"); rename(imgName);
    run("Multiply...", "value="+v0+" stack");
    resetMinAndMax();  
    close("tmp2");
  }
} else { if (bleachCorr==2) { // ... using the different time points.
	selectWindow("C2-imgFlatd");
	setSlice(floor(rawSc_s*0.5));
	
	x=newArray(rawSc_f); y=newArray(rawSc_f);
	for (i=0; i<rawSc_f; i++) {
		Stack.setFrame(i+1);
		getStatistics(tmpArea, tmpMean, tmpMin, tmpMax, tmpStd);
		x[i]=i*rawSc_s;
		y[i]=tmpMean*1.;
		//y[i]=tmpStd*1.;
	}
	
	Fit.doFit("y = a*exp(-x/b)", x, y, newArray(0.5, 1e5));
	bleachLifetime=Fit.p(1);
	Fit.plot;
	Plot.setLimits(NaN, NaN, 0, NaN);
	Plot.setXYLabels("Number of images (incl. frames and slices)", "Fluo. (a.u.)");
	//Plot.addText(("Fluorophore life-time = "+bleachLifetime, 0.1,0.1);
	print(bleachLifetime);

	selectWindow("C2-imgFlatd");
	for (i=0; i<rawSc_f*rawSc_s; i++) {
		setSlice((i%rawSc_s)+1);
		Stack.setFrame(floor(i/rawSc_s)+1);
		run("Multiply...", "value="+(1./exp(-i/bleachLifetime))+" slice");
		print(floor(i/rawSc_s)+1, (i%rawSc_s)+1, (1./exp(-i/bleachLifetime)));
	}

}}

selectWindow("C1-imgFlatd"); run("Gaussian Blur 3D...", "x="+sBlurXY+" y="+sBlurXY+" z="+sBlurZ);
selectWindow("C2-imgFlatd"); run("Gaussian Blur 3D...", "x="+sBlurXY+" y="+sBlurXY+" z="+sBlurZ);

if (averageTimePoints) {
	run("Merge Channels...", "c1=C1-imgFlatd c2=C2-imgFlatd create");
	selectWindow("imgFlatd");
	getDimensions(width, height, channels, slices, frames);
	run("Stack to Hyperstack...", "order=xyctz channels=2 slices="+frames+" frames="+slices+" display=Composite");
	run("Z Project...", "projection=[Average Intensity] all"); rename("tmp");
	run("Stack to Hyperstack...", "order=xyczt(default) channels=2 slices="+slices+" frames=1 display=Composite");
	close("imgFlatd");
	selectWindow("tmp"); rename("imgFlatd");
	run("Split Channels");
}

// Normalize MNP channel by free dye channel to correct for shadowing effects of the pillar
if (shadowCorr==1) {	
	imageCalculator("Divide create 32-bit stack", "C2-imgFlatd","C1-imgFlatd"); rename("imgAllCorr");
} else {
	selectWindow("C2-imgFlatd");
	run("Duplicate...", "title=imgAllCorr duplicate");
}

run("Merge Channels...", "c1=C1-imgFlatd c2=C2-imgFlatd create"); rename("imgFlatd");
//close("imgFlatd");

// Side view
selectWindow("imgAllCorr");
run("Reslice [/]...", "output=1.000 start=Left flip avoid"); rename("imgAllCorr_side");
run("Flip Horizontally", "stack");
close("raw");


// Make log(fluo) image
selectWindow("imgAllCorr");
run("Duplicate...", "title=logFluo duplicate");
run("32-bit");
//run("Subtract...", "value="+bgValue+" stack");
run("Log", "stack");
resetMinAndMax();

// Calculate 3D gradient and 3D force field
getDimensions(w, h, channels, slices, frames);
makeRectangle(1, 1, w-1, h-1);
run("Duplicate...", "title=img_x duplicate range=1-"+(slices-1)+" ");
selectWindow("logFluo");
makeRectangle(0, 0, w-1, h-1);
run("Duplicate...", "title=img_y duplicate range=1-"+(slices-1)+" ");
selectWindow("logFluo");
makeRectangle(0, 1, w-1, h-1);
run("Duplicate...", "title=img_z duplicate range=2-"+(slices)+" ");
selectWindow("logFluo");
makeRectangle(0, 1, w-1, h-1);
run("Duplicate...", "title=img_0 duplicate range=1-"+(slices-1)+" ");
close("logFluo");
imageCalculator("Subtract create stack", "img_x","img_0");
rename("Fx");
run("Multiply...", "value="+(kT/pixXY*rescaleFactorXY *1e15)+" stack");
setMinAndMax(-1,1); close("img_x");
imageCalculator("Subtract create stack", "img_y","img_0");
rename("Fy");
run("Multiply...", "value="+(kT/pixXY*rescaleFactorXY *1e15)+" stack");
setMinAndMax(-1,1); close("img_y");
imageCalculator("Subtract create stack", "img_z","img_0");
rename("Fz");
run("Multiply...", "value="+(kT/stepZ*rescaleFactorZ  *1e15)+" stack");
setMinAndMax(-1,1); close("img_z");
close("img_0");

// Calculate force magnitude
if (0) { // Use Fx, Fy and Fz
	selectWindow("Fx");
	run("Duplicate...", "title=Fx_2 duplicate");
	run("Square", "stack");
	selectWindow("Fy");
	run("Duplicate...", "title=Fy_2 duplicate");
	run("Square", "stack");
	selectWindow("Fz");
	run("Duplicate...", "title=Fz_2 duplicate");
	run("Square", "stack");
	imageCalculator("Add create stack", "Fx_2","Fy_2");
	rename("tmp2");
	imageCalculator("Add create stack", "tmp2","Fz_2");
	rename("Fnorm");
	run("Square Root", "stack");
	setMinAndMax(0,2); run("Fire");
	close("tmp2"); close("Fx_2"); close("Fy_2"); close("Fz_2");
} else { // Use only Fx and Fy
	selectWindow("Fx");
	run("Duplicate...", "title=Fx_2 duplicate");
	run("Square", "stack");
	selectWindow("Fy");
	run("Duplicate...", "title=Fy_2 duplicate");
	run("Square", "stack");
	imageCalculator("Add create stack", "Fx_2","Fy_2");
	rename("Fnorm");
	run("Square Root", "stack");
	setMinAndMax(0,2); run("Fire");
	close("tmp2"); close("Fx_2"); close("Fy_2");
}

run("Merge Channels...", "c1=Fx c2=Fy c3=Fz create ignore");
Stack.setDisplayMode("grayscale"); run("ICA");
rename("Fxyz");

// Side views
selectWindow("Fnorm");
run("Reslice [/]...", "output=1.000 start=Left flip avoid"); run("Flip Horizontally", "stack");
rename("Fnorm_side");
setSlice(floor(defaultX*rescaleFactorXY+0.5));

selectWindow("Fxyz");
run("Reslice [/]...", "output=1.000 start=Left flip avoid"); run("Flip Horizontally", "stack");
rename("Fxyz_side");
setSlice(floor(defaultX*rescaleFactorXY+0.5));

if (0) {
selectWindow("Fxyz");
	run("Duplicate...", "duplicate");
	getDimensions(width, height, channels, slices, frames);
	run("Stack to Hyperstack...", "order=xyczt(default) channels=3 slices=1 frames="+(slices*frames)+" display=Color");
	run("Split Channels");
	run("Combine...", "stack1=C1-Fxyz-1 stack2=C2-Fxyz-1"); rename("tmp1");
	run("Combine...", "stack1=tmp1 stack2=C3-Fxyz-1"); rename("Fxyz_combined");
	run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices="+slices+" frames="+frames+" display=Color");
}

selectWindow("imgFlatd"); setSlice(floor(defaultZ*rescaleFactorZ-0.5)*2+1);
selectWindow("imgAllCorr"); setSlice(floor(defaultZ*rescaleFactorZ-0.5)+1);
selectWindow("imgAllCorr_side"); setSlice(floor(defaultX*rescaleFactorXY-0.5)+1);
selectWindow("Fxyz"); setSlice(floor(defaultZ*rescaleFactorZ-0.5)*3+1 +1);
selectWindow("Fxyz_side"); setSlice(floor(defaultX*rescaleFactorXY-0.5)*3+1 +1);
selectWindow("Fnorm"); setSlice(floor(defaultZ*rescaleFactorZ-0.5)+1);
selectWindow("Fnorm_side"); setSlice(floor(defaultX*rescaleFactorXY-0.5)+1);

if (showGraphs) {
  //selectWindow("Fxyz"); getLocationAndSize(tmpX,tmpY,winTopX,winTopY);
  //selectWindow("Fxyz_side"); getLocationAndSize(tmpX,tmpY,winSideX,winSideY);
  //run("Plots...", "width="+winTopY+" height="+(winTopX+winSideX)+" font=12 draw draw_ticks fixed minimum="+(-maxDispForce)+" maximum="+maxDispForce);  
  selectWindow("Fxyz");
  makeLine(floor(defaultX*rescaleFactorXY+0.5),h,floor(defaultX*rescaleFactorXY+0.5),0);
  run("Plot Profile"); rename("Fxyz_plot");
  Plot.setLimits(NaN,NaN,-1.,1.);

  //run("Plots...", "width="+(winTopX+winSideX)+" height="+winTopY+" font=12 draw draw_ticks fixed minimum=0 maximum="+maxDispForce);  
  selectWindow("Fnorm");
  makeLine(floor(defaultX*rescaleFactorXY+0.5),h,floor(defaultX*rescaleFactorXY+0.5),0);
  run("Plot Profile"); rename("Fnorm_plot");
  Plot.setLimits(NaN,NaN,0,1.);
}

if (layoutWindows) {
  selectWindow("imgFlatd"); getLocationAndSize(tmpX,tmpY,winTopX,winTopY);
  wait(50); setLocation(winOrigX+winTopX,winOrigY);
  selectWindow("imgAllCorr"); getLocationAndSize(tmpX,tmpY,winTop1dX,winTop1dY);
  wait(50); setLocation(winOrigX+winTopX*2+winSep,winOrigY);
  selectWindow("imgAllCorr_side"); getLocationAndSize(tmpX,tmpY,winSideX,winSideY);
  wait(50); setLocation(winOrigX+winTopX*3+winSep,winOrigY+winTop1dY-winSideY);
  selectWindow("Fxyz");
  wait(50); setLocation(winOrigX,winOrigY+winTopY);
  selectWindow("Fxyz_side");
  wait(50); setLocation(winOrigX+winTopX,winOrigY+winTopY+winTop1dY-winSideY);
  selectWindow("Fnorm");
  wait(50); setLocation(winOrigX+winTopX*2+winSep,winOrigY+winTopY);
  selectWindow("Fnorm_side");
  wait(50); setLocation(winOrigX+winTopX*3+winSep,winOrigY+winTopY+winTop1dY-winSideY);
  if (showGraphs) {
    selectWindow("Fxyz_plot");
    wait(50); setLocation(winOrigX,winOrigY+winTopY*2,winTopX+winSideX,winTopY);
    selectWindow("Fnorm_plot");
    wait(50); setLocation(winOrigX+winTopX*2+winSep,winOrigY+winTopY*2,winTopX+winSideX,winTopY);
  }
}

if (includeOriginalImageName) {
  selectWindow("imgFlatd");           rename(prefix+"imgFlatd");
  selectWindow("imgAllCorr");         rename(prefix+"imgAllCorr");
  selectWindow("imgAllCorr_side");    rename(prefix+"imgAllCorr_side");
  selectWindow("Fxyz");               rename(prefix+"Fxyz");
  selectWindow("Fxyz_side");          rename(prefix+"Fxyz_side");
  selectWindow("Fnorm");              rename(prefix+"Fnorm");
  selectWindow("Fnorm_side");         rename(prefix+"Fnorm_side");
  if (showGraphs) {
  selectWindow("Fxyz_plot");          rename(prefix+"Fxyz_plot");
  selectWindow("Fnorm_plot");         rename(prefix+"Fnorm_plot");
  }
}



