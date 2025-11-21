# The Essence of Transient Storage

A small research project on EVM Transient Storage.

The main goal of this project is to provide a concise recap of Transient Storage. It was introduced in the Dencun fork, and discussions about it (in EIP-1153) began in 2019. Despite being an undoubtedly useful feature, it has not seen widespread adoption.

I am starting by comparing regular storage to transient storage, including gas metrics.

In the future it would be nice also to compare memory and transient storage

---

### Reentrancy Implementations: Storage vs Transient Storage

To make this comparison fair, all unrelated logic has been removed.
Because of this simplification, both implementations may exhibit unsafe behavior and **must not** be used in production.
They are included here **only for illustration**.

Comparing
[StorageLock.sol](./contracts/StorageLock.sol)
and
[TransientLock.sol](./contracts/TransientLock.sol),
we observe a dramatically large difference in gas consumption.

For clarity, all opcodes unrelated to storage or transient-storage access have been omitted.

---

#### Storage-Related Opcode Costs
For storage operations, the gas costs are written as cold(prewarmed using access list)  
All storage operations with cold (i.e. used at first time) slots 2100 gas require additionaly
| Operation | Gas Cost                   | Persistent | EIP  |
| --------- | -------------------------- | ---------- | ---- |
| `SLOAD`   | 100   | Yes        | 2929 |
| `SSTORE`  | 20,000 (0→1); 100 gas for access to dirty slot and Refund 19900 for writening back to original value (1->0 here) | Yes        | 2200 |
| `TLOAD`   | ~100                       | No         | 1153 |
| `TSTORE`  | ~100                       | No         | 1153 |

---

#### Gas Cost Differences Between Storage and Transient-Storage Reentrancy Locks

| Case                                       | Storage Opcodes Used        | Raw Gas Cost                    | Net Cost After Refund    |
| ------------------------------------------ | --------------------------- | ------------------------------- | ------------------------ |
| **StorageLock (normal execution)**         | `SLOAD`, `SSTORE`, `SSTORE` | (2100(1900) for SLOAD cold access) + 20000 + 100 +  = **22200(22000)** | 22200(22000) - 19900 = **2300(2200)** |
| **StorageLock (reverted by reentrancy)**   | `SLOAD`                     | **2100**                        | **2100** (no refund)     |
| **TransientLock (normal execution)**       | `TLOAD`, `TSTORE`, `TSTORE` | 100 + 100 + 100 = **300**       | **300** (no refund)      |
| **TransientLock (reverted by reentrancy)** | `TLOAD`                     | **100**                         | **100** (no refund)      |

### Corollary
Main difference between gas prices between storage and transient storage is that storage uses warming mechanism, which costs 2100(1900)(in fact 2000(1800) because SLoad is free when we are paying for cold access) gas and creates big difference between storage and transient storage realizations gas prices.