class SudokuTable
	attr_accessor :grid,:difficulty
	def initialize(grid,difficulty)
		@grid = grid
		@difficulty = difficulty
	end
end
