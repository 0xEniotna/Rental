from starkware.starknet.public.abi import get_selector_from_name

selector = get_selector_from_name('approve')

print(selector)