//####### CRaQ VERSION
version = "v1.11";
//####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### 


run("Set Measurements...", "area mean min center feret's redirect=None decimal=3");
run("Colors...", "foreground=black background=black selection=green");


choices=newArray("Unprojected DV files: fast acquisition mode","Unprojected DV files: slow acquisition mode","Projected files","TIF files","Deconvolved DVs");
Dialog.create("Set Channels");
	Dialog.addNumber("Data channel number",1,0,0,"");
	Dialog.addNumber("Reference channel number",1,0,0,"");
	Dialog.addNumber("DAPI channel number",4,0,0,"enter 0 if no DAPI was used");
	Dialog.addNumber("Total channels",4,0,0,"");
	Dialog.addMessage("");
	Dialog.addCheckbox("Change default parameter settings?",0);
	Dialog.addCheckbox("Cropped cells?",0);
Dialog.show();
	DataCh=Dialog.getNumber();
	RefCh=Dialog.getNumber();
	DapiCh=Dialog.getNumber();
	TotCh=Dialog.getNumber();
	Change=Dialog.getCheckbox();
	CroppedCells=Dialog.getCheckbox();
if (((RefCh-DapiCh)*(DataCh-DapiCh)) == 0){
	exit("Reference and Data channels should be different from DAPI channel");
	beep();
	}
}


Dialog.create("Change parameter settings");
	Dialog.addNumber("Square size",7,0,0,"pixels");
	Dialog.addNumber("Minimum Circularity",0.95,2,4,"a.u.");
	Dialog.addNumber("Max Feret's Diameter",7,1,3,"pixels");
	Dialog.addNumber("Min Centromere Size",4,0,2,"pixel");
	Dialog.addNumber("Max Centromere Size",35,0,2,"pixel");
	Dialog.addNumber("Threshold Factor",1.11,2,4,"pixel intensity");
	Dialog.addMessage("\nIf known, set the chromatic aberration of the reference channel compared to the data channel.");
	Dialog.addNumber("Chromatic aberration (horizontal): ",0,0,2,"pixels to right");
	Dialog.addNumber("Chromatic aberration (vertical): ",0,0,2,"pixels down");
if (Change == 1) 
	Dialog.show();		//####################keeps defaults if "Change default" is unchecked
	SquareSize=Dialog.getNumber();
	MinCirc=Dialog.getNumber();
	MaxFeret=Dialog.getNumber();
	MinCentro=Dialog.getNumber();
	MaxCentro=Dialog.getNumber();
	OtsuUp=Dialog.getNumber();
	xCor=Dialog.getNumber();
	yCor=Dialog.getNumber();
if (MinCirc >= 1)			exit("Minimum circularity should be smaller than 1");
if (MinCentro >= MaxCentro)		exit("Minimum centromere size should be smaller than maximum centromere size");



dir = getDirectory("Choose Base Directory ");

outf="_OUTPUT";
out=dir+outf+File.separator;
File.makeDirectory(out);

corner=(SquareSize-1)/2;
roiManager("reset");
Ch=newArray(RefCh,DataCh,DapiCh);
RDM=newArray("Ref","Data","Mask");

run("Close All");

listFiles(dir);

if(File.exists(dir+"OUTPUT_"+File.separator+"OUTPUT_.txt")==1)		File.delete(dir+"OUTPUT_"+File.separator+"OUTPUT_.txt");
if(File.exists(dir+"OUTPUT_"+File.separator+"PRJ_.txt")==1)			File.delete(dir+"OUTPUT_"+File.separator+"PRJ_.txt");
if(File.exists(dir+"OUTPUT_"+File.separator+"ROI_.txt")==1)			File.delete(dir+"OUTPUT_"+File.separator+"ROI_.txt");
selectWindow("B&C");
run("Close");
selectWindow("Log");
run("Close");
selectWindow("ROI Manager");
run("Close");





///////////////////////////FUNCTIONS///////////////////////////FUNCTIONS///////////////////////////FUNCTIONS///////////////////////////FUNCTIONS///////////////////////////
function listFiles(dir) {

	print("\\Clear");
	if(File.exists(getDirectory("macros")+File.separator+"PrintDateTime.txt")==1)		runMacro("PrintDateTime");
	else{
		getDateAndTime(y, m, dW, dM, h, min, s, ms);
		if(min<10)	min="0"+min;
		print(y,m,dM+"\n"+h+":"+min);
	}
//	print("Filetype: unprojected DV Files, Fast acquisition mode");
//	print("Method: Bandpass; minmax");
	print("CRaQ_ Macro version: "+version);
	print("Please visit http://uic.igc.gulbenkian.pt/micro-macros.htm for newest version of CRaQ_");
	print("ImageJ version: "+getVersion);
	print("Base Directory: ", dir);
	print("Reference Channel: "+Ch[0]);
	print("Data Channel: "+Ch[1]);
	print("DAPI Channel: "+Ch[2]);
	print("");
	print ("Square Size: ", SquareSize);
	print ("Minimum Circularity: ", MinCirc);
	print ("Maximum Ferets Diameter: ", MaxFeret);
	print ("Minimum Centromere Size: ", MinCentro);
	print ("Maximum Centromere Size: ", MaxCentro);
	print ("Threshold Factor: ", OtsuUp);
	print("Chromatic aberration correction: ("+xCor+","+yCor+") [(x,y) difference of reference compared to data]");
	selectWindow("Log");
	saveAs("Text",out+"_R"+Ch[0]+"D"+Ch[1]+"__logfile.txt");
	print("\\Clear") ;

	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/") && indexOf(list[i],outf)<0){
			sdir= dir+list[i];
			list[i]=substring(list[i],0,lengthOf(list[i])-1);
			slist= getFileList(sdir);
			print(list[i]+"\t"+list[i]);
			for (j=0; j<slist.length; j++) {
				if (endsWith(slist[j], ".dv") || endsWith(slist[j], ".tif")){
					dvFile = sdir+slist[j];
					run("Open...", "open=["+dvFile+"] view=[Standard ImageJ] stack_order=Default");
					Deco=indexOf(getTitle,"D3D");
					TotSl=nSlices;
					run("Properties...", "unit=pixel pixel_width=1 pixel_height=1");
					run("Rename...", "title=dvFile");
					//if(nSlices>1)		run("Grouped ZProjector", "group=["+nSlices/TotCh+"] projection=[Max Intensity]");
					if(nSlices>TotCh)		run("Z Project...", "projection=[Max Intensity]");
					else			run("Duplicate...", "title=PRJ duplicate");
					run("Rename...", "title=PRJ");
					selectWindow("dvFile");
					close();
					for (k=0; k<Ch.length; k++){
						if(Ch[k]>0){
							selectWindow("PRJ");
							setSlice(Ch[k]);
							run("Duplicate...", "title="+RDM[k]);
							run("Brightness/Contrast...");
							resetMinAndMax();
						}
					}
					selectWindow("PRJ");
					if(TotCh<TotSl){
						//File.makeDirectory(out+"PRJ_"+list[i]);
						saveAs("Tiff", out+slist[j]+"__PRJ.tif");
					}
					close();
					print("\n=="+slist[j]);
					measure();
					if (roiManager("count")>0) {
						//File.makeDirectory(out+"ROI_"+list[i]);
						roiManager("Save",out+slist[j]+"__ROI.zip")
						roiManager("Deselect");
						roiManager("Delete");
					}
				}
			}
			selectWindow("Log");
			saveAs("Text",out+"_R"+Ch[0]+"D"+Ch[1]+"_"+list[i]+".txt");
			print("\\Clear") ;
		}
	}
}



function measure(){
	count=1;

	if(DapiCh>0 && CroppedCells==0){
		selectWindow("Mask");
		run("Duplicate...", "title=blur");
		run("Gaussian Blur...", "sigma=75");
		imageCalculator("Subtract", "Mask","blur");
		selectWindow("blur");
		close();
		run("Invert");
		getStatistics(AREA,MEAN,MIN,MAX);
		for(i=0;AREA>=getWidth*getHeight;i+=10){
			makeRectangle(0,0,0,0);
			setThreshold(MIN,MAX-i);
			for(j=0;j<getHeight;j+=100)	doWand(0,j);
			getStatistics(AREA,a,b,c);
		}
		run("Convert to Mask");
		run("Fill Holes");
		run("16-bit");
		run("Multiply...", "value=257.000");
	}

	if(DapiCh>0 && CroppedCells==1){
		selectWindow("Mask");
		setAutoThreshold("Default");
		getThreshold(AAA,BBB);
		setThreshold(AAA, BBB*2/3);

		run("Convert to Mask");
		run("16-bit");
		run("Multiply...", "value=257.000");
		run("Invert");
	}

	selectWindow("Ref");
	run("Bandpass Filter...", "filter_large=10 filter_small=1 suppress=None tolerance=5 autoscale");
	if(DapiCh>0)	imageCalculator("AND", "Ref","Mask");
	run("Invert");
	if(is("Inverting LUT"))	run("Invert LUT");
	//run("MultiThresholder", "otsu");
	//getThreshold(lower, upper);
	//setThreshold(lower, upper*OtsuUp);
	setAutoThreshold("Default");
	run("Analyze Particles...", "size="+MinCentro+"-"+MaxCentro+" circularity="+MinCirc+"-1.00 show=Nothing exclude clear");

	selectWindow("Data");
	for (l=0;l<nResults;l++) {
		if (getResult("Feret", l)<MaxFeret){
			x=round(getResult("XM", l));
			y=round(getResult("YM", l));
			cx=x-xCor;cy=y-yCor;
			makeRectangle(x-corner, y-corner, SquareSize, SquareSize);
			getStatistics(area, no, no, no);
			makeRectangle(cx-corner, cy-corner, SquareSize, SquareSize);
			getStatistics(no, mean, min, max);
			if (min>0 && max<65000 && area==(SquareSize*SquareSize)){
				if (max>0)	print (count+"\t"+max-min);
				else		print (count+"\tND");
				count++;
				fillRect(cx-corner, cy-corner, SquareSize, SquareSize);	//########## puts black box over spots, these are then disregarded in the next cycle due to "if(min>0)"
				makeRectangle(cx-corner, cy-corner, SquareSize, SquareSize);
				roiManager("Add");
			}
		}
	}
	selectWindow("Data");
	close();
	selectWindow("Ref");
	close();
	if(DapiCh>0){
		selectWindow("Mask");
		close();
	}
}



//####### VERSION UPDATES //####### VERSION UPDATES //####### VERSION UPDATES //####### VERSION UPDATES //####### VERSION UPDATES //####### 
// v1.11 (Jan 2020):
// fix incompatible plugins (for FiJi):
//  - Grouped Z Projector --> Z Project
//  - MultiThresholder --> setAutoThreshold

// v1.10 (June 2019):
// make available for quantifying over time (use a certain channel from a certain timepoint the reference)

// v1.07 (30 Nov 2011):
// included printing URL of newest version of CRaQ_ in logfile (in line 104).

// v1.06 (25 may 2011):
// included a different kind of DAPI thresholding for the case of cropped single cells. I did this by:
// 1. adding line19 & line29 to pompt whether or not single cells are being analyzed
// 2. added �&& CroppedCells==0� to line168 to ensure that normal pictures are still thresholded in the normal way
// 3. added lines199-209 to do the thresholding in cropped cells (basically dapi is not blur-corrected and then the threshold is set to 2/3 of the autothreshold).

// v1.05 (11 mar 2011):
//fixed a bug in line 134, which didnt allow for analysis of single slice images (no ref or dapi images), by adding line 135

// v1.04 (25 nov 2010):
//added �if(nSlices>1)� to line 134, so that single slice images (already projected, single channel files) also work

// v1.03 (08 nov 2010):
// added a method to prevent cdentromeres that are too close to the side to be counted (i.e. if the square does not completely fit into the picture). I did this by:
// 1. adding �exclude� to line 204 to exclude any particles found on the edges
// 2. excluding squares that are smaller than the input squaresize by adding �&& area==SquareSize*SquareSize� to line 216
// 3. added lines 212 and 213, which create a square that is not corrected for chromatic aberration, which will be the reference to see if the squaresize is correct. This because otherwise random point measurements will not necessarily correlate with actual point measurements
// Due to point 3 (above), in pictures that are corrected for chromatic aberrations (or shifted for random measurements), I will count squares that are smaller than the input squaresize. However, in most cases this function is solely used for measuring random points rather than actually correcting chromatic aberrations and for that reason this is preferred.


// v1.02 (16 oct 2010):		
// removed �&& max>0� from line 214.
// changed line 215 from 	print (count+"\t"+max-min);	-->		if (max>0)print (count+"\t"+max-min);	else print (count+"\tND");


// v1.01 (1 sep 2010):		
// fixed error between spot recognition and roiManager addition		|||	L218: 	makeRectangle(x,y,SquareSize, SquareSize);		-->	makeRectangle(cx-corner, cy-corner, SquareSize, SquareSize);
// changed version number to variable
// added �&& max>0� to line 214 to exclude non-picture centromeres in the case of ChromAb corrector
// added printing of ImageJ version into logfile



