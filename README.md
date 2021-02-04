# OpenSeqSLAM2.0 Toolbox

OpenSeqSLAM2.0 is a MATLAB toolbox that allows users to thoroughly explore the SeqSLAM method in addressing the visual place recognition problem. The visual place recognition problem is centred around recognising a previously traversed route, regardless of whether it is seen during the day or night, in clear or inclement conditions, or in summer or winter. Recognising previously traversed routes is a crucial capability of navigating robots. Through the graphical interfaces packaged in OpenSeqSLAM2 users are able to:

- explore a number of previously published variations to the SeqSLAM method (including search and match selection methods);
- visually track progress;
- interactively tune parameters;
- dynamically reconfigure matching parameters while viewing results;
- explore precision-recall statistics;
- visualise difference matrices, match sequence images, and image pre-processing steps;
- view and export matching videos;
- automatically optimise selection thresholds against a ground truth;
- sweep any numeric parameter value through a batch operation mode; and
- operate in headless mode with parallelisation available.

The toolbox is open-source and downloadable from the [releases tab](https://github.com/qcr/openseqslam2/releases). All we ask is that if you use OpenSeqSLAM2 in any academic work, that you include a reference to corresponding publication (bibtex is available at the bottom of the page).

## How to use the toolbox

The toolbox is designed to be simple to use (it runs out of the box without any initial configuration required). To run the toolbox, simple run the command below (with the toolbox root directory in your MATLAB path):

```matlab
OpenSeqSLAM2();
```

There are a number of default configuration files included in the `.config` directory which showcase the capabilities of the toolbox. To use a configuration file, open the toolbox as described above, then use the `Import config` button. A summary of the features showcased in each of the configuration files is included below:

- `'images_same'`: The trimmed Nordland dataset images, with the same dataset used as both reference and query. Trajectory based search is used, and a velocity-based ground truth is included, but not used for auto-optimisation of match threshold.
- `'images_diff'`: The trimmed Nordland dataset images, with the summer traversal used as the reference dataset and the winter traversal as the query. Trajectory based search is used, and a \*.csv based ground truth is used for auto-optimising the match threshold selection.
- `'videos_same'`: The day night video dataset, with the same video used as both the reference and query dataset. Trajectory based search is used, with no ground truth provided.
- `'videos_diff'`: The day night video dataset, with the day traversal used as the reference dataset and the night traversal as the query. Trajectory based search is used, with no ground truth provided.
- `'hybrid_search'`: Same as `'videos_diff'`, but the hybrid search is used instead of trajectory search.
- `'no_gui'`: Same as `'videos_diff'`, but the progress is presented in the console rather than GUI and no results GUI is shown (tip: run OpenSeqSLAM2(‘<configpath>/no_gui.xml’) to see how the toolbox can run entirely headless)
- `'batch_with_gui'`: Same as `'images_diff'`, but a batch parameter sweep of the sequence length parameter is performed. The progress GUI shows the progress of the individual iteration and overall in separate windows.
- `'parrallelised_batch'`: Same as `'batch_with_gui'`, but the parameter sweep is done in parallel mode (which cannot be performed with the Progress GUI). The parallel mode will use a worker for each core available in the host CPU.
- `'default'`: is set to `'images_diff'`

_*Note:* the programs in the `./bin` directory can be run standalone by providing the appropriate results / config structs as arguments if you would like to use only a specific part of the pipeline (i.e. only configuration, or progress wrapped execution, or viewing results)._

## Citation details

If using the toolbox in any academic work, please include the following citation:

```bibtex
@ARTICLE{2018openseqslam2,
   author = {{Talbot}, B. and {Garg}, S. and {Milford}, M.},
    title = "{OpenSeqSLAM2.0: An Open Source Toolbox for Visual Place Recognition Under Changing Conditions}",
  journal = {ArXiv e-prints},
archivePrefix = "arXiv",
   eprint = {1804.02156},
 primaryClass = "cs.RO",
 keywords = {Computer Science - Robotics, Computer Science - Computer Vision and Pattern Recognition},
     year = 2018,
    month = apr,
   adsurl = {http://adsabs.harvard.edu/abs/2018arXiv180402156T},
  adsnote = {Provided by the SAO/NASA Astrophysics Data System}
}
```
