# OpenSeqSLAM2.0 Toolbox

The second release of OpenSeqSLAM, repackaged as an easy to use and configure toolbox for MATLAB. To run the software, simply run "OpenSeqSLAM2" with no arguments.

## Known Bugs (roughly ordered by severity):

* Under Ubuntu, the window manager sometimes incorrectly places the window title bar over the top of the figure, instead of on top (only current fix is to close window and reopen)
* Closing the Tweak popup resets the selected match in Results GUI (this should only be done when applying a tweak, not closing)
* In PR it is assumed that every query image has a reference image ground truth. Is this a valid assumption???


## TODO List (roughly ordered by value):

* Add horizontal scrolling to Sequence Popup
* Highlight the match in the Sequence Popup (i.e. middle pair of images)
* Rebrand all subprograms (i.e. in './bin/') to from "SeqSLAM" to "OpenSeqSLAM"
* Disable match selection in Results GUI when a popup is open (i.e. enforce ad hoc modal structure)


## Potential Future Feature List (may or may not eventuate...):

* Make the Progress UI correctly display the contrast enhanced difference matrix as an overlay
* Use Git LFS to manage storage of the samples archive
* Make resizable
* Fix axis management (currently a random mess full of unnecessary calls)
* Clean up of messy code areas (break GUI creation and sizing functions into manageable sub-functions, etc.)
