// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

contract RestrictedFunctions {
  /*
    Base functions that should be restricted for every lent NFTs
    */
  bytes4 internal constant setApprovalForAll =
    bytes4(keccak256("setApprovalForAll(address,bool)"));
  bytes4 internal constant approve =
    bytes4(keccak256("approve(address,uint256)"));
  bytes4 internal constant safeTransferFromERC721 =
    bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
  bytes4 internal constant transferFromERC721 =
    bytes4(keccak256("transferFrom(address,address,uint256)"));
  bytes4 internal constant safeTransferFromWithBytesERC721 =
    bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
  bytes4 internal constant safeTransferFromERC1155 =
    bytes4(
      keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")
    );
  bytes4 internal constant safeBatchTransferFromERC1155 =
    bytes4(
      keccak256(
        "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"
      )
    );
  bytes4 internal constant burn = bytes4(keccak256("burn(uint256)"));
  bytes4 internal constant _burn = bytes4(keccak256("_burn(uint256)"));

  /*
  Restricted function for CryptoBlades contracts
  Index 1
  */

  bytes4 internal constant burnCharactersIntoSoul =
    bytes4(keccak256("burnCharactersIntoSoul(uint256[])"));
  bytes4 internal constant burnWeapons =
    bytes4(keccak256("burnWeapons(uint256[])"));
  bytes4 internal constant reforgeWeapon =
    bytes4(keccak256("reforgeWeapon(uint256,uint256)"));
  bytes4 internal constant reforgeWeaponWithDust =
    bytes4(keccak256("reforgeWeaponWithDust(uint256,uint8,uint8,uint8)"));
  bytes4 internal constant burnWeaponsUsingStakedSkill =
    bytes4(keccak256("burnWeaponsUsingStakedSkill(uint256[])"));
  bytes4 internal constant reforgeWeaponUsingStakedSkill =
    bytes4(keccak256("reforgeWeaponUsingStakedSkill(uint256[],uint256)"));
  bytes4 internal constant reforgeWeaponWithDustUsingStakedSkill =
    bytes4(
      keccak256(
        "reforgeWeaponWithDustUsingStakedSkill(uint256,uint8,uint8,uint8)"
      )
    );
  bytes4 internal constant burnIntoSoul =
    bytes4(keccak256("burnIntoSoul(uint256[])"));
  bytes4 internal constant burnCharacterFromMarket =
    bytes4(keccak256("burnCharacterFromMarket(uint256)"));
  bytes4 internal constant burnCharactersIntoCharacter =
    bytes4(keccak256("burnCharactersIntoCharacter(uint256[],uint256)"));
  bytes4 internal constant burnIntoCharacter =
    bytes4(keccak256("burnIntoCharacter(uint256[],uint256,uint256)"));
}
