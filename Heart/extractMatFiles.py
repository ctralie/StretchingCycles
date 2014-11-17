from sys import exit, argv
import numpy as np
import scipy.io as sio

(START_STATE, READING_CONNECTIONS, READING_POINTS) = (0, 1, 2)

if __name__ == '__main__':
	if len(argv) < 3:
		print "Usage: python extractMatFiles.py <filein> <fileout>"
		exit(0)
	fin = open(argv[1], 'r')
	lines = fin.readlines()
	
	state = START_STATE
	NEdges = 0
	NVertices = 0
	NFrames = 0
	
	connections = []
	X = []
	Y = []
	Z = []
	frameNum = 0
	
	for line in lines:
		if line[0] == '#':
			continue
		fields = line.split()
		if len(fields) == 0:
			continue
		if state == START_STATE:
			if fields[0] == "connections":
				state = READING_CONNECTIONS
				NEdges = int(fields[1])
		elif state == READING_CONNECTIONS:
			if fields[0] == "points":
				NVertices = int(fields[1])
				NFrames = int(fields[2])
				#Allocate vertex positions
				X = np.zeros((NFrames, NVertices))
				Y = np.zeros((NFrames, NVertices))
				Z = np.zeros((NFrames, NVertices))
				state = READING_POINTS
				frameNum = 0
			else:
				fields = [int(f) for f in fields]
				connections.append(fields)
		elif state == READING_POINTS:
			if frameNum < NFrames:
				fields = [float(f) for f in fields]
				for i in range(0, NVertices):
					X[frameNum, i] = fields[3*i]
					Y[frameNum, i] = fields[3*i+1]
					Z[frameNum, i] = fields[3*i+2]
				frameNum = frameNum + 1
	
	connections = np.array(connections)
	sio.savemat(argv[2], {'edges':connections, 'X':X, 'Y':Y, 'Z':Z})
