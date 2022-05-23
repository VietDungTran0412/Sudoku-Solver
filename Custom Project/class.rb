class Button
	attr_accessor :text,:x,:y,:width,:height,:text_color
	def initialize(text,x,y,width,height,text_color)
		@text = text
		@x = x
		@y = y
		@width = width
		@height = height
		@text_color = text_color
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
	attr_accessor :grid,:difficulty
	def initialize(grid,difficulty)
		@grid = grid
		@difficulty = difficulty
	end
end
