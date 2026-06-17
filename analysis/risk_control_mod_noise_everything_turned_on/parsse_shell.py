import sys
import re
import itertools
import struct
import base64
import os


if (len(sys.argv)) !=4 :
	print("usage: log_file_in param_file_out data_file_out", file=sys.stderr)
	sys.exit(-1)


path = sys.argv[1]
param_path = sys.argv[2]
data_path = sys.argv[3]

PSTART='----++++//[[( params start )]]\\\\++++----'
PEND='----++++//[[( params end )]]\\\\++++----'

DSTART='----++++//[[( data start )]]\\\\++++----'
DEND='----++++//[[( data end )]]\\\\++++----'


md5sum_fmt = '16s' # 16 byte string
param_fmt = 'IIffffIIIII'+md5sum_fmt+'ffffHHHH'
param_fields = ['magic', 'timestamp_of_boost_detect__ms', 'pre_boost_pressure__kpa','bias_x__dps', 'bias_y__dps', 'bias_z__dps', 'bootcount', 'lockout__ms', 'num_flight_packets', 'num_preboost_packets', 'num_gyro_bias_packets', 'md5', 'up_axis_q1', 'up_axis_q2', 'up_axis_q3', 'up_axis_q4', "max_effort_iterations", "dead_time_iterations", "observation_time_iterations", "random_number"]



data_fmt = 'IHhfffffffffffffffffffffff'
data_size = struct.calcsize(data_fmt)
data_fields = ['timestamp__ms', 'state_and_upcounter' , 'temp__cc', 'pressure__kpa', 'accel_x__m_s2', 'accel_y__m_s2', 'accel_z__m_s2', 'gyro_x__dps', 'gyro_y__dps', 'gyro_z__dps','e_alt__m', 'e_vel__m_s', 'e_acc__m_s2', 'e_bias', 'innovation0', 'innovation1', 'r1c1', 'r1c2', 'r1c3', 'r2c1', 'r2c2', 'r2c3', 'r3c1', 'r3c2', 'r3c3', 'effort']

# if len(param_fmt) != len(param_fields):
# 	print("Param packet and labels mismatch", file=sys.stderr)
# 	sys.exit(-1)


if len(data_fmt) != len(data_fields):
	print("Data packet and labels mismatch", file=sys.stderr)
	sys.exit(-1)


def gen(start, end, lines):
	do = False
	for line in lines:
		if end in line:
			break
		if do:
			yield line.replace('\n', "")
		if start in line:
			do = True


with open(path, 'r') as fp:
	lines = fp.readlines()
	params = "".join([line for line in gen(PSTART, PEND, lines)])
	data= "".join([line for line in gen(DSTART, DEND, lines)])




def fmtAllAndBytesAsHex(n):
	if isinstance(n, bytes):
		return n.hex()
	return str(n)

if len(params) > 0:
	binary = base64.standard_b64decode(bytes(params, 'utf-8'))
	paramsS = struct.unpack(param_fmt, binary)
	with open(param_path, 'w') as f:
		f.write(",".join(param_fields))
		f.write("\n")
		f.write(",".join([fmtAllAndBytesAsHex(p) for p in paramsS]))
else:
	print("No Params Found", file=sys.stderr)

if len(data) > 0:
	binary = base64.standard_b64decode(bytes(data, 'utf-8'))
	num_whole_pacs = len(binary)//data_size
	datas= struct.iter_unpack(data_fmt, binary[:num_whole_pacs * data_size])
	with open(data_path, 'w') as f:
		f.write(",".join(data_fields)+"\n")
		for data in datas:
			f.write(",".join([str(d) for d in data])+"\n")
else:
	print("No Data Found", file=sys.stderr)
