// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// The contract imports the AggregatorV3Interface from the Chainlink library and the PriceConverter library. The AggregatorV3Interface is used to interact with the Chainlink price feed, while the PriceConverter library provides functions to convert ETH to USD using the price feed data.
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// Custom error for unauthorized access, which is more gas efficient than using require statements with strings.
error FundMe__NotOwner();

contract FundMe {

    // The contract uses the PriceConverter library for uint256 types, allowing us to call the library functions directly on uint256 variables. How that works is that the first parameter of the library function will be implicitly passed as the variable we call it on. For example, if we have a uint256 variable called amount, we can call amount.getConversionRate() and it will be equivalent to PriceConverter.getConversionRate(amount). This makes the code cleaner and more readable.

    // The PriceConverter library was written by Patrick Collins, and it provides two main functions: getPrice() which retrieves the current price of ETH in USD from the Chainlink price feed, and getConversionRate(uint256 ethAmount) which takes an amount of ETH and returns its equivalent value in USD using the price feed data. By using the library, we can easily convert between ETH and USD in our contract without having to write the conversion logic ourselves.
    using PriceConverter for uint256;

    // The mapping addressToAmountFunded keeps track of how much ETH each address has funded to the contract. It works by mapping an address (the funder's address) to a uint256 value (the amount of ETH they have sent). We do this so that we can keep track of how much each funder has contributed, which is useful for various reasons such as allowing funders to withdraw their funds or for record-keeping purposes.
    mapping(address => uint256) public addressToAmountFunded;

    // The public funders array keeops track of all the unique addresses that have funded the contract. We use an array to store the funders because we want to be able to iterate through them when we need to perform actions such as resetting their funded amounts during a withdrawal. By keeping track of the funders in an array, we can easily access and manage the list of contributors to our contract.
    address[] public funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ i_owner;
    // The above comment suggests that we could make the i_owner variable immutable instead of constant. The reason for this is that the value of i_owner is set in the constructor when the contract is deployed, and it cannot be changed afterwards. Immutable variables are similar to constants in that they cannot be modified after they are set, but they can be assigned a value at runtime (in the constructor), whereas constants must be assigned a value at compile time. Therefore, using immutable for i_owner allows us to set it to the deployer's address during deployment while still ensuring that it cannot be changed later on.

    // The MINIMUM_USD constant defines the minimum amount of USD (in terms of ETH) that a funder must send to the contract in order to be considered a valid contribution. In this case, it is set to 5 USD, which is represented as 5 * 10^18 to account for the fact that we are working with wei (the smallest unit of ETH). This means that funders must send at least 5 USD worth of ETH to the contract in order to be added to the list of funders and have their contribution recorded in the addressToAmountFunded mapping.
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;

    // The constructor function is a special function that is executed only once when the contract is deployed. In this case, the constructor sets the i_owner variable to the address of the account that deploys the contract (msg.sender). This means that the deployer of the contract will be the owner and will have special permissions, such as the ability to withdraw funds from the contract. By setting i_owner in the constructor, we ensure that it is initialized with the correct value at the time of deployment and cannot be changed later on.

    // msg.sender is a global variable in Solidity that represents the address of the account that is currently interacting with the contract. In the context of the constructor, msg.sender refers to the address of the account that is deploying the contract. By assigning msg.sender to i_owner, we are designating the deployer of the contract as the owner, who will have special permissions and control over certain functions within the contract, such as withdrawing funds. This allows us to implement access control and ensure that only the owner can perform certain actions on the contract.
    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly