# ShitToken (SHIT) — Website Version — Bytecode Verification

Byte-for-byte bytecode verification for the **website version** of ShitToken at
[`0xdbd98373c5152963AE9940E0477f078bd28aC411`](https://ethereumhistory.com/contract/0xdbd98373c5152963ae9940e0477f078bd28ac411),
the variant linked from [shitcoingod.github.io](https://shitcoingod.github.io/shittoken/)
and announced on [BitcoinTalk](https://bitcointalk.org/index.php?topic=2041542.0).

This is **not** the same contract as
[`0x337Bc91…`](https://github.com/cartoonitunes/shittoken-verification)
— that earlier deployment (block 4,061,425) was a first draft. The website
version was redeployed 19 minutes later with a different supply model:
the entire 151 SHIT supply is pre-minted to `ShitCoinGod`, and buyers
purchase from the deployer's balance via the fallback function (allowance +
`transferFrom`) rather than from an unallocated pool.

| Field | Value |
|---|---|
| Contract | `0xdbd98373c5152963AE9940E0477f078bd28aC411` |
| Network | Ethereum Mainnet |
| Block | 4,061,483 |
| Deployed | 2017-07-23 08:12:14 UTC |
| Deployer | `0xc952b2016f059483b8e365f3e53636ef0fe6fe6d` (ShitCoinGod) |
| Creation tx | `0x0cd145b9f89b0af848648111cfa36a59e57a9ecae590f01269eab89b98eb271a` |
| Compiler | `solc 0.4.11+commit.68ef5810.Darwin.appleclang` (native, not soljson) |
| Optimizer | ON, runs=1 |
| SafeMath | library + `using SafeMath for uint256;` |
| Runtime match | Exact bytecode (32-byte CBOR/swarm metadata hash differs only) |
| Runtime size | 2,317 bytes |

## Verification

```bash
./verify.sh
```

The script fetches the on-chain runtime via a public RPC, compiles
`ShitToken.sol` with native `solc 0.4.11`, optimizer ON, runs=1, and compares.
The first 2,283 of 2,317 runtime bytes are byte-for-byte identical; only the
trailing 32-byte Swarm metadata hash inside the CBOR section differs (it's a
content hash of the source file path/layout and cannot be reproduced from the
source code alone).

Tested with native `solc` from `solc-select install 0.4.11`.

## Difference from the first ShitToken (`0x337Bc91…`)

Same source structure, **one behavioral change** in the constructor:

| | First draft (`0x337Bc91…`) | Website version (`0xdbd98373…`) |
|---|---|---|
| Block | 4,061,425 | 4,061,483 (≈19 min later) |
| `balances[ShitCoinGod] = INITIAL_SUPPLY;` in constructor | **No** (full 151 supply unclaimed) | **Yes** (full 151 supply pre-minted to deployer) |
| Fallback function | Mints to buyer via direct `balances[]` writes | Sets `allowed[ShitCoinGod][msg.sender]` and calls `transferFrom(ShitCoinGod, msg.sender, tokens)` — pulls from deployer's balance |
| `Transfer` events for purchases | Emitted from a synthetic `0x0` mint | Emitted as a real transfer from `ShitCoinGod` |

The *economic outcome* is identical (`10 SHIT per 1 ETH`, capped at 151 SHIT
total), but the second version uses the standard "sell from owner" pattern:
the supply exists in the deployer's wallet from genesis and the fallback
function is just a swap, not a mint. This is the version that was advertised
on the project website.

## What this contract does

ShitToken (`SHIT`) is a **satirical anti-ICO** token deployed in July 2017,
at the height of the ICO bubble. It mocked ICO mechanics by:

- **Capped supply of 151 SHIT** — a deliberate reference to the original 151
  Pokémon, not "1 trillion to the moon."
- **Full pre-mint to deployer.** All 151 SHIT exist in `ShitCoinGod`'s
  balance from deployment. There is no founder/team/marketing allocation
  beyond that — sales reduce the deployer's holdings 1:1.
- **Deployer named `ShitCoinGod`.** Stored on-chain as a `public address`.
- **Fixed price `10 SHIT per 1 ETH`** in the fallback function. No bonding
  curve, no whitelist, no presale rounds, no vesting. Send ETH, the contract
  pulls tokens from the deployer's balance and forwards them to you.
- **`claimMoney()`** is the only owner-privileged function: it sends
  `this.balance` to `ShitCoinGod`. There is no admin mint, pause, blacklist,
  or upgrade.
- ERC-20 compliant: `transfer`, `transferFrom`, `approve`, `allowance`,
  `balanceOf`, `totalSupply`, plus standard `Transfer`/`Approval` events.
- Uses `SafeMath` as a separate library with the `using SafeMath for uint256;`
  pattern — early example of the library/using-for idiom that became standard
  in OpenZeppelin contracts.

## Historical context

- **BitcoinTalk thread:** https://bitcointalk.org/index.php?topic=2041542.0
- **Original website:** https://shitcoingod.github.io/shittoken/

ShitToken predates "fair launch" memecoins (SHIB, FOMO, etc.) by three years
and predates DeFi-era zero-pre-mine launches (YFI, July 2020) by exactly that.
It was a working ERC-20 with a credible no-rug structure deployed as a joke
about the surrounding token sales of mid-2017.

The website version (this contract) is the deployment that was actually
linked from the project's announcement page and BitcoinTalk thread; the
earlier `0x337Bc91…` deployment is unreferenced and appears to be an
abandoned first draft.

## Files

- [`ShitToken.sol`](ShitToken.sol) — reconstructed source, byte-for-byte
- [`ShitToken.abi.json`](ShitToken.abi.json) — ABI generated by solc
- [`verify.sh`](verify.sh) — reproducible verification script

Part of [Ethereum History](https://ethereumhistory.com/proofs).

## License

[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) — Public domain.
