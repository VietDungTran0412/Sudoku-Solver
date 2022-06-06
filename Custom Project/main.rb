# -----------------------------------------------------------------
# *			Student's name: Viet Dung Tran                            
# *			Student ID: 103486496																			
# *			Unit - Course: COS10009 - Introduction to Programming			
# *			Tutor: Nazar Najam																				
# *			Professor: Matthew Mitchell																	
# *			Custom program: Sudoku Solver 														
# *			Custom project: Backtracking and Its Application in Solving Sudoku Problem Recursively																														
# -----------------------------------------------------------------

#                        Reflection
# User can dive into the sudoku gameplay where we have 4 difficulties for user to choose from easy to evil
# Implementing backtracking to solve every sudoku problems
# All the sudoku problem has been downloaded into a text file via sudoku.com
require "gosu"
require "set"
require "benchmark"
require_relative "button"
require_relative "square"
require_relative "sudoku_table"
require_relative "circular_linkedlist"
# The following determines which layers things are placed on on the screen
# background is the lowest layer (drawn over by other layers), user interface objects are highest.
module Zorder
	BACKGROUND,UPPER, PLAYER, UI = *0..3
end

# Main game
class SudokuGameplay < Gosu::Window
	# The dimension of screen
	SCREEN_WIDTH = 1600
	SCREEN_HEIGHT = 1000
	def initialize
		super(SCREEN_WIDTH,SCREEN_HEIGHT)
		@scene = :menu                     # Scene will be set to menu - start scene where user can choose play or exit the game
		initialize_gameplay()							 # Initialize variable for gameplay scene
		initialize_start()								 # Initialize variable at the start scene
		initialize_difficulty()						 # Initialize variable for choosing difficulty scene
		initialize_tutorial()
		play_theme_song()
	end
	# Main button down function that executes all click on screen
	def button_down(id)
		case @scene
		when :gameplay
			button_down_gameplay(id)
		when :menu
			button_down_start(id)
		when :difficulty
			button_down_difficulty(id)
		when :tutorial
			button_down_tutorial(id)
		end
	end

	# Initialize in tutorial scene
	def initialize_tutorial
		@tutorial_scene_buttons = Hash.new()
	end

	# Button down in tutorial scene
	def button_down_tutorial(id)
		case id
		when Gosu::MsLeft
			clicked_menu_button(@tutorial_scene_buttons[:menu])
		end
	end

	# Draw single line of rule
	def display_rule_line(line,x,y)
		font = Gosu::Font.new(30)
		color = get_font_color()
		font.draw(line,x,y,Zorder::PLAYER,1,1,color)
	end

	# Draw multiple lines of rule
	def display_rule_lines(title,rules)
		font = Gosu::Font.new(60)
		left_x = 800
		title_y = 300
		color = get_font_color()
		font.draw(title,left_x,title_y,Zorder::PLAYER,1,1,color)
		gap = 80
		rule_y = title_y + gap
		rules.each do |line|
			display_rule_line(line,left_x,rule_y)
			rule_y += gap
		end
	end

	# Display rules
	def display_rules
		title = "Sudoku Tutorials"
		title_rules = "To win the game:"
		rules = ["1. The board must be all filled by digits from 1 to 9.",
						"2. Each column has no duplicated values.",
						"3. Each row has no duplicated values.",
						"4. Each subgrid of 3x3 has no duplicated values."]
		font = Gosu::Font.new(80)
		title_x = SCREEN_WIDTH/2 - font.text_width(title)/2
		title_y = 100
		font_color = get_font_color()
		font.draw(title,title_x,title_y,Zorder::PLAYER,1,1,font_color)
		display_rule_lines(title_rules,rules)
	end

	def draw_table_sample(path)
		img = Gosu::Image.new(path)
		img_x = 300
		img_y = 250
		img.draw(img_x,img_y,1.25,1.5,Zorder::PLAYER)
	end

	def draw_tutorial
		path = "./image/sample.png"
		draw_table_sample(path)
		display_rules()
	end
	# Main update function that executes all update on screen
	def update
		case @scene
		when :gameplay
			update_gameplay()
		end
	end
	
	# Main draw function that excecutes all draw on screen
	def draw
		draw_background()
		menu_button()
		case @scene
		when :gameplay
			draw_gameplay()
		when :menu
			draw_start()
		when :difficulty
			draw_difficulty()
		when :tutorial
			draw_tutorial()
		end
	end

	def play_theme_song
		path = "./music/theme.mp4"
		@song = Gosu::Song.new(path)
		@song.play(true)
	end

	# Check if the mouse were clicked in the right area
	def area_clicked(left_x,right_x,top_y,bottom_y)
		if mouse_x >= left_x && mouse_x <= right_x && mouse_y >= top_y && mouse_y <= bottom_y
			return true
		end
		return false
	end

	# Draw the background of the program
	def draw_background
		background_color = Gosu::Color::WHITE
		draw_quad(0,0,background_color,0,SCREEN_HEIGHT,background_color,SCREEN_WIDTH,0,background_color,SCREEN_WIDTH,SCREEN_HEIGHT,background_color,Zorder::BACKGROUND)
	end

	# Initialize variables when @scene = gameplay
	def initialize_gameplay()
		self.caption = "Sudoku Solver"
		@problems = read_problems()
		@selected_square = nil
		@is_clicked_solver = false
		@gameplay_scene_buttons = Hash.new()
	end
	
	# Insert the all the problems with different levels
	# into a hash table that make it easy to access by its key
	def insert_problems(problem,hash)
		if problem.difficulty == "Easy"
			hash[:easy].head = insert_at_end(hash[:easy].head,problem)
		elsif problem.difficulty == "Hard"
			hash[:hard].head = insert_at_end(hash[:hard].head,problem)
		elsif problem.difficulty == "Expert"
			hash[:expert].head = insert_at_end(hash[:expert].head,problem)
		else
			hash[:evil].head = insert_at_end(hash[:evil].head,problem)
		end
		return hash
	end

	# Read all the problems from a text file and add it into the hash
	# by reading the first line of text file where store the number of
	# problems
	def read_problems
		File.open("problems.txt","r") do |file|
			level = {:easy => CircularLinkedList.new(),
					:hard => CircularLinkedList.new(),
					:expert => CircularLinkedList.new(),
					:evil => CircularLinkedList.new()}
			count = file.readline()
			i = 0
			while i < count.to_i
				problem = read_problem(file)
				level = insert_problems(problem,level)
				i+=1
			end
			return level
		end
	end
	
	# Read the problem's information from a text file
	def read_problem file
		grid_size = 9
		grid = Array.new(grid_size)
		difficulty = read_difficulty(file)
		row = 0
		while row < grid_size
			line = file.readline()
			line = line.split(",")
			grid[row] = get_table(line,row)
			row+=1
		end
		table = SudokuTable.new(grid,difficulty)
		return table
	end
	
	# Read the line where stored the difficulty information of problem
	def read_difficulty(file)
		difficulty = file.readline().chomp()
		return difficulty
	end
	
	# Return the current problem'stable
	def get_current_problem()
		cur = @current_problem.data
		return cur
	end

	# Draw single square on screen and add the dimention and its coordinate
	# into the square records. The function get 3 arguments: square, its row
	# and its column
	def draw_square(square,row,col)
		f_pos = 100
		square_size = 96
		col = square.col
		row = square.row
		val = square.val
		x = f_pos + col*f_pos
		y = f_pos + row*f_pos
		square.x = x
		square.y = y
		color = square.color
		font = square.font
		draw_quad(x,y,color,x+square_size,y,color,x,y+square_size,color,x+square_size,y+square_size,color,Zorder::PLAYER)
		draw_square_val(font,val,x,y)
	end
	
	# Draw the square value if the square is not empty (value was not 0)
	def draw_square_val(font,val,x1_square,y1_square)
		square_size = 96
		mid = square_size / 2
		x_center = x1_square+mid
		x_text = x_center - font.text_width("#{val}")/2
		y_text = y1_square + 12
		color = get_font_color()
		if val !=0
			font.draw("#{val}",x_text,y_text,Zorder::UI,1,1,color)
		end
	end

	
	# Draw the sudoku table on screen by drawing all the square
	def draw_sudoku_table(table)
		grid = table.grid
		row = 0
		while row < grid.length
			col = 0
			while col < grid[row].length
				draw_square(grid[row][col],row,col)
				col+=1
			end
			row+=1
		end 
	end
	
	# Return the table from multiple squares
	def get_table(line,row)
		col = 0
		squares = Array.new(9)
		while col < line.length()
			val = line[col].to_i
			squares[col] = Square.new(val,row,col)
			squares[col].color = get_square_color(squares[col])
			col+=1
		end
		return squares
	end
	
	# Disable all squares which have value different from 0 in advance
	def disabled_square table
		row = 0
		grid_size = 9
		while row < grid_size
			col = 0
			while col < grid_size
				if table.grid[row][col].val == 0
					table.grid[row][col].touched = true
				end
				col+=1
			end
			row+=1
		end
	end
	
	# Checking users' attempt simutaneously if the answer is valid return true
	# adding all val into a set and if the value has been already in this set
	# the answer will be invalid --> return false
	def is_answer_valid(grid)
		row = 0
		grid_size = 9
		set = Set.new()
		while row < 9
			col = 0
			while col < grid_size
				# Check if the square has been filled by user or not return false if not
				if grid[row][col].val == 0 && grid[row][col].touched == true
					return false
				end
				found_col = "#{grid[row][col].val} found in col #{col}"
				found_row = "#{grid[row][col].val} found in row #{row}"
				found_box = "#{grid[row][col].val} found in box #{row-row%3} - #{col-col%3}"
				if set.include?(found_col) || set.include?(found_row) || set.include?(found_box)
					return false
				else
					set.add(found_col)
					set.add(found_row)
					set.add(found_box)
				end
				col+=1
			end
			row+=1
		end
		return true
	end

	def click_sounds
		path = "./music/click.wav"
		@sample  = Gosu::Sample.new(path)
		@sample.play
	end
	
	# Get the current square user has clicked on it
	def clicked_square(table)
		grid_size = 9
		grid = table.grid
		row = 0
		while row < grid_size
			col = 0
			while col < grid_size
				x = grid[row][col].x
				y = grid[row][col].y
				size = grid[row][col].size
				if area_clicked(x,x+size,y,y+size) && grid[row][col].touched == true
					click_sounds()
					return grid[row][col]
				end
				col+=1
			end
			row +=1
		end
	end
	
	# Reset all the table with original value
	def reset_table(table)
		grid = table.grid
		grid.each do |row|
			row.each do |square|
				if square.touched
					square.val = 0
				end
			end
		end
	end
	
	# Draw the border of the sudoku table
	def draw_border
		draw_quad(95,95,Gosu::Color::BLACK,1005,95,Gosu::Color::BLACK,95,1005,Gosu::Color::BLACK,1000,1005,Gosu::Color::BLACK,Zorder::BACKGROUND)
	end
	
	# Return true if there is a square that equals to selected square value
	def is_duplicate_val(row,col,num)
		if @sudoku_table.grid[row][col].val == num && @sudoku_table.grid[row][col].val != 0 && @sudoku_table.grid[row][col] != @selected_square
			return true
		else
			return false
		end
	end
	
	# Return true if there is a duplicate square over selected square in 
	# selected box
	def is_duplicate_box(row,col,num)
		box_size = 3
		i = 0
		while i < box_size
			j = 0
			while j < box_size
				if is_duplicate_val(row+i,col+j,num)
					return true
				end
				j+=1
			end
			i+=1
		end
		return false
	end
	
	# Return true if there is a duplicated square over selected square in
	# selected row
	def is_duplicate_row(row,num)
		col = 0
		grid_size = 9
		while col < grid_size
			if is_duplicate_val(row,col,num)
				return true
			end
			col+=1
		end
		return false
	end
	
	# Return true if there is a duplicated square over selected square in
	# selected column
	def is_duplicate_column(col,num)
		row = 0
		grid_size = 9
		while row < grid_size
			if is_duplicate_val(row,col,num)
				return true
			end
			row+=1
		end
		return false
	end

	# Return font color
	def get_font_color()
		return Gosu::Color.argb(0xff_202a44)
	end
	
	# Return square color
	def get_square_color(square)
		if square.val == 0
			return Gosu::Color::WHITE
		else
			return Gosu::Color.argb(0xff_b2dded)
		end
	end
	
	# Return color of selected area
	def selected_area_color()
		return Gosu::Color.argb(0xff_ccdde3)
	end
	
	# Return color in a square which is duplicated over selected square
	def duplicate_value_color()
		return Gosu::Color.argb(0xff_ffbebd)
	end
	
	# Return color of the selected square if find duplicate value over
	# box, row or column
	def selected_square_duplicate_color()
		return Gosu::Color.argb(0xff_f79292)
	end
	
	# Return color of all buttons in this program
	def get_button_color
		return Gosu::Color.argb(0xff_b2dded)
	end
	
	# Highlight the selected area including box, row and col where
	# the user clicked on selected square. The square is highlighted
	# by drawing another layer color on top of the square
	def highlight_selected_area()
		if @selected_square != nil
			highlight_selected_square(@selected_square)
			highlight_selected_column(@selected_square.col)
			highlight_selected_row(@selected_square.row)
			highlight_selected_box(@selected_square.row - @selected_square.row%3,@selected_square.col - @selected_square.col%3)
		end
	end
	
	# Highlight the selected square where users clicked on it
	def highlight_selected_square(square)
		x = square.x
		y = square.y
		size = square.size
		col = square.col
		row = square.row
		# Check if there is a duplicate value in row, column or box
		# color will be set to duplicate color of a selected square
		# if the statement is true and default color if false
		if is_duplicate_box(row-row%3,col-col%3,square.val) || is_duplicate_row(row,square.val) || is_duplicate_column(col,square.val)
			color = selected_square_duplicate_color()
		else
			color = Gosu::Color.argb(0xff_c9f9ff)
		end
		# Draw another layer on top of the selected square in order 
		# to highlight it
		draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
	end
	
	# Highlight the column of selected square
	def highlight_selected_column(col)
		row = 0
		grid_size = 9
		color = selected_area_color()
		while row< grid_size
			x = @sudoku_table.grid[row][col].x
			y = @sudoku_table.grid[row][col].y
			size = @sudoku_table.grid[row][col].size
			# Draw another layer to highlight selected column if it is touchable (touched = true)
			if @sudoku_table.grid[row][col] != @selected_square && @sudoku_table.grid[row][col].touched ==true
				color = selected_area_color()
				draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
			end
			# Check if it is duplicated --> change the highlight color
			if is_duplicate_val(row,col,@selected_square.val)
				color = duplicate_value_color()
				draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
			end
			row+=1
		end
	end
	
	# Highlight the row of selected square
	def highlight_selected_row(row)
		col = 0
		grid_size = 9
		color = selected_area_color()
		while col< grid_size
			x = @sudoku_table.grid[row][col].x
			y = @sudoku_table.grid[row][col].y
			size = @sudoku_table.grid[row][col].size
			# Draw another layer to highlight selected column if it is touchable (touched = true)
			if @sudoku_table.grid[row][col] != @selected_square && @sudoku_table.grid[row][col].touched ==true
				color = selected_area_color()
				draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
			end
			# Check if it is duplicated --> change the highlight color
			if is_duplicate_val(row,col,@selected_square.val)
				color = duplicate_value_color()
				draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
			end
			col+=1
		end
	end

	# Highlight the box of selected square
	def highlight_selected_box(row,col)
		i = 0
		box_size = 3
		while i < box_size
			j = 0
			while j < box_size
				x = @sudoku_table.grid[row+i][col+j].x
				y = @sudoku_table.grid[row+i][col+j].y
				size = @sudoku_table.grid[row+i][col+j].size
				# Draw another layer to highlight selected box if it is touchable (touched = true)
				if @sudoku_table.grid[row+i][col+j] != @selected_square && @sudoku_table.grid[row+i][col+j].touched ==true
					color = selected_area_color()
					draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
				end
				# Check if it is duplicated --> change the highlight color
				if is_duplicate_val(row+i,col+j,@selected_square.val)
					color = duplicate_value_color
					draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
				end
				j+=1
			end
			i+=1
		end
	end
	
	def needs_cursor?
		true
	end
	
	# Add value on the selected square
	def add_number(number)
		row = @selected_square.row
		col = @selected_square.col
		@sudoku_table.grid[row][col].val = number
		@selected_square.val = number
	end
	
	# Draw the solver button
	def draw_solver_button(buttons)
		button_x = 1150
		button_y = 300
		height = 75
		width = 250
		color = get_button_color()
		text_color = get_font_color()
		text = "Solver"
		font_size = 60
		buttons[:solver] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end
	
	# Check all the square on the table if it's empty
	# The empty square will have 0 value and touchable
	# Return true if there is no empty square in the table
	# that means the problem has been solved accurately.
	def is_empty_square(grid,cell)
		grid_size = 9
		row = 0
		while row < grid_size
			col = 0
			while col < grid_size
				if grid[row][col].val == 0
					cell[0] = row
					cell[1] = col
					return false
				end
				col+=1
			end
			row+=1
		end
		return true
	end
	
	# Checking if the box have duplicated values in box
	# and return true if it has. Otherwise return false
	# The box's size is 3x3
	def is_box_safe(grid,row,col,num)
		box_size = 3
		i = 0
		while i < box_size
			j = 0
			while j < box_size
				if grid[row+i][col+j].val == num
					return false
				end
				j+=1
			end
			i+=1
		end
		return true
	end
	
	# Check if the solution have duplicated values in column
	# and return true if it has. Otherwise, return false
	def is_column_safe(grid,col,num)
		row = 0
		grid_size = 9
		while row< grid_size
			if grid[row][col].val == num
				return false
			end
			row+=1
		end
		return true
	end
	
	# Check if the solution have duplicated values in row
	# and return true if it has. Otherwise, return false
	def is_row_safe(grid,row,num)
		grid_size = 9
		col = 0 
		while col < grid_size
			if grid[row][col].val == num
				return false
			end
			col+=1
		end
		return true
	end
	
	# Backtracking constraints checking if row, box, column
	# are having dupplicate values or not. Return true if it
	# has else return false
	def is_safe(grid,row,col,num)
		checked_col = is_column_safe(grid,col,num)
		checked_row = is_row_safe(grid,row,num)
		checked_box = is_box_safe(grid,row-row%3,col-col%3,num)
		if checked_box && checked_col && checked_row
			return true
		end
		return false
	end
	
	# Get the Sudoku solution by implementing backtracking
	def sudoku_solution(grid)
		cell = [0,0]                        # Store empty square in this cell
		if is_empty_square(grid,cell)				# If there is no more  empty square it means solution
			return true												# is correct
		end
		row = cell[0]												# Location of empty squaree
		col = cell[1]
		num = 1
		while num <= 9
			if is_safe(grid,row,col,num)      # Try different solution by checking if the value
				grid[row][col].val = num
				if sudoku_solution(grid)
					return true
				end
				grid[row][col].val = 0
			end
			num+=1
		end
		return false                        # Return false if the problem can be solved
	end
	
	# Users click the Solver button to get the solution
	def clicked_solver_button(button,table)
		x_button = button.x
		y_button = button.y
		width = button.width
		height = button.height
		if area_clicked(x_button,x_button+width,y_button,y_button+height)
			click_sounds()
			reset_table(table)
			grid = table.grid
			save_time_running(table)
			solved = sudoku_solution(grid)
			return solved
		end
	end

	# Save to time running to solve a problem for analysis
	def save_time_running(table)
		grid = table.grid
		time = Benchmark.measure{solved = sudoku_solution(grid)}
		File.open("time.txt", "a") do |file|
			file.write("#{table.difficulty} #{time}")
		end
	end
	
	# Draw the reset button
	def draw_reset_button(buttons)
		button_x = 1150
		button_y = 200
		height = 75
		width = 250
		color = get_button_color()
		text_color = get_font_color()
		text = "Reset"
		font_size = 60
		buttons[:reset] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end

	# User click the reset button to reset the Sudoku table
	def clicked_reset_button(button,table)
		buttonX = button.x
		buttonY = button.y
		width = button.width
		height = button.height
		if area_clicked(buttonX,buttonX+width,buttonY,buttonY+height)
			click_sounds()
			reset_table(table)
			@is_clicked_solver = false
		end
	end
	
	# The passed message will be displayed if the user passed the
	# problem without clicking on the solver button
	def display_passed_message()
		# if @is_solved == true
			font = Gosu::Font.new(60)
			font_x = 1150
			font_y = 100
			margin_right = 20
			message = 'Passed'
			ticked_y = font_y+5
			ticked_x = font_x + font.text_width(message)+margin_right
			color = get_font_color()
			font.draw(message,font_x,font_y,Zorder::PLAYER,1,1,color)
			ticked = Gosu::Image.new("./image/correct.png")
			ticked.draw(ticked_x,ticked_y,Zorder::UPPER,0.1,0.1)
		# end
	end
	
	# Draw the level of difficulty on screen
	def display_complexity(table)
		x = 100
		y = 20
		font = Gosu::Font.new(50)
		difficulty = table.difficulty
		color = get_font_color()
		font.draw("Complexity: #{difficulty}",x,y,Zorder::UPPER,1,1,color)
	end
	
	# Draw the next button allow users to skip to the next problem
	def next_problem_button(buttons)
		button_x = 1425
		button_y = 850
		width = 150
		height = 75
		color = get_button_color()
		text = "Next >>"
		text_color = get_font_color()
		font_size = 40
		buttons[:next] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end
	
	# Draw the previous button allow users to skip to the previous problem
	def prev_problem_button(buttons)
		button_x = 1025
		button_y = 850
		width = 150
		height = 75
		color = get_button_color()
		text = "<< Prev"
		text_color = get_font_color()
		font_size = 40
		buttons[:prev] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end
	
	# Clicking on the  previous button @current_problem will be equal to previous node
	def clicked_prev_button(button,table)
		x = button.x
		y = button.y
		width =button.width
		height = button.height
		if area_clicked(x,x+width,y,y+width)
			click_sounds()
			@current_problem = @current_problem.prev
			@sudoku_table = @current_problem.data
		end
	end
	
	# Back to the menu
	def clicked_menu_button(button)
		x = button.x
		y = button.y
		width = button.width
		height = button.height
		if area_clicked(x,x+width,y,y+height)
			click_sounds()
			@scene = :menu
		end
	end

	# Click the next button to skip to next problem
	def clicked_next_button(button,table)
		buttonX = button.x
		buttonY = button.y
		width = button.width
		height = button.height
		if area_clicked(buttonX,buttonX+width,buttonY,buttonY+height)
			click_sounds()
			@current_problem = @current_problem.next
			@sudoku_table = @current_problem.data
		end
	end
	
	# Get difficulty attributes in order to access the hash problems
	def get_difficulty(table)
		if table.difficulty.chomp == "Easy"
			difficulty = :easy
			return difficulty
		elsif table.difficulty.chomp == "Hard"
			difficulty = :hard
			return difficulty
		elsif table.difficulty.chomp == "Expert"
			difficulty = :expert
			return difficulty
		elsif table.difficulty.chomp == "Evil"
			difficulty = :evil
			return difficulty
		end
	end
	
	# Display the current problem number
	def display_problem_index(problems)
		cur = get_current_problem()
		difficulty = get_difficulty(@sudoku_table)
		head = problems[difficulty].head
		loc = get_index(head,@current_problem)
		length = get_length(head)
		x = 1250
		y = 850
		font = Gosu::Font.new(60)
		color = get_font_color()
		text = "#{loc} / #{length}"
		font.draw(text,x,y,Zorder::PLAYER,1,1,color)
	end

	# Draw every button by taking 4 arguments, basically coordinates
	# height, width and the background color
	def draw_button(x,y,height,width,color)
		draw_quad(x,y,color,x+width,y,color,x,y+height,color,x+width,y+height,color,Zorder::PLAYER)
	end
	
	# Hover effect over the buttons
	def hover_effect(x,y,width,height)
		if area_clicked(x,x+width,y,y+height)
			padding = 5
			color = Gosu::Color::BLACK
			draw_quad(x-padding,y-padding,color,x+width+padding,y-padding,color,x-padding,y+height+padding,color,x+width+padding,y+height+padding,color,Zorder::BACKGROUND)
		end
	end
	
	# Draw the text inside buttons
	def draw_text_button(text,x,y,width,height,color,font_size)
		margin_bottom = 15
		font = Gosu::Font.new(font_size)
		x_center = x + width/2
		x_text = x_center - font.text_width("#{text}")/2
		y_text = y + margin_bottom
		font.draw(text,x_text,y_text,Zorder::PLAYER,1,1,color)
	end
	
	# Functional excecute all button down activities when we are at gameplay scene
	def button_down_gameplay(id)
		case id
		when Gosu::MsLeft
			@selected_square = clicked_square(@sudoku_table)
			@is_clicked_solver = clicked_solver_button(@gameplay_scene_buttons[:solver],@sudoku_table)
			clicked_reset_button(@gameplay_scene_buttons[:reset],@sudoku_table)
			clicked_next_button(@gameplay_scene_buttons[:next],@sudoku_table)
			clicked_prev_button(@gameplay_scene_buttons[:prev],@sudoku_table)
			clicked_menu_button(@gameplay_scene_buttons[:menu])
		end
		if @selected_square != nil
			number = 0
			case id
			when Gosu::Kb1
				number = 1
				add_number(number)
			when Gosu::Kb2
				number = 2
				add_number(number)
			when Gosu::Kb3
				number = 3
				add_number(number)
			when Gosu::Kb4
				number = 4
				add_number(number)
			when Gosu::Kb5
				number = 5
				add_number(number)
			when Gosu::Kb6
				number = 6
				add_number(number)
			when Gosu::Kb7
				number = 7
				add_number(number)
			when Gosu::Kb8
				number = 8
				add_number(number)
			when Gosu::Kb9
				number = 9
				add_number(number)
			when Gosu::KbBackspace
				number = 0
				add_number(number)
			end
		end
	end
	
	# Update everytime all actions in gameplay scene
	def update_gameplay
		grid = @sudoku_table.grid
		@is_solved = is_answer_valid(grid)
		disabled_square(@sudoku_table)
	end

	# Draw every object that belongs to the gameplay scene
	def draw_gameplay()
		draw_sudoku_table(@sudoku_table)
		draw_border()
		highlight_selected_area()
		draw_solver_button(@gameplay_scene_buttons)
		draw_reset_button(@gameplay_scene_buttons)
		if @is_solved == true
			display_passed_message()
		end
		display_complexity(@sudoku_table)
		next_problem_button(@gameplay_scene_buttons)
		prev_problem_button(@gameplay_scene_buttons)
		display_problem_index(@problems)
	end

	# Initialize variable in start scene
	def initialize_start
		@start_scene_buttons = Hash.new()  # Store all buttons in a hash table
	end
	
	# Functional excecute all button down activities when we are at start scene
	def button_down_start(id)
		case id
		when Gosu::MsLeft
			clicked_play_button(@start_scene_buttons[:start])
			clicked_exit_button(@start_scene_buttons[:exit])
			clicked_tutorial_button(@start_scene_buttons[:tutorial])
		end
	end
	
	# Draw every objects that belong to start scene
	def draw_start
		path = "./image/sudoku.png"
		draw_game_logo(path)
		draw_play_button(@start_scene_buttons)
		draw_exit_button(@start_scene_buttons)
		draw_tutorial_button(@start_scene_buttons)
	end
	
	# Display the game artwork
	def draw_game_logo(path)
		img = Gosu::Image.new(path)
		img_size = 96 # The size of image if 96
		img_x = SCREEN_WIDTH/2 - img_size*2
		img_y = 40
		img.draw(img_x,img_y,Zorder::PLAYER,0.75,0.75) 
	end
	
	# Draw play button where user can click to play
	def draw_play_button(buttons)
		width = 300
		button_x = SCREEN_WIDTH/2 - width/2
		button_y = 500
		height = 100
		color = get_button_color()
		text = "Play"
		text_color = get_font_color()
		font_size = 80
		buttons[:start] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end

	def draw_tutorial_button(buttons)
		width  = 300
		button_x = SCREEN_WIDTH/2 - width/2
		button_y = 650
		height = 100
		color = get_button_color()
		text = "Tutorial"
		text_color = get_font_color()
		font_size = 80
		buttons[:tutorial] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)	
	end
	
	# Draw exit button where user can click to exit the screen
	def draw_exit_button(buttons)
		width = 300
		button_x = SCREEN_WIDTH/2 - width/2
		button_y = 800
		height = 100
		color = get_button_color()
		text = "Exit"
		text_color = get_font_color()
		font_size = 80
		buttons[:exit] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end
	
	# Click on exit button where user can click to exit the screen
	def clicked_exit_button(button)
		x = button.x
		y = button.y
		width = button.width
		height = button.height
		if area_clicked(x,x+width,y,y+height)
			click_sounds()
			close()
		end
	end
	
	# Click on play button where user can click to play the screen
	def clicked_play_button(button)
		x = button.x
		y = button.y
		width = button.width
		height = button.height
		if area_clicked(x,x+width,y,y+height)
			click_sounds()
			@scene = :difficulty
		end
	end

	def clicked_tutorial_button(button)
		x = button.x
		y = button.y
		width = button.width
		height = button.height
		if area_clicked(x,x+width,y,y+height)
			click_sounds()
			@scene = :tutorial
		end
	end

	# Draw menu button
	def draw_menu_button(x,y,width,height,buttons,font_size = 60,text = "Menu")
		color = get_button_color()
		text_color = get_font_color()
		buttons[:menu] = Button.new(text,x,y,width,height,text_color)
		draw_button(x,y,height,width,color)
		draw_text_button(text,x,y,width,height,text_color,font_size)
		hover_effect(x,y,width,height)
	end

	# Draw menu buttons in every scene to allows user back to start scene
	def menu_button()
		case @scene
		when :gameplay
			menu_x = 1150
			menu_y = 400
			width = 250
			height = 75
			draw_menu_button(menu_x,menu_y,width,height,@gameplay_scene_buttons)
		when :difficulty
			width = 300
			menu_x = SCREEN_WIDTH/2 - width/2
			menu_y = 800
			height = 100
			draw_menu_button(menu_x,menu_y,width,height,@diff_scene_buttons,font_size = 80)
		when :tutorial
			width = 300
			menu_x = SCREEN_WIDTH/2 - width/2
			menu_y = 800
			height = 100
			draw_menu_button(menu_x,menu_y,width,height,@tutorial_scene_buttons,font_size = 80)
		end
	end

	# Initialize variables when users in the scene to choose the difficulty
	def initialize_difficulty()
		@diff_scene_buttons = Hash.new()
	end
	
	def button_down_difficulty(id)
		case id
		when Gosu::MsLeft
			clicked_evil_button(@diff_scene_buttons[:evil])
			clicked_expert_button(@diff_scene_buttons[:expert])
			clicked_easy_button(@diff_scene_buttons[:easy])
			clicked_hard_button(@diff_scene_buttons[:hard])
			clicked_menu_button(@diff_scene_buttons[:menu])
		end
	end
	
	# Draw every objects in choosing difficuty scene
	def draw_difficulty()
		draw_easy_button(@diff_scene_buttons)
		draw_hard_button(@diff_scene_buttons)
		draw_expert_button(@diff_scene_buttons)
		draw_evil_button(@diff_scene_buttons)
		draw_difficulty_title()
	end
	
	# Draw the scene title
	def draw_difficulty_title()
		message = "Please choose difficulty"
		width = 1600
		font = Gosu::Font.new(80)
		x = width/2 - font.text_width(message)/2
		y = 50
		color = get_font_color()
		font.draw(message,x,y,Zorder::PLAYER,1,1,color)
	end
	
	# Draw easy button
	def draw_easy_button(buttons)
		width = 300
		button_x = SCREEN_WIDTH/2 - width/2
		button_y = 200
		height = 100
		color = get_button_color()
		text = "Easy"
		text_color = get_font_color()
		font_size = 80
		buttons[:easy] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end
	
	# Draw hard button
	def draw_hard_button(buttons)
		width = 300
		button_x = SCREEN_WIDTH/2 - width/2
		button_y = 350
		height = 100
		color = get_button_color()
		text = "Hard"
		text_color = get_font_color()
		font_size = 80
		buttons[:hard] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end
	
	# Draw expert button
	def draw_expert_button(buttons)
		width = 300
		button_x = SCREEN_WIDTH/2 - width/2
		button_y = 500
		height = 100
		color = get_button_color()
		text = "Expert"
		text_color = get_font_color()
		font_size = 80
		buttons[:expert] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end
	
	# Click on evil button
	def draw_evil_button(buttons)
		width = 300
		button_x = SCREEN_WIDTH/2 - width/2
		button_y = 650
		height = 100
		color = get_button_color()
		text = "Evil"
		text_color = get_font_color()
		font_size = 80
		buttons[:evil] = Button.new(text,button_x,button_y,width,height,text_color)
		draw_button(button_x,button_y,height,width,color)
		draw_text_button(text,button_x,button_y,width,height,text_color,font_size)
		hover_effect(button_x,button_y,width,height)
	end
	
	# Click on expert button
	def clicked_expert_button(button)
		x = button.x
		y = button.y
		width = button.width
		height = button.height
		if area_clicked(x,x+width,y,y+height)
			click_sounds()
			difficulty = :expert
			@scene = :gameplay
			@current_problem = @problems[difficulty].head
			@sudoku_table = get_current_problem()
		end
	end
	
	# Click on evil button
	def clicked_evil_button(button)
		x = button.x
		y = button.y
		width = button.width
		height = button.height
		if area_clicked(x,x+width,y,y+height)
			click_sounds()
			difficulty = :evil
			@scene = :gameplay
			@current_problem = @problems[difficulty].head
			@sudoku_table = get_current_problem()
		end
	end
	
	# Click on easy button
	def clicked_easy_button(button)
		x = button.x
		y = button.y
		width = button.width
		height = button.height
		if area_clicked(x,x+width,y,y+height)
			click_sounds()
			difficulty = :easy
			@scene = :gameplay
			@current_problem = @problems[difficulty].head
			@sudoku_table = get_current_problem()
		end
	end
	
	# Click on hard button
	def clicked_hard_button(button)
		x = button.x
		y = button.y
		width = button.width
		height = button.height
		if area_clicked(x,x+width,y,y+height)
			click_sounds()
			difficulty = :hard
			@scene = :gameplay
			@current_problem = @problems[difficulty].head
			@sudoku_table = get_current_problem()
		end
	end
end

if __FILE__ == $0
	SudokuGameplay.new().show()
end