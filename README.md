# OpenSeqSLAM2.0 Toolbox

The second release of OpenSeqSLAM, repackaged as an easy to use and configure toolbox for MATLAB.

## Known Bugs (roughly ordered by severity):

* Running SeqSLAM errors with "Subscripted assignment dimension mismatch" for "images(:,:,k) = imgOut" when running after opening SeqSLAM configuration GUI
* Opening SeqSLAM configuration GUI twice causes error ("The 'STRING' input must be either a char row vector, a cell array of char row vectors, or a string array")
* Percent update frequency is only respected for first step of Progress GUI (suspected because "lastPercent" value is not reset when changing states)
* Matching performs terribly on day night video dataset (could simply be poor parameter choices)
* Changing crop box doesn't fade corresponding previews (SeqSLAM configuration GUI)
* Crop boxes reset to full size when refreshing previews (SeqSLAM configuration GUI)


## TODO List (roughly ordered by value):

* Integrate absolute thresholding method (both in settings, and dynamic adjusting)
* Package up some samples that ship with the download
* Writing and reading of results from a directory (including logic for choosing whether to load existing or not)
* Allow resized dimensions to change aspect ratio (SeqSLAM configuration GUI - need to understand why this change...)
* Add help cues to the dialogs
* Implement the "outlier fading" functionality in the Difference Matrix Results GUI
* Re-evaluate regex matching scheme for images (in initial configuration GUI)


## Wish List (not a priority in any way shape or form):

* Make resizeable
* Fix axis management (currently a random mess full of unneccessary calls)
* Clean up of messy code areas (break GUI creation and sizing functions into manageable sub-functions, etc.)
