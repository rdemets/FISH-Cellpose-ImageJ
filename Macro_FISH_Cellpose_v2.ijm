prominence = 100;
cell_diameter = 180;
// This macro aims to quantify the spots in nuclei using Cellpose
// All function used are available from the stable version of Fiji and PTBIOP IJPB-plugins.
// Requires installation of cellpose through Anaconda



// Macro author R. De Mets
// Version : 0.1.1 , 09/07/2024
// Add trial mode


// Function to read the current macro code from the file into an array of lines

function getCurrentMacroPath() {
    directory = getDirectory("current");
    fileName = "Macro_FISH_Cellpose_v2.ijm";
    return directory + fileName;
}

function readMacroLines(macroPath) {
    if (File.exists(macroPath)) {
        code = File.openAsString(macroPath);
        lines = split(code, "\n");
        return lines;
    } else {
        return newArray();
    }
}

// Function to write the updated lines back to the macro file
function writeMacroLines(macroPath, lines) {
    code = String.join(lines, "\n");
    File.saveString(code, macroPath);
}


// Function to modify a specific line in the array of lines
function modifyLine(lines, lineNumber, newContent) {
    if (lineNumber < lengthOf(lines)) {
        lines[lineNumber] = newContent;
    }
}



//setBatchMode(true);
run("Close All");
print("\\Clear");
//prominence = 100;
	
	
	
Dialog.create("GUI");
Dialog.addDirectory("Source image path","");
//Dialog.addNumber("Cell Diameter (px)",cell_diameter);
Dialog.addNumber("Prominence for spots",prominence);
Dialog.addCheckbox("Parameters trial mode ?", false);
Dialog.addCheckbox("Remove nuclei touching the borders ?", true);
Dialog.addCheckbox("Save cellpose segmentation ?", true);
Dialog.addCheckbox("Save spot detection ?", true);
	
Dialog.show();
	

dirS = Dialog.getString;
//cell_diameter = Dialog.getNumber();
prominence = Dialog.getNumber();
trial = Dialog.getCheckbox;
	
remove_borders = Dialog.getCheckbox;
save_cellpose = Dialog.getCheckbox;
save_spots = Dialog.getCheckbox;
filenames = getFileList(dirS);






ImageTitle = newArray();
CellNumber = newArray();
SpotTotal = newArray();
// Open each file
for (i = 0; i < filenames.length; i++) {
// Open file if CZI
	currFile = dirS+filenames[i];
	if(endsWith(currFile, ".czi") && matches(filenames[i],".*Airyscan.*")) { // process czi files matching regex
		//open(currFile);
		run("Clear Results");
		roiManager("reset");
		run("Bio-Formats Windowless Importer", "open=[" + currFile+"]");
		window_title = getTitle();
		getDimensions(width, height, channels, slices, frames);
		getPixelSize(unit, pw, ph, pd);
		title = File.nameWithoutExtension;
		print(window_title);
			
		run("Set Measurements...", "area mean centroid shape redirect=None decimal=2");
		run("Z Project...", "projection=[Max Intensity]");
		run("Make Composite");
		saveAs("Tiff", dirS+title+"_MAX.tif");
		rename("Image_max");
		
		
		if (trial==false) {

			// Segmenting nuclei
			run("Duplicate...", "duplicate channels=2");
			rename("Nuclei");
			run("Segment Nuclei Adv.", "nuclei_channel=1 diameter="+cell_diameter+" cellproba_threshold=0.0 flow_threshold=0.5 dimensionmode=2D");
				
			if (remove_borders) {
				run("Remove Border Labels", "left right top bottom");
			}
				
			rename("Cellpose-result");
			run("Label image to ROIs", "rm=[RoiManager[size=100, visible=true]]");
	
			if (save_cellpose) {
				roi_cellpose_Save = dirS + title+"_rois.zip";
				roiManager("Save", roi_cellpose_Save);
			}
	
			// Retrieve number of detected nuclei
			NNuc = roiManager("count");
			Spots = newArray(NNuc);
		}
		// Counting spots per nucleus
		// Segmenting FISH spots
		selectImage("Image_max");
		run("Duplicate...", "duplicate channels=1");
		rename("FISH");
		run("FeatureJ Laplacian", "compute smoothing=1.5");
		rename("Filtered");
			
		if (trial) {
			macroPath = getCurrentMacroPath();
			run("Find Maxima...");
			prominence=getNumber("Which prominence did you set?", prominence);
			lines = readMacroLines(macroPath);
			// Determine which line to modify and what the new content should be
			lineToModify = 0; // Assuming the second line should be modified (index starts at 0)
			newContent = "prominence = " +prominence+";";

			// Modify the specified line
			modifyLine(lines, lineToModify, newContent);
				
			// Print the updated lines for debugging purposes
			//print(join(lines, "\n"));
				
			// Write the updated lines back to the file
			writeMacroLines(macroPath, lines);
			i = filenames.length;
			break;
		}
		
			
		run("Find Maxima...", "prominence="+prominence+" output=[Single Points] light");
		rename("Spot");
		selectImage("FISH");
		close();
		selectImage("Filtered");
		close();
		selectImage("Spot");
			
		if (save_spots) {
			run("Duplicate...", " ");
			// Remove out of cells signal
			roiManager("Combine");
			run("Clear Outside");
			roiManager("Deselect");
			run("Dilate");
			run("Dilate");
			saveAs("Tiff", dirS+title+"_spots.tif");
			close();
		}
			
		for(j=0;j<NNuc;j++)
		{
			roiManager("select",j);
			getRawStatistics(nPixels, mean);
			NSpots = round(mean*nPixels/255);
			Spots[j] = Spots[j]+NSpots;
			
			ImageTitle = Array.concat(ImageTitle, title);
			CellNumber = Array.concat(CellNumber, j);
			SpotTotal = Array.concat(SpotTotal, NSpots);
		}
		close("Spot");
		// Display results
		for(j=0;j<NNuc;j++)
		{
			print("Nucleus "+d2s(j+1,0)+" : "+Spots[j]);
		}
		run("Close All");
		roiManager("reset");
	}
}
Array.show(ImageTitle, CellNumber,SpotTotal);
Dialog.create("Done");
Dialog.show();
//}

		
//Array.print(Spots);
