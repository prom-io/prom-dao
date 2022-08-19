// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RestrictedContracts is Ownable {
  event ContractRestrictionStatusSet(address _contract, uint256 _gameIndex);
  mapping(address => uint256) public isContractRestricted;

  address internal cbCharacters;
  address internal cbWeapons;

  function setIsContractRestricted(address _contract, uint256 _gameIndex)
    public
    onlyOwner
  {
    isContractRestricted[_contract] = _gameIndex;
  }

  function setCbContracts(address _cbCharacters, address _cbWeapons)
    public
    onlyOwner
  {
    cbCharacters = _cbCharacters;
    cbWeapons = _cbWeapons;
  }
}
