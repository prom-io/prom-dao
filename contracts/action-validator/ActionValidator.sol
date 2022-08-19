// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./RestrictedFunctions.sol";
import "./RestrictedContracts.sol";

interface IPrometaAddressRegistry {
  function marketplace() external view returns (address);

  function vaultManager() external view returns (address);
}

interface IVaultManager {
  function lending(address, uint256)
    external
    view
    returns (
      address,
      uint256,
      address
    );

  function isItemLent(address, uint256) external view returns (bool);
}

contract ActionValidator is RestrictedFunctions, RestrictedContracts {
  IPrometaAddressRegistry public addressRegistry;
  bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

  constructor(address _addressRegistry) {
    addressRegistry = IPrometaAddressRegistry(_addressRegistry);
  }

  function validateAction(address _nftAddress, bytes calldata _data)
    external
    view
  {
    IVaultManager vaultManager = IVaultManager(addressRegistry.vaultManager());
    if (isContractRestricted[_nftAddress] == 0) {
      _validateStandardAction(_nftAddress, _data, vaultManager);
    } else {
      if (isContractRestricted[_nftAddress] == 1) {
        _validateCryptoBladesAction(_nftAddress, _data, vaultManager);
      }
    }
  }

  function _validateCryptoBladesAction(
    address,
    bytes calldata _data,
    IVaultManager vaultManager
  ) internal view {
    bytes4 data = bytes4(_data[:4]);
    if (data == burnWeapons || data == burnWeaponsUsingStakedSkill) {
      uint256[] memory tokenIds = abi.decode(_data[4:], (uint256[]));
      _validateActions(cbWeapons, tokenIds, vaultManager);
    } else if (data == burnCharactersIntoSoul || data == burnIntoSoul) {
      uint256[] memory tokenIds = abi.decode(_data[4:], (uint256[]));
      _validateActions(cbCharacters, tokenIds, vaultManager);
    } else if (data == burnCharacterFromMarket) {
      uint256 tokenId = abi.decode(_data[4:], (uint256));
      _validateAction(cbCharacters, tokenId, vaultManager);
    } else if (data == burnCharactersIntoCharacter) {
      (uint256[] memory tokenIds, uint256 tokenId) = abi.decode(
        _data[4:],
        (uint256[], uint256)
      );
      _validateActions(cbCharacters, tokenIds, vaultManager);
      _validateAction(cbCharacters, tokenId, vaultManager);
    } else if (data == burnIntoCharacter) {
      (uint256[] memory tokenIds, uint256 tokenId, uint256 tokenId2) = abi
        .decode(_data[4:], (uint256[], uint256, uint256));
      _validateActions(cbCharacters, tokenIds, vaultManager);
      _validateAction(cbCharacters, tokenId, vaultManager);
      _validateAction(cbCharacters, tokenId2, vaultManager);
    } else if (data == reforgeWeapon) {
      (uint256 tokenIdA, uint256 tokenIdB) = abi.decode(
        _data[4:],
        (uint256, uint256)
      );
      _validateAction(cbWeapons, tokenIdA, vaultManager);

      _validateAction(cbWeapons, tokenIdB, vaultManager);
    } else if (
      data == reforgeWeaponWithDust ||
      data == reforgeWeaponWithDustUsingStakedSkill
    ) {
      (uint256 tokenId, , , ) = abi.decode(
        _data[4:],
        (uint256, uint8, uint8, uint8)
      );
      _validateAction(cbWeapons, tokenId, vaultManager);
    } else if (data == reforgeWeaponUsingStakedSkill) {
      (uint256[] memory tokenIdsA, uint256 tokenIdB) = abi.decode(
        _data[4:],
        (uint256[], uint256)
      );
      _validateActions(cbWeapons, tokenIdsA, vaultManager);
      _validateAction(cbWeapons, tokenIdB, vaultManager);
    }
  }

  function _validateStandardAction(
    address _nftAddress,
    bytes calldata _data,
    IVaultManager vaultManager
  ) internal view {
    bytes4 data = bytes4(_data[:4]);

    if (data == approve) {
      (address to, uint256 tokenId) = abi.decode(_data[4:], (address, uint256));
      (, , address lender) = vaultManager.lending(_nftAddress, tokenId);

      if (lender != address(0)) {
        require(
          to == addressRegistry.vaultManager(),
          "Only VaultManager may have approval"
        );
      }
    } else if (data == setApprovalForAll) {
      (address to, bool boolean) = abi.decode(_data[4:], (address, bool));
      require(
        to == addressRegistry.vaultManager(),
        "Only VaultManager may have approval for ERC1155"
      );
      require(boolean != false, "Can't remove approval from VaultManager");
    } else if (data == safeTransferFromERC721 || data == transferFromERC721) {
      (, , uint256 tokenId) = abi.decode(
        _data[4:],
        (address, address, uint256)
      );
      _validateAction(_nftAddress, tokenId, vaultManager);
    } else if (data == safeTransferFromWithBytesERC721) {
      (, , uint256 tokenId, ) = abi.decode(
        _data[4:],
        (address, address, uint256, bytes)
      );
      _validateAction(_nftAddress, tokenId, vaultManager);
    } else if (data == safeTransferFromERC1155) {
      (, , uint256 tokenId, , ) = abi.decode(
        _data[4:],
        (address, address, uint256, uint256, bytes)
      );
      _validateAction(_nftAddress, tokenId, vaultManager);
    } else if (data == safeBatchTransferFromERC1155) {
      (, , uint256[] memory tokenIds, , ) = abi.decode(
        _data[4:],
        (address, address, uint256[], uint256[], bytes)
      );

      _validateActions(_nftAddress, tokenIds, vaultManager);
    } else if (data == burn || data == _burn) {
      uint256 tokenId = abi.decode(_data[4:], (uint256));
      _validateAction(_nftAddress, tokenId, vaultManager);
    }
  }

  function _validateAction(
    address _nftAddress,
    uint256 _tokenId,
    IVaultManager vaultManager
  ) internal view {
    (, , address lender) = vaultManager.lending(_nftAddress, _tokenId);

    require(lender == address(0), "Transfers of lent assets are restricted");
  }

  function _validateActions(
    address _nftAddress,
    uint256[] memory _tokenIds,
    IVaultManager vaultManager
  ) internal view {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _validateAction(_nftAddress, _tokenIds[i], vaultManager);
    }
  }
}
