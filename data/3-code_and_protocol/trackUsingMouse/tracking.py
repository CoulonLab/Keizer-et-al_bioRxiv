######################################################################
#
# -- TrackUsingMouse --
#
# Manually-assisted tracking and Gaussian mask fitting.
#
# Copyright (C) 2021  Antoine Coulon (Institut Curie - CNRS).
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Contact: software@coulonlab.org - www.coulonlab.org
#
######################################################################

from scipy import *
from scipy import ndimage,fftpack,optimize
from skimage import io, filters
from matplotlib import pyplot as plt
import os

__version__="1.2.5"


def GaussianMaskFit2(im,coo,s,optLoc=1,bgSub=2,winSize=13,convDelta=.05,nbIter=20):
  """Applies the algorithm from [Thompson et al. (2002) PNAS, 82:2775].
Parameters:
- im: a numpy array with the image (axes:YX)
- coo: approximate coordinates (in pixels, axes:YX) of the spot to localize and measure
- s: width of the PSF in pixels
- optLoc: If 1, applied the iterative localization refinement algorithm, starting with the coordinates provided in coo. If 0, only measures the spot intensity at the coordinates provided in coo.
- bgSub: 0 -> no background subtraction. 1 -> constant background subtraction. 2 -> tilted plane background subtraction.
- convDelta: cutoff to determine convergence, i.e. the distance (in pixels) between two iterations
- nbIter: the maximal number of iterations.

Returns
- the intensity value of the spot.
- the corrdinates of the spot.

If convergence is not found after nbIter iterations, return 0 for both intensity value and coordinates.
"""
  coo=array(coo);
  for i in range(nbIter):
    if not prod(coo-winSize/2.>=0)*prod(coo+winSize/2.<=im.shape): return 0.,r_[0.,0.], r_[0.,0.,0.]
    winOrig=(coo-(winSize-1)/2).astype(int)
    ix,iy=meshgrid(winOrig[1]+r_[:winSize],winOrig[0]+r_[:winSize]);
    N=exp(-(iy-coo[0])**2/(2*s**2)-(ix-coo[1])**2/(2*s**2))/(2*pi*s**2)
    S=im[winOrig[0]:winOrig[0]+winSize][:,winOrig[1]:winOrig[1]+winSize]*1.
    if bgSub==2:
      xy=r_[:2*winSize]%winSize-(winSize-1)/2.
      bgx=polyfit(xy,r_[S[0],S[-1]],1); S=(S-xy[:winSize]*bgx[0]).T;
      bgy=polyfit(xy,r_[S[0],S[-1]],1); S=(S-xy[:winSize]*bgy[0]).T;
      bg=mean([S[0],S[-1],S[:,0],S[:,-1],]); S-=bg
      bg=r_[bg,bgx[0],bgy[0]]
    if bgSub==1:
      bg=mean([S[0],S[-1],S[:,0],S[:,-1],]); S-=bg
    #S=S.clip(0) # Prevent negative values !!!!
    if optLoc:
      SN=S*N; ncoo=r_[sum(iy*SN),sum(ix*SN)]/sum(SN)
      #ncoo=2*ncoo-coo # Extrapolation of localization step !!!!
      if abs(coo-ncoo).max()<convDelta: return sum(SN)/sum(N**2),coo,bg
      else: coo=ncoo
    else: return sum(S*N)/sum(N**2),coo,bg
  return 0.,r_[0.,0.], r_[0.,0.,0.]


def GaussianMaskFit3D(im,coo,s,sZ=None,optLoc=1,bgSub=2,winSize=None,winSizeZ=None,convDelta=.05,nbIter=20):
  """Applies the algorithm from [Thompson et al. (2002) PNAS, 82:2775] adapted to 3D images.
Parameters:
- im: a numpy array with the image (axes:ZYX)
- coo: approximate z,y,x coordinates (in pixels, axes:ZYX) of the spot to localize and measure
- s: width of the PSF in x,y in pixels
- sZ: width of the PSF in z in pixels. Defaults to the same value as s.
- optLoc: If 1, applied the iterative localization refinement algorithm, starting with the coordinates provided in coo. If 0, only measures the spot intensity at the coordinates provided in coo.
- bgSub: 0 -> no background subtraction. 1 -> constant background subtraction. 2 -> tilted plane background subtraction.
- winSize: Size of the x,y window (in pixels) around the position in coo, used for the iterative localization and for the background subtraction.
- winSizeZ: Same as winSize, in the z dimension.
- convDelta: cutoff to determine convergence, i.e. the distance (in pixels) between two iterations
- nbIter: the maximal number of iterations.

Returns
- the intensity value of the spot.
- the coordinates of the spot (z,y,x).
- the background level:
   - either a constant value if bgSub=1
   - or [offset, tilt in z, tilt in y, tilt in x] if bgSub=2

If convergence is not found after nbIter iterations, return 0 for both intensity value and coordinates.
"""
  coo=array(coo);
  if sZ==None: sZ=s
  if winSize ==None: winSize =int(ceil(s*8./2))*2+1
  if winSizeZ==None: winSizeZ=int(ceil(sZ*4./2))*2+1
  for i in range(nbIter):
    if not (winSizeZ/2.<=coo[0]<=im.shape[0]-winSizeZ/2.)*prod([winSize/2.<=coo[j]<=im.shape[j]-winSize/2. for j in [1,2]]):
      return 0.,r_[0.,0.,0.], r_[0.,0.,0.,0.]
    winOrig=r_[coo[0]-int(winSizeZ/2),coo[1:]-int(winSize/2)].astype(int)
    iy,iz,ix=meshgrid(winOrig[1]+r_[:winSize],winOrig[0]+r_[:winSizeZ],winOrig[2]+r_[:winSize]);
    N=exp(-(iz-coo[0])**2/(2*sZ**2)-(iy-coo[1])**2/(2*s**2)-(ix-coo[2])**2/(2*s**2))/((2*pi)**1.5*s*s*sZ)
    S=im[winOrig[0]:winOrig[0]+winSizeZ][:,winOrig[1]:winOrig[1]+winSize][:,:,winOrig[2]:winOrig[2]+winSize]*1.
    if bgSub==2:
      cxy=r_[:winSize]-(winSize-1)/2.
      cz=r_[:winSizeZ]-(winSizeZ-1)/2.
      bgx=polyfit(cxy,mean(r_[S[:,0],S[:,-1]],0),1)[0];
      bgy=polyfit(cxy,mean(r_[S[:,:,0],S[:,:,-1]],0),1)[0];
      bgz=polyfit(cz,mean(c_[S[:,0],S[:,-1],S[:,1:-1,0],S[:,1:-1,-1]],1),1)[0];
      S=rollaxis(rollaxis(rollaxis(S-cxy*bgx,2)-cxy*bgy,2)-cz*bgz,2)
      bg=mean([S[:,0],S[:,-1],S[:,:,0],S[:,:,-1],]); S-=bg
      bg=r_[bg,bgz,bgy,bgx]
    if bgSub==1:
      bg=mean([S[:,0],S[:,-1],S[:,:,0],S[:,:,-1],]); S-=bg
    #S=S.clip(0) # Prevent negative values !!!!
    if optLoc:
      SN=S*N; ncoo=r_[sum(iz*SN),sum(iy*SN),sum(ix*SN)]/sum(SN)
      #ncoo+=ncoo-coo # Extrapolation of localization step !!!!
      #ncoo+=(ncoo-coo)*.7 # Extrapolation of localization step !!!!
      #print(i,ncoo,abs(coo-ncoo).max())
      if abs(coo-ncoo).max()<convDelta: return sum(SN)/sum(N**2),coo,bg
      else: coo=ncoo
    else: return sum(S*N)/sum(N**2),coo,bg
  return 0.,r_[0.,0.,0.], r_[0.,0.,0.,0.]


def bpass(im,r1=1.,r2=1.7):
  x=r_[r_[:(1+im.shape[1])//2],r_[(1-im.shape[1])//2:0]]
  y=r_[r_[:(1+im.shape[0])//2],r_[(1-im.shape[0])//2:0]]
  ker1x=exp(-(x/r1)**2/2); ker1x/=sum(ker1x); fker1x=fft(ker1x);
  ker1y=exp(-(y/r1)**2/2); ker1y/=sum(ker1y); fker1y=fft(ker1y);
  ker2x=exp(-(x/r2)**2/2); ker2x/=sum(ker2x); fker2x=fft(ker2x);
  ker2y=exp(-(y/r2)**2/2); ker2y/=sum(ker2y); fker2y=fft(ker2y);
  fim=fftpack.fftn(im)
  return fftpack.ifftn((fim*fker1x).T*fker1y-(fim*fker2x).T*fker2y).real.T

def bpass3D(im,r1=1.,r2=1.7,rz1=1.,rz2=1.7,zMirror=False):
  return filters.gaussian(im,r_[rz1,r1,r1],mode='mirror')-filters.gaussian(im,r_[rz2,r2,r2],mode='mirror')


def trackUsingMouse(fnTif,fnSuff,
                    mtrk_file=None,fps=0,performFit=True,
                    psfPx=1.7,psfZPx=None,thresholdSD=5,roiSize=40,border=3,distThreshold=20,trackMemory=0,reactionDelay=.0,disp=3):
  """Tracks a spot using the mouse.

  1. The TIF file is shown in fiji and the user has to follow the spot of interest
     with the mouse. A .mtrk file is created (columns specified in header).
  2. If performFit is True:
     - Spots are detected using a s.d. threshold on a bandpass filtered image. The
       region of interest is centered on the position of the mouse. The detected
       spot that is the closest to both the mouse position and the spot found in
       the previous image (mim square sum) is selected.
     - Iterative Gaussian mask fitting is used to localize and fit the spot in each
       frame. A .trk2 file is created (columns specified in header).

  Parameters:
  - fnTif:         Full path of the TIF file to be tracked.
  - fnSuff:        Suffix added at the end of the TIF file name for the resulting
                   .mtrk and .trk files.
  - mtrk_file:     Path of the .mtrk file (if set to None, it is created from the path of
                   the input image).
  - fps:           Frame rate at which the movie is played during the manual
                   tracking. If set to 0, the movie has to be played manually
                   (e.g. with right/left arrows or with the mouse wheel). When
                   going back and forth, only the last time a frame is played
                   counts. If set to < 0, fiji macro will not be run.
  - performFit     If False, only a .mtrk file is generated.
                   If True, Gaussian mask fitting is performed using the following
                   parameters. (Note: only works on single-channel images)
  - psfPx:         PSD size in pixels in XY. Used for the bandpass filtering.
  - psfZPx:        PSD size in pixels in Z. Is None, the value of psfPx is used.
  - thresholdSD:   Number of standard deviations used to detect objects in the
                   bandpassed image.
  - roiSize:       Size in pixels of the region of interest, around the mouse
                   position, where spots are considered.
  - border:        Number of pixels added one each side of the ROI in the
                   bandpass filtering and removed afterwards.
  - distThreshold: Maximal distance that the spot can be from the position of the
                   mouse. Used for both object detection in the bandpassed-
                   filtered image and for testing the convergence of the Gaussian
                   fit algorithm.
  - trackMemory:   Maximal number of frames used for the location of of the
                   previous spot. If 0, only the distance to the mouse
                   coordinates is used.
  - reactionDelay: Time delay (in sec) by which the manual coordinates are
                   expected to be lagging.
  - disp:          If 1, the result of the tracking is displayed.
  """

  norm01=(lambda a: (lambda b: b/max(b.flatten()))(a*1.-min(a.flatten())))

  def prepForDisp(l,size):
    return [c_[c_[el,zeros((el.shape[0],size[0]-el.shape[1]))].T,zeros((size[0],size[1]-el.shape[0]))].T for el in l]  


  if fps!=0:
    macro="""fps=%f;
if (isOpen('%s')==0) { open('%s'); }
selectWindow('%s');
setSlice(1);
print('\\\\Clear'); print('Starting in 3 sec...'); wait(1000.);
print('\\\\Clear'); print('Starting in 2 sec...'); wait(1000.);
print('\\\\Clear'); print('Starting in 1 sec...'); wait(1000.);
print('\\\\Clear');
Stack.getDimensions(width, height, channels, slices, frames);
for (i=0; i<frames; i++) {
  setSlice(1+channels*slices*i);
  wait(1000./fps);
  getCursorLoc(x, y, z, flags); 
  print(i+1, x, y);
}
selectWindow('Log');
saveAs('Text','%s');"""%(fps,os.path.basename(fnTif),fnTif,os.path.basename(fnTif),fnTif[:-4]+fnSuff+'.txt')
  else:
    macro="""
if (isOpen('%s')==0) { open('%s'); }
selectWindow('%s');
title=getTitle();
setSlice(1);
Stack.getDimensions(width, height, channels, slices, frames);
print('\\\Clear');
//print('# T X Y Z C');
if (slices==1) { print('# T X Y'); }
else           { print('# T X Y Z'); }
currImgNb=getSliceNumber();
Stack.getPosition(currChannel, currSlice, currFrame)
while (isOpen(title)) {
  newImgNb=getSliceNumber();
  if (newImgNb!=currImgNb) {
    getCursorLoc(x, y, zDoNotUse, flags);
    if (slices==1) { print(currFrame, x, y); }
    else           { print(currFrame, x, y, currSlice); }    
    Stack.getPosition(currChannel, currSlice, currFrame)
    currImgNb=newImgNb; }
  else wait(1.);
}
selectWindow('Log');
saveAs('Text','%s');"""%(os.path.basename(fnTif),fnTif,os.path.basename(fnTif),fnTif[:-4]+fnSuff+'.txt')
  
  if fps>=0: # Run macro
    open('.tmp_trackUsingMouse.ijm','w').writelines([macro])
    os.system(fijiCmd+""" -macro .tmp_trackUsingMouse.ijm""")
    
    try: os.replace(fnTif[:-4]+fnSuff+'.txt',fnTif[:-4]+fnSuff+'.mtrk')
    except:
        print("Error when renaming mtrk file.")
        raise
    os.remove(".tmp_trackUsingMouse.ijm")
  else: fps=0. # For re-running trackUsingMouse() without re-running the imagej macro

  if mtrk_file is None:
    fn_mtrk=fnTif[:-4]+fnSuff+'.mtrk'
  else:
    fn_mtrk = mtrk_file
  fn_trk2 = mtrk_file.replace(".mtrk", ".trk2")
  lPosGuess=loadtxt(fn_mtrk,skiprows=1)

  # Remove duplicates in lPosGuess
  if fps==0:
    tmp=zeros((int(lPosGuess[:,0].max()),lPosGuess.shape[1]))
    for posGuess in lPosGuess:
      tmp[int(posGuess[0])-1]=posGuess #(note: lPosGuess is still 1-based)
    lPosGuess=tmp
    savetxt(fn_mtrk,lPosGuess,header="# T X Y Z",fmt="%d")

#  # Remove duplicates in lPosGuess
#  if fps==0:
#    tmp=lPosGuess;
#    lPosGuess=r_[0:lPosGuess[:,0].max()+1];
#    lPosGuess=c_[lPosGuess,zeros((lPosGuess.shape[0],2))]
#    i=tmp[0,0]-1
#    for ltmp in tmp:
#      if i<=ltmp[0]: lPosGuess[int(i)+1:int(ltmp[0])+1][:,1:]=ltmp[1:]
#      else:         lPosGuess[int(ltmp[0]):int(i)][:,1:]=ltmp[1:]
#      i=ltmp[0]
#    lPosGuess=loadtxt(fnTif[:-4]+fnSuff+'.mtrk',skiprows=1)

  a=io.imread(fnTif);
  nbFrames=a.shape[0]

  if nbFrames!=lPosGuess.shape[0]:
    print("!! Warning: number of frame in '.tif' and '.mtrk' files differ.")

  if not performFit:
    print("Generated file '%s'"%fn_mtrk)
    return

  lPosGuess[:,0]-=1 # Convert t to zero-based indexing
  lPosGuess[:,3]-=1 # Convert z to zero-based indexing

  frameDelay=int(reactionDelay*fps)
  resPos=[]; res=[]; toDisp=[]

  ####################################################
  if lPosGuess.shape[1]==3: ########## Data set is 2D #
        
      for i in range(nbFrames):
        posGuess=lPosGuess[max(0,i-frameDelay)][1:]
        box=c_[(posGuess[0]+r_[-1,1]*(roiSize//2+border)).clip(0,a[i].shape[1]-1),
               (posGuess[1]+r_[-1,1]*(roiSize//2+border)).clip(0,a[i].shape[0]-1)].flatten().astype(int)
        im2=a[i][:,box[0]:box[2]][box[1]:box[3]]                   # Cropped image
        im3=bpass(im2,1.,psfPx)[border:-border][:,border:-border]  # Band-passed image
        im4=(im3-mean(im3))/var(im3)**.5                           # Standardized image
        im5=(im4>thresholdSD)*1                                    # Binary image
        im6,nbFeat=ndimage.measurements.label(im5)                 # Labeled imag
        #showMat(c_[norm01(im2[border:-border][:,border:-border]),norm01(im3),norm01(im6)])
        #g('reset; set ticsl 0; splot '+GpD3dMat(im4)+' w l t""')
        spotFound=0
        if nbFeat:
          objs=ndimage.measurements.find_objects(im6) # Identify objects
          cooObjs=box[:2]+border+array([r_[r_[oo[1]].mean(),r_[oo[0]].mean()] for oo in objs])
          if trackMemory and len(resPos) and i-resPos[-1][0]<=trackMemory:
            # Find closest to both posGuess and previous spot (up to 'trackMemory' frames ago)
            dist2 =sum((cooObjs-posGuess)**2,1);
            dist2+=sum((cooObjs-resPos[-1][1:-1])**2,1);
            objId=dist2.argmin(); pos=cooObjs[objId]
          else:
            # Find closest to posGuess
            dist2=sum((cooObjs-posGuess)**2,1); objId=dist2.argmin(); pos=cooObjs[objId]
          if dist2[objId]<distThreshold**2:
            im7=.5*(im6==objId+1)+.5*im5 # Image with 1 = selected object, 0.5 = other objects
            resPos.append(r_[i,pos,1]); spotFound=1
          else: im7=.5*im5
        else: im7=im5*0
        res.append([box,im2])
        toDisp.append(prepForDisp([norm01(im2[border:-border][:,border:-border]),norm01(im3),im7],[roiSize,roiSize]))
        print("Detecting spots... frame %d - %d object(s)."%(i,nbFeat)+(" best=[%.1f,%.1f]"%(pos[0],pos[1]) if spotFound else ""))

      # Interpolate coodinate
      #lPos=(lambda (f,x,y): c_[interp(r_[:nbFrames],f,x),interp(r_[:nbFrames],f,y)])(array(resPos).T)

      # -OR- Fill in with manual position guess.
      lPos=c_[lPosGuess[maximum(0,r_[:nbFrames]-frameDelay)][:,1:],zeros(nbFrames)]
      for rp in resPos: lPos[int(rp[0])]=rp[1:]

      trk2=[]
      for i in range(nbFrames):
        box,im2=res[i]; pos=lPos[i]; posGuess=lPosGuess[max(0,i-frameDelay)]
        f,posFit,bg=GaussianMaskFit2(im2,(pos[:2]-box[:2])[::-1],psfPx,convDelta=.01);
        posFit=posFit[::-1]+box[:2]
        if f==0. or sum((posFit-pos[:2])**2)>distThreshold**2:
          f,posFit,bg=GaussianMaskFit2(im2,(pos[:2]-box[:2])[::-1],psfPx,optLoc=0);
          posFit=posFit[::-1]+box[:2]
          conv=False
        else: conv=True
        trk2.append(r_[i,posFit,nan,f,bg,nan,pos[2]+2*conv])
        print("Fitting spots... frame %d (converged: %s) - [%.1f,%.1f]"%(i,['n','y'][conv],posFit[0],posFit[1]))
        im8=toDisp[i][0]*0; # Image with 0.3 = mouse position, 0.7 = bpass object, 1 = fit (if converged)
        pt=(posGuess[1:]-box[:2]-border+.5).astype(int);
        if prod(0<=pt)*prod(pt<roiSize): im8[pt[1],pt[0]]=.3
        pt=(pos[:2]-box[:2]-border+.5).astype(int);
        if prod(0<=pt)*prod(pt<roiSize): im8[pt[1],pt[0]]=.7
        if conv:
          pt=(posFit-box[:2]-border+.5).astype(int);
          if prod(0<=pt)*prod(pt<roiSize): im8[pt[1],pt[0]]=1
        toDisp[i].append(im8)

      trk2=array(trk2); savetxt(fn_trk2,trk2,delimiter='\t',fmt='%.5e',header='Frame\tPosition X\tPosition Y\tPosition Z\tFluo. instensity\tBackgound level\tBackgound tilt X\tBackgound tilt Y\tBackgound tilt Z\tCode (bits: spot detected, fit convereged)')

      if disp&1:
        fig=plt.figure(figsize=(8,6));
        fig.add_subplot(411); plt.grid(1); plt.ylabel('X coordinate (px)'); plt.plot(lPosGuess[:,0],lPosGuess[:,1],label="Manual track"); plt.plot(trk2[:,0],trk2[:,1],label="Gaussian fit"); plt.legend()
        fig.add_subplot(412); plt.grid(1); plt.ylabel('Y coordinate (px)'); plt.plot(lPosGuess[:,0],lPosGuess[:,2],label="Manual track"); plt.plot(trk2[:,0],trk2[:,2],label="Gaussian fit"); plt.legend()
        fig.add_subplot(413); plt.grid(1); plt.ylabel('Jump distance (px)'); plt.ylim(0,20); plt.plot(sum(diff(trk2[:,1:3],1,0)**2,1)**.5);
        fig.add_subplot(414); plt.grid(1); plt.ylabel('Fluo. (x 1e-3)'); plt.xlabel('Frame'); plt.plot(trk2[:,0],trk2[:,4]*1e-3,label="Gaussian fit");
        plt.tight_layout(); plt.ion(); plt.show(); plt.ioff(); 
      if disp&2:
        io.imsave(fnTif[:-4]+fnSuff+'_track.tif',array([r_[c_[aa[0],aa[1]],c_[aa[3],aa[2]]] for aa in toDisp]).astype(float32))

        
        
  ####################################################
  else: ########## Data set is 3D #

      if type(psfZPx)==type(None): psfZPx=psfPx
    
      for i in range(nbFrames):
        posGuess=lPosGuess[max(0,i-frameDelay)][1:]
        box=c_[(posGuess[0]+r_[-1,1]*(roiSize//2+border)).clip(0,a[i].shape[2]-1),
               (posGuess[1]+r_[-1,1]*(roiSize//2+border)).clip(0,a[i].shape[1]-1)].flatten().astype(int)
        im2=a[i][:,:,box[0]:box[2]][:,box[1]:box[3]]               # Cropped image
        im3=bpass3D(im2,1.,psfPx,1.,psfZPx,zMirror=4)[:,border:-border][:,:,border:-border]  # Band-passed image
        im4=(im3-mean(im3))/var(im3)**.5                           # Standardized image
        im5=(im4>thresholdSD)*1                                    # Binary image
        im6,nbFeat=ndimage.measurements.label(im5)                 # Labeled imag
        #showMat(c_[norm01(im2[border:-border][:,border:-border]),norm01(im3),norm01(im6)])
        #g('reset; set ticsl 0; splot '+GpD3dMat(im4)+' w l t""')
        spotFound=0
        if nbFeat:
          objs=ndimage.measurements.find_objects(im6) # Identify objects
          cooObjs=r_[box[:2],0]+border*r_[1,1,0]+array([r_[r_[oo[2]].mean(),r_[oo[1]].mean(),r_[oo[0]].mean()] for oo in objs])
          if trackMemory and len(resPos) and i-resPos[-1][0]<=trackMemory:
            # Find closest to both posGuess and previous spot (up to 'trackMemory' frames ago)
            dist2 =sum((cooObjs-posGuess)**2,1);
            dist2+=sum((cooObjs-resPos[-1][1:])**2,1);
            objId=dist2.argmin(); pos=cooObjs[objId]
          else:
            # Find closest to posGuess
            dist2=sum((cooObjs-posGuess)**2,1); objId=dist2.argmin(); pos=cooObjs[objId]
          if dist2[objId]<distThreshold**2:
            im7=.5*(im6==objId+1)+.5*im5 # Image with 1 = selected object, 0.5 = other objects
            resPos.append(r_[i,pos,1]); spotFound=1
          else: im7=.5*im5
        else: im7=im5*0
        res.append([box,im2])
        print(posGuess,im2.shape,im3.shape,a[i].shape,int(posGuess[2]))
        toDisp.append(prepForDisp([norm01(im2[int(posGuess[2]),border:-border][:,border:-border]),norm01(im3[int(posGuess[2])]),im7.max(0)],[roiSize,roiSize]))
        print("Detecting spots... frame %d - %d object(s)."%(i,nbFeat)+(" best=[%.1f,%.1f,%.1f]"%(pos[0],pos[1],pos[2]) if spotFound else ""))

      # Interpolate coodinate
      #lPos=(lambda (f,x,y): c_[interp(r_[:nbFrames],f,x),interp(r_[:nbFrames],f,y)])(array(resPos).T)
      # ---OR---
      # Fill in with manual position guess.
      lPos=c_[lPosGuess[maximum(0,r_[:nbFrames]-frameDelay)][:,1:],zeros(nbFrames)]
      for rp in resPos: lPos[int(rp[0])]=rp[1:]

      trk2=[]
      for i in range(nbFrames):
        box,im2=res[i]; pos=lPos[i]; posGuess=lPosGuess[max(0,i-frameDelay)]
        f,posFit,bg=GaussianMaskFit3D(im2,(pos[:3]-r_[box[:2],0])[::-1],psfPx,psfZPx,convDelta=.01);
        posFit=posFit[::-1]+r_[box[:2],0]
        if f==0. or sum((posFit-pos[:3])**2)>distThreshold**2:
          f,posFit,bg=GaussianMaskFit3D(im2,(pos[:3]-r_[box[:2],0])[::-1],psfPx,psfZPx,optLoc=0);
          posFit=posFit[::-1]+r_[box[:2],0]
          conv=False
        else: conv=True
        trk2.append(r_[i,posFit,f,bg,pos[3]+2*conv])
        print("Fitting spots... frame %d (converged: %s) - [%.1f,%.1f,%.1f]"%(i,['n','y'][conv],posFit[0],posFit[1],posFit[2]))
        im8=toDisp[i][0]*0; # Image with 0.3 = mouse position, 0.7 = bpass object, 1 = fit (if converged)
        pt=(posGuess[1:3]-box[:2]-border+.5).astype(int);
        if prod(0<=pt)*prod(pt<roiSize): im8[pt[1],pt[0]]=.3
        pt=(pos[:2]-box[:2]-border+.5).astype(int);
        if prod(0<=pt)*prod(pt<roiSize): im8[pt[1],pt[0]]=.7
        if conv:
          pt=(posFit[:2]-box[:2]-border+.5).astype(int);
          if prod(0<=pt)*prod(pt<roiSize): im8[pt[1],pt[0]]=1
        toDisp[i].append(im8)

      trk2=array(trk2);
      savetxt(fnTif[:-4]+fnSuff+'.trk2',trk2,delimiter='\t',fmt='%.5e',header='Frame\tPosition X\tPosition Y\tPosition Z\tFluo. instensity\tBackgound level\tBackgound tilt X\tBackgound tilt Y\tBackgound tilt Z\tCode (bits: spot detected, fit convereged)')

      if disp&1:
        fig=plt.figure(figsize=(8,8));
        fig.add_subplot(511); plt.grid(1); plt.ylabel('X coordinate (px)'); plt.plot(lPosGuess[:,0],lPosGuess[:,1],label="Manual track"); plt.plot(trk2[:,0],trk2[:,1],label="Gaussian fit"); plt.legend()
        fig.add_subplot(512); plt.grid(1); plt.ylabel('Y coordinate (px)'); plt.plot(lPosGuess[:,0],lPosGuess[:,2],label="Manual track"); plt.plot(trk2[:,0],trk2[:,2],label="Gaussian fit"); plt.legend()
        fig.add_subplot(513); plt.grid(1); plt.ylabel('Z coordinate (px)'); plt.plot(lPosGuess[:,0],lPosGuess[:,3],label="Manual track"); plt.plot(trk2[:,0],trk2[:,3],label="Gaussian fit"); plt.legend()
        fig.add_subplot(514); plt.grid(1); plt.ylabel('Jump distance (px)'); plt.ylim(0,20); plt.plot(sum(diff(trk2[:,1:3],1,0)**2,1)**.5);
        fig.add_subplot(515); plt.grid(1); plt.ylabel('Fluo. (x 1e-3)'); plt.xlabel('Frame'); plt.plot(trk2[:,0],trk2[:,4]*1e-3,label="Gaussian fit");
        plt.tight_layout(); plt.ion(); plt.show(); plt.ioff(); 
      if disp&2:
        io.imsave(fnTif[:-4]+fnSuff+'_track.tif',array([r_[c_[aa[0],aa[1]],c_[aa[3],aa[2]]] for aa in toDisp]).astype(float32))

