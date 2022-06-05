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