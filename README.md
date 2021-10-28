# DynBioNet
A shiny app to visualize and explore dynamic (temporal) biological networks (such as correlation networks and others).<br>
Cite us as: Huang, X. and Mora, A. (2021), DynBioNet –Understanding disease through visualization and analysis of dynamic biological networks, Under review.<br>

## 1. Install DynBioNet:
### 1.1. From Github:  https://github.com/mora-lab/DynBioNet<br>

Of course, you could run this shinyApp directly using `shiny::runApp("mora-lab/DynBioNet")` with R. But it will re-download data from [zenodo](https://zenodo.org/record/5336148#.YXoqPp7P2Uk) when you run this shiny each time. Therefore, we recommand you run this shinyApp using `shiny::runApp()` after downloading the repository to avoid the need to download data each time.

### 1.2. From Docker: https://hub.docker.com/r/moralab/dynbionet<br>

Run command in terminal

```shell
sudo docker run -d \
    --publish=3838:3838 \
    --name dynbionet \
     moralab/dynbionet:latest
```

After run the command, you can visit http://localhost:3838/DynBioNet/ to using the shiny app.

The scripts of DynBioNet locate in `srv/shiny-server/` folder in the container.

### 1.3. From Virtual Machine: https://zenodo.org/deposit/5539480<br>

Download `DynBioNet-VM.ova` and import this VirtualBox using Oracle [VM VirtualBox](https://www.virtualbox.org/). 

After start this VirtualBox, log in using `moralab` as user and password, open the Firefox browser can see the DynBioNet interface. Or visit the address http://localhost:3838/DynBioNet/.



## 2. Upload data:
### 2.1. The input files

The input files has design file, expression data file, edges(network) file, module file. We made example input files at https://zenodo.org/record/5336148#.YXoqPp7P2Uk.

- **Design file** is a CSV file which has `sample`, `group` and `timepoint` columns. The `timepoint` column should made time character ordered as you want. For example, `3 months` sets `M03` to replace `M3`.
- **Expression data file** is for plot gene expression violin figure. The first column is `gene` which has the same of gene identifier of edges file.

- **Edges (network) file** is a CSV file which has `fromNode`, `toNode`, `weight`, `timepoint`, `group` column. We suggest using SYMBOL gene identifier for `fromeNode` and `toNode`. Edges file can be merged from the results of the function `exportNetworkToCytoscape()` of `WGCNA` package. This file designs two nodes (genes) has relationship over time.

- **Module file** is to plot alluvial diagram. Module file has `nodeName`, `timepoint`, `group` and `module` columns. <br>

  

### 2.2. Browsing the four input files from DynBioNet:<br>

After you submit all files, the table of your corresponding files will be displayed on the right side of the page `Upload your data`. We set the size of a single file less than 500MB in `global.R`  file.



## 3. KEGG pathway and GO term subnetwork analysis:
### 3.1. Biological example. <br>

The networks for genes in `Human cytomegalovirus infection` KEGG pathway over time with COPD smoker group.

<img src="README.assets/Human-cytomegalovirus-infection.png" alt="Human-cytomegalovirus-infection" style="zoom: 25%;" />



### 3.2. Input data. <br>

- **Select your data**: The options from your uploaded data. We set an example option is `COPD-data` .
- **KEGG ID or KEGG pathway**: After you upload the `edges file`, the shiny app will automatically match genes to KEGG pathways and product the options. You can input one or more KEGG ID (or description) to filter the genes. If you didn't input KEGG ID or description, it will choose all genes.
- **GO ID or GO term**: After you upload the `edges file`, the shiny app will automatically match genes to GO terms and product the options. You can input one or more GO ID (or term) to filter the genes.  If you didn't input any GO ID or term, it will choose all genes.
- **Groups**: The options are from `group` column in`design file` you uploaded. 
- **Timepoints**: The options are from `timepoint` column in `design file` you uploaded. 
- **Weight:** The slider can be set the maximum and minimum. The limit values are from `weight` in `edges file` . If the `weight` column not in the `edge file`, it will not show this slider. As default, it will filter all weights of edges with timepoints or groups.
- **Plot**: It has three options. `genes to genes` plots genes relationships. `genes to KEGG` plots genes from KEGG pathway. `genes to GO` plots genes from GO. You can choose  one or more options. If you didn't choose option, it will not plot network.

### 3.3. Network visualization. <br>

Network plot by `visNewtwork` R package. You can zoom in and zoom out, move, edit this network. There also support download the plot as you see.

- **Edit**: When you selected one node and click `Edit`, you can `Add Node`, `Add Edge`, `Edit Node` and `Delete selected` node. When you selected one edge, you can `Add Edge`, `Edit Edge` and `Delete selected` edge.
- **Move**: you can move nodes and edges as network form you want. When your mouse move to the node, it will show you the node details. It is the same of moving mouse to the edge.
- **Colors**: When you only choose one group, different colors nodes means the nodes have different type edges, while different colors edges means the different type edges. We set the edges type from `timepoint` and `group` in `edge file`.



### 3.4. Node information. <br>

In the bottle of the shiny interface, `Node information` has `Gene Node`, `KEGG Node`, `GO Node`, and `Gene Expression` subtable.

- **Gene Node**: to record the genes information in the network plot.
- **KEGG Node**: to record the KEGG information in the network plot.
- **GO Node**: to record the GO information in the network plot.
- **Gene Expression**: using data from `expression data file` to plot violin figure when your mouse move to gene node in the network.

### 3.5. Edge information. <br>

**Edge information** record all edge information in the network. 

### 3.6. Network coordination scores. <br>

The tab collect genes number, KEGG number, GO number, edges number and others.

### 3.7. Download. <br>

The `Download`  tab supports download excel file of `gene nodes`,  `KEGG nodes`, `GO nodes` and `edges`  information.

## 4. Gene neighborhood analysis:
### 4.1. Biological example.<br>

The networks for `IL1β` genes over time with COPD smoker group. 

<img src="README.assets/network-il1b.png" alt="network-il1b" style="zoom:25%;" />

### 4.2. Input data.<br>

- **Select your data**: Same of `Select your data` in the part `3.2. Input data`
- **Gene symbol or entrezid**: Specify one or more genes to obtain the relationships associated with them.
- **Groups**: Same of `Groups` in the part `3.2. Input data`
- **Timepoints**: Same of `Timepoints` in the part `3.2. Input data`
- **Weights**: Same of `Weights` in the part `3.2. Input data`
- **Plot**: Same of `Plot` in the part `3.2. Input data`

### 4.3. Network visualization.<br>

Same of the part `3.3. Network visualization`.

### 4.4. Node information.<br>

Same of the part `3.4. Node information`.

### 4.5. Edge information.<br>

**Edge information** record all edge information in the network. 

### 4.6. Network coordination scores.<br>

The tab collect genes number, KEGG number, GO number, edges number and others.

### 4.7. Time neighborhood membership.<br>

Specify one gene neighborhood memberships over time with specify group in one table.

### 4.8. Download.<br>

The `Download`  tab supports download excel file of `gene nodes`,  `KEGG nodes`, `GO nodes` and `edges`  information.



## 5. Alluvial diagram:

The alluvial diagram depicts the changes in the clustering of genes over time with specify group.

<img src="README.assets/Alluvial-diagram.png" alt="Alluvial-diagram" style="zoom:40%;" />

## 6. Help us improving DynBioNet:
### 6.1. Report bugs: You can report any bugs or mistakes to our email:<br>

Huang Xiaowei: h15016211223@163.com

Antonio Mora: antoniocmora@gzhmu.edu.cn 

### 6.2. Adding new functionality:<br>

* `global.R` file: This file calls the required libraries and install the data files if they haven't been installed yet. Please update it if you are using new libraries or installing new datasets.<br>
* `server.R` file: This file included all server functions for the DynBioNet.<br>
* `ui.R` file: This file defined all interface for the DynBioNet.<br>
* `ui folder`: This folder contains one R script for each of the current tabs of DynBioNet, which contain the main computations for each tab. If you add a new tab, please add a new R file here.<br>
* `Functions folder:` This folder contains all the functions for very specific tasks such as getting data or plotting data, which are called by the main routines. Place here any new function that will be called by the main routines.<br>

*Last reviewed: Oct. 28th, 2021*
