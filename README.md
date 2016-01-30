# eup2board
A ruby script to create `*_board_top.png` and `*_board_bottom.png` from eagleUp's .eup file.

## Using
`ruby -r "./eup2board.rb" -e "import_file('/path/to/file.eup')"`

input files:
- eagleUp_boardname_bottom_mask.png
- eagleUp_boardname_bottom_silk.png
- eagleUp_boardname_bottom.png
- eagleUp_boardname_imagesize.png
- eagleUp_boardname_outline.png
- eagleUp_boardname_top_mask.png
- eagleUp_boardname_top_silk.png
- eagleUp_boardname_top.png

Output files:
- eagleUp_boardname_board_bottom.png
- eagleUp_boardname_board_top.png
