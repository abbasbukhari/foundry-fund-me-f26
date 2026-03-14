// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
// Importing the AggregatorV3Interface from the Chainlink contracts library. This interface allows us to interact with Chainlink price feeds to get the latest price data for ETH/USD.
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?

// The above questions are asking about the choice of using a library for the PriceConverter instead of an abstract contract or an interface. The reason for using a library in this case is that the PriceConverter is a collection of reusable functions that do not require any state variables or inheritance. Libraries in Solidity are designed to be stateless and can be called directly without needing to be deployed as a separate contract, which makes them ideal for utility functions like those in PriceConverter.
library PriceConverter {
    // We could make this public, but then we'd have to deploy it

    // The above comment suggests that if we were to make the getPrice function public, we would need to deploy the PriceConverter library as a separate contract on the blockchain. This is because public functions in a library can be called from other contracts, which requires the library to be deployed and have an address. By keeping the functions internal, we can use them directly within our main contract without needing to deploy the library separately, which simplifies our development process and reduces deployment costs.
    function getPrice() internal view returns (uint256) {
        // Sepolia ETH / USD Address
        // https://docs.chain.link/data-feeds/price-feeds/addresses

        // The above comments provide context for the getPrice function. It mentions that the function is using the Sepolia testnet's ETH/USD price feed address, which can be found in the Chainlink documentation. This means that when we call getPrice, it will fetch the latest ETH/USD price from the specified Chainlink price feed on the Sepolia testnet. This is useful for testing and development purposes, as it allows us to work with real-time price data without needing to use the mainnet.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        // latestRoundData() returns: (roundId, answer, startedAt, updatedAt, answeredInRound)
        // We only need answer (the ETH/USD price) — commas discard the rest
        // answer has 8 decimals: 200000000000 = $2,000.00
        // Therefore (, int256 answer, , , ) unpacks the tuple returned by latestRoundData, capturing only the answer and ignoring the other values. The answer is the current price of ETH in USD, which is returned with 8 decimal places. To convert it to a more standard format with 18 decimal places (like wei), we multiply it by 10^10 (or 10000000000) to shift the decimal point accordingly. This way, we can work with the price in a consistent format throughout our contract.
        // And then priceFeed.latestRoundData(); returns a tuple containing the latest price data, and we extract the answer (the ETH/USD price) from that tuple while ignoring the other values.
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        // We then return the price of ETH in USD, adjusted to have 18 decimal places by multiplying the answer (which has 8 decimals) by 10^10. This allows us to work with the price in a consistent format that is compatible with other values in our contract that also use 18 decimal places, such as wei amounts.
        // The reason it is multiplied by 10^10 is to convert the price from having 8 decimal places (as returned by the Chainlink price feed) to having 18 decimal places, which is a common standard in Ethereum for representing values in wei. This way, we can perform calculations with the price and other values in our contract without needing to worry about mismatched decimal places.
        return uint256(answer * 10000000000);
    }

    // The getConversionRate function takes an amount of ETH (in wei) as input and returns the equivalent value in USD (also in a format with 18 decimal places). It does this by first calling the getPrice function to get the current price of ETH in USD, and then multiplying that price by the amount of ETH to get the total value in USD. Finally, it divides by 10^18 to adjust for the fact that both the price and the amount of ETH are represented with 18 decimal places, ensuring that the final result is also in a consistent format.
    // Notice how this is a view function that doesn't modify state, and it can be called from other functions within the same contract or from external contracts that import this library. However it performs calculations based on the latest price data from the Chainlink price feed, so it will always return the most up-to-date conversion rate when called.
    function getConversionRate(
        // 1. getConversionRate() takes an ethAmount (in wei) as input and returns the equivalent USD value (also in a format with 18 decimal places).
        uint256 ethAmount
    ) internal view returns (uint256) {
        // 2. uint256 ethPrice = getPrice(); calls the getPrice() function to retrieve the current price of ETH in USD, which is returned with 18 decimal places.
        uint256 ethPrice = getPrice();
        // 3. uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; calculates the equivalent USD value of the given amount of ETH by multiplying the price of ETH (in USD) by the amount of ETH (in wei) and then dividing by 10^18 to adjust for the fact that both values are represented with 18 decimal places. This ensures that the final result is also in a consistent format with 18 decimal places, representing the USD value of the specified amount of ETH.
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.

        // The above comment explains that the ethAmountInUsd variable now holds the actual conversion rate of the specified amount of ETH to USD, after adjusting for the extra decimal places. This means that if you input a certain amount of ETH (in wei), the getConversionRate function will return the equivalent value in USD (also with 18 decimal places), allowing you to easily determine how much a given amount of ETH is worth in USD based on the latest price data from the Chainlink price feed.

        // 4. Finally, the function returns the calculated USD value of the specified amount of ETH, allowing other parts of the contract to use this conversion rate for various purposes, such as enforcing minimum funding amounts or calculating refunds.
        return ethAmountInUsd;
    }
}
