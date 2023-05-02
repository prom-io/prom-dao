// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../PromDaoGovernanceWrap.sol";

// This contract is designed to simulate a reentracy attack on the contract
contract ReentrancyAttacker {
    PromDaoGovernanceWrap public wrapContract;
    uint256 public attackCount;

    constructor(PromDaoGovernanceWrap _wrapContract) {
        wrapContract = _wrapContract;
    }

    function approveWrap(uint256 _amount) external {
        // Approve wrapContract to spend the attacker's Prom tokens
        IERC20(wrapContract.prom()).approve(address(wrapContract), _amount);
    }

    function simulateWrapReentrancyAttack(uint256 _amount) external {
        // Check if the attacker has enough balance in the Prom token
        require(
            IERC20(wrapContract.prom()).balanceOf(address(this)) >= _amount,
            "Not enough Prom tokens"
        );

        wrapReentrancy(_amount);
    }

    function wrapReentrancy(uint256 _amount) internal {
        for (uint i = 0; i < 10; i++) {
            wrapContract.wrap(_amount);
        }
    }

    function simulateUnwrapReentrancyAttack(uint256 _amount) external {
        // Check if the attacker has enough balance in the wrapped Prom token
        require(
            IERC20(address(wrapContract)).balanceOf(address(this)) >= _amount,
            "Not enough wrapped Prom tokens"
        );

        attackCount = 0;
        unwrapReentrancy(_amount);
    }

    function unwrapReentrancy(uint256 _amount) internal {
        if (attackCount >= 10) {
            return;
        }
        attackCount++;

        wrapContract.unwrap(_amount);

        unwrapReentrancy(_amount);
    }
}
