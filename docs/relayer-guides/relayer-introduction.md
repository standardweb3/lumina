# Relayer Introduction

Relayer is an external client to deliver the messages across blockchains. It was first introduced as Zone from Cosmos. It was supposed to be a sovereign chain made with Tendermint consensus to deliver cross-chain transactions in decentralized way between heterogeneous blockchains, but it now serves as an external client to deliver IBC standard messages between two Cosmos sovereign chains.&#x20;

Lumina's relayer follows the original vision of Cosmos Zone, but with more robust consensus to prevent 2/3 byzantine fault. Also, it extends the datagram standard to be adaptable to all kinds of cross-chain transaction format including IBC, XCMP, inscriptions, etc.
