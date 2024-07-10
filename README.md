# Motivations


The aim of this macro is to measure the number of FISH spots in nuclei using Cellpose to segment the cells in Fiji

## How to install

Drag and drop the file into Fiji and click on Run.

## Requirements

This macro requires **PTBIOP** and **IJPB-plugins** from the Fiji plugins updater. Please follow the instructions from their [website](https://github.com/MouseLand/cellpose) to install Cellpose GUI and cite the respective authors.

## How to use

Click on run and modify the GUI according to your experiment. The data are expected to be in a single folder with **Airyscan** on the title. This macro aims to work on confocal data acquired from an airyscan microscope.
<br>The first checkbox allows you to enter into a trial mode where only the first image will be open. Finetune the parameters for the prominence for the detection of the spots and key-in the value that satisfied you. The script will then modify itself to save the keyed-in value as a default parameter.
<br>The other checkboxes are for QC and should be kept ticked. A table with the result will be displayed at the end and should be saved manually.

## Citations

Please cite [Cellpose](https://www.nature.com/articles/s41592-020-01018-x) if you use this macro.

## Updates history
(0.0.1) Segment using Cellpose for individual nuclei
<br>(0.1.0) Add Dialog box
<br>(0.1.1) Add trial checkbox
