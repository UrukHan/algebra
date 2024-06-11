const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SubscriptionPlugin with Algebra Integration", function () {
    let subscriptionPlugin;
    let paymentToken;
    let swapRouter;
    let owner;
    let addr1;
    let addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        // Deploy mock ERC20 token
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        paymentToken = await ERC20Mock.deploy("MockToken", "MTK", 18);
        await paymentToken.waitForDeployment();
        const paymentTokenAddress = await paymentToken.getAddress();
        console.log("ERC20Mock deployed to:", paymentTokenAddress);

        // Mint some tokens
        await paymentToken.mint(owner.address, ethers.parseUnits("1000", 18));
        await paymentToken.mint(addr1.address, ethers.parseUnits("1000", 18));

        // Deploy mock SwapRouter
        const SwapRouterMock = await ethers.getContractFactory("SwapRouterMock");
        swapRouter = await SwapRouterMock.deploy();
        await swapRouter.waitForDeployment();
        const swapRouterAddress = await swapRouter.getAddress();
        console.log("SwapRouterMock deployed to:", swapRouterAddress);

        // Deploy SubscriptionPlugin
        const SubscriptionPlugin = await ethers.getContractFactory("SubscriptionPlugin");
        subscriptionPlugin = await SubscriptionPlugin.deploy(paymentTokenAddress, ethers.parseUnits("10", 18), 30 * 24 * 60 * 60);
        await subscriptionPlugin.waitForDeployment();
        const subscriptionPluginAddress = await subscriptionPlugin.getAddress();
        console.log("SubscriptionPlugin deployed to:", subscriptionPluginAddress);

        // Set plugin in SwapRouterMock
        await swapRouter.setPlugin(subscriptionPluginAddress);
    });

    it("should subscribe and allow swap", async function () {
        // Approve and subscribe
        await paymentToken.connect(addr1).approve(subscriptionPlugin.getAddress(), ethers.parseUnits("10", 18));
        await subscriptionPlugin.connect(addr1).subscribe();

        const expiration = await subscriptionPlugin.subscriptions(addr1.address);
        expect(expiration).to.be.gt(0);

        await paymentToken.connect(addr1).approve(swapRouter.getAddress(), ethers.parseUnits("10", 18));
        await swapRouter.connect(addr1).swapExactInputSingle({
            tokenIn: paymentToken.getAddress(),
            tokenOut: paymentToken.getAddress(),
            recipient: addr1.getAddress(),
            deadline: Math.floor(Date.now() / 1000) + 60 * 10,
            amountIn: ethers.parseUnits("10", 18),
            amountOutMinimum: 0,
            limitSqrtPrice: 0
        });
    });

    it("should revert swap if not subscribed", async function () {
        await expect(
            swapRouter.connect(addr2).swapExactInputSingle({
                tokenIn: paymentToken.getAddress(),
                tokenOut: paymentToken.getAddress(),
                recipient: addr2.getAddress(),
                deadline: Math.floor(Date.now() / 1000) + 60 * 10,
                amountIn: ethers.parseUnits("10", 18),
                amountOutMinimum: 0,
                limitSqrtPrice: 0
            })
        ).to.be.revertedWith("Subscription required");
    });
});
