// needs PTBIOP for cellpose
// needs CLIJ2 for label expansion


// This macro aims to quantify the spots in nuclei using Cellpose
// All function used are available from the stable version of Fiji and PTBIOP CLIJ2-plugins.
// Requires installation of cellpose through Anaconda



// Macro author R. De Mets
// Version : 0.1.1 , 19/08/2024
// Add trial mode
// Filter small cells commented
// Works with NVIDIA 2080Ti GPU, need to be tested on other GPU


//setBatchMode(true);
run("Close All");
print("\\Clear");
prominence2 = 150;
prominence3 = 150;
min_cell_size = 20; //for filtering cells



Dialog.create("GUI");
Dialog.addDirectory("Source image path","");
Dialog.show();

dirS = Dialog.getString;
filenames = getFileList(dirS);

ImageTitle = newArray();
CellNumber = newArray();
Spot_ch1 = newArray();
Spot_ch2 = newArray();

// Open each file
for (i = 0; i < filenames.length; i++) {
//for (i = 0; i < 1; i++) {
// Open file if CZI
	currFile = dirS+filenames[i];
	if(endsWith(currFile, ".czi")) { // process czi files matching regex
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
		
		run("Duplicate...", "duplicate channels=1");
		rename("Nuclei");

		run("Cellpose Advanced", "diameter=30 cellproba_threshold=0.0 flow_threshold=0.4 anisotropy=1.0 diam_threshold=12.0 model=cyto3 nuclei_channel=2 cyto_channel=1 dimensionmode=2D stitch_threshold=-1.0 omni=false cluster=false additional_flags=");
		run("Remove Border Labels", "left right top bottom");
		run("glasbey_on_dark");
		saveAs("png", dirS+title+"_labels.png");
		rename("Cellpose-result");
		
		// dilate labels
		run("CLIJ2 Macro Extensions", "cl_device=[NVIDIA GeForce RTX 2080 Ti]");
		image1 = "Cellpose-result";
		Ext.CLIJ2_push(image1);
		image2 = "dilated_labels";
		radius = 20.0;
		Ext.CLIJ2_dilateLabels(image1, image2, radius);
		Ext.CLIJ2_pull(image2);
		Ext.CLIJ_clear();
		run("Label image to ROIs", "rm=[RoiManager[size=2000, visible=true]]");
		roi_cellpose_Save = dirS + title+"_rois.zip";
		roiManager("Save", roi_cellpose_Save);
		
//		for (im = roiManager("count"); im > 0; im--) {
//			roiManager("Select", im-1);
//			roiManager("Measure");
//			area_temp = getResult("Area", 0);
//			run("Clear Results");
//			if (area_temp<min_cell_size) {
//				roiManager("Delete");
//			}
//		}
		
		// Retrieve number of detected nuclei
		NNuc = roiManager("count");
		Spots = newArray(NNuc);
		
		for (ch = 2; ch <= channels; ch++) {
			// Segmenting FISH spots
			selectImage("Image_max");
			run("Duplicate...", "duplicate channels="+ch);
			rename("FISH");
			run("FeatureJ Laplacian", "compute smoothing=2");
			rename("Filtered");
			if (ch==2) {
				run("Find Maxima...", "prominence="+prominence2+" output=[Single Points] light");
			}
			else{
				run("Find Maxima...", "prominence="+prominence3+" output=[Single Points] light");
			}
			rename("Spot");
			selectImage("FISH");
			close();
			selectImage("Filtered");
			close();
			selectImage("Spot");
			
			// for saving purpose
			run("Duplicate...", " ");
			
			rename("temp");
			run("Dilate");
			run("Invert LUT");
			roiManager("Deselect");
			roiManager("Combine");
			run("Clear Outside");
			roiManager("Deselect");
			saveAs("Tiff", dirS+title+"_spots_ch"+ch+".tif");
			close();
			
			for(j=0;j<NNuc;j++){
				roiManager("select",j);
				getRawStatistics(nPixels, mean);
				NSpots = round(mean*nPixels/255);
				Spots[j] = Spots[j]+NSpots;
				
				if (ch==2) {
					ImageTitle = Array.concat(ImageTitle, title);
					CellNumber = Array.concat(CellNumber, j);
					Spot_ch1 = Array.concat(Spot_ch1, NSpots);
				}
				else{
					Spot_ch2 = Array.concat(Spot_ch2, NSpots);
				}
			}
			close("Spot");
			// Display results
			for(j=0;j<NNuc;j++){
				print("Nucleus "+d2s(j+1,0)+" : "+Spots[j]);
			}
		}
		run("Close All");
		roiManager("reset");
	}
}
		
Array.show(ImageTitle, CellNumber,Spot_ch1, Spot_ch2);	
Dialog.create("Done");
Dialog.show();
		
		