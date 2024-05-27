run: build
	docker run -it --rm bigscript

build:
	docker build -t bigscript .
