# DynBioNet
A shiny app to visualize and explore dynamic (temporal) biological networks (such as correlation networks and others).<br>
Cite us as: Huang, X. and Mora, A. (2021), DynBioNet –Understanding disease through visualization and analysis of dynamic biological networks, Under review.<br>

## 1. Install DynBioNet:
1.1. From Github:<br>
1.2. From Docker:<br>
1.3. From Virtual Machine:<br>

## 2. Upload data:
2.1. The input files: Design file, expression data file, edges (network) file, and module file:<br>
2.2. Browsing the four input files from DynBioNet:<br>

## 3. KEGG pathway and GO term subnetwork analysis:
3.1. Biological example.<br>
3.2. Input data.<br>
3.3. Network visualization.<br>
3.4. Node information.<br>
3.5. Edge information.<br>
3.6. Network coordination scores.<br>
3.7. Download.<br>

## 4. Gene neighborhood analysis:
4.1. Biological example.<br>
4.2. Input data.<br>
4.3. Network visualization.<br>
4.4. Node information.<br>
4.5. Edge information.<br>
4.6. Network coordination scores.<br>
4.7. Time neighborhood membership.<br>
4.8. Download.<br>

## 5. Alluvial diagram:

## 6. Help us improving DynBioNet:
6.1. Report bugs: You can report any bugs or mistakes to our email:<br><br>
6.2. Adding new functionality:<br>
* global.R file: This file calls the required libraries and install the data files if they haven't been installed yet. Please update it if you are using new libraries or installing new datasets.<br>
* server.R file: This file<br>
* ui.R file: This file<br>
* ui folder: This folder contains one R script for each of the current tabs of DynBioNet, which contain the main computations for each tab. If you add a new tab, please add a new R file here.<br>
* Functions folder: This folder contains all the functions for very specific tasks such as getting data or plotting data, which are called by the main routines. Place here any new function that will be called by the main routines.<br>

*Last reviewed: Sep.24th, 2021*
