# ruby -r "./eup2board.rb" -e "import_file('/path/to/EagleUp.eup')"


USE_RELATIVE_PATH = 0	# set to 0 to keep absolute paths

def newColor(str,default_color)
	if(str[0,2] == "0x")
		red = str[2,2].hex
		green = str[4,2].hex
		blue = str[6,2].hex
		color = "#" + str[2,2] + str[4,2] + str[6,2]
	else
		case str
			when "silver"
			color = "#C0C0C0"
			
			when "ivory"
			color = "#FFFFF0"
			
			when "gold"
			color = "#FFD700"
			
			when "white"
			color = "#FFFFFF"
			
			when "black"
			color = "#000000"
			
		end
			
		#color = rgb_string(str)
	end

	return color
end
# Returns a RGB string formated as "#abcdef" from a color object
def rgb_string(reg, green, blue)
	return sprintf("#%2.2X%2.2X%2.2X",red,green,blue);
end

def import_file(file_data_path) #,options)
	# Get the directory of the loaded file
	loaded_file_dir = File::dirname(file_data_path)
	# Change directory to the directory of the loaded file
	Dir::chdir(loaded_file_dir)
	
	# definition of the colors used for the board and for the plating
	default_board_color = 0x266844      # 0x266844 - Green
	default_plating_color = 0xbfac5f	# 0xbfac5f - Gold
	default_silk_color = 0xfffff0 # Ivory

	color_board = default_board_color
	color_tracing = default_board_color
	color_plating = default_plating_color
	color_silk = default_silk_color

	# log file open at the beginning in case we want to write during import
	file = File.open file_data_path , "r"
		puts "eagleUp > open file " + file_data_path
	log_file = File.new( file_data_path[0..-5] + ".log" ,  "w")

	
	# global variables
	decimal_separator = "."
	model_path = 		""
	convert_cmd = 		""
	composite_cmd = 	""
	rm_cmd = 			""
	
	image_prefix 	=	""
	# If file doesn't exist abort
		# Warning file couldn't be opened

	# Check if a valid text file was selected

	# from now on the eup file is read and for each line an action is processed, like adding a package on the board
	
	result_extension=""		# used in diff places
	
	file.each do |line|

		# when using comma as decimal sign some errors can occur as the raw data is recorded with a dot
		# if the user defines comma in the settings, the dots are replaced by commas then the command is interpretated
		initial_line = String.new( line )
		if( decimal_separator == "," )
			line.gsub!(/\./,",")
		end

		# the array elements contain the various fields of each line
		elements = line.split(";")
		initial_elements = initial_line.split(";")
		
		
		case elements[0]
	
			when "settings"
				model_path = 		initial_elements[1]
				convert_cmd = 		initial_elements[2]
				composite_cmd = 	initial_elements[3]
				rm_cmd = 			initial_elements[4]
					puts "system > settings imported"
		
			when "color"
				# input file describes the color of the board and of the plating
				color_board		= newColor(elements[1],default_board_color)
				color_tracing	= newColor(elements[2],default_board_color)
				color_plating	= newColor(elements[3],default_plating_color)
				color_silk		= newColor(elements[4],default_silk_color)
					puts "color > colors set"
						
			when "images"
				if USE_RELATIVE_PATH == 1
					directory = ""
				else
					directory = initial_elements[1]
				end
				
				image_prefix = initial_elements[2]
				image_suffix = initial_elements[3]
				result_extension = initial_elements[5]

				# Produce the top and bottom images
					puts "images > creating top and bottom images"
					create_images(directory,image_prefix,image_suffix,color_board,color_tracing,color_plating,color_silk,convert_cmd,composite_cmd,rm_cmd,file_data_path,result_extension)
					puts "images > images created"
		end # end case
	
	end # end
end
		
def create_images(directory, prefix,image_suffix,color_board,color_tracing,color_plating,color_silk,convert_cmd,composite_cmd,rm_cmd,file_data_path,result_extension)
	image_prefix = directory + prefix
	# Find board size
	crop_cmd = convert_cmd + " -trim \"" + image_prefix + "_imagesize.png\" -format \"%wx%h+%X+%Y\" info:\n"
	crop_arg = `#{crop_cmd}`.strip

	# versions 6.7.7 of ImageMagick had issues with the output parameters. To solve it a + sign is forced in the string.
	# The following lines clean and trim the output.
	crop_arg.gsub!("+++","+")
	crop_arg.gsub!("++","+")
	crop_arg.gsub!("\n","")
	
			
	# top image
	top_cmds  = composite_cmd + ' -transparent-color "white" -compose plus ' + "\"" + image_prefix + "_top_mask.png\" " + "\"" + image_prefix + "_top.png\" pads.png\n"
	top_cmds += convert_cmd + " -negate \"" + image_prefix + "_top_mask.png\" maskn.png\n"
	top_cmds += composite_cmd + " -transparent-color \"white\" -compose plus \"" + image_prefix + "_top.png\" maskn.png  traces.png\n"
	cmds = top_cmds

	# create board
	board_color_cmds = convert_cmd + " \"" + image_prefix + "_imagesize.png\" " + ' -transparent "white"  -fill "' + (color_board) + '" -colorize "100,100,100,0"  board.png' + "\n"
	cmds += board_color_cmds

	# set colors
	color_cmds  = convert_cmd + ' -transparent "white" -fill "' + color_plating + '" -colorize "100,100,100,0" pads.png pads.png' + "\n"
	color_cmds += convert_cmd + ' -transparent "white"  -fill "' + color_tracing + '" -colorize "100,100,100,0" traces.png traces.png' + "\n"
	
	cmds += color_cmds
	cmds += convert_cmd + " \"" + image_prefix + "_top_silk.png\" " + ' -transparent "white" -fill "' + (color_silk) + '" -colorize "100,100,100,0" silk.png' + "\n"

	# create combined top image
	top_combine_cmds = convert_cmd + ' -flatten -background "none" ' + "board.png traces.png silk.png pads.png \"" + prefix + "_board_top.png\"\n"
	top_combine_cmds += convert_cmd + " \"" + prefix + "_board_top.png\" -crop \"" + crop_arg + "\" \"" + prefix + "_board_top." + result_extension + "\"\n"
	cmds += top_combine_cmds

	# bottom image
	bottom_cmds = composite_cmd + " -transparent-color \"white\" -compose plus \"" + image_prefix + "_bottom_mask.png\" \"" + image_prefix + "_bottom.png\" padsB.png\n"
	bottom_cmds += convert_cmd + " -negate \"" + image_prefix + "_bottom_mask.png\" masknB.png\n"
	bottom_cmds += composite_cmd + " -transparent-color \"white\" -compose plus \"" + image_prefix + "_bottom.png\" masknB.png tracesB.png\n"
	cmds += bottom_cmds

	# set colors
	color_cmds  = convert_cmd + ' -transparent "white" -fill "' + (color_plating) + '" -colorize "100,100,100,0" padsB.png padsB.png' + "\n"
	color_cmds += convert_cmd + ' -transparent "white"  -fill "' + (color_tracing) + '" -colorize "100,100,100,0" tracesB.png tracesB.png' + "\n"
	cmds += color_cmds
	cmds += convert_cmd + " \"" + image_prefix + "_bottom_silk.png\" " + ' -transparent "white" -fill "' + (color_silk) + '" -colorize "100,100,100,0" silkB.png' + "\n"

	# create combined bottom image
	bottom_combine_cmds = convert_cmd + ' -flatten -background "none" ' + "board.png tracesB.png  silkB.png padsB.png \"" + prefix + "_board_bottom.png\"\n"
	bottom_combine_cmds += convert_cmd + " \"" + prefix + "_board_bottom.png\" -crop \"" + crop_arg + "\" -flop \"" + prefix + "_board_bottom." + result_extension + "\"\n"
	cmds += bottom_combine_cmds

	# remove temporary files
	rm_cmds = rm_cmd + " board.png pads.png padsB.png silk.png silkB.png maskn.png masknB.png traces.png tracesB.png\n"
	if( result_extension == "jpg" )
		rm_cmds += rm_cmd + " \"" + prefix + "_board_top.png\"  \"" + prefix + "_board_bottom.png " 
	end
	cmds += rm_cmds

	# Run commands
	# Change to working directory
	if USE_RELATIVE_PATH == 0
		Dir.chdir(directory);
	end
	
	cmds.each_line do |line|
		`#{line}`
	end
end
