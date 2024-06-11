const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SubscriptionPlugin with Algebra Integration", function () {
    let subscriptionPlugin;
    let paymentToken;
    let swapRouter;
    let owner;
    let addr1;
    let addr2;

    this.timeout(60000); // Увеличение тайм-аута до 60 секунд

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        // Deploy mock ERC20 token
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        paymentToken = await ERC20Mock.deploy("MockToken", "MTK", 18);
        await paymentToken.waitForDeployment();

        // Mint some tokens
        await paymentToken.mint(owner.address, ethers.parseUnits("1000", 18));
        await paymentToken.mint(addr1.address, ethers.parseUnits("1000", 18));

        // Deploy mock SwapRouter
        const SwapRouterMock = await ethers.getContractFactory("SwapRouterMock");
        swapRouter = await SwapRouterMock.deploy();
        await swapRouter.waitForDeployment();

        // Deploy SubscriptionPlugin
        const SubscriptionPlugin = await ethers.getContractFactory("SubscriptionPlugin");
        subscriptionPlugin = await SubscriptionPlugin.deploy(
            paymentToken.target, // Используйте target вместо getAddress для получения корректного адреса
            ethers.parseUnits("10", 18),
            30 * 24 * 60 * 60,
            swapRouter.target // Используйте target вместо getAddress для получения корректного адреса
        );
        await subscriptionPlugin.waitForDeployment();
    });

    it("should subscribe and allow swap", async function () {
        // Approve and subscribe
        await paymentToken.connect(addr1).approve(subscriptionPlugin.target, ethers.parseUnits("10", 18));
        await subscriptionPlugin.connect(addr1).subscribe();

        const expiration = await subscriptionPlugin.s_subscriptions(addr1.address);
        expect(expiration).to.be.gt(0);

        // Perform swap
        await paymentToken.connect(addr1).approve(subscriptionPlugin.target, ethers.parseUnits("10", 18));
        const tx = await subscriptionPlugin.connect(addr1).swapExactInputSingle(
            ethers.parseUnits("10", 18),
            paymentToken.target,
            paymentToken.target
        );
        await tx.wait(); // Wait for transaction to complete
    });

    it("should revert swap if not subscribed", async function () {
        await expect(
            subscriptionPlugin.connect(addr2).swapExactInputSingle(
                ethers.parseUnits("10", 18),
                paymentToken.target,
                paymentToken.target
            )
        ).to.be.revertedWithCustomError(subscriptionPlugin, "SubscriptionRequired");
    });

    it("should revert if already subscribed", async function () {
        // Approve and subscribe the first time
        await paymentToken.connect(addr1).approve(subscriptionPlugin.target, ethers.parseUnits("10", 18));
        await subscriptionPlugin.connect(addr1).subscribe();

        // Try to subscribe again before expiration
        await expect(subscriptionPlugin.connect(addr1).subscribe()).to.be.revertedWithCustomError(subscriptionPlugin, "AlreadySubscribed");
    });

    it("should allow admin to withdraw funds", async function () {
        // Mint additional tokens to addr1
        await paymentToken.mint(addr1.address, ethers.parseUnits("100", 18));

        // Approve and subscribe
        await paymentToken.connect(addr1).approve(subscriptionPlugin.target, ethers.parseUnits("10", 18));
        await subscriptionPlugin.connect(addr1).subscribe();

        // Check contract balance
        let contractBalance = await paymentToken.balanceOf(subscriptionPlugin.target);
        expect(contractBalance).to.equal(ethers.parseUnits("10", 18));

        // Withdraw funds
        await subscriptionPlugin.connect(owner).withdraw();

        // Check contract balance after withdrawal
        contractBalance = await paymentToken.balanceOf(subscriptionPlugin.target);
        expect(contractBalance).to.equal(0);

        // Check admin balance after withdrawal
        const adminBalance = await paymentToken.balanceOf(owner.address);
        expect(adminBalance).to.equal(ethers.parseUnits("1010", 18));
    });
});
