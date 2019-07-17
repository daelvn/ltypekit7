MOONC="moonc"

all: clean compile

compile:
	moonc ltypekit
	moonc test

clean:
	find . -name '*.lua' -delete
