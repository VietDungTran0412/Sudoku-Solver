require "gosu"
require "set"
module Zorder
	BACKGROUND,LAYOUT, PLAYER, UI = *0..3
end

class Button
	attr_accessor :text,:x,:y,:width,:height,:text_color
	def initialize(text,x,y,width,height)
		@text = text
		@x = x
		@y = y
		@width = width
		@height = height
		@text_color = Gosu::Color::BLACK
	end
end

class Square
	attr_accessor :val,:color,:row,:col,:font,:x,:y,:touched,:size
	def initialize(val,row,col)
		@val = val
		@color = color
		@row = row
		@col = col
		@font = Gosu::Font.new(80)
		@x = x
		@y = y 
		@touched = false
		@size = 96
	end
end

class SudokuTable
	SIZE = 9
	attr_accessor :grid,:difficulty
	def initialize(grid,difficulty)
		@grid = grid
		@difficulty = difficulty
		@solved = false
	end
end
class SudokuGameplay < Gosu::Window
	WIDTH = 1600
	HEIGHT = 1000
	def initialize
		super(WIDTH,HEIGHT)
		self.caption = "Sudoku Solver"
		@sudokuTable = readProblem()
		@selectedSquare = nil
		@number = 0
		@fontColor = Gosu::Color.argb(0xff_202a44)
		@isClickedSolver = false
		disabledSquare()
	end

	def disabledSquare
		row = 0
		gridSize = 9
		while row < gridSize
			col = 0
			while col < gridSize
				if @sudokuTable.grid[row][col].val == 0
					@sudokuTable.grid[row][col].touched = true
				end
				col+=1
			end
			row+=1
		end
	end

	def drawBackground
		backgroundColor = Gosu::Color::WHITE
		draw_quad(0,0,backgroundColor,0,HEIGHT,backgroundColor,WIDTH,0,backgroundColor,WIDTH,HEIGHT,backgroundColor,Zorder::BACKGROUND)
	end

	def readProblem
		gridSize = 9
		grid = Array.new(gridSize)
		File.open("problems.txt","r") do |file|
			difficulty = readDifficulty(file)
			row = 0
			while row < gridSize
				line = file.readline()
				line = line.split(",")
				grid[row] = squareRow(line,row)
				row+=1
			end
			table = SudokuTable.new(grid,difficulty)
			return table
		end
	end

	def readDifficulty(file)
		difficulty = file.readline()
		return difficulty
	end

	def getSquareColor(square)
		if square.val == 0
			return Gosu::Color::WHITE
		else
			return Gosu::Color.argb(0xff_b2dded)
		end
		
	end

	def squareRow(line,row)
		col = 0
		squares = Array.new(9)
		while col < line.length()
			val = line[col].to_i
			squares[col] = Square.new(val,row,col)
			squares[col].color = getSquareColor(squares[col])
			col+=1
		end
		return squares
	end

	def drawBorder
		draw_quad(95,95,Gosu::Color::BLACK,1005,95,Gosu::Color::BLACK,95,1005,Gosu::Color::BLACK,1000,1005,Gosu::Color::BLACK,Zorder::BACKGROUND)
	end


	def areaClicked(leftX,rightX,topY,bottomY)
		if mouse_x >= leftX && mouse_x <= rightX && mouse_y >= topY && mouse_y <= bottomY
			return true
		end
		return false
	end



	def hightlightSelectedArea()
		if @selectedSquare != nil
			x = @selectedSquare.x
			y = @selectedSquare.y
			size = @selectedSquare.size
			hightlightSelectedSquare(x,y,size)
			highlightSelectedCol(@selectedSquare.col)
			highlightSelectedRow(@selectedSquare.row)
			highlightSelectedBox(@selectedSquare.row - @selectedSquare.row%3,@selectedSquare.col - @selectedSquare.col%3)
		end
	end

	def hightlightSelectedSquare(x,y,size)
		highlightColor= Gosu::Color.argb(0xff_c9f9ff)
		draw_quad(x,y,highlightColor,x+size,y,highlightColor,x,y+size,highlightColor,x+size,y+size,highlightColor,Zorder::PLAYER)
	end

	def selectedAreaColor()
		return Gosu::Color.argb(0xff_ccdde3)
	end

	def highlightSelectedBox(row,col)
		i = 0
		boxSize = 3
		color = selectedAreaColor()
		while i < boxSize
			j = 0
			while j < boxSize
				if @sudokuTable.grid[row+i][col+j] != @selectedSquare && @sudokuTable.grid[row+i][col+j].touched ==true
					x = @sudokuTable.grid[row+i][col+j].x
					y = @sudokuTable.grid[row+i][col+j].y
					size = @sudokuTable.grid[row+i][col+j].size
					draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
				end
				j+=1
			end
			i+=1
		end
	end

	def highlightSelectedCol(col)
		row = 0
		gridSize = 9
		color = selectedAreaColor()
		while row< gridSize
			if @sudokuTable.grid[row][col] != @selectedSquare && @sudokuTable.grid[row][col].touched ==true
				x = @sudokuTable.grid[row][col].x
				y = @sudokuTable.grid[row][col].y
				size = @sudokuTable.grid[row][col].size
				draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
			end
			row+=1
		end
	end

	def highlightSelectedRow(row)
		col = 0
		gridSize = 9
		color = selectedAreaColor()
		while col< gridSize
			if @sudokuTable.grid[row][col] != @selectedSquare && @sudokuTable.grid[row][col].touched ==true
				x = @sudokuTable.grid[row][col].x
				y = @sudokuTable.grid[row][col].y
				size = @sudokuTable.grid[row][col].size
				draw_quad(x,y,color,x+size,y,color,x,y+size,color,x+size,y+size,color,Zorder::PLAYER)
			end
			col+=1
		end
	end
	
	def drawSudokuTable()
		grid = @sudokuTable.grid
		row = 0
		while row < grid.length
			col = 0
			while col < grid[row].length
				drawSquare(grid[row][col],row,col)
				col+=1
			end
			row+=1
		end 
	end

	def needs_cursor?
		true
	end

	def drawSquare(square,row,col)
		padding = 5
		margin = 100
		squareSize = 96
		col = square.col
		row = square.row
		val = square.val
		x1 = margin + col*margin
		y1 = margin + row*margin
		@sudokuTable.grid[row][col].x = x1
		@sudokuTable.grid[row][col].y = y1
		x2 = x1 + squareSize
		y2 = y1
		x3 = x2
		y3 = y2+ squareSize
		x4 = x1
		y4 = y3
		color = square.color
		font = square.font
		draw_quad(x1,y1,color,x2,y2,color,x3,y3,color,x4,y4,color,Zorder::PLAYER)
		drawSquareValue(font,val,x1,y1)
	end

	def drawSquareValue(font,val,x1_square,y1_square)
		sizeSquare = 96
		mid = sizeSquare / 2
		x_center = x1_square+mid
		x_text = x_center - font.text_width("#{val}")/2
		y_text = y1_square + 12
		if val !=0
			font.draw("#{val}",x_text,y_text,Zorder::UI,1,1,@fontColor)
		end
	end

	def clickedSquare()
		gridSize = 9
		grid = @sudokuTable.grid
		row = 0
		while row < gridSize
			col = 0
			while col < gridSize
				x = grid[row][col].x
				y = grid[row][col].y
				size = grid[row][col].size
				if areaClicked(x,x+size,y,y+size) && grid[row][col].touched == true
					return grid[row][col]
				end
				col+=1
			end
			row +=1
		end
	end

	def addNumberinSelectedSquare(number)
		row = @selectedSquare.row
		col = @selectedSquare.col
		@sudokuTable.grid[row][col].val = number
		@selectedSquare.val = number
	end

	def highlightDuplicateValue
		if @selectedSquare != nil
			row = @selectedSquare.row
			col = @selectedSquare.col
			num = @selectedSquare.val
			highlightDuplicateRowVal(row,num)
			highlightDuplicateColumnVal(col,num)
			highlightDuplicateBoxVal(row - row%3,col-col%3,num)
		end
	end

	def duplicateValueColor()
		return Gosu::Color.argb(0xff_ffbebd)
	end

	def selectedDuplicateColor()
		return Gosu::Color.argb(0xff_f79292)
	end
	
	def isDuplicateValue(row,col,num)
		if @sudokuTable.grid[row][col].val == num && @sudokuTable.grid[row][col].val != 0 && @sudokuTable.grid[row][col] != @selectedSquare
			return true
		else
			return false
		end
	end

	def highlightDuplicateSquare
		selectedColor =  selectedDuplicateColor()
		squareX = @selectedSquare.x
		squareY = @selectedSquare.y
		squareSize = @selectedSquare.size
		draw_quad(squareX,squareY,selectedColor,squareX+squareSize,squareY,selectedColor,squareX,squareY+squareSize,selectedColor,squareX+squareSize,squareY+squareSize,selectedColor,Zorder::PLAYER)
	end

	def highlightDuplicateBoxVal(row,col,num)
		boxSize = 3
		i = 0
		duplicateColor = duplicateValueColor()
		while i < boxSize
			j = 0
			while j < boxSize
				if isDuplicateValue(row+i,col+j,num)
					x = @sudokuTable.grid[row+i][col+j].x
					y = @sudokuTable.grid[row+i][col+j].y
					size = @sudokuTable.grid[row+i][col+j].size
					draw_quad(x,y,duplicateColor,x,y+size,duplicateColor,x+size,y,duplicateColor,x+size,y+size,duplicateColor,Zorder::PLAYER)
					highlightDuplicateSquare()
				end
				j+=1
			end
			i+=1
		end
	end

	def highlightDuplicateColumnVal(col,num)
		row = 0
		gridSize = 9
		duplicateColor = duplicateValueColor()   
		while row < gridSize
			if isDuplicateValue(row,col,num)
				x = @sudokuTable.grid[row][col].x
				y = @sudokuTable.grid[row][col].y
				size = @sudokuTable.grid[row][col].size
				draw_quad(x,y,duplicateColor,x,y+size,duplicateColor,x+size,y,duplicateColor,x+size,y+size,duplicateColor,Zorder::PLAYER)
				highlightDuplicateSquare()
			end
			row+=1
		end
	end

	def highlightDuplicateRowVal(row,num)
		col = 0
		gridSize = 9
		duplicateColor = duplicateValueColor()
		while col < gridSize
			if isDuplicateValue(row,col,num)
				x = @sudokuTable.grid[row][col].x
				y = @sudokuTable.grid[row][col].y
				size = @sudokuTable.grid[row][col].size
				draw_quad(x,y,duplicateColor,x,y+size,duplicateColor,x+size,y,duplicateColor,x+size,y+size,duplicateColor,Zorder::PLAYER)
				highlightDuplicateSquare()
			end
			col+=1
		end
	end

	def drawSolverButton
		buttonX1 = 1100
		buttonY1 = 200
		height = 75
		width = 300
		color = Gosu::Color.argb(0xff_b2dded)
		text = "Solver"
		@solverButton = Button.new(text,buttonX1,buttonY1,width,height)
		draw_quad(buttonX1,buttonY1,color,buttonX1+width,buttonY1,color,buttonX1,buttonY1+height,color,buttonX1+width,buttonY1+height,color,Zorder::PLAYER)
		drawTextButton(text,buttonX1,buttonY1,width,height,@solverButton.text_color)
		hoverEffect(buttonX1,buttonY1,width,height)
	end


	def hoverEffect(x,y,width,height)
		if areaClicked(x,x+width,y,y+height)
			padding = 5
			color = Gosu::Color::BLACK
			draw_quad(x-padding,y-padding,color,x+width+padding,y-padding,color,x-padding,y+height+padding,color,x+width+padding,y+height+padding,color,Zorder::BACKGROUND)
		end
	end

	def drawTextButton(text,x,y,width,height,color)
		marginLeft = 70
		font = Gosu::Font.new(60)
		x_center = x + marginLeft
		y_center = y + height/6
		font.draw(text,x_center,y_center,Zorder::PLAYER,1,1,color)
	end

	def isEmptyCell(grid,cell)
		gridSize = 9
		row = 0
		while row < gridSize
			col = 0
			while col < gridSize
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

	def isBoxSafe(grid,row,col,num)
		boxSize = 3
		i = 0
		while i < boxSize
			j = 0
			while j < boxSize
				if grid[row+i][col+j].val == num
					return false
				end
				j+=1
			end
			i+=1
		end
		return true
	end

	def isColumnSafe(grid,col,num)
		row = 0
		gridSize = 9
		while row< gridSize
			if grid[row][col].val == num
				return false
			end
			row+=1
		end
		return true
	end

	def isRowSafe(grid,row,num)
		gridSize = 9
		col = 0 
		while col < gridSize
			if grid[row][col].val == num
				return false
			end
			col+=1
		end
		return true
	end

	def isSafe(grid,row,col,num)
		checkedCol = isColumnSafe(grid,col,num)
		checkedRow = isRowSafe(grid,row,num)
		checkedBox = isBoxSafe(grid,row-row%3,col-col%3,num)
		if checkedBox && checkedCol && checkedRow
			return true
		end
		return false
	end

	def sudokuSolution(grid)
		cell = [0,0]
		if isEmptyCell(grid,cell)
			return true
		end
		row = cell[0]
		col = cell[1]
		num = 1
		while num < 10
			if isSafe(grid,row,col,num)
				grid[row][col].val = num
				if sudokuSolution(grid)
					return true
				end
				grid[row][col].val = 0
			end
			num+=1
		end
		return false
	end

	def clickedSolver()
		x_button = @solverButton.x
		y_button = @solverButton.y
		width = @solverButton.width
		height = @solverButton.height
		if areaClicked(x_button,x_button+width,y_button,y_button+height)
			resetTable()
			grid = @sudokuTable.grid
			solved = sudokuSolution(grid)
			return solved
		end
	end

	def drawResetButton
		buttonX1 = 1100
		buttonY1 = 300
		height = 75
		width = 300
		color = Gosu::Color.argb(0xff_b2dded)
		text = "Reset"
		@resetButton = Button.new(text,buttonX1,buttonY1,width,height)
		draw_quad(buttonX1,buttonY1,color, buttonX1 + width,buttonY1,color,buttonX1,buttonY1+height,color,buttonX1+width,buttonY1+height,color,Zorder::LAYOUT)
		drawTextButton(text,buttonX1,buttonY1,width,height,@resetButton.text_color)
		hoverEffect(buttonX1,buttonY1,width,height)
	end

	def clickedResetButton()
		buttonX = @resetButton.x
		buttonY = @resetButton.y
		width = @resetButton.width
		height = @resetButton.height
		if areaClicked(buttonX,buttonX+width,buttonY,buttonY+height)
			resetTable()
			@isClickedSolver = false
		end
	end

	def resetTable()
		@sudokuTable = readProblem()
		disabledSquare()
		@isClickedSolver = false
	end

	def isAnswerValid(grid)
		row = 0
		gridSize = 9
		set = Set.new()
		while row < 9
			col = 0
			while col < gridSize
				foundCol = "#{grid[row][col].val} found in col #{col}"
				foundRow = "#{grid[row][col].val} found in row #{row}"
				foundBox = "#{grid[row][col].val} found in box #{row} - #{col}"
				if set.include?(foundCol) || set.include?(foundRow) || set.include?(foundBox)
					return false
				else
					set.add(foundCol)
					set.add(foundRow)
					set.add(foundBox)
				end
				col+=1
			end
			row+=1
		end
		return true
	end

	def displayPassedMessage()
		if @isSolved == true
			font = Gosu::Font.new(60)
			fontX = 1100
			fontY = 100
			marginRight = 20
			message = 'Passed'
			tickedY = fontY+5
			tickedX = fontX + font.text_width(message)+marginRight
			font.draw(message,fontX,fontY,Zorder::PLAYER,1,1,@fontColor)
			ticked = Gosu::Image.new("./image/correct.png")
			ticked.draw(tickedX,tickedY,Zorder::LAYOUT,0.1,0.1)
		end
	end

	def drawDifficulty()
		x = 100
		y = 20
		font = Gosu::Font.new(50)
		difficulty = @sudokuTable.difficulty
		font.draw("Difficulty: #{difficulty}",x,y,Zorder::LAYOUT,1,1,Gosu::Color::BLACK)
	end

	def update
		grid = @sudokuTable.grid
		if @isClickedSolver == false
			@isSolved = isAnswerValid(grid)
		end
	end

	def button_down(id)
		case id
		when Gosu::MsLeft
			@selectedSquare = clickedSquare()
			@isClickedSolver = clickedSolver()
			clickedResetButton()
		end
		if @selectedSquare != nil
			case id
			when Gosu::Kb1
				@number = 1
				addNumberinSelectedSquare(@number)
			when Gosu::Kb2
				@number = 2
				addNumberinSelectedSquare(@number)
			when Gosu::Kb3
				@number = 3
				addNumberinSelectedSquare(@number)
			when Gosu::Kb4
				@number = 4
				addNumberinSelectedSquare(@number)
			when Gosu::Kb5
				@number = 5
				addNumberinSelectedSquare(@number)
			when Gosu::Kb6
				@number = 6
				addNumberinSelectedSquare(@number)
			when Gosu::Kb7
				@number = 7
				addNumberinSelectedSquare(@number)
			when Gosu::Kb8
				@number = 8
				addNumberinSelectedSquare(@number)
			when Gosu::Kb9
				@number = 9
				addNumberinSelectedSquare(@number)
			when Gosu::KbBackspace
				@number = 0
				addNumberinSelectedSquare(@number)
			end
		end
	end

	def draw
		drawBackground()
		drawSudokuTable()
		drawBorder()
		hightlightSelectedArea()
		highlightDuplicateValue()
		drawSolverButton()
		drawResetButton()
		displayPassedMessage()
		drawDifficulty()
	end
end

if __FILE__ == $0
	SudokuGameplay.new().show()
end