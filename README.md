# OpenSeqSLAM2.0 Toolbox

The second release of OpenSeqSLAM, repackaged as an easy to use and configure toolbox for MATLAB. To run the software, simply run "OpenSeqSLAM2" with no arguments.

## Known Bugs (roughly ordered by severity):

* Under Ubuntu, the window manager sometimes incorrectly places the window title bar over the top of the figure, instead of on top (only current fix is to close window and reopen)
* Closing the Tweak popup resets the selected match in Results GUI (this should only be done when applying a tweak, not closing)


## TODO List (roughly ordered by value):

* Add a screen to the Results GUI for comparing to ground truth and generating precision recall curves
* Add horizontal scrolling to Sequence Popup
* Highlight the match in the Sequence Popup (i.e. middle pair of images)
* Rebrand all subprograms (i.e. in './bin/') to from "SeqSLAM" to "OpenSeqSLAM"
* Disable match selection in Results GUI when a popup is open (i.e. enforce ad hoc modal structure)
* Re-evaluate regex matching scheme for images (in initial configuration GUI)


## Potential Future Feature List (may or may not eventuate...):

* Make the Progress UI correctly display the contrast enhanced difference matrix as an overlay
* Use Git LFS to manage storage of the samples archive
* Make resizable
* Fix axis management (currently a random mess full of unnecessary calls)
* Clean up of messy code areas (break GUI creation and sizing functions into manageable sub-functions, etc.)
