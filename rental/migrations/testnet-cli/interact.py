import subprocess, json
from dotenv import load_dotenv
import os

from starkware.starknet.public.abi import get_selector_from_name

load_dotenv()

def run_command(cmd):
  out = subprocess.check_output(cmd.split(" "))
  return out.decode("utf-8")



contract_address = 0x06a731547c278a64dc4a92ca91db6845d76ff3b762d5103e2edcea9f301b7c5e
OWNER= 0x0443880faaa6a2dacd3c1d7cafd3cc42bd9be74afb26124d04a1ae3a8b91fcf2
INPUTS=f"{0x0625029EBA3D6fCdaD88E2Cc0AF513a019275c11E1C46C43460f4DB9CDf2Cb45} 1"
print("INVOKE")
out = run_command(f"protostar --profile testnet2 invoke --contract-address {contract_address} --function approve --inputs {INPUTS} --account-address {OWNER} --private-key-path ./pk.txt --json --max-fee 100000000000 --json")
print(out)
print("DONE")


