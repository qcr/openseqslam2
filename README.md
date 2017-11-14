# SeqSLAM Toolbox

An official SeqSLAM Toolbox for MATLAB.

## Known Bugs (roughly ordered by severity):

* Running SeqSLAM errors with "Subscripted assignment dimension mismatch" for "images(:,:,k) = imgOut" when running after opening SeqSLAM configuration GUI
* Percent update frequency is only respected for first step of Progress GUI (suspected because "lastPercent" value is not reset when changing states)
* Matching performs terribly on day night video dataset (could simply be poor parameter choices)
* Changing crop box doesn't fade corresponding previews (SeqSLAM configuration GUI)
* Crop boxes reset to full size when refreshing previews (SeqSLAM configuration GUI)
* Remove blank difference matrix screen (SeqSLAM configuration GUI)
* Remove visualiser settings button (initial configuration GUI)

## TODO List (roughly ordered by value):

* Annotations for the SeqSLAM configuration visual helpers
* Integrate absolute thresholding method (both in settings, and dynamic adjusting)
* Writing and reading of results from a directory (including logic for choosing whether to load existing or not)
* Allow resized dimensions to change aspect ratio (SeqSLAM configuration GUI - need to understand why this change...)
* Implement the "outlier fading" functionality in the Difference Matrix Results GUI
* Re-evaluate regex matching scheme for images (in initial configuration GUI)

## Wish List (not a priority in any way shape or form):

* Make resizeable
* Fix axis management (currently a random mess full of unneccessary calls)
* Clean up of messy code areas (break GUI creation and sizing functions into manageable sub-functions, etc.)
