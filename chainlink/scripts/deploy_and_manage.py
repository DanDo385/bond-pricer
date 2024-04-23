from brownie import Bond, accounts, config, network, ChainlinkVRF
import time

def main():
    account = accounts.add(config['wallets']['from_key'])
    
    # User input for bond parameters
    term_years = int(input("Enter the bond's term in years: "))
    daily_rate = float(input("Enter the bond's daily interest rate (as a percentage): "))

    # Deploy the bond contract
    bond = Bond.deploy(
        term_years,
        daily_rate,
        config['networks'][network.show_active()]['vrf_coordinator'],
        config['networks'][network.show_active()]['link_token'],
        config['networks'][network.show_active()]['keyhash'],
        {'from': account}
    )

    # Fund the contract with LINK
    link = ChainlinkVRF[-1]
    link.transfer(bond.address, "1 ether", {'from': account})

    # Request a random auction price
    request_id = bond.requestAuctionPrice({'from': account})
    print(f"Requested random auction price with request ID: {request_id}")

    # Wait for Chainlink VRF fulfillment
    time.sleep(180)  # Simulate waiting for the VRF callback

    # Retrieve the auction price
    print(f"Auction price is set to: {bond.auctionPrice()}")

if __name__ == "__main__":
    main()
