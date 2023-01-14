import subprocess, json
from dotenv import load_dotenv
import os

from starkware.starknet.public.abi import get_selector_from_name

load_dotenv()

def run_command(cmd):
  out = subprocess.check_output(cmd.split(" "))
  return out.decode("utf-8")

selector = get_selector_from_name("initializer")
ACCOUNT = os.getenv('OWNER_ADDRESS')
print(selector)
owner_address=0x625029eba3d6fcdad88e2cc0af513a019275c11e1c46c43460f4db9cdf2cb45
implementation=0x3afe01ed713377a0c0a4200f44c7431aa7f4790e20d29826e43ee58b1990134
rental_hash=0x1ff06790b799add7d3c89bfc51b77fb2ad3861f98a06af79cd1f36c1121920b
proxy_class_hash=0xeafb0413e759430def79539db681f8a4eb98cf4196fe457077d694c6aeeb82

calldata_len=3
calldata=f"{ACCOUNT} {ACCOUNT} {rental_hash} {proxy_class_hash}"
# Rental constructor parameters are
#  proxy_admin: felt, _owner: felt, _rental_class_hash: felt
PK = '../../px.txt'
INPUTS= f"{implementation} {selector} {calldata_len} {calldata}"


###### TESTNET 1 ########

# print("BUILD")
# run_command("./protostar build")
# print("TEST")
# run_command("./protostar test")
# print("DECLARE")
# out = run_command(f"protostar --profile testnet1 declare ./build/proxy.json --account-address {ACCOUNT} --private-key-path {PK} --json --max-fee auto")
print("DEPLOY")
out = run_command(f"protostar --profile testnet1 deploy {proxy_class_hash} --inputs {INPUTS} --account-address {ACCOUNT} --private-key-path './pk.txt' --json --max-fee auto")


###### TESTNET 2 ########

# print("BUILD")
# run_command("./protostar build")
# print("TEST")
# run_command("./protostar test")
# print("DECLARE")
# out = run_command(f"protostar --profile testnet2 declare ./build/proxy.json --account-address {ACCOUNT} --private-key-path {PK} --json --max-fee auto")
# print("DEPLOY")
# out = run_command(f"protostar --profile testnet2 deploy {proxy_class_hash} --inputs {INPUTS} --account-address {ACCOUNT} --private-key-path {PK} --json --max-fee auto")

print(out)
print("DONE")


