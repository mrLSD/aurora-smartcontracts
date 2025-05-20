import hre from "hardhat";
import { formatEther, parseEther } from "viem";
import fs from "fs";
import path from "path";

async function main() {
    const [deployer, client1] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();
    const deployerBalance = await publicClient.getBalance({
        address: deployer.account.address,
    });
    const client1Balance = await publicClient.getBalance({
        address: deployer.account.address,
    });
    console.log(`Deployer balance: ${formatEther(deployerBalance)} ETH`);
    console.log(`Client1 balance: ${formatEther(client1Balance)} ETH`);

    console.log("Deploying contracts with the account:", deployer.account.address);

    // 1. Deploy ERC20 token
    const initialSupply = 1_000_000_000;

    const erc20 = await hre.viem.deployContract("StakeToken", [
        initialSupply,
    ]);
    let symbol = await erc20.read.symbol();
    console.log(`StakeToken (${symbol}) deployed to: ${erc20.address}`);
    console.log(`\tTotal supply of ${symbol}: ${await erc20.read.totalSupply()}\n`);

    // 2. Deploy Staking contract
    // (0.01 * 86400 = 864 tokenes per day)
    const initialRewardRate = parseEther("0.01");

    const stakingContract = await hre.viem.deployContract("Staking", [
        erc20.address,
        initialRewardRate,
    ]);
    console.log(`Staking contract deployed to: ${stakingContract.address}`);
    console.log(`\tRewardRate: ${await stakingContract.read.rewardRate()}\n`);

    // 3. Transfer reward tokens to the Staking contract
    const rewardSupply = parseEther("10000000");
    console.log(`\tTransferring ${formatEther(rewardSupply)} ${symbol} to Staking contract for rewards...`);
    const transferTx = await erc20.write.transfer([stakingContract.address, rewardSupply], {
        account: deployer.account,
    });
    await publicClient.waitForTransactionReceipt({ hash: transferTx });
    console.log("\tReward tokens transferred.");

    // 4. Approve the Staking contract to spend STK tokens
    const approveAmount = parseEther("100000");
    console.log(`\tApproving Staking contract to spend ${formatEther(approveAmount)} ${symbol} for ${deployer.account.address}...`);
    const approveTx = await erc20.write.approve([stakingContract.address, approveAmount], {
        account: deployer.account
    });
    await publicClient.waitForTransactionReceipt({ hash: approveTx });
    console.log("\tApproval successful.");


    // Save contract addresses and ABIs to frontend
    saveFrontendFiles("StakeToken", erc20.address, erc20.abi);
    saveFrontendFiles("StakingContract", stakingContract.address, stakingContract.abi);

    console.log("\n--- DEPLOYMENT COMPLETE ---");
    console.log("Deployer address:", deployer.account.address);
    console.log("ERC20 address:", erc20.address);
    console.log("StakingContract address:", stakingContract.address);
    console.log("---------------------------\n");
}


function saveFrontendFiles(name: string, address: string, abi: any) {
    const contractsDir = path.resolve(__dirname, "..", "frontend3", "contracts");

    if (!fs.existsSync(contractsDir)) {
        fs.mkdirSync(contractsDir, { recursive: true });
    }

    const contractData = {
        address: address,
        abi: abi
    };
    const filePath = path.join(contractsDir, `${name}.contract.json`);

    fs.writeFileSync(
        filePath,
        JSON.stringify(contractData, null, 2)
    );
    console.log(`Contract data for "${name}" saved to: ${filePath}`);



}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});