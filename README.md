# OpenSeqSLAM2.0 Toolbox

The second release of OpenSeqSLAM, repackaged as an easy to use and configure toolbox for MATLAB.

## Known Bugs (roughly ordered by severity):

* Running SeqSLAM errors with "Subscripted assignment dimension mismatch" for "images(:,:,k) = imgOut" when running after opening SeqSLAM configuration GUI
* Percent update frequency is only respected for first step of Progress GUI (suspected because "lastPercent" value is not reset when changing states)
* Matching performs terribly on day night video dataset (could simply be poor parameter choices)
* Changing crop box doesn't fade corresponding previews (SeqSLAM configuration GUI)
* Crop boxes reset to full size when refreshing previews (SeqSLAM configuration GUI)


## TODO List (roughly ordered by value):

* Allow resized dimensions to change aspect ratio (SeqSLAM configuration GUI - need to understand why this change...)
* Add help cues to the dialogs
* Re-evaluate regex matching scheme for images (in initial configuration GUI)


## Wish List (not a priority in any way shape or form):

* Use Git LFS to manage storage of the samples archive
* Make resizable
* Fix axis management (currently a random mess full of unnecessary calls)
* Clean up of messy code areas (break GUI creation and sizing functions into manageable sub-functions, etc.)
