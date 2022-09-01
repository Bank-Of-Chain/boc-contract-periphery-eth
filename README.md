# Documentation
## What is BOC

BOC (Bank Of Chain) is a new and innovative platform in the decentralized finance ([DeFi](../more/appendix.md#decentralized-finance-defi)) ecosystem. It helps ordinary users to obtain a near "risk-free" wealth management tool on the [blockchain](../more/appendix.md#blockchain-network).

The BOC platform connects carefully selected protocols within the crypto ecosystem, including [Automatic Market Makers (AMMs)](../more/appendix.md#automated-market-maker-amm), [lending protocols](../more/appendix.md#lending-protocol), [yield aggregators](../more/appendix.md#yield-aggregators), among others. (see [Dashboard](https://dashboard.bankofchain.io/#/) for details).

By accessing high-quality [protocols](../more/appendix.md#protocol) and smart [strategies](../more/appendix.md#strategy), BOC provides a 4-5% more APY than other similar USD managed funds.

This is the best way to start in the DeFi ecosystem for newcomers to the crypto industry. As a one-click protocol, BOC will bring a new revolution to the DeFi industry, attracting hundreds of millions of dollars of investment.

## BOC Source of Yield

BOC is a DeFi protocol that provides the best long-term near "risk-free" return. Depending on the strategy the sources of yield come from:

* The transaction fee charged for providing market-making funds to decentralized exchanges [(DEX)](../more/appendix.md#decentralized-exchanges-dexs).
* The interest charged on funds borrowed for [over-collateralized loans](../more/appendix.md#Over-collateralized-loans).
* [Governance token's](../more/appendix.md#governance-token) rewards.

## Fund Allocation Rules

* High-yield [liquidity pools](../more/appendix.md#liquidity-pool) have allocation priority.
* The capital invested in a single liquidity pool cannot exceed 20% of the total assets under management.
* The capital allocated to a single liquidity pool cannot exceed 50% of their existing lock-up amount.
* The total capital invested on different liquidity pools from the same protocol cannot exceed 30% of the total assets under management.
* Funds allocation is adjusted automatically to ensure the most cost-efficient position.

The existing DeFi protocols present the following problems:

* [Impermanent losses](../more/appendix.md#impermanent-loss) in decentralized exchanges from market makers. In 2021, UniswapV3’s market-making revenue was about $200 million, but [those pools have suffered impermanent losses of $260 million](https://cointelegraph.com/news/half-of-uniswap-v3-liquidity-providers-are-losing-money-new-research), resulting in a total net loss of $60 million.
* [Circular dependencies](../more/appendix.md#circular-dependencies) for yield aggregators.
* High investment thresholds.
* Present a complex user interface and requires high-expertise in DeFi investments.
* Requirement of multiple cryptocurrencies.

## What makes BOC different?

BOC is the first Decentralized Bank (DeB), where you can deposit your crypto assets and automatically BOC´s smart contracts will perform decentralized investing by carefully running selected strategies on different high-quality DeFi protocols to create long-term stable income near "risk-free".

The main characteristics that make BOC a unique product are:

**Bank-like Structure:**

1. Bank-like user interface.
  * Users can deposit and withdraw directly without considering the difficulties of implementing complex operations such as farming, exchange, and reallocation. BOC makes the best selection for them.
  * Historical and dynamic returns are intuitively visible.
2. Bank-like service.
  * Wealth management tool on the blockchain.
  * Lendings (to be implemented)
3. Bank-deposit-like tokens (USDi & ETHi):
  * Fully liquid.
  * Interest-bearing.
  * Fully backed.
  * 1:1 pegged.

**Oustanding DeFi Protocols:**

1. The strategies and movement of funds have full transparency.
2. Provides a sustainable yield.
3. Performs due diligence to all stakeholders before any further collaborations.
4. It's dummy-proof.

**Prioritized Safety Features:**

1. The market cap of qualified stablecoins exceeds 1 billion dollars.
2. The TVL of qualified Blockchains exceeds 5 billion dollars.
3. It has third-party auditing in place.
4. It only uses authorized third-party cross-chain bridges for transactions.
5. Its oracles are attack-proof. The price quotation relies on Chainlink, a market-leading oracle.

**Equipped with Risk Control Measures:**

1. It minimizes the de-anchoring risk of stablecoins.
2. It reduces the risk of impermanent loss. BOC uses market-making for [stablecoin](../more/appendix.md#stablecoin) pairs only.
3. The systemic risk is optimized by the highly selective wrapped [tokens](../more/appendix.md#token) and yield aggregators.
4. Algorithmic stablecoin are prohibited.
5. Any leverage function is provided.
6. Circular dependency is constantly being studied to avoid it.

**Smart Automation:**

1. Yields are regularly calibrated, weighing the cost and reward for funds reallocation.
2. It searches for the optimum rate regularly through exchange aggregators.
3. It performs FX interest swap, adjusting FX synthesis based on the exchange rate and yield.
4. Parameters are automatically set for market-making and lending strategy.

In summary, BOC Platform is the missing catalyst that will revolutionize the industry, generating a new route to interact with the DeFi Ecosystem, making it a safe path for newcomers.

## Project startup steps

* Copy a copy of `dev-keys.json.sample` in the root path, change the name to `dev-keys.json`, and configure the `alchemyKey` you applied for
* Install project dependencies through the `yarn install` command.
* Start local chain via `yarn chain`
* Execute contract initialization deployment via `yarn deploy`

  *For detailed operations and problems, please refer to the follow-up documents. *

## Steps
### install yarn

````
npm i yarn -g
````

### Install project dependencies

````
// execute in root directory
yarn install
````

### Start local chain

````
// execute in root directory
yarn chain
// or
npx hardhat node // custom parameters, refer to hardhat documentation
````
### Deploy the contract to the local chain

> Currently, when deploying the contract, several USDT coins will be injected into accounts[0], accounts[1], and accounts[2] users. It is recommended to use this user for self-testing.

````
// execute in root directory
yarn deploy
````
## common problem

### yarn installation failed

> [Install hardhat project dependencies] or [Install front-end project dependencies], you can install it again through npm or cnpm

````
// cnpm way:
npm install cnpm -g
cnpm install

// the npm way
npm install
````

### During the installation process, no permission to access a git repository

````
npm ERR! fatal: unable to access 'https://github.com/web3-js/WebSocket-Node.git/': OpenSSL SSL_read: Connection was aborted, errno 10053
// After the console performs the following configuration, install it again.
git config --global url."https://".insteadOf git://
````

## Security plugin
use [Slither](https://github.com/crytic/slither).
````
slither . --detect abiencoderv2-array,array-by-reference,incorrect-shift,multiple-constructors,name-reused,public-mappings-nested,rtlo,shadowing-state,suicidal,uninitialized-state,uninitialized-storage,unprotected-upgrade,arbitrary-send,controlled-array-length,controlled-delegatecall,delegatecall-loop,msg-value-loop,reentrancy-eth,storage-array,unchecked-transfer,weak-prng,enum-conversion,erc20-interface,erc721-interface,incorrect-equality,locked-ether,mapping-deletion,shadowing-abstract,tautology,write-after-write,boolean-cst,constant-function-asm,constant-function-state,divide-before-multiply,reentrancy-no-eth,reused-constructor,tx-origin,unchecked-lowlevel,unchecked-send,uninitialized-local,unused-return --checklist >./slither_check_result.md
````