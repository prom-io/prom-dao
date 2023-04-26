/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IPromFeesDao,
  IPromFeesDaoInterface,
} from "../../../contracts/PromDaoGovernanceWrap.sol/IPromFeesDao";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    name: "cleanseAll",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export class IPromFeesDao__factory {
  static readonly abi = _abi;
  static createInterface(): IPromFeesDaoInterface {
    return new utils.Interface(_abi) as IPromFeesDaoInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IPromFeesDao {
    return new Contract(address, _abi, signerOrProvider) as IPromFeesDao;
  }
}