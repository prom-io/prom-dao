# Initial version of PromDao voting system

Interaction with PromDao smart contract give community of Token Holders a chance to change the state of
contracts that control Trade and Rental marketplaces of prom.io

Currently users may add and remove Trade and Rental Collection to the allow-list of marketplace contracts.
** Addition and removal of rental collections require also a submission of a new ActionValidator contract **

During a proposal submission users include in the function parameters an address of NFT collection they want to add or remove.
At the moment of block execution 14 days voting period for such proposal starts.

Users may vote for that proposal by staking their Prom tokens to the smart contract. In case users claim tokens back before
proposal voting period ends - their votes are getting removed from the proposal.votes field.

It is needed for holders of ** 20% of Prom Tokens ** to vote for a proposal to get it accepted.

After 14 days, if sufficient amounts of votes were received - anyone may call field setter in the Address Registry that will implement the proposal, while performing all the necessary checks.

Users may interact with the smart contracts directly through the Ether mainnet or binance scanners.
Contract method names and parameters are self-explanatory, which ensures an easy voting.

It is easy to track for existing proposals by calling the dedicated mapping or by tracking on the events.

It is impossible for Prom developers to override an approve proposal decision. Instead only new proposal may override such thing.
