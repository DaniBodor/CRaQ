//####### CRaQ VERSION
version = "v1.11";
//####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //####### //#######


run("Set Measurements...", "area mean min center feret's redirect=None decimal=3");
run("Colors...", "foreground=black background=black selection=green");


choices=newArray("Unprojected DV files: fast acquisition mode","Unprojected DV files: slow acquisition mode","Projected files","TIF files","Deconvolved DVs");
Dialog.create("Set Channels");
	Dialog.addString("Data channel number (use commas (,) to separate multiple inputs","1,2,3",1);
	Dialog.addNumber("Reference channel number",1,0,0,"");
	Dialog.addNumber("DAPI channel number",99,0,0,"large number --> last channel");
	Dialog.addNumber("Total channels",0,0,0," use 0 to auto-detect");
	Dialog.addMessage("");
	Dialog.addNumber("Camera Bitdepth",12,0,0,"usually 12 or 16");
	Dialog.addMessage("");
	Dialog.addCheckbox("Change default parameter settings?",0);
	Dialog.addCheckbox("Cropped cells?",0);
	Dialog.addMessage("");
	
Dialog.show();
	DataCh=Dialog.getString();
	RefCh=Dialog.getNumber();
	DapiCh=Dialog.getNumber();
	TotCh=Dialog.getNumber();
	CameraBitDepth=Dialog.getNumber();
	Change=Dialog.getCheckbox();
	CroppedCells=Dialog.getCheckbox();

if (RefCh == DapiCh){
	exit("Reference and Data channels should be different from DAPI channel");
}
SatPixVal = 1;
for (b = 0; b < CameraBitDepth; b++) {
	SatPixVal *= 2;
}

DataSplit = split(DataCh, ",,");	// using two commas to avoid errors when string ends with comma or consecutive commas are used
DataChArray = newArray(DataSplit.length);
for (i = 0; i < DataSplit.length; i++) {
	DataChArray[i] = parseInt(DataSplit[i]);

	if (isNaN(DataChArray[i])){
		exit("\"" + DataSplit[i] + "\" detected as input for Data channel\n  Only integers are allowed in this field\n  Multiple inputs can be separated by using a comma (,)");
	}
}

Ch = Array.concat(newArray(RefCh,DapiCh),DataChArray);
RMD = newArray(Ch.length); RMD[0] = "Ref";	RMD[1] = "Mask";
for (i = 2; i < RMD.length; i++) {
	RMD[i] = "Data_"+d2s(i-1,0);
}



Dialog.create("Change parameter settings");
	Dialog.addNumber("Square size",7,0,0,"pixels");
	Dialog.addNumber("Minimum Circularity",0.95,2,4,"a.u.");
	Dialog.addNumber("Max Feret's Diameter",7,1,3,"pixels");
	Dialog.addNumber("Min Centromere Size",4,0,2,"pixel");
	Dialog.addNumber("Max Centromere Size",35,0,2,"pixel");
	Dialog.addNumber("Threshold Factor",1.11,2,4,"pixel intensity");
	Dialog.addNumber("Pixels are considered saturated at: ",92,0,2,"% of camera saturation");
	Dialog.addMessage("\nIf known, set the chromatic aberration of the reference channel compared to the data channel.");
	Dialog.addNumber("Chromatic aberration (horizontal): ",0,0,2,"pixels to right");
	Dialog.addNumber("Chromatic aberration (vertical): ",0,0,2,"pixels down");
if (Change == 1) 
	Dialog.show();		//####################keeps defaults if "Change default" is unchecked
	SquareSize=Dialog.getNumber();		corner=(SquareSize-1)/2;
	MinCirc=Dialog.getNumber();
	MaxFeret=Dialog.getNumber();
	MinCentro=Dialog.getNumber();
	MaxCentro=Dialog.getNumber();
	OtsuUp=Dialog.getNumber();
	Saturation = Dialog.getNumber() * SatPixVal / 100;
	xCor=Dialog.getNumber();
	yCor=Dialog.getNumber();
if (MinCirc >= 1)				exit("Minimum circularity was set to" + MinCirc + ".\n Please enter a value between 0 and 1");
if (MinCentro > MaxCentro)		exit("Minimum centromere size ("+MinCentro+") may not be larger than maximum centromere size ("+MaxCentro+")");



run("Close All");
roiManager("reset");


dir = getDirectory("Choose Base Directory ");
outf="_OUTPUT";
out=dir+outf+File.separator;
File.makeDirectory(out);

INITIATING_FUNCTION(dir);

close("B&C");
close("Log");
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
	print("Please visit https://github.com/DaniBodor/CRaQ for updates");
	print("ImageJ version: "+getVersion);
	print("Base Directory: ", dir);
	print("Reference Channel: "+Ch[0]);
	print("Data Channel(s): "+Ch[1]);
	print("DAPI Channel: "+Ch[2]);
	print("");
	print ("Square Size: ", SquareSize);
	print ("Minimum Circularity: ", MinCirc);
	print ("Maximum Ferets Diameter: ", MaxFeret);
	print ("Minimum Centromere Size: ", MinCentro);
	print ("Maximum Centromere Size: ", MaxCentro);
	print ("Threshold Factor: ", OtsuUp);
	print ("Chromatic aberration correction: ("+xCor+","+yCor+") [(x,y) difference of reference compared to data]");
	print ("CameraBitDepth: ", CameraBitDepth);
	print ("Pixel Saturation at: ", Saturation, "arbitrary intensity units");
	selectWindow("Log");
	saveAs("Text",out+"_R"+Ch[0]+"D"+Ch[1]+"__logfile.txt");
	print("\\Clear");
	Table.create("DataTable");

	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/") && indexOf(list[i],outf)<0){
			sdir= dir+list[i];
			DIRname=substring(list[i],0,lengthOf(list[i])-1);
			slist= getFileList(sdir);
			for (j=0; j<slist.length; j++) {
				if (endsWith(slist[j], ".dv") || endsWith(slist[j], ".tif")){
					ImageLoc = sdir+slist[j];
					IMname = slist[j];
					run("Open...", "open=["+ImageLoc+"] view=[Standard ImageJ] stack_order=Default");
					if (TotCh == 0) 		Stack.getDimensions(WIDTH,HEIGHT,   TotCh   ,Zdepth,Tframes);		// read total chanel info from Metadata; everything else unused
					Deco=indexOf(getTitle,"D3D");
					TotSlice=nSlices;
					run("Properties...", "unit=pixel pixel_width=1 pixel_height=1");
					run("Rename...", "title=Image");
					
					if(nSlices>TotCh)		run("Z Project...", "projection=[Max Intensity]");
					else			run("Duplicate...", "title=PRJ duplicate");
					run("Rename...", "title=PRJ");
					selectWindow("Image");
					close();
					for (k=0; k<Ch.length; k++){
						if(Ch[k]>0){
							//waitForUser(Ch[k],RMD[k]);
							selectWindow("PRJ");
							Stack.setChannel(Ch[k]);
							run("Duplicate...", "title="+RMD[k]);
							run("Brightness/Contrast...");
							resetMinAndMax();
							//waitForUser(Ch[k],RMD[k]);
						}
					}
					selectWindow("PRJ");
					if(TotCh<TotSlice){
						saveAs("Tiff", out+slist[j]+"__PRJ.tif");
					}
					close();
					print("\n=="+slist[j]);
					MEASURE_FUNCTION();
					if (roiManager("count")>0) {
						roiManager("Save",out+slist[j]+"__ROI.zip")
						roiManager("reset");
					}
				}
			}
			selectWindow("Log");
			saveAs("Text",out+"_R"+Ch[0]+"D"+Ch[1]+"_"+DIRname+".txt");
			print("\\Clear") ;
		}
	}
}



function MEASURE_FUNCTION(){
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
	if(DapiCh != 0)	imageCalculator("AND", "Ref","Mask");
	run("Invert");
	if(is("Inverting LUT"))	run("Invert LUT");
	setAutoThreshold("Default");
	run("Analyze Particles...", "size="+MinCentro+"-"+MaxCentro+" circularity="+MinCirc+"-1.00 show=Nothing exclude clear");

	for (l=0;l<nResults;l++) {
		if (getResult("Feret", l)<MaxFeret){
			selectWindow("Ref");
			x=round(getResult("XM", l));
			y=round(getResult("YM", l));
			cx=x-xCor;cy=y-yCor;
			makeRectangle(x-corner, y-corner, SquareSize, SquareSize);
			getStatistics(area, no, minRef, no);
			if (minRef>0 && area==(SquareSize*SquareSize)){
				makeRectangle(cx-corner, cy-corner, SquareSize, SquareSize);
				fillRect(cx-corner, cy-corner, SquareSize, SquareSize);	//########## puts black box over spots, these are then disregarded in the next cycle due to "if(min>0)"
				makeRectangle(cx-corner, cy-corner, SquareSize, SquareSize);
				roiManager("Add");
			}
		}
	}
	roiNumber = roiManager("count");
	
	// RESOLVE BY NOT RESETTING TABLE EACH TIME, NOT USING SET COLUMN, BUT USING SET. SEE https://wsr.imagej.net/macros/Sine_Cosine_Table2.txt

	for (data_channels = 0; data_channels < DataChArray.length; data_channels++) {
		columnName = DataChArray[data_channels];
		resArray = newArray(0);
		selectWindow(RMD[data_channels+2]);
		for (roi = 0; roi < roiNumber; roi++) {
			Table.set("Image",roi,IMname);
			Table.set("ROI", roi, roi+1);
			roiManager("select", roi);
			getStatistics(no, DataMean, DataMin, DataMax);
			spot_value = DataMax - DataMin;
			//if (DataMax > Saturation)	resArray = Array.concat(resArray,"Saturated Pixel");
			//else						resArray = Array.concat(resArray,spot_value);
			if (DataMax > Saturation){
				Table.set(columnName, roi, "Saturated Pixel");
			} else {
				Table.set(columnName, roi, spot_value);
			}
			
		}
		Table.update;
	}
	
	
	

	run("Close All");
/*
	selectWindow("Data");
	close();
	selectWindow("Ref");
	close();
	if(DapiCh != 0){
		selectWindow("Mask");
		close();
	}
*/
}



//####### VERSION UPDATES //####### VERSION UPDATES //####### VERSION UPDATES //####### VERSION UPDATES //####### VERSION UPDATES //####### 
// Check github initial commit for version updates from published version