import os

for i in range(1, 18):
	os.popen3("meshlabserver -i %i.off -o %i.off -s butterfly.mlx"%(i, i))
