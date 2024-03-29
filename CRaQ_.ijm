//####### CRaQ VERSION
version = "v1.3";
//####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //#######


run("Set Measurements...", "area mean min center feret's redirect=None decimal=3");
run("Colors...", "foreground=black background=black selection=green");


choices=newArray("Unprojected DV files: fast acquisition mode","Unprojected DV files: slow acquisition mode","Projected files","TIF files","Deconvolved DVs");
Dialog.create("Set Channels");
	Dialog.addString("Data channel number (use commas (,) to separate multiple inputs","1,2,3,4",8);
	Dialog.addNumber("Reference channel number",4,0,0,"");
	Dialog.addNumber("DAPI channel number",1,0,0,"large number --> last channel");
	Dialog.addNumber("Total channels",0,0,0," use 0 to auto-detect");
	Dialog.addMessage("");
	Dialog.addNumber("Square size",5,0,0,"pixels");
	Dialog.addMessage("");
	Dialog.addNumber("Camera Bitdepth",16,0,0,"usually 12 or 16; used for determining overexposed pixels");
	Dialog.addMessage("");
	Dialog.addCheckbox("Chromatic aberration correction using MultiStackReg",1);
	Dialog.addCheckbox("Change default parameter settings",0);
	Dialog.addCheckbox("Cropped cells",0);
	Dialog.addMessage("");
	
Dialog.show();
	DataCh=Dialog.getString();
	RefCh=Dialog.getNumber();
	DapiCh=Dialog.getNumber();
	TotCh=Dialog.getNumber();
	RoiSize=Dialog.getNumber();
		corner=(RoiSize-1)/2;
	CameraBitDepth=Dialog.getNumber();
	AutoChromAbCorr=Dialog.getCheckbox();
	Change=Dialog.getCheckbox();
	CroppedCells=Dialog.getCheckbox();


if (RefCh == DapiCh)	exit("Reference and Data channels should be different from DAPI channel");
SatPixVal = 1;
for (b = 0; b < CameraBitDepth; b++) SatPixVal *= 2;

Dialog.create("Change parameter settings");
	Dialog.addNumber("Ring Width (for Hoffman corrections)",1,0,0,"pixels");
	Dialog.addNumber("Minimum Circularity",0.95,2,4,"a.u.");
	Dialog.addNumber("Max Feret's Diameter",7,1,3,"pixels");
	Dialog.addNumber("Min Centromere Size",4,0,2,"pixel");
	Dialog.addNumber("Max Centromere Size",35,0,2,"pixel");
	ThreshTypes = getList("threshold.methods");
	Dialog.addChoice("Choose Threshold Type for spot recognition", ThreshTypes, ThreshTypes[0]);
	Dialog.addNumber("Threshold Factor",1.00,2,4,"pixel intensity");
	Dialog.addNumber("Pixels are considered saturated at: ",92,0,2,"% of camera saturation");
	Dialog.addMessage("\nIf known, set the chromatic aberration of the reference channel compared to the data channel.");
	Dialog.addMessage("If automatic corrections are used, this should be left at (0,0).");
	Dialog.addNumber("Chromatic aberration (horizontal): ",0,0,2,"pixels to right");
	Dialog.addNumber("Chromatic aberration (vertical): ",0,0,2,"pixels down");
if (Change == 1) 
	Dialog.show();		//####################keeps defaults if "Change default" is unchecked
	RingWidth=Dialog.getNumber();
	MinCirc=Dialog.getNumber();
	MaxFeret=Dialog.getNumber();
	MinCentro=Dialog.getNumber();
	MaxCentro=Dialog.getNumber();
	ThreshType=Dialog.getChoice();
	ThreshFact=Dialog.getNumber();
	SatPercent = Dialog.getNumber();
	xCor=Dialog.getNumber();
	yCor=Dialog.getNumber();
if (MinCirc >= 1)				exit("Minimum circularity was set to" + MinCirc + ".\n Please enter a value between 0 and 1");
if (MinCentro > MaxCentro)		exit("Minimum centromere size ("+MinCentro+") may not be larger than maximum centromere size ("+MaxCentro+")");

Saturation = floor(SatPercent * SatPixVal / 100);

// Make Data input correlate to channel numbers
if (parseInt(DataCh) > 99){
	DataChArray = newArray(lengthOf(DataCh));
	for (d=0;d<lengthOf(DataCh);d++){
		DataChArray[d] = parseInt(substring(DataCh, d, d+1));
	}
}
else{
	DataSplit = split(DataCh, ",,");	// using two commas to avoid errors when string ends with comma or consecutive commas are used
	DataChArray = newArray(DataSplit.length);
	for (i = 0; i < DataSplit.length; i++) {
		DataChArray[i] = parseInt(DataSplit[i]);
	
		if (isNaN(DataChArray[i])){
			exit("\"" + DataSplit[i] + "\" detected as input for Data channel\n  Only integers are allowed in this field\n  Multiple inputs can be separated by using a comma (,)");
		}
	}
}
Ch = Array.concat(newArray(RefCh,DapiCh),DataChArray);
RMD = newArray(Ch.length); RMD[0] = "Ref";	RMD[1] = "Mask";
for (i = 2; i < RMD.length; i++) {
	RMD[i] = "Data_"+d2s(i-1,0);
}



run("Close All");
roiManager("reset");


dir = getDirectory("Choose Base Directory ");
outf="_CRaQ_output";
out=dir+outf+File.separator;
File.makeDirectory(out);

INITIATING_FUNCTION(dir);

close("B&C");
//close("Log");
close("ROI Manager");
run("Close All");
waitForUser("CRaQ done");


///////////////////////////FUNCTIONS///////////////////////////FUNCTIONS///////////////////////////FUNCTIONS///////////////////////////FUNCTIONS///////////////////////////
function INITIATING_FUNCTION(dir) {

	print("\\Clear");
	
	if(File.exists(getDirectory("macros")+File.separator+"PrintDateTime.txt")==1)		runMacro("PrintDateTime");
	else{
		getDateAndTime(y, m, dW, dM, h, min, s, ms);
		if(min<10)	min="0"+min;
		print(y,m,dM+"\n"+h+":"+min);
	}

	print("CRaQ_ Macro version: "+version);
	print("Updates will be published on:\nhttps://github.com/DaniBodor/CRaQ/");
	print("ImageJ version: "+getVersion);
	print("Base Directory: ", dir);
	print("Data Channel(s): "+DataCh);
	print("Reference Channel: "+RefCh);
	print("DAPI Channel: "+DapiCh);
	print("");
	print ("ROI Size: ", RoiSize);
	print ("Ring Width (for Hoffman corrections): ", RingWidth);
	print ("Minimum Circularity: ", MinCirc);
	print ("Maximum Ferets Diameter: ", MaxFeret);
	print ("Minimum Centromere Size: ", MinCentro);
	print ("Maximum Centromere Size: ", MaxCentro);
	print ("Threshold type for spot recognition: ", ThreshType);
	print ("Threshold Factor: ", ThreshFact);
	if (AutoChromAbCorr == 1)	answer="Yes"; else answer="No";
	print ("Automatic correction of chromatic aberration using MultiStackReg: "+answer);
	print ("User-defined chromatic aberration correction: ("+xCor+","+yCor+") [(x,y) difference of reference compared to data]");
	print ("CameraBitDepth: ", CameraBitDepth);
	print ("Pixel Saturation at: ", Saturation, "arbitrary intensity units");
	selectWindow("Log");
	saveAs("Text",out+"__logfile.txt");



	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/") && indexOf(list[i],outf)<0 && startsWith(list[i], "_") == 0){
			sdir= dir+list[i];
			DIRname=substring(list[i],0,lengthOf(list[i])-1);
			Table.create("DataTable");
			rowOffset = 0;
			slist= getFileList(sdir);
			for (j=0; j<slist.length; j++) {
				if (endsWith(slist[j], ".dv") || endsWith(slist[j], ".tif")){
					ImageLoc = sdir+slist[j];
					IMname = slist[j];
					run("Open...", "open=["+ImageLoc+"] view=[Standard ImageJ] stack_order=Default");
					roiManager("reset");
					if (TotCh == 0) 		Stack.getDimensions(WIDTH,HEIGHT,   TotCh   ,Zdepth,Tframes);		// read total chanel info from Metadata; everything else unused
					Deco=indexOf(getTitle,"D3D");
					TotSlice=nSlices;
					run("Properties...", "unit=pixel pixel_width=1 pixel_height=1");
					run("Rename...", "title=Image");
					
					if(nSlices>TotCh)		run("Z Project...", "projection=[Max Intensity]");
					else			run("Duplicate...", "title=PRJ duplicate");
					run("Rename...", "title=PRJ");
					
					// auto-chromatic aberration correction
					if (AutoChromAbCorr == 1){
						run("MultiStackReg", "stack_1=PRJ action_1=Align file_1=[] stack_2=None action_2=Ignore file_2=[] transformation=Translation");
						run("Z Project...", "projection=[Min Intensity]");
						MinPRJ = getTitle();
						doWand(0,0);
						run("Make Inverse");
						//waitForUser(IMname);
						selectWindow("PRJ");
						run("Restore Selection");
						run("Crop");
						close(MinPRJ);
					}
					
					close("Image");
					for (k=0; k<Ch.length; k++){
						if(Ch[k]>0){
							selectWindow("PRJ");
							Stack.setChannel(Ch[k]);
							run("Duplicate...", "title="+RMD[k]);
							run("Brightness/Contrast...");
							resetMinAndMax();
						}
					}
					selectWindow("PRJ");
					saveAs("Tiff", out+slist[j]+"__PRJ.tif");
					close();
					//print("\n=="+slist[j]);
					rowOffset = MEASURE_FUNCTION(rowOffset);
					if (roiManager("count")>0) {
						roiManager("Save",out+slist[j]+"__ROI.zip")
						roiManager("reset");
					}
					run("Close All");
				}
			}
/*			selectWindow("Log");
			saveAs("Text",out+"_"+DIRname+".txt");
			print("\\Clear") ;
*/			
			selectWindow("DataTable");
			saveAs("Results",out+"_"+DIRname+".csv");
//			waitForUser(Table.title);
			close("_"+DIRname+".csv");
//			waitForUser("_"+DIRname+".csv");
		}
	}
}



function MEASURE_FUNCTION(rowOffset){
	count=1;

	if(DapiCh != 0 && CroppedCells == 0){
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

	if( DapiCh != 0 && CroppedCells == 1){
		selectWindow("Mask");
		setAutoThreshold("Default dark");
		getThreshold(AAA,BBB);
		setThreshold(AAA*2/3, BBB);

		run("Convert to Mask");
		run("Fill Holes");
		run("16-bit");
		run("Multiply...", "value=257.000");
		//run("Invert");
	}

	selectWindow("Ref");
	run("Bandpass Filter...", "filter_large=10 filter_small=1 suppress=None tolerance=5 autoscale");
	if(DapiCh != 0)	imageCalculator("AND", "Ref","Mask");
	run("Invert");
	if(is("Inverting LUT"))	run("Invert LUT");
//waitForUser("test 1 $$$$$$$$$$$$");
	setAutoThreshold(ThreshType +" dark");
	getThreshold(minThresh,maxThresh);
	setThreshold(0 , minThresh * ThreshFact);
	run("Analyze Particles...", "size="+MinCentro+"-"+MaxCentro+" circularity="+MinCirc+"-1.00 show=Nothing exclude clear");
//waitForUser("test 2 $$$$$$$$$$$$" + minThresh +", " + ThreshFact);
	makeOval	(0,0, RoiSize, RoiSize);
	getStatistics(TrueOvalArea); 

	for (l=0;l<nResults;l++) {
		if (getResult("Feret", l)<MaxFeret){
			selectWindow("Ref");
			x=round(getResult("XM", l));
			y=round(getResult("YM", l));
			cx=x-xCor;cy=y-yCor;		// chromatic aberration correction
			makeOval	(cx-corner, cy-corner, RoiSize, RoiSize);
			getStatistics(area, no, minRef, no);
			if (minRef>0 && area==TrueOvalArea){
				roiManager("Add");
				fillOval(cx-corner, cy-corner, RoiSize, RoiSize);	//########## puts black box over spots, these are then disregarded in the next cycle due to "if(minRef>0)"
				// would be nice to add sth to make it exclude both boxes rather than just the later one
				// this would be via a new b/w image with boxes (?use roimanager-fill, then doWand and check for size?)
			}
		}
	}
	roiNumber = roiManager("count");
//waitForUser("test 3 $$$$$$$$$$$$\n roi count: "+roiNumber);
	
	for (data_channels = 0; data_channels < DataChArray.length; data_channels++) {
		columnName = "Ch" + DataChArray[data_channels];
		testColName = columnName+"_MaxMin";
		resArray = newArray(0);
		selectWindow(RMD[data_channels+2]);
		selectWindow("DataTable");
		for (roi = 0; roi < roiNumber; roi++) {
			row = roi + rowOffset;
			Table.set("Image",row, IMname);
			Table.set("ROI", row, roi+1);
			roiManager("select", roi);
			getStatistics(DataArea, DataMean, DataMin, DataMax);
			MaxMin_value = DataMax - DataMin;
			
			getSelectionBounds(Rx,Ry,Rw,Rh);
			makeOval(Rx-RingWidth, Ry-RingWidth, Rw+2*RingWidth, Rh+2*RingWidth);
			getStatistics(LargeArea, LargeMean, LargeMin, LargeMax);
			
			DataIntDens  = DataArea  * DataMean;
			LargeIntDens = LargeArea * LargeMean;
			RingArea = LargeArea-DataArea;
			RingIntDens = LargeIntDens-DataIntDens;
			RingMean = RingIntDens/RingArea;
			HoffmanSignal = DataMean - RingMean;
			
			if (LargeMax > Saturation){
				Table.set(columnName, row, "Saturated Pixel");
			} else {
				Table.set(testColName, row, MaxMin_value);
				Table.set(columnName, row, HoffmanSignal);
			}
			
		}
		Table.update;
	}
	rowOffset += roiNumber;
	return rowOffset;
}


function DataInputToChannelArray(){
	// make Data input readable my code

}


//####### VERSION UPDATES //####### VERSION UPDATES //####### VERSION UPDATES //####### VERSION UPDATES //####### VERSION UPDATES //####### 
// Check github initial commit for version updates from published version
/*
v1.3 updates
- changes relating to default thresholding being dark background or dark forground
- minor changes to settings dialogs


*/