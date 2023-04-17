// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error TransfersNotAllowed();
error ApprovesNotAllowed();
error NotEnoughPower();
error ZeroAddress();

contract PromDaoGovernanceWrap is ReentrancyGuard, ERC20 {
    IERC20 public immutable prom;

    mapping(address => uint256) public wrappedValue;

    event Wrapped(uint256 amount);
    event Unwrapped(uint256 amount);

    constructor(IERC20 _prom) ERC20("Prom Fee Influence Power", "PFIP") {
        if (address(_prom) == address(0)) {
            revert ZeroAddress();
        }
        prom = _prom;
    }

    function _transfer(
        address owner,
        address to,
        uint256 amount
    ) internal virtual override {
        revert TransfersNotAllowed();
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        revert ApprovesNotAllowed();
    }

    function wrap(uint256 _amount) external nonReentrant {
        if (prom.balanceOf(msg.sender) < _amount) {
            revert NotEnoughPower();
        }
        prom.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        emit Wrapped(_amount);
    }

    function unwrap(uint256 _amount) external nonReentrant {
        if (IERC20(address(this)).balanceOf(msg.sender) < _amount) {
            revert NotEnoughPower();
        }
        // TODO:
        // Check if there are votes done by msg.sender.
        // If there are any - decrease them by _amount
        _burn(msg.sender, _amount);
        prom.transfer(msg.sender, _amount);
        emit Unwrapped(_amount);
    }
}
