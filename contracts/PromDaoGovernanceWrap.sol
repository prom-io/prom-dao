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

interface IAddressRegistry {
    function promFeesDao() external returns (address);
}

interface IPromFeesDao {
    function cleanseAll(address, uint256) external;
}

contract PromDaoGovernanceWrap is ReentrancyGuard, ERC20 {
    IERC20 public immutable prom;
    IAddressRegistry public addressRegistry;

    mapping(address => uint256) public wrappedValue;

    event Wrapped(uint256 amount);
    event Unwrapped(uint256 amount);

    constructor(
        IERC20 _prom,
        IAddressRegistry _addressRegistry
    ) ERC20("Prom Fee Influence Power", "PFIP") {
        if (
            address(_prom) == address(0) ||
            address(_addressRegistry) == address(0)
        ) {
            revert ZeroAddress();
        }
        prom = _prom;
        addressRegistry = _addressRegistry;
    }

    function _transfer(address, address, uint256) internal virtual override {
        revert TransfersNotAllowed();
    }

    function _approve(address, address, uint256) internal virtual override {
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

        IPromFeesDao(addressRegistry.promFeesDao()).cleanseAll(
            msg.sender,
            _amount
        );
        _burn(msg.sender, _amount);
        prom.transfer(msg.sender, _amount);
        emit Unwrapped(_amount);
    }
}
