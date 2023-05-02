import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { TERC20 } from "../typechain-types/contracts/helpers/TERC20";
import { PromDaoGovernanceWrap } from "../typechain-types/contracts/PromDaoGovernanceWrap";
import { PromFieldSettingDao } from "../typechain-types/contracts/PromFeesDao.sol";
import { AddressRegistry } from "../typechain-types/contracts/helpers/AddressRegistry";
import { ReentrancyAttacker } from "../typechain-types/contracts/helpers/ReentranctAttacker.sol/ReentrancyAttacker";
import { latest } from "./utils/timeMethods";

describe("Smoke functionality of Prom DAO", () => {
  context("Smoke tests", async () => {
    let deployer: SignerWithAddress,
      hacker: SignerWithAddress,
      user: SignerWithAddress,
      promOwner: SignerWithAddress,
      emptyUser: SignerWithAddress;
    let prom: TERC20;
    let wrap: PromDaoGovernanceWrap;
    let addressRegistry: AddressRegistry;
    let feesDao: PromFieldSettingDao;

    const getProposal = async (index: number) => {
      const [
        deadlineTimestamp,
        marketplace,
        targetCollection,
        targetFee,
        proposalCreator,
        upvotes,
        downvotes,
      ] = await feesDao.proposal(index);

      return {
        deadlineTimestamp,
        marketplace,
        targetCollection,
        targetFee,
        proposalCreator,
        upvotes,
        downvotes,
      };
    };

    before(async () => {
      [deployer, hacker, user, promOwner, emptyUser] =
        await ethers.getSigners();
      addressRegistry = (await (
        await (await ethers.getContractFactory("AddressRegistry"))
          .connect(deployer)
          .deploy()
      ).deployed()) as AddressRegistry;
      prom = (await (
        await (await ethers.getContractFactory("TERC20"))
          .connect(promOwner)
          .deploy("Prom", "PROM", 100)
      ).deployed()) as TERC20;

      wrap = (await (
        await (await ethers.getContractFactory("PromDaoGovernanceWrap"))
          .connect(deployer)
          .deploy(prom.address, addressRegistry.address)
      ).deployed()) as PromDaoGovernanceWrap;
      await expect(
        (
          await ethers.getContractFactory("PromDaoGovernanceWrap")
        ).deploy(ethers.constants.AddressZero, ethers.constants.AddressZero)
      ).to.be.revertedWithCustomError(wrap, "ZeroAddress");
      feesDao = (await (
        await (
          await ethers.getContractFactory("PromFieldSettingDao")
        ).deploy(addressRegistry.address, ethers.utils.parseEther("15"))
      ).deployed()) as PromFieldSettingDao;
      await addressRegistry.setPromFeesDao(feesDao.address);
      await addressRegistry.setImplementationPower(wrap.address);
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
    it("should not let wrap token if there are non at the caller disposal", async () => {
      await expect(
        wrap.connect(emptyUser).wrap(1)
      ).to.be.revertedWithCustomError(wrap, "NotEnoughPower");
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
      expect(await wrap.balanceOf(hacker.address)).to.be.equal(0);
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
    it("should let create a proposal", async () => {
      await expect(feesDao.createFeeUpdateProposal(prom.address, 1000)).not.to
        .be.reverted;
      const {
        deadlineTimestamp,
        marketplace,
        targetCollection,
        targetFee,
        proposalCreator,
        upvotes,
        downvotes,
      } = await getProposal(1);
      expect(deadlineTimestamp).to.be.equal((await latest()).add(14 * 86400));
      expect(marketplace).to.be.equal(ethers.constants.AddressZero);
      expect(targetCollection).to.be.equal(prom.address);
      expect(targetFee).to.be.equal(1000);
      expect(proposalCreator).to.be.equal(deployer.address);
      expect(upvotes).to.be.equal(0);
      expect(downvotes).to.be.equal(0);
    });
    it("should let users with power to upvote", async () => {
      // User has 1 eth of power
      // Deployer & Hacker 0
      await expect(feesDao.connect(user).upvote(1)).not.to.be.reverted;
      expect((await getProposal(1)).upvotes).to.be.equal(
        ethers.utils.parseEther("1")
      );
    });
    it("should not abuse upvote with the same power", async () => {
      await expect(feesDao.connect(user).upvote(1)).not.to.be.reverted;
      expect((await getProposal(1)).upvotes).to.be.equal(
        ethers.utils.parseEther("1")
      );
    });
    it("should let update upvote with the new power", async () => {
      await prom
        .connect(user)
        .approve(wrap.address, ethers.utils.parseEther("1000"));
      await wrap.connect(user).wrap(ethers.utils.parseEther("1"));
      await expect(feesDao.connect(user).upvote(1)).not.to.be.reverted;
      expect((await getProposal(1)).upvotes).to.be.equal(
        ethers.utils.parseEther("2")
      );
    });
    it("should show ongoing proposals correctly (case single proposal)", async () => {
      expect((await feesDao.getOngoingProposals()).length).to.be.equal(1);
      expect((await feesDao.getOngoingProposals())[0]).to.be.equal(1);
    });
    it("should show participated proposals correctly (case single proposal)", async () => {
      expect(
        (await feesDao.getAllParticipatedProposalsByUser(user.address)).length
      ).to.be.equal(1);
      expect(
        (await feesDao.getAllParticipatedProposalsByUser(user.address))[0]
      ).to.be.equal(1);
    });
    it("should remove upvotes if voting power is unwrapped", async () => {
      expect((await getProposal(1)).upvotes).to.be.equal(
        ethers.utils.parseEther("2")
      );
      console.log("user: ", user.address);
      await wrap.connect(user).unwrap(ethers.utils.parseEther("2"));
      expect(await wrap.balanceOf(user.address)).to.be.equal(
        ethers.utils.parseEther("0")
      );
      expect((await getProposal(1)).upvotes).to.be.equal(
        ethers.utils.parseEther("0")
      );
    });
    it("should not change upvotes if voting with 0 power", async () => {});
    it("should let user with power to downvote", async () => {});
    it("should not abuse downvote with the same power", async () => {});
    it("should let update downvote with the new power", async () => {});
    it("should not change downvote if voting with 0 power", async () => {});
    it("should not let implement the proposal if threshold is not reached", async () => {});
    it("should let implement the proposal if threshold is reached", async () => {});
    it("should not let implement the same proposal twice if threshold is reached", async () => {});
    it("should not let users use the same proposal votes after implementation", async () => {});
    it("should let create new proposals after some proposal was implemented", async () => {});
    it("should not let implement upvote or downvote after deadline is reached", async () => {});
  });
});
