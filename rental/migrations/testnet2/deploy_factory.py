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
implementation=0x1eee9a17aa1c9ca97d18dcb2be4c678a7d1b7553f0ba3b591396943d27c7a45
calldata_len=3
calldata=f"{ACCOUNT} {ACCOUNT} 0x7522d3edaefb05fe2e1395653f648ecec3c46e1314d9a3d1c342b258950ecf2"
# Rental constructor parameters are
#  proxy_admin: felt, _owner: felt, _rental_class_hash: felt
PK = 'px.txt'
INPUTS= f"implementation_hash={implementation} selector={selector} calldata_len={calldata_len} calldata={calldata}"

# print("BUILD")
# run_command("./protostar build")
# print("TEST")
# run_command("./protostar test")
print("DECLARE")
out = run_command(f"protostar --profile testnet2 declare ./build/proxy.json --account-address {ACCOUNT} --private-key-path {PK} --json --max-fee auto")
print("DEPLOY")
class_hash = json.loads(out)['class_hash']
out = run_command(f"protostar --profile testnet2 deploy {class_hash} --inputs {INPUTS} --account-address {ACCOUNT} --private-key-path {PK} --json ")
# print("CALL")
# contract_address = json.loads(out)['contract_address']
# out = run_command(f"./protostar call --contract-address {contract_address} --function get_balance --json")
print(out)
print("DONE")


