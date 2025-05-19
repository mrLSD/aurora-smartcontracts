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
    console.log("Deployer balance: ${formatEther(deployerBalance)} ETH");
    console.log("Client1 balance: ${formatEther(client1Balance)} ETH");

    console.log("Deploying contracts with the account:", deployer.account.address);

    // 1. Deploy ERC20 token
    const initialSupply = parseEther("1000000000");

    const erc20 = await hre.viem.deployContract("StakeToken", [
        initialSupply,
    ]);
    console.log(`StakeToken (STK) deployed to: ${erc20.address}`);

    // 2. Deploy Staking contract
    // (0.01 * 86400 = 864 tokenes per day)
    const initialRewardRate = parseEther("0.01");

    const stakingContract = await hre.viem.deployContract("Staking", [
        erc20.address,
        initialRewardRate,
    ]);
    console.log(`Staking contract deployed to: ${stakingContract.address}`);

    console.log(`Total supply of STK: ${erc20.read.totalSupply()}`);

    // 3. Transfer reward tokens to the Staking contract
    const rewardSupply = parseEther("1000000"); // 100,000 токенов для наград
    console.log(`Transferring ${formatEther(rewardSupply)} STK to Staking contract for rewards...`);
    const transferTx = await erc20.write.transfer([stakingContract.address, rewardSupply], {
        account: deployer.account,
    });
    await publicClient.waitForTransactionReceipt({ hash: transferTx });
    console.log("Reward tokens transferred.");

    // 4. Approve the Staking contract to spend STK tokens
    const approveAmount = parseEther("100000");
    console.log(`Approving Staking contract to spend ${formatEther(approveAmount)} STK for ${deployer.account.address}...`);
    const approveTx = await erc20.write.approve([stakingContract.address, approveAmount], {
        account: deployer.account
    });
    await publicClient.waitForTransactionReceipt({ hash: approveTx });
    console.log("Approval successful.");


    // Save contract addresses and ABIs to frontend
    saveFrontendFiles("StakeToken", erc20.address, erc20.abi);
    saveFrontendFiles("StakeingContract", stakingContract.address, stakingContract.abi);

    console.log("\n--- DEPLOYMENT COMPLETE ---");
    console.log("Deployer address:", deployer.account.address);
    console.log("ERC20 address:", erc20.address);
    console.log("StakingContract address:", stakingContract.address);
    console.log("---------------------------\n");
    console.log("NEXT STEPS:");
}


function saveFrontendFiles(name: string, address: string, abi: any) {
    const contractsDir = path.resolve(__dirname, "..", "frontend", "src", "contracts");

    if (!fs.existsSync(contractsDir)) {
        fs.mkdirSync(contractsDir, { recursive: true });
    }

    fs.writeFileSync(
        path.join(contractsDir, `${name}-abi.json`),
        JSON.stringify({ abi }, null, 2)
    );


    const addressPath = path.join(contractsDir, "${name}-address.json");

    let addresses: Record<string, string> = {};
    if (fs.existsSync(addressPath)) {
        addresses = JSON.parse(fs.readFileSync(addressPath, "utf8"));
    }

    addresses[name] = address;

    fs.writeFileSync(addressPath, JSON.stringify(addresses, null, 2));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});