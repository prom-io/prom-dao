import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { TERC20 } from "../typechain-types/contracts/helpers/TERC20";
import { PromDaoGovernanceWrap } from "../typechain-types/contracts/PromDaoGovernanceWrap";
import { ReentrancyAttacker } from "../typechain-types/contracts/helpers/ReentranctAttacker.sol/ReentrancyAttacker";

describe("Smoke functionality of Prom DAO", () => {
  context("Smoke tests", async () => {
    let deployer: SignerWithAddress,
      hacker: SignerWithAddress,
      user: SignerWithAddress,
      promOwner: SignerWithAddress;
    let prom: TERC20;
    let wrap: PromDaoGovernanceWrap;

    before(async () => {
      [deployer, hacker, user, promOwner] = await ethers.getSigners();
      prom = (await (
        await (await ethers.getContractFactory("TERC20"))
          .connect(promOwner)
          .deploy("Prom", "PROM", 100)
      ).deployed()) as TERC20;
      wrap = (await (
        await (await ethers.getContractFactory("PromDaoGovernanceWrap"))
          .connect(deployer)
          .deploy(prom.address)
      ).deployed()) as PromDaoGovernanceWrap;
      await prom
        .connect(promOwner)
        .transfer(hacker.address, ethers.utils.parseEther("10"));
      await prom
        .connect(promOwner)
        .transfer(user.address, ethers.utils.parseEther("10"));
    });

    it("should not let wrap tokens if not approved", async () => {
      await expect(wrap.connect(user).wrap(2)).to.be.revertedWith(
        "ERC20: insufficient allowance"
      );
    });
    it("should let wrap correct amount of tokens and return correct amount of wrapped tokens", async () => {
      await prom
        .connect(user)
        .approve(wrap.address, ethers.utils.parseEther("2"));
      await expect(wrap.connect(user).wrap(ethers.utils.parseEther("2"))).not.to
        .be.reverted;
      expect(await wrap.balanceOf(user.address)).to.be.equal(
        ethers.utils.parseEther("2")
      );
      expect(await prom.balanceOf(wrap.address)).to.be.equal(
        ethers.utils.parseEther("2")
      );
      expect(await prom.balanceOf(user.address)).to.be.equal(
        ethers.utils.parseEther("8")
      );
    });
    it("should not let call approve of wrapped token", async () => {
      await prom
        .connect(hacker)
        .approve(wrap.address, ethers.utils.parseEther("2"));
      await wrap.connect(hacker).wrap(ethers.utils.parseEther("2"));
      await expect(
        wrap.connect(hacker).approve(user.address, 15)
      ).to.be.revertedWithCustomError(wrap, "ApprovesNotAllowed");
    });
    it("should not let call transfer of wrapped token", async () => {
      await expect(
        wrap.connect(hacker).transfer(user.address, 15)
      ).to.be.revertedWithCustomError(wrap, "TransfersNotAllowed");
    });
    it("should not let call transferFrom of wrapped token", async () => {
      await expect(
        wrap.connect(hacker).transfer(user.address, 15)
      ).to.be.revertedWithCustomError(wrap, "TransfersNotAllowed");
      await wrap.connect(hacker).unwrap(ethers.utils.parseEther("2"));
    });
    it("should not fall for reentrancy attack in wrapping", async () => {
      const reentrancy = (await (
        await (
          await ethers.getContractFactory("ReentrancyAttacker")
        ).deploy(wrap.address)
      ).deployed()) as ReentrancyAttacker;

      await prom
        .connect(promOwner)
        .transfer(reentrancy.address, ethers.utils.parseEther("11"));

      await reentrancy
        .connect(hacker)
        .approveWrap(ethers.utils.parseEther("11"));
      await reentrancy
        .connect(hacker)
        .simulateWrapReentrancyAttack(ethers.utils.parseEther("1"));

      expect(await wrap.balanceOf(reentrancy.address)).to.be.equal(
        ethers.utils.parseEther("10")
      );
      expect(await prom.balanceOf(reentrancy.address)).to.be.equal(
        ethers.utils.parseEther("1")
      );
      expect(await prom.balanceOf(wrap.address)).to.be.equal(
        ethers.utils.parseEther("12")
      );
    });

    it("should let unwrap tokens correctly", async () => {
      const balanceWrapUserBefore = await wrap.balanceOf(user.address);
      const balancePromUserBefore = await prom.balanceOf(user.address);
      const balancePromWrapBefore = await prom.balanceOf(wrap.address);
      await expect(wrap.connect(user).unwrap(ethers.utils.parseEther("1"))).not
        .to.be.reverted;
      expect(await prom.balanceOf(wrap.address)).to.be.equal(
        balancePromWrapBefore.sub(ethers.utils.parseEther("1"))
      );
      expect(await prom.balanceOf(user.address)).to.be.equal(
        balancePromUserBefore.add(ethers.utils.parseEther("1"))
      );
      expect(await wrap.balanceOf(user.address)).to.be.equal(
        balanceWrapUserBefore.sub(ethers.utils.parseEther("1"))
      );
    });
    it("should not let unwrap tokens if there are none at users account", async () => {
      expect(await wrap.balanceOf(hacker.address)).to.be.equal(0);
      expect(await prom.balanceOf(wrap.address)).to.be.equal(
        ethers.utils.parseEther("11")
      );
      await expect(
        wrap.connect(hacker).unwrap(ethers.utils.parseEther("1"))
      ).to.be.revertedWithCustomError(wrap, "NotEnoughPower");
    });
  });
});
