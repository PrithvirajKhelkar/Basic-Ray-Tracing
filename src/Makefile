OBJ = main.o
INC = -I "./"

ray_tracer: $(OBJ)
	g++ $(OBJ) -o ray_tracer.exe
	rm -f $(OBJ)

main.o:
	g++ -c main.cpp $(INC)

clean:
	rm -f $(OBJ) ray_tracer
