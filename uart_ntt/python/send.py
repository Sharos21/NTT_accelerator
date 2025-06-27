#%%
import serial
import re
import numpy as np
import time
from tqdm import tqdm

# Serial port can be found with Serial Monitor extension
ser = serial.Serial(f"COM7", 115200)

with open('./bytes.txt','r') as file:
  _bytes = file.read()
  _bytes = _bytes.strip("\n").split("\n")
  _bytes = list(
    [bytes.fromhex(b) for b in _bytes]
  )

  # Number of WORDS (Bytes/4)
  hex_str = f"{len(_bytes)//4:08x}"
  inv_hex_str = re.findall(r"\S{2}", hex_str)[::-1]
  inv_hex_str = list(
    [bytes.fromhex(b) for b in inv_hex_str]
  )

  # Start address
  start_addr_bs = list([b'\x00']*4)

  # Total bytes to send with UART are:
  _bytes = start_addr_bs + inv_hex_str + _bytes

  # print(start_addr_bs + inv_hex_str + _bytes)

  for b in tqdm(_bytes):
    ser.write(b)
    # time.sleep(0.005)