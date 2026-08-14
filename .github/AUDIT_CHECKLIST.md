# Manual Audit Checklist — Sepolia Testnet Deployment Gate

**Reviewer:** ________________  
**Date:** __________  
**Commit:** __________

---

## Functional

- [ ] Minting path (`createRandomArtWork`) accepts exact fee; excess not silently lost.
- [ ] `withdraw` transfers full balance only to owner.
- [ ] `levelUp` enforces `ownerOf(_artId) == msg.sender`.
- [ ] `updateFee` is `onlyOwner`.

## Security

- [ ] No reentrancy in `_createArtWork` (state written before external `_safeMint`).
- [ ] Randomness via `block.timestamp` documented as weak — accepted for non-value-critical traits.
- [ ] `transfer()` in `withdraw` is bounded to contract balance (no DoS via push).
- [ ] `infoSmartContract` does not leak sensitive info.
- [ ] `getOwnerArtWork` gas usage acceptable at expected NFT count (avoid unbounded loop).

## Operational (Sepolia Specific)

- [ ] Owner is a multisig / Safe on Sepolia.
- [ ] Deployer wallet has sufficient Sepolia ETH for deployment gas.
- [ ] Verified on Sepolia Etherscan; constructor args published.
- [ ] Initial fee (`5 ether`) represents test parameters for Sepolia.
- [ ] RPC URL endpoint is stable and rate-limit safe (e.g., Alchemy/Infura Sepolia endpoint).

## Sign-off

- [ ] All findings below "High" have been triaged.
- [ ] Final go/no-go decision recorded.

---

**Decision:** [ ] GO  [ ] NO-GO