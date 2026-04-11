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
param_fmt = 'IIffffIIIII'+md5sum_fmt+'ffffffffff'
param_fields = ['magic', 'timstamp_of_boost_detect_ms', 'pre_boost_pressure','bias_x_dps', 'bias_y_dps', 'bias_z_dps', 'bootcount', 'lockout_ms', 'num_flight_packets', 'num_preboost_packets', 'num_gyro_bias_packets', 'md5', 'up_axis_q1', 'up_axis_q2', 'up_axis_q3', 'up_axis_q4', 'atmo0', 'atmo1', 'atmo2', "atmo3", "atmo4", "atmo5"]



data_fmt = 'Iffffffffffffffffffffffff'
data_size = struct.calcsize(data_fmt)
data_fields = ['timestamp_ms', 'temp_c', 'pressure_kpa', 'accel_x_m_s2', 'accel_y_m_s2', 'accel_z_m_s2', 'gyro_x_dps', 'gyro_y_dps', 'gyro_z_dps','e_alt_m', 'e_vel_m_s', 'e_acc_m_s2', 'e_bias', 'innovation0', 'innovation1', 'r1c1', 'r1c2', 'r1c3', 'r2c1', 'r2c2', 'r2c3', 'r3c1', 'r3c2', 'r3c3', 'effort']

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
		f.write(", ".join(param_fields))
		f.write("\n")
		f.write(", ".join([fmtAllAndBytesAsHex(p) for p in paramsS]))
else:
	print("No Params Found", file=sys.stderr)

if len(data) > 0:
	binary = base64.standard_b64decode(bytes(data, 'utf-8'))
	num_whole_pacs = len(binary)//data_size
	datas= struct.iter_unpack(data_fmt, binary[:num_whole_pacs * data_size])
	with open(data_path, 'w') as f:
		f.write(", ".join(data_fields)+"\n")
		for data in datas:
			f.write(", ".join([str(d) for d in data])+"\n")
else:
	print("No Data Found", file=sys.stderr)
