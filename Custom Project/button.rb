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