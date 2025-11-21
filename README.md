# The Essence of Transient Storage

A small research project on EVM Transient Storage.

The main goal of this project is to provide a concise recap of Transient Storage. It was introduced in the Dencun fork, and discussions about it (in EIP-1153) began in 2019. Despite being an undoubtedly useful feature, it has not seen widespread adoption.

I am starting by comparing regular storage to transient storage, including gas metrics.

**Future Scope:** Comparison between Memory and Transient Storage costs.

---

### 1. Reentrancy Protection: Storage vs Transient Storage

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
For storage operations, the gas costs depend heavily on whether the slot is "cold" (accessed for the first time in the transaction) or "warm".

| Operation | Gas Cost (Warm) | Gas Cost (Cold) | Persistent | EIP |
| --------- | --------------- | --------------- | ---------- | --- |
| `SLOAD`   | 100             | 2100            | Yes        | 2929|
| `SSTORE`  | 100 (dirty)     | 22100 (init)    | Yes        | 2200|
| `TLOAD`   | 100             | 100             | No         | 1153|
| `TSTORE`  | 100             | 100             | No         | 1153|

*Note: `SSTORE` costs vary significantly based on the current value, new value, and original value (e.g., 20k gas for 0->1, 5k for 1->2, refunds for clearing).*

---

#### Gas Cost Differences Between Storage and Transient-Storage Reentrancy Locks

| Case                                       | Storage Opcodes Used        | Raw Gas Cost                    | Net Cost After Refund    |
| ------------------------------------------ | --------------------------- | ------------------------------- | ------------------------ |
| **StorageLock (normal execution)**         | `SLOAD`, `SSTORE`, `SSTORE` | (2100(1900) for SLOAD cold access) + 20000 + 100 +  = **22200(22000)** | 22200(22000) - 19900 = **2300(2100)** |
| **StorageLock (reverted by reentrancy)**   | `SLOAD`                     | **2100**                        | **2100** (no refund)     |
| **TransientLock (normal execution)**       | `TLOAD`, `TSTORE`, `TSTORE` | 100 + 100 + 100 = **300**       | **300** (no refund)      |
| **TransientLock (reverted by reentrancy)** | `TLOAD`                     | **100**                         | **100** (no refund)      |

[Detailed opcodes costs](https://www.evm.codes)
Also details about SSTORE/SLOAD opcodes costs and cold/warm access: [EIP2929](https://eips.ethereum.org/EIPS/eip-2929) and continued in [EIP2930](https://eips.ethereum.org/EIPS/eip-2930)
#### Corollary
For both successful and reverted execution, we observe a **~2000 gas difference**.

The primary cost difference stems from the **"Cold Load" penalty** in regular storage. Accessing a storage slot for the first time costs ~2100 gas, whereas transient storage slots are always "warm" and cost only 100 gas. This makes transient storage ideal for temporary state like reentrancy locks.

---

### 2. Context Passing (Callback) Pattern
Another powerful use case is passing context to callbacks without polluting `msg.data` or using expensive storage. 
Actually using Transient storage costs more gas than using calldata if there are not many indermediate contracts(<3-4) But Transient storage allows:
- to pass context to callbacks without polluting `msg.data`
- pass data which couldn't be passed to untrusted intermediate contracts, because they can modify it. (Storage can be used. But it will cost thousands of gas)

See [TransientContext.sol](./contracts/TransientContext.sol).

**Scenario:**
1. Contract A sets a "Context" (e.g., who is the real initiator etc) in transient storage.
2. Contract A calls Contract B.
3. Contract B calls back Contract A (e.g., `receive()` or a specific callback).
4. Contract A reads the "Context" from transient storage to know who initiated the flow.

**Benefit:**
- Gas Efficiency for cases where is is impossible to pass data through intermediate contracts(security reasons e.g.): `TSTORE`/`TLOAD` (100 gas) vs `SSTORE`/`SLOAD` (thousands of gas).
- Cleaner Interfaces: No need to append extra arguments to every function call just to pass context through intermediate contracts. 