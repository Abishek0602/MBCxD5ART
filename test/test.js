const MBCPaymentSplitter = artifacts.require("MBCPaymentSplitter");
const assert = require("assert"); // <-- Built-in Node.js module
const { toWei } = web3.utils;



contract("MBCPaymentSplitter", (accounts) => {
  const [owner, d5artAdmin, d5artSubAdmin, jvWallet, user1, fakeUser] = accounts;

  const PRECISION = 1e6;
  const BONUS_PERCENT = 100000; // 10%
  const JV_PERCENT = 200000; // 20%

  const BASIC = 0;

  let contract;
  let originalPrice;
  let concessionPrice;

  beforeEach(async () => {
    originalPrice = toWei("1.5", "ether");
    concessionPrice = (BigInt(originalPrice) * BigInt(PRECISION - BONUS_PERCENT)) / BigInt(PRECISION);

    contract = await MBCPaymentSplitter.new(
      owner,
      d5artAdmin,
      d5artSubAdmin,
      jvWallet,
      originalPrice,
      originalPrice,
      originalPrice
    );
  });

  it("✅ should accept correct payment and split commissions", async () => {
    const jvBalanceBefore = BigInt(await web3.eth.getBalance(jvWallet));
    const mbcBalanceBefore = BigInt(await web3.eth.getBalance(owner));

    const tx = await contract.makePayment(BASIC, { from: user1, value: concessionPrice.toString() });

    const jvExpected = (BigInt(originalPrice) * BigInt(JV_PERCENT)) / BigInt(PRECISION);
    const bonusExpected = (BigInt(originalPrice) * BigInt(BONUS_PERCENT)) / BigInt(PRECISION);

    const jvBalanceAfter = BigInt(await web3.eth.getBalance(jvWallet));
    const mbcBalanceAfter = BigInt(await web3.eth.getBalance(owner));

    assert.equal(jvBalanceAfter - jvBalanceBefore, jvExpected, "JV should receive correct amount");
    assert.equal(mbcBalanceAfter - mbcBalanceBefore, bonusExpected, "MBC Admin should receive correct bonus");
  });

  it("❌ should revert on incorrect payment amount", async () => {
    try {
      await contract.makePayment(BASIC, { from: user1, value: toWei("1", "ether") });
      assert.fail("Payment should have reverted due to incorrect amount");
    } catch (error) {
      assert(error.message.includes("Incorrect payment amount"), "Expected revert on incorrect payment");
    }
  });

  it("❌ should reject direct Ether transfers (fallback)", async () => {
    try {
      await web3.eth.sendTransaction({
        from: user1,
        to: contract.address,
        value: toWei("1", "ether"),
      });
      assert.fail("Should have reverted on direct transfer");
    } catch (error) {
      assert(error.message.includes("revert"), "Expected revert on fallback");
    }
  });

  it("❌ should revert if unauthorized user tries to approve", async () => {
    try {
      await contract.approveRelease({ from: fakeUser });
      assert.fail("Should have reverted for unauthorized approval");
    } catch (error) {
      assert(error.message.includes("Unauthorized"), "Expected revert for non-admin approval");
    }
  });

  it("✅ should release funds to D5ART_ADMIN after both approvals", async () => {
    await contract.makePayment(BASIC, { from: user1, value: concessionPrice.toString() });

    const before = BigInt(await web3.eth.getBalance(d5artAdmin));

    const tx1 = await contract.approveRelease({ from: d5artSubAdmin });
    const tx2 = await contract.approveRelease({ from: d5artAdmin });

    const after = BigInt(await web3.eth.getBalance(d5artAdmin));

    assert(after > before, "D5ART_ADMIN should receive the remaining funds");
  });

  it("✅ should allow MBC admin to update MBC admin", async () => {
    await contract.updateMbcAdmin(fakeUser, { from: owner });
    const updated = await contract.MBC_ADMIN();
    assert.equal(updated, fakeUser);
  });

  it("❌ should prevent non-admin from updating MBC admin", async () => {
    try {
      await contract.updateMbcAdmin(user1, { from: user1 });
      assert.fail("Should not allow non-admin to update MBC admin");
    } catch (error) {
      assert(error.message.includes("Only MBC admin allowed"));
    }
  });

  it("✅ should allow D5ART admin to update subadmin", async () => {
    await contract.updateD5art_subAdmin(fakeUser, { from: d5artAdmin });
    const updated = await contract.D5ART_SUBADMIN();
    assert.equal(updated, fakeUser);
  });

  it("❌ should prevent non-D5ART admin from updating subadmin", async () => {
    try {
      await contract.updateD5art_subAdmin(fakeUser, { from: user1 });
      assert.fail("Only D5ART admin should be allowed");
    } catch (error) {
      assert(error.message.includes("Only D5Art admin allowed"));
    }
  });

  it("✅ should allow MBC admin to update JV wallet", async () => {
    await contract.updateJvWallet(fakeUser, { from: owner });
    const updated = await contract.JV_WALLET();
    assert.equal(updated, fakeUser);
  });

  it("❌ should prevent others from updating JV wallet", async () => {
    try {
      await contract.updateJvWallet(fakeUser, { from: user1 });
      assert.fail("Only MBC admin can update JV wallet");
    } catch (error) {
      assert(error.message.includes("Only MBC admin allowed"));
    }
  });

  it("✅ should allow MBC admin to update price", async () => {
    const newPrice = toWei("2", "ether");
    await contract.updatePrice(BASIC, newPrice, { from: owner });
    const updatedPrice = await contract.originalPrices(BASIC);
    assert.equal(updatedPrice.toString(), newPrice);
  });

  it("❌ should prevent others from updating price", async () => {
    try {
      await contract.updatePrice(BASIC, toWei("2", "ether"), { from: user1 });
      assert.fail("Only MBC admin should be allowed to update price");
    } catch (error) {
      assert(error.message.includes("Only MBC admin allowed"));
    }
  });

  it("✅ should return correct contract balance", async () => {
    await contract.makePayment(BASIC, { from: user1, value: concessionPrice.toString() });
    const balance = await contract.getContractBalance();
    assert(balance > 0, "Contract should hold remaining funds");
  });
});
