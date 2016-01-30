# eup2board
A ruby script to create eagleUp_demo3d_board_top.png and eagleUp_demo3d_board_bottom.png from eagleUp's .eup file.

## Using
`ruby -r "./eup2board.rb" -e "import_file('/path/to/demo3d.eup')"`

input files:
- eagleUp_demo3d_bottom_mask.png
- eagleUp_demo3d_bottom_silk.png
- eagleUp_demo3d_bottom.png
- eagleUp_demo3d_imagesize.png
- eagleUp_demo3d_outline.png
- eagleUp_demo3d_top_mask.png
- eagleUp_demo3d_top_silk.png
- eagleUp_demo3d_top.png

Output files:
- eagleUp_demo3d_board_bottom.png
- eagleUp_demo3d_board_top.png
