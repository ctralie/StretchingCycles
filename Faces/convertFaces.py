import os
from subprocess import call
from sys import argv, exit
import numpy as np
import scipy.io as sio

(STATE_IDLE, STATE_READTEX, STATE_READFACES) = (0, 1, 2)

#Extract the texture coordinates and faces from WRL files
#in the BU-3DFE dataset
def saveTexCoordsAndFaces(filePrefix):
	fHandle = open("%s.wrl"%filePrefix, 'r')
	texCoords = []
	faces = []
	
	state = STATE_IDLE
	
	for line in fHandle.readlines():
		if state == STATE_IDLE:
			fields = line.split()
			if len(fields) == 0:
				continue
			if fields[0] == "texCoord":
				state = STATE_READTEX
			elif fields[0] == "texCoordIndex":
				state = STATE_READFACES
		elif state == STATE_READTEX:
			fields = line.split(",")[0].split()
			if fields[0] == ']':
				state = STATE_IDLE
			else:
				texCoords.append([float(fields[0]), float(fields[1])])
		elif state == STATE_READFACES:
			fields = line.split(",")
			if len(fields) < 4:
				break
			#1-index for Matlab
			faces.append([int(fields[0]) + 1, int(fields[1]) + 1, int(fields[2]) + 1])
	
	texCoords = np.array(texCoords)
	faces = np.array(faces)
	
	fileOut = "%sTexCoords.mat"%filePrefix
	
	sio.savemat(fileOut, {'texCoords':texCoords, 'faces':faces})

if __name__ == '__main__':
	faces = ["F%.3i"%i for i in range(1, 10)]
	types = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise']
	for face in faces:
		for t in types:
			directory = "BU_4DFE/%s/%s"%(face, t)
			files = os.listdir(directory)
			counter = 0
			for f in files:
				if f[-3:] == "wrl":
					fnew = "%s.off"%f[0:-4]
					filePrefix = "%s/%s"%(directory, f[0:-4])
					print filePrefix
					command = "meshlabserver -i %s/%s -o %s/%s"%(directory, f, directory, fnew)
					print command
					os.system(command)
					counter = counter + 1
#					print ".",
#					if counter % 50 == 0:
#						print ""
					saveTexCoordsAndFaces(filePrefix)
			print "Finished %s"%directory
