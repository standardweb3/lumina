
/// executes txs without race conditions in production environment
/// example
/// const tx = await factory.connect(deployer).setFeeTo(deployer.address);
/// await executeTx(tx, "Execute setFeeTo at")
/// logs 
/// Executes setFeeTo at: 0xf81ded9ca5936a06f9a4ee53db8a568eb84ffd39095ff6dfe0ff5aa60bb98058

import { ethers } from "ethers";
import { ChainId, recordAddress, getAddress } from ".";

/// Mining...
export async function executeTx(tx: any, event: string) {
    console.log(`${event}: ${tx.hash}`);
    console.log("Mining...");
    await tx.wait();
    console.log("Mined!");
}
  
/// deploys a contract without race conditions in production environment
/// example
/// console.log(`Deploying Standard AMM router with the account: ${deployer.address}`);  
/// const Router = await ethers.getContractFactory("UniswapV2Router02");
/// const router = await Router.deploy(factory.address, weth);
/// await deployContract(router, "UniswapV2Router02")
/// logs 
/// UniswapV2Router02 address: 0x4633C1F0F633Cc42FD0Ba394762283606C88ae52
/// Mining...
export async function deployContract(deploy: ethers.Contract, contract: string){
    const chainId = (await deploy.provider.getNetwork()).chainId;
    // Get network from chain ID
    let chain = ChainId[chainId]
    console.log(`${contract} address at Chain Id of ${chain}:`, deploy.address);
    console.log(`Mining at ${deploy.hash}...`);
    await deploy.deployed();
    console.log("Mined!");
    await recordAddress(contract, chain, deploy.address)
}

export async function deploySubgraph(hre: any, contractName: any) {
  const chainId = (await hre.provider.getNetwork()).chainId;
  const address = getAddress(contractName, chainId);
  const a = hre.run('init', {contractName, address})
  .then(() => console.log(`Subgraph deployed at ${a}`))
  .catch((error: any) => {
    console.error(error);
    process.exit(1);
  });
}

export async function executeFrom(ethers: any, deployer: any, func: any) {
    // Get before state
    console.log(
      `Deployer balance: ${ethers.utils.formatEther(
        await deployer.getBalance()
      )} ETH`
    );
    await func()
    // Get results
    console.log(
      `Deployer balance: ${ethers.utils.formatEther(
        await deployer.getBalance()
      )} ETH`
    );
  }