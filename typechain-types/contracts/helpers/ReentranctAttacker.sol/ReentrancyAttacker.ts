/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../../common";

export interface ReentrancyAttackerInterface extends utils.Interface {
  functions: {
    "approveWrap(uint256)": FunctionFragment;
    "attackCount()": FunctionFragment;
    "simulateUnwrapReentrancyAttack(uint256)": FunctionFragment;
    "simulateWrapReentrancyAttack(uint256)": FunctionFragment;
    "wrapContract()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "approveWrap"
      | "attackCount"
      | "simulateUnwrapReentrancyAttack"
      | "simulateWrapReentrancyAttack"
      | "wrapContract"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "approveWrap",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "attackCount",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "simulateUnwrapReentrancyAttack",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "simulateWrapReentrancyAttack",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "wrapContract",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "approveWrap",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "attackCount",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "simulateUnwrapReentrancyAttack",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "simulateWrapReentrancyAttack",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "wrapContract",
    data: BytesLike
  ): Result;

  events: {};
}

export interface ReentrancyAttacker extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ReentrancyAttackerInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    approveWrap(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    attackCount(overrides?: CallOverrides): Promise<[BigNumber]>;

    simulateUnwrapReentrancyAttack(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    simulateWrapReentrancyAttack(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    wrapContract(overrides?: CallOverrides): Promise<[string]>;
  };

  approveWrap(
    _amount: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  attackCount(overrides?: CallOverrides): Promise<BigNumber>;

  simulateUnwrapReentrancyAttack(
    _amount: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  simulateWrapReentrancyAttack(
    _amount: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  wrapContract(overrides?: CallOverrides): Promise<string>;

  callStatic: {
    approveWrap(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    attackCount(overrides?: CallOverrides): Promise<BigNumber>;

    simulateUnwrapReentrancyAttack(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    simulateWrapReentrancyAttack(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    wrapContract(overrides?: CallOverrides): Promise<string>;
  };

  filters: {};

  estimateGas: {
    approveWrap(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    attackCount(overrides?: CallOverrides): Promise<BigNumber>;

    simulateUnwrapReentrancyAttack(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    simulateWrapReentrancyAttack(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    wrapContract(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    approveWrap(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    attackCount(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    simulateUnwrapReentrancyAttack(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    simulateWrapReentrancyAttack(
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    wrapContract(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
