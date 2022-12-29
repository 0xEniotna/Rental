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
implementation=0x00ad184ddc9d7ac7cc53833be5b9b56550ac330dabf1d114d41379911607be1c
rental_hash=0x0402637b07042318060876540a157e8b9adf02c6503c9d0cdb2a65487051a06e
calldata_len=3
calldata=f"{ACCOUNT} {ACCOUNT} {rental_hash}"
# Rental constructor parameters are
#  proxy_admin: felt, _owner: felt, _rental_class_hash: felt
PK = 'px.txt'
INPUTS= f"implementation_hash={implementation} selector={selector} calldata_len={calldata_len} calldata={calldata}"

# print("BUILD")
# run_command("./protostar build")
# print("TEST")
# run_command("./protostar test")
# print("DECLARE")
# out = run_command(f"protostar --profile testnet2 declare ./build/proxy.json --account-address {ACCOUNT} --private-key-path {PK} --json --max-fee auto")
print("DEPLOY")
proxy_class_hash=0xeafb0413e759430def79539db681f8a4eb98cf4196fe457077d694c6aeeb82
out = run_command(f"protostar --profile testnet2 deploy {proxy_class_hash} --inputs {INPUTS} --account-address {ACCOUNT} --private-key-path {PK} --json --max-fee auto")

print(out)
print("DONE")


