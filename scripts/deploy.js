const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const paymentToken = await ERC20Mock.deploy("Mock Token", "MTK", 18);
    await paymentToken.waitForDeployment();
    const paymentTokenAddress = await paymentToken.getAddress();
    console.log("Mock Token deployed to:", paymentTokenAddress);

    const SubscriptionPlugin = await ethers.getContractFactory("SubscriptionPlugin");
    const subscriptionPlugin = await SubscriptionPlugin.deploy(paymentTokenAddress, ethers.parseUnits("1", 18), 30 * 24 * 60 * 60);
    await subscriptionPlugin.waitForDeployment();
    const subscriptionPluginAddress = await subscriptionPlugin.getAddress();
    console.log("Subscription Plugin deployed to:", subscriptionPluginAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
