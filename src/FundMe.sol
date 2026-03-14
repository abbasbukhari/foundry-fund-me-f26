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

    // The fund function is a payable function that allows users to send ETH to the contract. When a user calls the fund function and sends ETH, the function first checks if the amount of ETH sent (msg.value) is greater than or equal to the minimum required amount in USD (MINIMUM_USD) by using the getConversionRate function from the PriceConverter library. If the conversion rate of the sent ETH is less than the minimum required USD amount, the transaction will be reverted with an error message "You need to spend more ETH!". If the check passes, the function updates the addressToAmountFunded mapping to record how much ETH the sender has contributed and adds the sender's address to the funders array. This allows us to keep track of all contributors and their respective contributions to the contract.
    function fund() public payable {

        // The differnce between the two require statements is that the first one uses the getConversionRate function from the PriceConverter library directly on msg.value, which is possible because we have used the "using PriceConverter for uint256" statement at the beginning of the contract. This allows us to call the library function as if it were a method on the uint256 type. The second require statement calls the getConversionRate function from the PriceConverter library in a more traditional way, passing msg.value as an argument. Both statements achieve the same result, but the first one is more concise and takes advantage of Solidity's ability to extend types with library functions.

        // Why do we need to use "msg.value.getConversionRate() >= MINIMUM_USD" instead of "PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD"?

        // The reason we can use "msg.value.getConversionRate() >= MINIMUM_USD" instead of "PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD" is because of the "using PriceConverter for uint256" statement at the beginning of the contract. This statement allows us to call the functions in the PriceConverter library as if they were methods on uint256 types. When we write "msg.value.getConversionRate()", it is implicitly calling "PriceConverter.getConversionRate(msg.value)" under the hood. This syntactic sugar provided by Solidity makes our code cleaner and more readable, allowing us to use a more natural syntax when working with library functions.
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");

        // The addressToAmountFunded mapping which takes [msg.sender] as the key and adds the msg.value to the existing amount. This way, we keep track of how much each address has funded in total.
        // The [msg.sender] syntax is used to access the value associated with the sender's address in the mapping. By using +=, we are adding the new contribution (msg.value) to the existing amount that the sender has already funded, allowing us to maintain a cumulative total of their contributions.
        // In simple terms, this line updates the total amount of ETH that the sender has contributed to the contract by adding the new contribution to their previous total. example: if the sender has already funded 1 ETH and they send another 0.5 ETH, this line will update their total contribution to 1.5 ETH in the addressToAmountFunded mapping.
        addressToAmountFunded[msg.sender] += msg.value;

        // The funders array is updated by pushing the sender's address (msg.sender) into the array. This allows us to keep track of all the unique addresses that have funded the contract. By maintaining this list of funders, we can easily access and manage the contributors to our contract, such as when we need to reset their funded amounts during a withdrawal or for record-keeping purposes.
        funders.push(msg.sender);
    }

    // The getVersion function is a public view function that returns the version of the Chainlink price feed being used. It creates an instance of the AggregatorV3Interface using the address of the price feed contract (0x694AA1769357215DE4FAC081bf1f309aDC325306) and then calls the version() function on that instance to retrieve the version number. This function is useful for verifying that we are using the correct version of the price feed and can help with debugging or ensuring compatibility with different versions of the Chainlink contracts.
    function getVersion() public view returns (uint256) {

        // It is important to note that the address used to create the AggregatorV3Interface instance is specific to the network we are using (in this case, Sepolia). If we were to deploy this contract on a different network, we would need to update the address to point to the correct price feed contract for that network.
        // The priceFeed variable is an instance of the AggregatorV3Interface, which allows us to interact with the Chainlink price feed contract. By calling priceFeed.version(), we can retrieve the version number of the price feed, which can be useful for ensuring that we are using the correct version and for debugging purposes.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }
    // The onlyOwner modifier is a custom modifier that restricts access to certain functions in the contract to only the owner (the address that deployed the contract). It checks if the msg.sender (the address calling the function) is equal to i_owner (the owner's address). If the check fails, it reverts the transaction with a custom error FundMe__NotOwner. If the check passes, it allows the function to execute by using the _; statement. This modifier is used to protect sensitive functions, such as withdraw(), ensuring that only the owner can call them and preventing unauthorized access.
    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // The withdraw function is a public function that allows the owner of the contract to withdraw all the funds that have been contributed. It first iterates through the funders array and resets their funded amounts in the addressToAmountFunded mapping to 0. Then, it resets the funders array to an empty array. Finally, it uses the call method to transfer the entire balance of the contract to the owner's address (msg.sender). The call method is preferred over transfer and send because it forwards all available gas and does not impose a fixed gas limit, making it more flexible and less likely to fail due to gas issues. The function also checks if the call was successful and reverts with an error message "Call failed" if it was not.
    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the funders array to an empty array by creating a new array of type address with length 0. This effectively clears the list of funders, allowing us to start fresh for the next round of funding.
        funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // The above comments show the two older methods of transferring funds in Solidity: transfer and send. The transfer method automatically reverts if the transfer fails, while the send method returns a boolean indicating success or failure, which requires an additional require statement to handle the failure case. However, both of these methods have limitations, such as a fixed gas stipend of 2300 gas, which can cause transactions to fail if the recipient's fallback function requires more gas. The call method, on the other hand, forwards all available gas and does not impose a fixed limit, making it more flexible and less likely to fail due to gas issues. This is why the call method is now recommended for transferring funds in Solidity.

        // The call method is used to transfer funds in a more flexible way. It allows us to specify the amount of ETH to send and also forwards all available gas, which can help prevent issues with gas limits that may arise with the older transfer and send methods. In this case, we are sending the entire balance of the contract (address(this).balance) to the msg.sender (the owner). The call method returns a boolean indicating whether the transfer was successful, and we check this value to ensure that the transfer went through. If the call was not successful, we revert the transaction with an error message "Call failed". This approach provides a more robust and reliable way to handle fund transfers in our contract.

        // Lets breakdown the call method:
        // (bool callSuccess,) unpacks the two return values from .call:
        //   bool callSuccess  → true if the transfer succeeded, false if it failed cuz its a boolean
        //   (the bare comma)  → the second return value is raw bytes data; we don't need it here so we discard it

        // Breaking down: payable(msg.sender).call{value: address(this).balance}("")
        //
        // payable(msg.sender)        → the owner's wallet address, marked as able to receive ETH
        // .call{value: ...}          → send ETH to that wallet (.call is preferred over .transfer
        //                              because .transfer caps gas at 2300 units which can cause failures;
        //                              .call forwards all available gas)
        // address(this).balance      → the amount to send: the entire ETH balance held by this contract
        // ("")                       → no extra instructions attached, just send the money
        //
        // The return value is a tuple: (bool callSuccess, bytes memory data)
        // We only care about success, so we capture callSuccess and ignore the data with a bare comma.
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        // The require statement checks if the call was successful by evaluating the callSuccess boolean. If callSuccess is false, it means that the transfer of funds failed for some reason (e.g., the recipient's fallback function ran out of gas, or there was an issue with the recipient's address). In that case, the transaction will be reverted with the error message "Call failed". This ensures that we handle any potential issues with the fund transfer and maintain the integrity of our contract's state.
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

    // The Above diagram explains how the fallback and receive functions work in Solidity. When Ether is sent to a contract, the contract checks if there is any data attached to the transaction (msg.data). If msg.data is empty, it will first check if there is a receive() function defined in the contract. If receive() exists, it will be called to handle the incoming Ether. If receive() does not exist, or if msg.data is not empty, the fallback() function will be called instead. The fallback() function can be used to handle both cases: when there is data and when there isn't. In our contract, we have defined both fallback() and receive() functions to ensure that we can handle incoming Ether regardless of whether it comes with data or not. Both functions call the fund() function to process the incoming funds and update our mappings and arrays accordingly.


    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    // In the case of our FundMe contract, the fallback() and receive() functions are designed to call the fund() function whenever Ether is sent to the contract. This means that if someone sends Ether directly to the contract's address without calling the fund() function explicitly, the receive() function will be triggered (since msg.data will be empty), and it will call fund() to process the contribution. If someone sends Ether with data (e.g., by calling a non-existent function or sending a transaction with data), the fallback() function will be triggered, which also calls fund(). This ensures that all incoming Ether is properly handled and recorded in our contract, regardless of how it is sent.

    // The fallback() and receive() functions are essential for ensuring that our contract can handle incoming Ether in various scenarios. By implementing both functions, we can ensure that any Ether sent to the contract, whether it comes with data or not, will be processed correctly and contribute to the funding goals of our contract. This design allows for greater flexibility and robustness in handling transactions, making our contract more user-friendly and resilient to different types of interactions.

}

// What concepts did we cover in this contract?
// 1. Type Declarations (libraries, interfaces, contracts)
// 2. State Variables
// 3. Functions (constructor, receive, fallback)
// 4. Function Modifiers
// 5. Error Handling (require, revert, custom errors)
// 6. Gas Optimization (constant, immutable, custom errors) 

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly

// The above comments list some advanced concepts in Solidity that were not covered in this contract but will be explored in later sections. These concepts include:

// 1. Enum: A user-defined type that consists of a set of named values, which can be used to represent a collection of related constants in a more readable way.
// 2. Events: A way to log information on the blockchain that can be accessed by external applications, such as front-end interfaces or other contracts, to track changes in the contract's state or to trigger certain actions.
// 3. Try / Catch: A mechanism for handling exceptions in Solidity, allowing developers to gracefully handle errors that may occur during contract execution, such as failed external calls or invalid operations.
// 4. Function Selector: A unique identifier for each function in a contract, derived from the function's name and its parameter types, which is used to determine which function to call when a transaction is sent to the contract.
// 5. abi.encode / decode: Functions used to encode and decode data in a format that can be easily transmitted and understood by both contracts and external applications, often used for interacting with other contracts or for handling complex data structures.
// 6. Hash with keccak256: A cryptographic hashing function used in Solidity to generate a fixed-size hash from input data, which is commonly used for tasks such as generating unique identifiers, creating digital signatures, or implementing data integrity checks.
// 7. Yul / Assembly: A low-level programming language that can be used within Solidity to write more efficient code or to access features that are not directly available in Solidity, allowing developers to optimize certain parts of their contracts for better performance or to implement custom functionality.   